/**
 * Menu Item Analyzer
 * Simple analysis of menu items from parsed OCR data
 * Based on the logic from geminitest2.js
 */

/**
 * Cleans item names by removing immediate duplicated word sequences (e.g., "A A B B" -> "A B").
 * It also indicates if a duplication was found and removed.
 *
 * @param {string} name - The original item name string.
 * @returns {{cleanedName: string, wasDuplicateRemoved: boolean}} An object containing the cleaned name and a flag indicating if a duplicate was removed.
 */
function cleanItemName(name) {
    if (!name || typeof name !== 'string') {
        return { cleanedName: name, wasDuplicateRemoved: false };
    }

    const words = name.split(' ');
    if (words.length <= 1) {
        return { cleanedName: name, wasDuplicateRemoved: false }; // Cannot have duplicates with one or zero words
    }

    const cleanedWords = [];
    let i = 0;
    let duplicateDetected = false; // Flag to track if any duplication was handled

    // Iterate through the words to find and remove repeating segments
    while (i < words.length) {
        let longestMatchLength = 0;
        let bestMatchSegment = '';

        // Try to find the longest repeating segment starting from the current word 'i'
        // Example: For "TOAST BREAD TOAST BREAD BUTTER BUTTER"
        // If i=0:
        //   j=1: "TOAST" vs "BREAD" -> No match
        //   j=2: "TOAST BREAD" vs "TOAST BREAD" -> Match! (longestMatchLength = 2, bestMatchSegment = "TOAST BREAD")
        // If i=4 (after processing "TOAST BREAD TOAST BREAD"):
        //   j=1: "BUTTER" vs "BUTTER" -> Match! (longestMatchLength = 1, bestMatchSegment = "BUTTER")
        for (let j = 1; i + j <= words.length; j++) {
            const currentSegment = words.slice(i, i + j);
            const nextSegment = words.slice(i + j, i + 2 * j);

            // Check if currentSegment is repeated immediately after itself
            if (currentSegment.join(' ') === nextSegment.join(' ') && currentSegment.length > 0) {
                longestMatchLength = currentSegment.length;
                bestMatchSegment = currentSegment.join(' ');
                duplicateDetected = true; // Mark that a duplicate pattern was found
                break; // Found the smallest repeating unit, no need to check longer segments for this starting point
            }
        }

        if (longestMatchLength > 0) {
            // If a repeating segment was found, add it once to the cleaned list
            cleanedWords.push(bestMatchSegment);
            // Move the index 'i' past *both* occurrences of the duplicated segment
            i += (longestMatchLength * 2);
        } else {
            // If no repetition was found for this word, add it as is and move to the next word
            cleanedWords.push(words[i]);
            i++;
        }
    }
    return { cleanedName: cleanedWords.join(' '), wasDuplicateRemoved: duplicateDetected };
}

/**
 * Analyze menu items from parsed OCR data
 * @param {Object|Array} data - Either the parsed JSON object with menuItems, or the detections array (for backward compatibility)
 * @returns {Object} - Analysis results with menu items and metadata
 */
function analyzeMenuItems(data) {
  try {
    let menuItems = [];
    
    // Handle different input formats
    if (Array.isArray(data)) {
      // Legacy format: array of detections - not supported in new implementation
      console.log('[MenuAnalyzer] Legacy detection array format not supported in new implementation');
      return {
        success: false,
        error: 'Please provide parsed menu items, not raw detections',
        menuItems: [],
        metadata: {}
      };
    } else if (data && data.menuItems && Array.isArray(data.menuItems)) {
      // New format: already parsed menu items
      menuItems = data.menuItems;
    } else {
      return {
        success: false,
        error: 'Invalid input format',
        menuItems: [],
        metadata: {}
      };
    }
    
    console.log(`[MenuAnalyzer] Starting analysis with ${menuItems.length} menu items`);
    
    // An array to store the items after processing (cleaning and potential guessing)
    const processedItems = [];
    
    // Iterate over each item found in the 'menuItems' array
    menuItems.forEach(item => {
      // --- Core Filtering Logic ---
      // Only process items that have both a 'name' and a valid, non-null price.
      // This filters out lines like "THANK YOU" or "DATE" which typically don't have prices
      // and are not actual menu items.
      if (item.name && item.price !== null && item.price !== undefined) {
        // Apply the cleaning function to the item's name
        const { cleanedName, wasDuplicateRemoved } = cleanItemName(item.name);
        
        // Create the processed item with all original properties plus cleaned name
        const processedItem = {
          ...item, // Keep all original properties (including receiptOrder)
          name: cleanedName,
          originalName: item.name // Keep track of original name
        };
        
        // Add the cleaned item to our list of processed items
        processedItems.push(processedItem);
        
        // --- "Guessing" Heuristic Logic ---
        // If the 'cleanItemName' function detected and removed a duplicate word sequence
        // (e.g., "TOAST BREAD TOAST BREAD BUTTER BUTTER" -> "TOAST BREAD BUTTER"),
        // AND the item had a price, we assume this implies a second, identical item was ordered
        // but consolidated by the OCR.
        if (wasDuplicateRemoved) {
          // Add a duplicate of the cleaned item to the processed list
          processedItems.push({
            ...processedItem,
            isDuplicate: true // Mark this as a guessed duplicate
          });
          console.log(`[MenuAnalyzer] Detected repeated sequence in "${item.name}" -> Added duplicate of "${cleanedName}"`);
        }
      }
      // Items without a valid price (item.price === null || item.price === undefined)
      // are intentionally skipped and not added to 'processedItems'.
    });
    
    console.log(`[MenuAnalyzer] Processed ${processedItems.length} items from ${menuItems.length} input items`);
    
    return {
      success: true,
      menuItems: processedItems,
      metadata: {
        totalInputItems: menuItems.length,
        processedItems: processedItems.length,
        itemsWithPrice: processedItems.filter(item => !item.isDuplicate).length,
        duplicatesDetected: processedItems.filter(item => item.isDuplicate).length
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

module.exports = {
  analyzeMenuItems,
  cleanItemName // Export for testing purposes
};