const fs = require('fs');

// Define the file path
const filePath = 'bread-parsed.txt';

fs.readFile(filePath, 'utf8', (err, data) => {
    if (err) {
        console.error('Error reading the file:', err);
        return;
    }

    try {
        // The data appears to be double-encoded JSON (escaped quotes)
        // First, replace escaped quotes with regular quotes
        const unescapedData = data.replace(/""/g, '"');
        
        // Parse the JSON data
        const jsonData = JSON.parse(unescapedData);

        // Extract menu items
        const menuItems = jsonData.menuItems;

        console.log("Menu Items and Prices:");
        menuItems.forEach(item => {
            if (item.name && item.price !== null) { // Check if price is not null
                console.log(`* ${item.name}: £${item.price.toFixed(2)}`);
            } else if (item.name) {
                console.log(`* ${item.name}: Price Not Available`);
            }
        });

    } catch (parseErr) {
        console.error('Error parsing JSON data:', parseErr);
    }
});