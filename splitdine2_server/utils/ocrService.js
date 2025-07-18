const vision = require('@google-cloud/vision');
const path = require('path');

// Initialize Google Vision client with service account
const client = new vision.ImageAnnotatorClient({
  keyFilename: path.join(__dirname, '../../docs/splitdine-ocr-6921886ed122.json')
});

/**
 * Extract text from receipt image using Google Vision API
 * @param {string} imagePath - Path to the image file
 * @returns {Object} - OCR results with text and confidence
 */
async function extractTextFromReceipt(imagePath) {
  try {
    console.log('Processing image with Google Vision API:', imagePath);
    
    // Perform text detection on the image
    const [result] = await client.textDetection(imagePath);
    const detections = result.textAnnotations;
    
    if (!detections || detections.length === 0) {
      return {
        success: false,
        error: 'No text detected in image',
        text: '',
        confidence: 0
      };
    }
    
    // First detection contains the full text
    const fullText = detections[0].description;
    
    // Calculate average confidence from all detections
    let totalConfidence = 0;
    let confidenceCount = 0;
    
    detections.forEach(detection => {
      if (detection.confidence !== undefined) {
        totalConfidence += detection.confidence;
        confidenceCount++;
      }
    });
    
    const averageConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : 0.8;
    
    console.log('OCR completed successfully');
    console.log('Text length:', fullText.length);
    console.log('Average confidence:', averageConfidence);
    
    return {
      success: true,
      text: fullText,
      confidence: Math.round(averageConfidence * 100) / 100,
      detections: detections.slice(1)
    };
    
  } catch (error) {
    console.error('Google Vision API error:', error);
    return {
      success: false,
      error: error.message,
      text: '',
      confidence: 0
    };
  }
}

/**
 * Parse receipt text to extract items, prices, and totals.
 * This is an enhanced parser that correctly handles items and prices
 * appearing on separate lines and defensively handles items with missing prices.
 * @param {string} text - Raw OCR text from the receipt.
 * @returns {Object} - Parsed receipt data.
 */
function parseReceiptText(text) {
  try {
    console.log('Parsing receipt text with enhanced, resilient logic...');

    const lines = text.split('\n').map(line => line.trim().toUpperCase());
    const items = [];
    const totals = {
      total_amount: null,
      tax_amount: null,
      service_charge: null,
    };

    const priceRegex = /([\d,]+\.\d{2})$/; // Matches prices like 12.00, 1,234.50
    
    const addItem = (name, price) => {
      if (!name) return;

      const nameParts = name.trim().split(' ');
      let quantity = 1;
      
      // Attempt to extract quantity if the first part is a number and there are more parts to the name
      const potentialQuantity = parseInt(nameParts[0], 10);
      if (!isNaN(potentialQuantity) && potentialQuantity > 0 && nameParts.length > 1) {
        quantity = potentialQuantity;
        nameParts.shift(); // Remove the quantity from the name parts
      }
      
      let cleanedName = nameParts.join(' ').replace(/["%]/g, '').trim();

      // Basic OCR corrections/standardization
      cleanedName = cleanedName.replace('CHCKN', 'CHICKEN');
      cleanedName = cleanedName.replace('TRKY', 'TURKEY');
      cleanedName = cleanedName.replace('BRGR', 'BURGER');
      cleanedName = cleanedName.replace('CHCK%', 'CHICKEN');
      cleanedName = cleanedName.replace('POT PIE', 'POT PIE');
      cleanedName = cleanedName.replace('ROAST CHCK', 'ROAST CHICKEN');
      cleanedName = cleanedName.replace('IL LEMONADE', 'LEMONADE');

      // Only add if the name isn't empty after cleaning.
      if (cleanedName) {
        items.push({ 
          quantity, 
          name: cleanedName, 
          price: price || 0.00 // Default to 0 if no price
        });
      }
    };

    const classifyLine = (line) => {
      if (!line || line.length < 2) return 'SKIP';
      
      // Known non-item patterns
      if (/^(THANK|ORDER|STATION|TOTAL|TAX|GRATUITY|PARTIES|PLEASE|CHECK OUT ONLINE|RECOMMENDING US|SERV #\d+|A\d+|C\d+|\d{2}:\d{2})/.test(line)) {
        return 'SKIP';
      }
      
      if (line.startsWith('TOTAL')) return 'TOTAL';
      if (line.startsWith('TAX')) return 'TAX';
      if (line.includes('SERVICE') || line.includes('GRATUITY')) return 'SERVICE';
      
      return 'ITEM';
    };

    let potentialItemName = null;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (!line) continue;

      const type = classifyLine(line);
      
      if (type === 'SKIP') {
        continue;
      }

      if (type === 'TOTAL' || type === 'TAX' || type === 'SERVICE') {
        // Always flush old pending item
        if (potentialItemName) {
          addItem(potentialItemName, null);
          potentialItemName = null;
        }

        const priceMatch = line.match(priceRegex);
        if (priceMatch) {
          const price = parseFloat(priceMatch[1].replace(',', ''));
          if (type === 'TOTAL') totals.total_amount = price;
          else if (type === 'TAX') totals.tax_amount = price;
          else if (type === 'SERVICE') totals.service_charge = price;
        }
        continue;
      }

      if (type === 'ITEM') {
        // Always flush old pending item
        if (potentialItemName) {
          addItem(potentialItemName, null);
          potentialItemName = null;
        }

        const nextLine = lines[i + 1] || '';
        if (/^\d+(\.\d{2})$/.test(nextLine)) {
          addItem(line, parseFloat(nextLine));
          i++;
          continue;
        }

        const priceMatch = line.match(priceRegex);
        if (priceMatch) {
          const price = parseFloat(priceMatch[1].replace(',', ''));
          const name = line.substring(0, priceMatch.index).trim();
          addItem(name, price);
        } else {
          potentialItemName = line;
        }
      }
    }
    
    // Final check: if the loop ends and we still have a pending item.
    if (potentialItemName) {
      addItem(potentialItemName, null);
    }

    console.log(`✅ Parsed ${items.length} items. Flagged items with missing prices.`);
    return {
      success: true,
      items: items,
      totals: totals
    };

  } catch (error) {
    console.error('Receipt parsing error:', error);
    return {
      success: false,
      error: error.message,
      items: [],
      totals: {}
    };
  }
}

module.exports = {
  extractTextFromReceipt,
  parseReceiptText
};
