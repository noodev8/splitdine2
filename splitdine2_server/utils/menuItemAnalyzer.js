/**
 * Menu Item Analyzer
 * Intelligent analysis of OCR detections to extract menu items from receipt noise
 */

/**
 * Analyze raw OCR detections and extract menu items
 * @param {Array} detections - Array of OCR detection objects
 * @returns {Object} - Analysis results with menu items and metadata
 */
function analyzeMenuItems(detections) {
  if (!Array.isArray(detections) || detections.length === 0) {
    return {
      success: false,
      error: 'No detections provided',
      menuItems: [],
      metadata: {}
    };
  }

  try {
    console.log(`[MenuAnalyzer] Starting analysis with ${detections.length} detections`);
    
    // Step 1: Parse and validate detections
    const validDetections = parseDetections(detections);
    console.log(`[MenuAnalyzer] Valid detections: ${validDetections.length}`);
    
    // Step 2: Spatial analysis - group by position
    const spatialGroups = performSpatialAnalysis(validDetections);
    console.log(`[MenuAnalyzer] Spatial groups: ${spatialGroups.length}`);
    
    // Step 3: Filter out receipt metadata
    const filteredGroups = applyPatternFiltering(spatialGroups);
    console.log(`[MenuAnalyzer] Filtered groups: ${filteredGroups.length}`);
    
    // Step 4: Group food-related words into menu items
    const menuItems = performContextualGrouping(filteredGroups);
    console.log(`[MenuAnalyzer] Menu items before enhancement: ${menuItems.length}`);
    
    // Step 5: Enhance with food keyword analysis
    const enhancedItems = enhanceFoodDetection(menuItems);
    console.log(`[MenuAnalyzer] Enhanced menu items: ${enhancedItems.length}`);
    
    // Debug: log details of enhanced items
    enhancedItems.forEach((item, index) => {
      console.log(`[DEBUG] Item ${index + 1}: "${item.name}" - Price: ${item.price} - isLikelyMenuItem: ${item.isLikelyMenuItem} - foodScore: ${item.foodScore}`);
    });
    
    return {
      success: true,
      menuItems: enhancedItems,
      metadata: {
        totalDetections: detections.length,
        validDetections: validDetections.length,
        spatialGroups: spatialGroups.length,
        filteredGroups: filteredGroups.length,
        menuItemsFound: enhancedItems.length
      }
    };

  } catch (error) {
    console.error('Menu item analysis error:', error);
    return {
      success: false,
      error: error.message,
      menuItems: [],
      metadata: {}
    };
  }
}

/**
 * Parse and validate detection objects
 * @param {Array} detections - Raw detection objects
 * @returns {Array} - Validated detection objects
 */
function parseDetections(detections) {
  return detections
    .map(detection => {
      // Handle different input formats
      const text = detection.detection_text || detection.text || '';
      const confidence = parseFloat(detection.confidence) || 0;
      
      // Parse bounding box if it's a JSON string
      let boundingBox = detection.bounding_box || detection.boundingPoly || null;
      if (typeof boundingBox === 'string') {
        try {
          boundingBox = JSON.parse(boundingBox);
        } catch (e) {
          console.warn('Failed to parse bounding box JSON:', e);
          boundingBox = null;
        }
      }
      
      return {
        text: text.trim(),
        confidence,
        boundingBox,
        original: detection
      };
    })
    .filter(d => d.text && d.text.length > 0); // Remove empty detections
}

/**
 * Group detections by spatial position (same line/area)
 * @param {Array} detections - Validated detections
 * @returns {Array} - Array of spatial groups
 */
