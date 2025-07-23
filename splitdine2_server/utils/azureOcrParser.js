/**
 * Azure OCR Parser
 * Parses raw Azure OCR data to extract menu items with prices
 */

/**
 * Parse Azure OCR detections to extract menu items
 * @param {Array} detections - Array of detection objects from Azure OCR
 * @returns {Object} - Parsed menu items ready for analysis
 */
function parseAzureOcrToMenuItems(detections) {
  if (!Array.isArray(detections) || detections.length === 0) {
    return {
      menuItems: [],
      detections: detections || []
    };
  }

  const menuItems = [];
  const processedIndices = new Set();

  // Group detections by Y position (same line)
  const lineGroups = groupDetectionsByLine(detections);
  
  console.log(`[OcrParser] Found ${lineGroups.length} line groups from ${detections.length} detections`);

  // Process each line to find menu items
  lineGroups.forEach((lineGroup, groupIndex) => {
    // Extract text and prices from the line
    const lineText = [];
    const prices = [];
    
    lineGroup.detections.forEach(detection => {
      const text = (detection.description || detection.text || '').trim();
      
      if (isPotentialPrice(text)) {
        const price = extractPrice(text);
        if (price !== null) {
          prices.push({ value: price, text: text });
        }
      } else if (!isReceiptNoise(text)) {
        lineText.push(text);
      }
    });
    
    // If we have both text and price on this line, it's likely a menu item
    if (lineText.length > 0 && prices.length > 0) {
      const itemName = lineText.join(' ');
      const price = prices[prices.length - 1].value; // Use the last price found on the line
      
      menuItems.push({
        name: itemName,
        price: price,
        confidence: lineGroup.avgConfidence,
        foodScore: calculateFoodScore(itemName),
        wordCount: lineText.length,
        isLikelyMenuItem: true,
        enhancedConfidence: lineGroup.avgConfidence,
        originalGroup: lineGroup
      });
      
      console.log(`[OcrParser] Found menu item: "${itemName}" - £${price}`);
    }
  });

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
    /^(THANK|YOU|PLEASE|CALL|AGAIN|DATE|TIME|TOTAL|CASH|CARD|CHANGE)$/i,
    /^(GST|TAX|SERVICE|CHARGE|TIP|SUBTOTAL)$/i,
    /^(RECEIPT|INVOICE|BILL|ORDER)$/i,
    /^\d{2}\/\d{2}\/\d{4}$/,  // Dates
    /^\d{1,2}:\d{2}(:\d{2})?$/,  // Times
    /^[A-Z]{2,3}$/,  // Short codes like GST, TAX
    /^#\d+$/,  // Order numbers
    /^[\W]+$/  // Only special characters
  ];
  
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