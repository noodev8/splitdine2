#!/usr/bin/env node

/**
 * Receipt Debug Test Script
 * Simple Node.js script to test receipt scanning without needing the full app
 * 
 * Usage: node test_receipt_debug.js <image_path>
 * Example: node test_receipt_debug.js ./receipts/mcdonalds.jpg
 */

const fs = require('fs');
const path = require('path');
const FormData = require('form-data');

// Use built-in fetch for Node.js 18+, fallback to node-fetch
let fetch;
try {
  fetch = globalThis.fetch;
  if (!fetch) {
    fetch = require('node-fetch');
  }
} catch (error) {
  console.error('Could not load fetch. Please install node-fetch: npm install node-fetch@2');
  process.exit(1);
}

// Configuration - reads from Flutter config if available
function getServerUrl() {
  try {
    // Try to read Flutter config file
    const configPath = path.join(__dirname, '../splitdine2_flutter/lib/config/app_config.dart');
    if (fs.existsSync(configPath)) {
      const configContent = fs.readFileSync(configPath, 'utf8');
      const match = configContent.match(/static const String baseUrl = '([^']+)'/);
      if (match) {
        const baseUrl = match[1];
        // Remove '/api' suffix and return server URL
        return baseUrl.replace('/api', '');
      }
    }
  } catch (error) {
    console.log('Could not read Flutter config, using default');
  }
  
  // Fallback to localhost
  return 'http://localhost:3000';
}

const SERVER_URL = getServerUrl();
const DEBUG_ENDPOINT = '/api/receipt_scan/debug';

async function testReceipt(imagePath) {
  try {
    // Check if image file exists
    if (!fs.existsSync(imagePath)) {
      console.error('Error: Image file not found:', imagePath);
      process.exit(1);
    }

    console.log('Testing receipt:', path.basename(imagePath));
    console.log('File size:', fs.statSync(imagePath).size, 'bytes');
    console.log('Uploading to:', SERVER_URL + DEBUG_ENDPOINT);
    console.log('---');

    // Create form data
    const form = new FormData();
    form.append('image', fs.createReadStream(imagePath));

    // Make request to debug endpoint
    const response = await fetch(SERVER_URL + DEBUG_ENDPOINT, {
      method: 'POST',
      body: form,
      headers: form.getHeaders()
    });

    console.log('Response status:', response.status);
    console.log('Response headers:', response.headers.get('content-type'));
    
    const responseText = await response.text();
    console.log('Raw response:', responseText.substring(0, 200) + '...');
    
    let result;
    try {
      result = JSON.parse(responseText);
    } catch (parseError) {
      console.error('Failed to parse JSON response');
      console.error('Full response:', responseText);
      throw new Error('Invalid JSON response from server');
    }

    if (result.return_code === 'SUCCESS') {
      console.log('✅ Upload successful!');
      console.log('\n📊 OCR Results:');
      console.log('- Success:', result.data.ocr_result?.success);
      console.log('- Confidence:', result.data.ocr_result?.confidence);
      
      if (result.data.parse_result) {
        console.log('\n🔍 Parse Results:');
        console.log('- Success:', result.data.parse_result.success);
        console.log('- Items found:', result.data.parse_result.items?.length || 0);
        console.log('- Total amount:', result.data.parse_result.totals?.total_amount);
        console.log('- Tax amount:', result.data.parse_result.totals?.tax_amount);
        
        if (result.data.parse_result.items?.length > 0) {
          console.log('\n📝 Items:');
          result.data.parse_result.items.forEach((item, index) => {
            console.log(`  ${index + 1}. ${item.name} - $${item.price} (qty: ${item.quantity})`);
          });
        }
      }

      console.log('\n📄 Raw OCR Text:');
      console.log('---');
      console.log(result.data.ocr_result?.text || 'No text extracted');
      console.log('---');

    } else {
      console.error('❌ Upload failed:', result.message);
      if (result.error) {
        console.error('Error:', result.error);
      }
      if (result.stack) {
        console.error('Stack trace:', result.stack);
      }
      console.error('Full error response:', JSON.stringify(result, null, 2));
    }

    console.log('\n💾 Debug data saved to server in debug_receipts/ folder');
    console.log('✨ Test complete!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('\nIs the server running? Try: npm run dev');
    process.exit(1);
  }
}

// Check command line arguments
if (process.argv.length < 3) {
  console.log('Usage: node test_receipt_debug.js <image_path>');
  console.log('Example: node test_receipt_debug.js ./receipts/mcdonalds.jpg');
  process.exit(1);
}

const imagePath = process.argv[2];
testReceipt(imagePath);