function performSpatialAnalysis(detections) {
  const groups = [];
  const processed = new Set();
  
  detections.forEach((detection, index) => {
    if (processed.has(index)) return;
    
    const group = {
      items: [detection],
      yPosition: getYPosition(detection.boundingBox),
      xPosition: getXPosition(detection.boundingBox),
      confidence: detection.confidence
    };
    
    // Find nearby detections (same line)
    for (let i = index + 1; i < detections.length; i++) {
      if (processed.has(i)) continue;
      
      const otherDetection = detections[i];
      const otherY = getYPosition(otherDetection.boundingBox);
      
      // If detections are on similar Y-axis (same line), group them
      if (Math.abs(group.yPosition - otherY) < 20) {
        group.items.push(otherDetection);
        processed.add(i);
      }
    }
    
    // Sort items in group by X position (left to right)
    group.items.sort((a, b) => getXPosition(a.boundingBox) - getXPosition(b.boundingBox));
    
    groups.push(group);
    processed.add(index);
  });
  
  // Sort groups by Y position (top to bottom)
  return groups.sort((a, b) => a.yPosition - b.yPosition);
}

/**
 * Filter out common receipt metadata patterns
 * @param {Array} spatialGroups - Groups from spatial analysis
 * @returns {Array} - Filtered groups likely to contain menu items
 */
