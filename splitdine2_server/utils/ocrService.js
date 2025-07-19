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
 * Parse table format receipts (PRODUCT PRICE QTY TOTAL)
 * @param {Array} lines - Array of text lines
 * @param {Function} addItem - Function to add items
 * @param {Function} classifyLine - Function to classify line types
 * @param {RegExp} priceRegex - Regex for price matching
 * @param {Object} totals - Totals object to populate
 * @returns {Object} - Parse results
 */
function parseTableFormatReceipt(lines, addItem, classifyLine, priceRegex, totals) {
  const items = [];
  
  // Local addItem function - creates individual lines for each quantity
  const localAddItem = (name, price, quantity = 1) => {
    if (!name) return;
    
    let cleanedName = name.replace(/["%]/g, '').trim();
    cleanedName = cleanedName.replace('CHCKN', 'CHICKEN');
    cleanedName = cleanedName.replace('TRKY', 'TURKEY');
    cleanedName = cleanedName.replace('BRGR', 'BURGER');
    
    if (cleanedName) {
      // Create separate line for each quantity
      const itemPrice = price || 0.00;
      for (let i = 0; i < (quantity || 1); i++) {
        items.push({ 
          quantity: 1, 
          name: cleanedName, 
          price: itemPrice
        });
      }
    }
  };
  
  // Find where the table starts (after PRODUCT header)
  const productHeaderIndex = lines.findIndex(line => 
    line === 'PRODUCT' || line.includes('PRODUCT') || line.includes('PRICE') && line.includes('QTY')
  );
  
  if (productHeaderIndex === -1) {
    return { success: false, error: 'Could not find product table header', items: [], totals: {} };
  }
  
  // Process lines after the header
  for (let i = productHeaderIndex + 1; i < lines.length; i++) {
    const line = lines[i];
    if (!line) continue;
    
    const type = classifyLine(line);
    if (type === 'SKIP') continue;
    
    // Check if this line contains totals
    if (type === 'TOTAL' || type === 'TAX' || type === 'SERVICE') {
      const priceMatch = line.match(/[\$£]\s*([\d,]+(?:\.\d{2})?)/);
      if (priceMatch) {
        const price = parseFloat(priceMatch[1].replace(',', ''));
        if (line.includes('SUB TOTAL') || line.includes('SUBTOTAL')) {
          // Don't set as final total
        } else if (type === 'TOTAL') {
          totals.total_amount = price;
        } else if (type === 'TAX') {
          totals.tax_amount = price;
        }
      }
      continue;
    }
    
    // Try to parse table row with pattern: Item £Price Qty £Total
    // Example: "Sisig £6.00 1 £6.00"
    const tableRowRegex = /^(.+?)\s+([\$£][\d.]+)\s+(\d+)\s+([\$£][\d.]+)$/;
    const tableMatch = line.match(tableRowRegex);
    
    if (tableMatch) {
      const itemName = tableMatch[1].trim();
      const unitPrice = parseFloat(tableMatch[2].replace(/[\$£]/, ''));
      const quantity = parseInt(tableMatch[3]);
      localAddItem(itemName, unitPrice, quantity);
      continue;
    }
    
    // Alternative pattern: Item on one line, price/qty on next
    // Check if this is just an item name (no prices)
    if (!priceRegex.test(line) && !/^\d+$/.test(line) && !/^[\$£]/.test(line)) {
      // Look at next line for price pattern
      const nextLine = lines[i + 1] || '';
      const priceQtyRegex = /([\$£][\d.]+)\s+(\d+)\s+([\$£][\d.]+)/;
      const nextMatch = nextLine.match(priceQtyRegex);
      
      if (nextMatch) {
        const unitPrice = parseFloat(nextMatch[1].replace(/[\$£]/, ''));
        const quantity = parseInt(nextMatch[2]);
        localAddItem(line, unitPrice, quantity);
        i++; // Skip the price line
        continue;
      }
    }
    
    // Skip lines that are just prices without items
    if (/^[\$£][\d.]+\s+\d+\s*$/.test(line)) {
      continue;
    }
    
    // Fallback: try to extract any item with inline price
    const inlinePriceMatch = line.match(/(.*?)\s+([\$£]\d+\.?\d*)/);
    if (inlinePriceMatch) {
      const itemName = inlinePriceMatch[1].trim();
      const price = parseFloat(inlinePriceMatch[2].replace(/[\$£]/, ''));
      if (itemName.length >= 3 && !classifyLine(itemName) !== 'SKIP') {
        localAddItem(itemName, price);
      }
    }
  }
  
  const validatedItems = validateAndCleanItems(items);
  
  return {
    success: true,
    items: validatedItems,
    totals: totals
  };
}

/**
 * Parse column-based receipts where items and prices are in separate sections
 * @param {Array} lines - Array of text lines
 * @param {Function} addItem - Function to add items
 * @param {Function} classifyLine - Function to classify line types
 * @param {RegExp} priceRegex - Regex for price matching
 * @param {Object} totals - Totals object to populate
 * @returns {Object} - Parse results
 */
function parseColumnBasedReceipt(lines, addItem, classifyLine, priceRegex, totals) {
  const items = [];
  
  // Local addItem function that updates our items array - creates individual lines for each quantity
  const localAddItem = (name, price) => {
    if (!name) return;
    const nameParts = name.trim().split(' ');
    let quantity = 1;
    
    const potentialQuantity = parseInt(nameParts[0], 10);
    if (!isNaN(potentialQuantity) && potentialQuantity > 0 && nameParts.length > 1) {
      quantity = potentialQuantity;
      nameParts.shift();
    }
    
    let cleanedName = nameParts.join(' ').replace(/["%]/g, '').trim();
    cleanedName = cleanedName.replace('CHCKN', 'CHICKEN');
    cleanedName = cleanedName.replace('TRKY', 'TURKEY');
    cleanedName = cleanedName.replace('BRGR', 'BURGER');
    cleanedName = cleanedName.replace('CHCK%', 'CHICKEN');
    
    if (cleanedName) {
      // Create separate line for each quantity
      const itemPrice = price || 0.00;
      for (let i = 0; i < quantity; i++) {
        items.push({ 
          quantity: 1, 
          name: cleanedName, 
          price: itemPrice
        });
      }
    }
  };
  
  // Find the sections
  const itemHeaderIndex = lines.findIndex(line => line === 'ITEM');
  const amountHeaderIndex = lines.findIndex(line => line === 'AMOUNT');
  
  if (itemHeaderIndex === -1 || amountHeaderIndex === -1) {
    return { success: false, error: 'Could not find ITEM/AMOUNT headers', items: [], totals: {} };
  }
  
  // Collect items (lines after ITEM header that are potential menu items)
  const itemLines = [];
  const priceLines = [];
  
  // Collect item names (from ITEM section)  
  for (let i = itemHeaderIndex + 1; i < lines.length; i++) {
    const line = lines[i];
    if (!line || line === 'AMOUNT') break;
    
    const type = classifyLine(line);
    
    // Special handling for specific known food items that might be misclassified
    const knownFoodItems = ['SANDWITCH', 'SANDWICH', 'NOODLES', 'BURGER', 'PIZZA', 'SALAD', 'SOUP'];
    const isKnownFood = knownFoodItems.some(food => line.includes(food));
    
    // Only add actual food items (not headers, addresses, etc.)
    if ((type === 'ITEM' || isKnownFood) && !priceRegex.test(line)) {
      // Additional filter: likely food items are usually 3-20 characters, no numbers at start
      if (line.length >= 3 && line.length <= 20 && !/^\d/.test(line)) {
        itemLines.push(line);
      }
    } else if (type === 'TOTAL' || type === 'TAX' || type === 'SERVICE') {
      itemLines.push({ line, type }); // Keep track of total lines
    }
  }
  
  // Collect prices - focus on prices that appear after AMOUNT header or are reasonable food prices
  let foundAmountHeader = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line === 'AMOUNT') {
      foundAmountHeader = true;
      continue;
    }
    
    if (priceRegex.test(line)) {
      const priceMatch = line.match(priceRegex);
      if (priceMatch) {
        const price = parseFloat(priceMatch[1].replace(',', ''));
        // Filter reasonable prices (between 0.01 and 999.99) and prioritize those after AMOUNT
        if (price >= 0.01 && price <= 999.99) {
          priceLines.push({
            line,
            price: price,
            index: i,
            afterAmount: foundAmountHeader || i > amountHeaderIndex
          });
        }
      }
    }
  }
  
  // Sort prices: prioritize those after AMOUNT header, then by order of appearance
  priceLines.sort((a, b) => {
    if (a.afterAmount && !b.afterAmount) return -1;
    if (!a.afterAmount && b.afterAmount) return 1;
    return a.index - b.index;
  });
  
  // Match items with prices based on order
  let priceIndex = 0;
  for (let i = 0; i < itemLines.length; i++) {
    const itemLine = itemLines[i];
    
    if (typeof itemLine === 'object' && itemLine.type) {
      // This is a total/tax line
      if (priceIndex < priceLines.length) {
        const priceData = priceLines[priceIndex];
        const lineLower = itemLine.line.toLowerCase();
        
        if (lineLower.includes('sub-total') || lineLower.includes('subtotal')) {
          // Don't set as final total, this is just subtotal
        } else if (itemLine.type === 'TOTAL' && (lineLower.includes('total:') || lineLower === 'total:')) {
          totals.total_amount = priceData.price;
        } else if (itemLine.type === 'TAX' || lineLower.includes('tax')) {
          totals.tax_amount = priceData.price;
        } else if (itemLine.type === 'SERVICE') {
          totals.service_charge = priceData.price;
        }
        priceIndex++;
      }
    } else {
      // This is a regular item
      if (priceIndex < priceLines.length) {
        const priceData = priceLines[priceIndex];
        localAddItem(itemLine, priceData.price);
        priceIndex++;
      } else {
        localAddItem(itemLine, 0); // No price found
      }
    }
  }
  
  const validatedItems = validateAndCleanItems(items);
  
  return {
    success: true,
    items: validatedItems,
    totals: totals
  };
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

    const lines = text.split('\n').map(line => line.trim().toUpperCase());
    const items = [];
    const totals = {
      total_amount: null,
      tax_amount: null,
      service_charge: null,
    };

    // Detect receipt format by looking for various headers
    const hasItemHeader = lines.some(line => line === 'ITEM');
    const hasAmountHeader = lines.some(line => line === 'AMOUNT');
    const hasProductHeader = lines.some(line => line === 'PRODUCT' || line.includes('PRODUCT'));
    const hasPriceQtyHeader = lines.some(line => line.includes('PRICE') && line.includes('QTY'));
    
    const isColumnBased = hasItemHeader && hasAmountHeader;
    const isTableFormat = hasProductHeader || hasPriceQtyHeader;

    // Enhanced price regex to handle multiple formats and currencies
    const priceRegex = /[\$£]?\s*([\d,]+(?:\.\d{2})?)\s*$/; // Matches $23, £23, $56, $ 79, 12.00, 1,234.50
    
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
        // Create separate line for each quantity
        const itemPrice = price || 0.00;
        for (let i = 0; i < quantity; i++) {
          items.push({ 
            quantity: 1, 
            name: cleanedName, 
            price: itemPrice
          });
        }
      }
    };

    const classifyLine = (line) => {
      if (!line || line.length < 2) return 'SKIP';
      
      // Restaurant info, addresses, dates, headers
      if (/^(THANK|ORDER|STATION|PARTIES|PLEASE|CHECK OUT|RECOMMENDING|SERV #\d+|A\d+|C\d+|\d{2}:\d{2})/.test(line)) {
        return 'SKIP';
      }
      
      // Receipt metadata - batch, approval codes, trace numbers, etc.
      if (/BATCH\s*#|APPRCODE|TRACE:|TO-\d+|APPROVED|SALE|MASTERCARD|VISA|DEBIT|INSERT|CHIP/.test(line)) {
        return 'SKIP';
      }
      
      // Restaurant branding with asterisks or special characters
      if (/^\*.*\*$/.test(line) || /^[\*\-=]+$/.test(line)) {
        return 'SKIP';
      }
      
      // Address patterns (street numbers, zip codes, phone numbers)
      if (/^\d{3,5}\s+\w+|DC\s+\d{5}|\+?\d[\d\-]{8,}|AVE|STREET|ST|BLVD|ROAD|RD/.test(line)) {
        return 'SKIP';
      }
      
      // Dates and times (various formats)
      if (/\d{1,2}\s+(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|JUNE)\s+\d{4}|\d{1,2}\/\d{1,2}\/\d{2,4}|\d{1,2}:\d{2}\s*(AM|PM)?/.test(line)) {
        return 'SKIP';
      }
      
      // Restaurant names/taglines (typically all caps with no prices, or contains "Best", "Voted", etc.)
      if ((/^[A-Z\s&]+$/.test(line) && !priceRegex.test(line) && line.length > 8) || /VOTED|BEST|FOOD TRUCK/.test(line)) {
        return 'SKIP';
      }
      
      // Payment info, invoice numbers, card numbers, customer copy, tip lines
      if (/INVOICE|PAYMENT|CARD|CASH|SUCCESS|STATUS|CUSTOMER|^\d{10,}|X{5,}|COPY|GRATUITY|GRAT \d+%|TIP:|TOTAL:/.test(line)) {
        return 'SKIP';
      }
      
      // Column headers
      if (/^(ITEM|AMOUNT)$/.test(line)) {
        return 'SKIP';
      }
      
      // Totals and taxes
      if (line.includes('TOTAL') || line.startsWith('TOTAL')) return 'TOTAL';
      if (line.includes('TAX') || line.startsWith('TAX') || line === 'ΤΑΧ') return 'TAX';
      if (line.includes('SUB-TOTAL') || line.includes('SUBTOTAL')) return 'TOTAL';
      if (line.includes('SERVICE') || line.includes('GRATUITY')) return 'SERVICE';
      
      return 'ITEM';
    };

    // Choose parsing strategy based on receipt format
    if (isColumnBased) {
      return parseColumnBasedReceipt(lines, addItem, classifyLine, priceRegex, totals);
    } else if (isTableFormat) {
      return parseTableFormatReceipt(lines, addItem, classifyLine, priceRegex, totals);
    }

    // Original parsing logic for non-column receipts
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

        // Look ahead for prices in next few lines (for multi-line items)
        let priceFound = false;
        for (let j = 1; j <= 3; j++) {
          const nextLine = lines[i + j] || '';
          // Check if this line is a standalone price
          if (/^[\$£]?\s*\d+(\.\d{2})?\s*$/.test(nextLine)) {
            const nextPriceMatch = nextLine.match(/[\$£]?\s*(\d+(?:\.\d{2})?)/);
            if (nextPriceMatch) {
              addItem(line, parseFloat(nextPriceMatch[1]));
              // Skip the price line when we get to it
              if (j === 1) i++;
              priceFound = true;
              break;
            }
          }
          // Stop looking if we hit another item or non-price line
          if (nextLine && !/^[\$£]?\s*\d+/.test(nextLine)) {
            break;
          }
        }
        
        if (priceFound) continue;

        const priceMatch = line.match(priceRegex);
        if (priceMatch) {
          const price = parseFloat(priceMatch[1].replace(',', ''));
          // Remove price from end of line to get item name
          const name = line.replace(priceRegex, '').trim();
          
          // Additional filtering: name should be reasonable length and not just numbers
          if (name.length >= 3 && name.length <= 50 && !/^\d+$/.test(name)) {
            addItem(name, price);
          }
        } else {
          // Store as potential item if it's likely to be a food item
          if (line.length >= 3 && line.length <= 30 && !/^\d+$/.test(line) && !line.includes('#')) {
            // Check if this looks like a real menu item (contains common food words or patterns)
            const foodPatterns = /BURRITO|TACO|WATER|BEER|SODA|CHICKEN|BEEF|PORK|FISH|SALAD|SOUP|SANDWICH|BURGER|FRIES|RICE|BEANS|NACHOS|CHIPS|DRINK|COFFEE|TEA|JUICE/;
            if (foodPatterns.test(line) || /^\d+\s+[A-Z]/.test(line)) {
              // This is likely a food item, add it even without price (user can add later)
              addItem(line, 0.00);
            } else {
              potentialItemName = line;
            }
          }
        }
      }
    }
    
    // Final check: if the loop ends and we still have a pending item.
    if (potentialItemName) {
      addItem(potentialItemName, null);
    }

    // Post-process items to validate they're likely food items
    const validatedItems = validateAndCleanItems(items);
    
    return {
      success: true,
      items: validatedItems,
      totals: totals
    };

  } catch (error) {
    return {
      success: false,
      error: error.message,
      items: [],
      totals: {}
    };
  }
}

