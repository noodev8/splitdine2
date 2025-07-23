const fs = require('fs');
const path = require('path');

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


// Define the path to the JSON file
// path.join is used for cross-platform compatibility (handles '/' and '\' correctly)
const filePath = path.join(__dirname, 'bread-parsed.json');

// Asynchronously read the content of the file
fs.readFile(filePath, 'utf8', (err, data) => {
    // Handle any errors during file reading
    if (err) {
        console.error('Error reading the file:', err);
        return;
    }

    try {
        // Parse the JSON string data into a JavaScript object
        const jsonData = JSON.parse(data);

        // Access the 'menuItems' array from the parsed JSON
        const menuItems = jsonData.menuItems;

        // An array to store the items after processing (cleaning and potential guessing)
        const processedItems = [];

        console.log("Menu Items and Prices:");

        // Iterate over each item found in the 'menuItems' array
        menuItems.forEach(item => {
            // --- Core Filtering Logic ---
            // Only process items that have both a 'name' and a valid, non-null price.
            // This filters out lines like "THANK YOU" or "DATE" which typically don't have prices
            // and are not actual menu items.
            if (item.name && item.price !== null && item.price !== undefined) {
                // Apply the cleaning function to the item's name
                const { cleanedName, wasDuplicateRemoved } = cleanItemName(item.name);

                // Add the cleaned item to our list of processed items
                processedItems.push({ name: cleanedName, price: item.price });

                // --- "Guessing" Heuristic Logic ---
                // If the 'cleanItemName' function detected and removed a duplicate word sequence
                // (e.g., "TOAST BREAD TOAST BREAD BUTTER BUTTER" -> "TOAST BREAD BUTTER"),
                // AND the item had a price, we assume this implies a second, identical item was ordered
                // but consolidated by the OCR.
                if (wasDuplicateRemoved) {
                    // Add a duplicate of the cleaned item to the processed list
                    processedItems.push({ name: cleanedName, price: item.price });
                }
            }
            // Items without a valid price (item.price === null || item.price === undefined)
            // are intentionally skipped and not added to 'processedItems'.
        });

        // --- Final Output ---
        // Check if any priced menu items were found after processing
        if (processedItems.length > 0) {
            // If items were found, print each one in the desired format
            processedItems.forEach(item => {
                console.log(`* ${item.name}: £${item.price.toFixed(2)}`);
            });
        } else {
            // If no priced menu items were found, inform the user
            console.log("No menu items with prices found in the file.");
        }

    } catch (parseErr) {
        // Catch and report errors if the file content is not valid JSON
        console.error('Error parsing JSON data. Please ensure the file contains valid JSON:', parseErr);
    }
});