function applyPatternFiltering(spatialGroups) {
  // Common receipt metadata patterns to exclude
  const excludePatterns = [
    // Restaurant info
    /^(RESTAURANT|PTE|LTD|CAFE|BISTRO|BAR|KITCHEN)$/i,
    
    // Address components  
    /^(BLK|BLOCK|ROAD|STREET|AVE|AVENUE|UNIT|#\d+|S\d{6})$/i,
    
    // Contact info
    /^(TEL|PHONE|FAX|EMAIL|WWW\.|@)$/i,
    /^\d{4,}$/,  // Long numbers (phone, etc.)
    
    // Receipt metadata
    /^(GST|TAX|NO\.|NUMBER|DATE|TIME|TABLE|BILL|RECEIPT)$/i,
    /^\d{4}-\d{2}-\d{2}$/,  // Dates
    /^\d{1,2}:\d{2}(:\d{2})?$/,  // Times
    
    // Column headers and totals
    /^(DESCRIPTION|PRICE|AMOUNT|QTY|QUANTITY|SUBTOTAL|TOTAL|GRAND)$/i,
    /^(CASH|CARD|CHANGE|PAYMENT|THANK|YOU|VISIT|US)$/i,
    
    // Pure symbols and single characters
    /^[:;,.\-%]$/,
    
    // Pure percentages
    /^\d+%$/
  ];
  
  return spatialGroups.filter(group => {
    // Check if group contains mostly excluded patterns
    const excludedCount = group.items.filter(item => 
      excludePatterns.some(pattern => pattern.test(item.text))
    ).length;
    
    const groupText = group.items.map(item => item.text).join(' ');
    console.log(`[DEBUG] Group: "${groupText}" - Excluded: ${excludedCount}/${group.items.length}`);
    
    // Keep groups where less than 70% are excluded patterns
    return excludedCount < (group.items.length * 0.7);
  }).map(group => ({
    ...group,
    // Remove excluded items from the group
    items: group.items.filter(item => {
      const isExcluded = excludePatterns.some(pattern => pattern.test(item.text));
      if (isExcluded) {
        console.log(`[DEBUG] Filtering out: "${item.text}"`);
      }
      return !isExcluded;
    })
  })).filter(group => group.items.length > 0); // Remove empty groups
}

/**
 * Group food-related words into coherent menu items
 * @param {Array} filteredGroups - Filtered spatial groups
 * @returns {Array} - Array of menu item objects
 */
function performContextualGrouping(filteredGroups) {
  const menuItems = [];
  
  filteredGroups.forEach(group => {
    const words = group.items.map(item => item.text);
    const confidences = group.items.map(item => item.confidence);
    
    // Separate potential prices from item names
    const prices = [];
    const itemWords = [];
    
    group.items.forEach(item => {
      if (isPotentialPrice(item.text)) {
        prices.push(parseFloat(item.text));
      } else if (!isPureNumber(item.text)) {
        itemWords.push(item.text);
      }
    });
    
    // Only create menu item if we have actual food words
    if (itemWords.length > 0) {
      const itemName = itemWords.join(' ');
      const avgConfidence = confidences.reduce((a, b) => a + b, 0) / confidences.length;
      
      menuItems.push({
        name: itemName,
        price: prices.length > 0 ? Math.max(...prices) : null, // Use highest price if multiple
        confidence: avgConfidence,
        wordCount: itemWords.length,
        originalGroup: group
      });
    }
  });
  
  return menuItems;
}

/**
 * Enhance menu items with food keyword analysis
 * @param {Array} menuItems - Basic menu items
 * @returns {Array} - Enhanced menu items with food scores
 */
function enhanceFoodDetection(menuItems) {
  // Comprehensive food keyword dictionary
  const foodKeywords = [
    // Proteins
    'chicken', 'mutton', 'beef', 'pork', 'fish', 'squid', 'prawn', 'lamb', 'duck', 'turkey',
    
    // Indian/Asian cuisine
    'curry', 'tandoori', 'biryani', 'dal', 'samosa', 'naan', 'roti', 'chapati', 'dosa', 'idli',
    'mee', 'laksa', 'satay', 'rendang', 'tom', 'yum', 'pad', 'thai', 'dim', 'sum',
    
    // Cooking methods
    'fried', 'grilled', 'roasted', 'steamed', 'baked', 'boiled', 'braised', 'cutlet',
    
    // Common dishes
    'rice', 'noodles', 'soup', 'salad', 'sandwich', 'burger', 'pizza', 'pasta',
    
    // Beverages
    'juice', 'tea', 'coffee', 'water', 'soda', 'beer', 'wine', 'cocktail', 'smoothie',
    'lime', 'orange', 'apple', 'mango', 'coconut',
    
    // Vegetables & sides
    'vegetable', 'potato', 'onion', 'mushroom', 'broccoli', 'spinach', 'carrot',
    
    // Size/modifiers
    'small', 'medium', 'large', 'big', 'mini', 'jumbo', 'regular', 'special',
    
    // Descriptors
    'spicy', 'mild', 'sweet', 'sour', 'hot', 'cold', 'fresh', 'crispy', 'tender',
    'white', 'black', 'red', 'green', 'yellow'
  ];
  
  return menuItems.map(item => {
    const nameLower = item.name.toLowerCase();
    const foodMatches = foodKeywords.filter(keyword => 
      nameLower.includes(keyword)
    );
    
    // Calculate food relevance score
    const foodScore = Math.min(1.0, foodMatches.length * 0.3);
    
    // Boost confidence for items with clear food keywords
    const enhancedConfidence = Math.min(1.0, item.confidence + foodScore * 0.2);
    
    return {
      ...item,
      foodScore,
      foodKeywords: foodMatches,
      enhancedConfidence,
      isLikelyMenuItem: foodScore > 0 || item.confidence > 0.8
    };
  })
  .sort((a, b) => b.enhancedConfidence - a.enhancedConfidence); // Sort by enhanced confidence
}

/**
 * Helper functions
 */
function getYPosition(boundingBox) {
  if (!boundingBox || !boundingBox.vertices) {
    console.log('[DEBUG] No bounding box or vertices found');
    return 0;
  }
  const vertices = boundingBox.vertices;
  const yPos = vertices.reduce((sum, vertex) => sum + (vertex.y || 0), 0) / vertices.length;
  return yPos;
}

function getXPosition(boundingBox) {
  if (!boundingBox || !boundingBox.vertices) return 0;
  const vertices = boundingBox.vertices;
  return vertices.reduce((sum, vertex) => sum + (vertex.x || 0), 0) / vertices.length;
}

function isPotentialPrice(text) {
  return /^\d+\.\d{2}$/.test(text) && parseFloat(text) > 0.50 && parseFloat(text) < 999.99;
}

function isPureNumber(text) {
  return /^\d+$/.test(text);
}

module.exports = {
  analyzeMenuItems
};