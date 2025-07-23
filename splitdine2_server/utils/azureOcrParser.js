/**
 * Azure OCR Parser
 * Parses raw Azure OCR data to extract menu items with prices
 */

/**
 * Parse Azure OCR detections to extract menu items
 * Uses a simple line-by-line approach based on the fullTextAnnotation
 * @param {Object} ocrResult - Full OCR result from Azure with detections and fullTextAnnotation
 * @returns {Object} - Parsed menu items ready for analysis
 */
function parseAzureOcrToMenuItems(ocrResult) {
  // Extract the full text from Azure OCR
  const fullText = ocrResult.fullTextAnnotation?.text || '';
  const detections = ocrResult.detections || [];
  
  if (!fullText) {
    console.log('[OcrParser] No full text found in OCR result');
    return {
      menuItems: [],
      detections: detections
    };
  }

  console.log('[OcrParser] Full text from Azure:');
  console.log(fullText);

  const menuItems = [];
  const lines = fullText.split('\n').map(line => line.trim()).filter(line => line.length > 0);
  
  console.log(`[OcrParser] Processing ${lines.length} lines`);

  // Look for item-price pairs
  for (let i = 0; i < lines.length; i++) {
    const currentLine = lines[i];
    
    // Skip obvious receipt noise
    if (isReceiptNoise(currentLine)) {
      console.log(`[OcrParser] Skipping noise: "${currentLine}"`);
      continue;
    }
    
    // Check if current line is a price
    if (isPotentialPrice(currentLine)) {
      // Look backwards for the item name
      if (i > 0) {
        const previousLine = lines[i - 1];
        if (!isReceiptNoise(previousLine) && !isPotentialPrice(previousLine)) {
          const price = extractPrice(currentLine);
          if (price !== null) {
            menuItems.push({
              name: previousLine,
              price: price,
              confidence: 0.9,
              foodScore: calculateFoodScore(previousLine),
              wordCount: previousLine.split(' ').length,
              isLikelyMenuItem: true,
              enhancedConfidence: 0.9,
              originalLine: previousLine + ' ' + currentLine
            });
            
            console.log(`[OcrParser] Found menu item: "${previousLine}" - £${price}`);
          }
        }
      }
    }
    
    // Also check if current line contains both item and price
    const words = currentLine.split(' ');
    const lastWord = words[words.length - 1];
    
    if (words.length > 1 && isPotentialPrice(lastWord)) {
      const itemName = words.slice(0, -1).join(' ');
      if (!isReceiptNoise(itemName)) {
        const price = extractPrice(lastWord);
        if (price !== null) {
          menuItems.push({
            name: itemName,
            price: price,
            confidence: 0.9,
            foodScore: calculateFoodScore(itemName),
            wordCount: itemName.split(' ').length,
            isLikelyMenuItem: true,
            enhancedConfidence: 0.9,
            originalLine: currentLine
          });
          
          console.log(`[OcrParser] Found menu item on same line: "${itemName}" - £${price}`);
        }
      }
    }
  }

  console.log(`[OcrParser] Found ${menuItems.length} menu items total`);
  
  return {
    menuItems: menuItems,
    detections: detections
  };
}

/**
 * Group detections by their Y position (same line on receipt)
 */
function groupDetectionsByLine(detections) {
  const groups = [];
  const used = new Set();
  
  detections.forEach((detection, index) => {
    if (used.has(index)) return;
    
    const group = {
      detections: [detection],
      minY: getMinY(detection),
      maxY: getMaxY(detection),
      avgY: getAvgY(detection),
      avgConfidence: detection.confidence || 0.9
    };
    
    // Find other detections on the same line
    detections.forEach((other, otherIndex) => {
      if (otherIndex === index || used.has(otherIndex)) return;
      
      const otherAvgY = getAvgY(other);
      
      // Check if Y positions overlap (same line)
      if (otherAvgY >= group.minY - 10 && otherAvgY <= group.maxY + 10) {
        group.detections.push(other);
        group.minY = Math.min(group.minY, getMinY(other));
        group.maxY = Math.max(group.maxY, getMaxY(other));
        group.avgConfidence = (group.avgConfidence + (other.confidence || 0.9)) / 2;
        used.add(otherIndex);
      }
    });
    
    // Sort detections in group by X position (left to right)
    group.detections.sort((a, b) => getAvgX(a) - getAvgX(b));
    
    groups.push(group);
    used.add(index);
  });
  
  // Sort groups by Y position (top to bottom)
  return groups.sort((a, b) => a.avgY - b.avgY);
}