/**
 * Validate and clean extracted items to ensure they're likely food items
 * @param {Array} items - Array of parsed items
 * @returns {Array} - Validated and cleaned items
 */
function validateAndCleanItems(items) {
  if (!items || !Array.isArray(items)) return [];
  
  // Common food-related words (can be expanded over time)
  const foodKeywords = [
    // Food types
    'BURGER', 'BURRITO', 'TACO', 'PIZZA', 'PASTA', 'SALAD', 'SOUP', 'SANDWICH', 
    'CHICKEN', 'BEEF', 'PORK', 'FISH', 'SHRIMP', 'TURKEY', 'BACON', 'SAUSAGE',
    'RICE', 'NOODLES', 'BREAD', 'FRIES', 'CHIPS', 'NACHOS', 'WINGS',
    
    // Drinks
    'WATER', 'COKE', 'PEPSI', 'SODA', 'JUICE', 'COFFEE', 'TEA', 'BEER', 'WINE',
    'LEMONADE', 'SMOOTHIE', 'SHAKE', 'MILK',
    
    // Specific dishes
    'SISIG', 'LUMPIA', 'LECHON', 'KAWALI', 'ADOBO', 'PANCIT',
    
    // Modifiers
    'EXTRA', 'LARGE', 'SMALL', 'MEDIUM', 'GRANDE', 'MACHO', 'SKINNY',
    
    // Common restaurant terms
    'COMBO', 'MEAL', 'SPECIAL', 'PLATTER', 'BOWL', 'WRAP', 'SUB'
  ];
  
  // Patterns that indicate NOT a food item
  const nonFoodPatterns = [
    /@/,                           // Email addresses
    /^[\$£]\d+/,                  // Price strings
    /^\d{10,}/,                   // Long numbers (phone, card numbers)
    /RECEIPT|INVOICE|COPY/,       // Receipt metadata
    /CUSTOMER|STAFF|DEVICE/,      // Receipt headers
    /THANK YOU|APPROVED/,         // Receipt footers
    /^\d{1,2}\/\d{1,2}\/\d{2,4}/, // Dates
    /^\d{1,2}:\d{2}/,            // Times
    /BATCH|TRACE|CODE/,          // Transaction data
    /^[A-Z0-9]{10,}$/,           // Long codes
    /\.COM|\.CO\.|WWW\./         // URLs/domains
  ];
  
  const validatedItems = items.filter(item => {
    const name = item.name.toUpperCase();
    
    // Skip if matches non-food patterns
    for (const pattern of nonFoodPatterns) {
      if (pattern.test(name)) return false;
    }
    
    // Skip if too short or too long
    if (name.length < 2 || name.length > 50) return false;
    
    // Skip if it's just numbers or special characters
    if (/^[\d\s\-\.\,]+$/.test(name)) return false;
    
    // Accept if contains food keywords
    for (const keyword of foodKeywords) {
      if (name.includes(keyword)) return true;
    }
    
    // Accept if it looks like a food item pattern
    // - Starts with a number (quantity) followed by letters
    if (/^\d+\s+[A-Z]{3,}/.test(name)) return true;
    
    // - Has reasonable length and contains mostly letters
    if (name.length >= 3 && name.length <= 25 && /[A-Z]{3,}/.test(name)) {
      // Check if it's not obviously non-food
      const hasOnlyConsonants = !/[AEIOU]/.test(name.replace(/[^A-Z]/g, ''));
      if (!hasOnlyConsonants) return true;
    }
    
    // When in doubt, include it (user can remove)
    // But only if it has a price or looks reasonable
    return item.price > 0 || (name.length >= 4 && name.length <= 20);
  });
  
  // Clean up item names
  return validatedItems.map(item => ({
    ...item,
    name: cleanItemName(item.name)
  }));
}

/**
 * Clean up individual item names
 * @param {string} name - Item name to clean
 * @returns {string} - Cleaned name
 */
function cleanItemName(name) {
  let cleaned = name;
  
  // Remove price patterns from names
  cleaned = cleaned.replace(/[\$£]\d+\.?\d*\s*/, '');
  
  // Remove trailing numbers that might be codes
  cleaned = cleaned.replace(/\s+\d{3,}$/, '');
  
  // Fix common OCR issues
  cleaned = cleaned.replace(/\s+/g, ' ').trim();
  
  return cleaned;
}

module.exports = {
  extractTextFromReceipt,
  parseReceiptText
};
