const axios = require('axios');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

/**
 * Extract text from receipt image using Azure Computer Vision OCR API
 * @param {string} imagePath - Path to the image file
 * @returns {Object} - OCR results with text and confidence
 */
async function extractTextFromReceipt(imagePath) {
  try {
    // Read image file
    const imageBuffer = fs.readFileSync(imagePath);
    
    // Azure OCR endpoint
    const endpoint = process.env.AZURE_OCR_ENDPOINT;
    const apiKey = process.env.AZURE_OCR_API_KEY;
    
    if (!endpoint || !apiKey) {
      throw new Error('Azure OCR credentials not configured');
    }
    
    // Use the Read API for better receipt processing
    const readUrl = `${endpoint}vision/v3.2/read/analyze`;
    
    // Start the async read operation
    const readResponse = await axios.post(
      readUrl,
      imageBuffer,
      {
        headers: {
          'Ocp-Apim-Subscription-Key': apiKey,
          'Content-Type': 'application/octet-stream'
        }
      }
    );
    
    // Get the operation location from headers
    const operationLocation = readResponse.headers['operation-location'];
    if (!operationLocation) {
      throw new Error('Failed to get operation location from Azure OCR');
    }
    
    // Poll for results
    let result;
    let attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
      
      const resultResponse = await axios.get(operationLocation, {
        headers: {
          'Ocp-Apim-Subscription-Key': apiKey
        }
      });
      
      result = resultResponse.data;
      
      if (result.status === 'succeeded') {
        break;
      } else if (result.status === 'failed') {
        throw new Error('Azure OCR processing failed');
      }
      
      attempts++;
    }
    
    if (!result || result.status !== 'succeeded') {
      throw new Error('Azure OCR processing timed out');
    }
    
    // Extract text and detections from the result
    const detections = [];
    let fullText = '';
    let totalConfidence = 0;
    let confidenceCount = 0;
    
    // Process read results
    if (result.analyzeResult && result.analyzeResult.readResults) {
      for (const page of result.analyzeResult.readResults) {
        for (const line of page.lines) {
          // Add line text to full text
          fullText += line.text + '\n';
          
          // Create detection for the line
          detections.push({
            description: line.text,
            boundingPoly: {
              vertices: [
                { x: line.boundingBox[0], y: line.boundingBox[1] },
                { x: line.boundingBox[2], y: line.boundingBox[3] },
                { x: line.boundingBox[4], y: line.boundingBox[5] },
                { x: line.boundingBox[6], y: line.boundingBox[7] }
              ]
            },
            confidence: 0.9 // Azure doesn't provide per-line confidence in Read API
          });
          
          // Add individual words as detections
          for (const word of line.words) {
            detections.push({
              description: word.text,
              boundingPoly: {
                vertices: [
                  { x: word.boundingBox[0], y: word.boundingBox[1] },
                  { x: word.boundingBox[2], y: word.boundingBox[3] },
                  { x: word.boundingBox[4], y: word.boundingBox[5] },
                  { x: word.boundingBox[6], y: word.boundingBox[7] }
                ]
              },
              confidence: word.confidence || 0.9
            });
            
            if (word.confidence) {
              totalConfidence += word.confidence;
              confidenceCount++;
            }
          }
        }
      }
    }
    
    // Calculate average confidence
    const averageConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : 0.9;
    
    // Create fullTextAnnotation similar to Google Vision
    const fullTextAnnotation = {
      pages: result.analyzeResult?.readResults?.map(page => ({
        width: page.width,
        height: page.height,
        blocks: page.lines.map(line => ({
          boundingBox: line.boundingBox,
          paragraphs: [{
            boundingBox: line.boundingBox,
            words: line.words.map(word => ({
              boundingBox: word.boundingBox,
              symbols: word.text.split('').map((char, index) => ({
                text: char,
                confidence: word.confidence || 0.9
              }))
            }))
          }]
        }))
      })) || [],
      text: fullText.trim()
    };
    
    return {
      success: true,
      text: fullText.trim(),
      confidence: Math.round(averageConfidence * 100) / 100,
      detections: detections,
      fullTextAnnotation: fullTextAnnotation
    };
    
  } catch (error) {
    console.error('Azure OCR API error:', error.message);
    return {
      success: false,
      error: error.message,
      text: '',
      confidence: 0
    };
  }
}

module.exports = {
  extractTextFromReceipt
};