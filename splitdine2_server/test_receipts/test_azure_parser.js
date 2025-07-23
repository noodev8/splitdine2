const fs = require('fs');
const path = require('path');
const { parseAzureOcrToMenuItems } = require('../utils/azureOcrParser');
const { analyzeMenuItems } = require('../utils/menuItemAnalyzer');

// Load the bread-parsed.json to simulate full Azure OCR result
const data = JSON.parse(fs.readFileSync(path.join(__dirname, 'bread_parsed.json'), 'utf8'));

// Create Azure OCR result format
const ocrResult = {
  detections: data.detections,
  fullTextAnnotation: data.fullTextAnnotation
};

console.log(`\nTotal detections from Azure: ${ocrResult.detections.length}`);

// Parse the Azure OCR result to menu items
console.log('\n--- PARSING AZURE OCR DATA ---');
const parsedData = parseAzureOcrToMenuItems(ocrResult);

console.log(`\nParsed menu items: ${parsedData.menuItems.length}`);
parsedData.menuItems.forEach((item, i) => {
  console.log(`${i + 1}. "${item.name}" - £${item.price} (receiptOrder: ${item.receiptOrder})`);
});

// Analyze the parsed menu items (clean duplicates)
console.log('\n--- ANALYZING MENU ITEMS ---');
const analysisResult = analyzeMenuItems(parsedData);

console.log(`\nFinal menu items: ${analysisResult.menuItems.length}`);
analysisResult.menuItems.forEach((item, i) => {
  console.log(`${i + 1}. "${item.name}" - £${item.price} (receiptOrder: ${item.receiptOrder})${item.isDuplicate ? ' (duplicate detected)' : ''}`);
});

// Test the sorting
console.log('\n--- SORTED BY RECEIPT ORDER ---');
const sorted = analysisResult.menuItems.sort((a, b) => (a.receiptOrder || 0) - (b.receiptOrder || 0));
sorted.forEach((item, i) => {
  console.log(`${i + 1}. "${item.name}" - £${item.price} (receiptOrder: ${item.receiptOrder})`);
});