/**
 * Check if text is likely a price
 */
function isPotentialPrice(text) {
  // Match various price formats
  const pricePatterns = [
    /^[£$]?\d+\.?\d*[£$]?$/,  // £10.50, $10, 10.50£
    /^\d+\.\d{2}$/,            // 10.50
    /^[£$]\d+$/,               // £10, $10
    /^\d+$/                    // 10 (whole number prices)
  ];
  
  return pricePatterns.some(pattern => pattern.test(text));
}

/**
 * Extract numeric price value from text
 */
function extractPrice(text) {
  const cleaned = text.replace(/[£$,]/g, '');
  const price = parseFloat(cleaned);
  
  // Validate reasonable price range
  if (!isNaN(price) && price >= 0.01 && price <= 9999.99) {
    return price;
  }
  
  return null;
}

/**
 * Check if text is common receipt noise to filter out
 */
function isReceiptNoise(text) {
  const noisePatterns = [
    /^(THANK|YOU|PLEASE|CALL|AGAIN|DATE|TIME|CASH|CARD|CHANGE)$/i,
    /^(GST|TAX|SERVICE|CHARGE|TIP|SUBTOTAL)$/i,
    /^(RECEIPT|INVOICE|BILL|ORDER)$/i,
    /^\d{2}\/\d{2}\/\d{4}$/,  // Dates
    /^\d{1,2}:\d{2}(:\d{2})?$/,  // Times
    /^[A-Z]{2,3}$/,  // Short codes like GST, TAX - but not TEA!
    /^#\d+$/,  // Order numbers
    /^[\W]+$/,  // Only special characters
    /^(FOR|YOUR|CUSTOM)$/i,  // Common non-menu phrases
    /^TOTAL$/i  // Skip TOTAL lines
  ];
  
  // Special case: TEA is a valid menu item, not noise
  if (text.toUpperCase() === 'TEA') {
    return false;
  }
  
  return noisePatterns.some(pattern => pattern.test(text));
}

/**
 * Calculate a simple food score based on keywords
 */
function calculateFoodScore(text) {
  const foodKeywords = [
    'chicken', 'beef', 'pork', 'fish', 'lamb', 'mutton',
    'rice', 'noodle', 'bread', 'pasta', 'pizza', 'burger',
    'curry', 'soup', 'salad', 'sandwich', 'wrap',
    'tea', 'coffee', 'juice', 'water', 'coke', 'beer',
    'toast', 'butter', 'cheese', 'egg', 'bacon',
    'vegetable', 'veg', 'fruit', 'dessert', 'cake',
    'fried', 'grilled', 'roasted', 'steamed', 'baked'
  ];
  
  const lowerText = text.toLowerCase();
  const matches = foodKeywords.filter(keyword => lowerText.includes(keyword));
  
  return Math.min(1.0, matches.length * 0.3);
}

/**
 * Helper functions to extract Y positions from bounding boxes
 */
function getAvgY(detection) {
  const box = detection.boundingPoly || detection.boundingBox;
  if (!box || !box.vertices) return 0;
  
  const sum = box.vertices.reduce((acc, v) => acc + (v.y || 0), 0);
  return sum / box.vertices.length;
}

function getMinY(detection) {
  const box = detection.boundingPoly || detection.boundingBox;
  if (!box || !box.vertices) return 0;
  
  return Math.min(...box.vertices.map(v => v.y || 0));
}

function getMaxY(detection) {
  const box = detection.boundingPoly || detection.boundingBox;
  if (!box || !box.vertices) return 0;
  
  return Math.max(...box.vertices.map(v => v.y || 0));
}

function getAvgX(detection) {
  const box = detection.boundingPoly || detection.boundingBox;
  if (!box || !box.vertices) return 0;
  
  const sum = box.vertices.reduce((acc, v) => acc + (v.x || 0), 0);
  return sum / box.vertices.length;
}

module.exports = {
  parseAzureOcrToMenuItems
};