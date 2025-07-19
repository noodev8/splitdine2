const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();

const { receiptScanQueries, sessionQueries, participantQueries, receiptQueries } = require('../utils/database');
const { extractTextFromReceipt, parseReceiptText } = require('../utils/ocrService');
const { authenticateToken } = require('../middleware/auth');

/**
 * Receipt Scan Routes
 * All routes use POST method and return standardized JSON responses
 */

// Test endpoint
router.get('/test', (req, res) => {
  res.json({
    return_code: 'SUCCESS',
    message: 'Receipt scan service is working',
    timestamp: new Date().toISOString()
  });
});




// Configure multer for file uploads (temporary storage)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../temp_uploads');
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'receipt-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept image files by MIME type or file extension
    const isImageMimeType = file.mimetype.startsWith('image/');
    const hasImageExtension = /\.(jpg|jpeg|png|gif|bmp|webp)$/i.test(file.originalname);
    
    if (isImageMimeType || hasImageExtension || file.mimetype === 'application/octet-stream') {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

/**
 * POST /api/receipt_scan/debug
 * Debug endpoint to capture OCR and parsing results for analysis
 * Does not require authentication - for testing purposes only
 * 
 * Body: multipart/form-data
 * - image: File (required) - Receipt image file
 * 
 * Returns: Complete OCR and parsing data including raw Vision API response
 */
router.post('/debug', upload.single('image'), async (req, res) => {
  let tempFilePath = null;

  try {
    if (!req.file) {
      return res.status(400).json({
        return_code: 'MISSING_IMAGE',
        message: 'Receipt image is required',
        timestamp: new Date().toISOString()
      });
    }
    
    tempFilePath = req.file.path;
    
    // Process image with OCR
    const ocrResult = await extractTextFromReceipt(tempFilePath);
    
    let parseResult = null;
    if (ocrResult.success) {
      // Parse the OCR text to extract items and totals
      parseResult = parseReceiptText(ocrResult.text);
      
      // Convert items to unit prices for consistency with main API
      if (parseResult && parseResult.success && parseResult.items) {
        const itemsWithUnitPrices = parseResult.items.map(item => ({
          name: item.name,
          price: item.quantity > 1 ? Math.round((item.price / item.quantity) * 100) / 100 : item.price, // Unit price with rounding
          quantity: item.quantity,
          total: item.price // Original total
        }));
        parseResult = {
          ...parseResult,
          items: itemsWithUnitPrices
        };
      }
    }
    
    // Create comprehensive debug response
    const debugData = {
      filename: req.file.originalname,
      filesize: req.file.size,
      ocr_result: ocrResult,
      parse_result: parseResult,
      timestamp: new Date().toISOString()
    };
    
    // Save debug data to file for analysis
    try {
      const debugDir = path.join(__dirname, '../debug_receipts');
      if (!fs.existsSync(debugDir)) {
        fs.mkdirSync(debugDir, { recursive: true });
      }
      
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const debugFileName = `receipt_debug_${timestamp}.json`;
      const debugFilePath = path.join(debugDir, debugFileName);
      
      fs.writeFileSync(debugFilePath, JSON.stringify(debugData, null, 2));
    } catch (saveError) {
      // Silent fail for debug data saving
    }
    
    // Return all data for analysis
    res.json({
      return_code: 'SUCCESS',
      message: 'Debug processing complete',
      data: debugData,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Internal server error during debug processing',
      timestamp: new Date().toISOString()
    });
  } finally {
    // Clean up temporary file
    if (tempFilePath && fs.existsSync(tempFilePath)) {
      try {
        fs.unlinkSync(tempFilePath);
      } catch (cleanupError) {
        // Silent fail for cleanup
      }
    }
  }
});

/**
 * POST /api/receipt_scan/upload
 * Upload and process receipt image with OCR
 * 
 * Body: multipart/form-data
 * - image: File (required) - Receipt image file
 * - session_id: Number (required) - Session ID
 * 
 * Returns: Parsed receipt items and totals
 */
router.post('/upload', authenticateToken, upload.single('image'), async (req, res) => {
  let tempFilePath = null;

  try {
    const { session_id } = req.body;
    
    // Validate required fields
    if (!session_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID is required',
        timestamp: new Date().toISOString()
      });
    }
    
    if (!req.file) {
      return res.status(400).json({
        return_code: 'MISSING_IMAGE',
        message: 'Receipt image is required',
        timestamp: new Date().toISOString()
      });
    }
    
    tempFilePath = req.file.path;
    
    // Verify session exists and user is participant
    const session = await sessionQueries.findById(parseInt(session_id));
    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check if user is session participant
    const isParticipant = await participantQueries.isParticipant(parseInt(session_id), req.user.id);
    const isHost = session.organizer_id === req.user.id;
    
    if (!isParticipant && !isHost) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You must be a session participant to upload receipts',
        timestamp: new Date().toISOString()
      });
    }
    
    // Create receipt scan record
    const scanData = {
      session_id: parseInt(session_id),
      image_path: tempFilePath,
      uploaded_by_user_id: req.user.id
    };
    
    const receiptScan = await receiptScanQueries.create(scanData);
    
    // Process image with OCR
    const ocrResult = await extractTextFromReceipt(tempFilePath);
    
    if (!ocrResult.success) {
      // Update scan record with error status
      await receiptScanQueries.updateOcrResults(receiptScan.id, {
        processing_status: 'failed',
        ocr_text: null,
        ocr_confidence: 0,
        parsed_items: null,
        total_amount: null,
        tax_amount: null,
        service_charge: null
      });
      
      return res.status(400).json({
        return_code: 'OCR_FAILED',
        message: ocrResult.error || 'Failed to process receipt image',
        timestamp: new Date().toISOString()
      });
    }
    
    // Parse the OCR text to extract items and totals
    const parseResult = parseReceiptText(ocrResult.text);
    
    if (!parseResult.success) {
      // Update scan record with parsing error
      await receiptScanQueries.updateOcrResults(receiptScan.id, {
        processing_status: 'failed',
        ocr_text: ocrResult.text,
        ocr_confidence: ocrResult.confidence,
        parsed_items: null,
        total_amount: null,
        tax_amount: null,
        service_charge: null
      });
      
      return res.status(400).json({
        return_code: 'PARSING_FAILED',
        message: parseResult.error || 'Failed to parse receipt content',
        timestamp: new Date().toISOString()
      });
    }
    
    // Update scan record with successful results
    const updateData = {
      processing_status: 'completed',
      ocr_text: ocrResult.text,
      ocr_confidence: ocrResult.confidence,
      parsed_items: JSON.stringify(parseResult.items),
      total_amount: parseResult.totals.total_amount,
      tax_amount: parseResult.totals.tax_amount,
      service_charge: parseResult.totals.service_charge
    };
    
    const updatedScan = await receiptScanQueries.updateOcrResults(receiptScan.id, updateData);

    // Convert items to unit prices for Flutter frontend
    const itemsWithUnitPrices = parseResult.items.map(item => ({
      name: item.name,
      price: item.quantity > 1 ? Math.round((item.price / item.quantity) * 100) / 100 : item.price, // Unit price with rounding
      quantity: item.quantity,
      total: item.price // Original total for reference
    }));

    // Return parsed results
    res.json({
      return_code: 'SUCCESS',
      message: 'Receipt processed successfully',
      data: {
        scan_id: updatedScan.id,
        items: itemsWithUnitPrices,
        totals: parseResult.totals,
        ocr_confidence: ocrResult.confidence,
        raw_text: ocrResult.text
      },
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Receipt scan error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Internal server error during receipt processing',
      timestamp: new Date().toISOString()
    });
  } finally {
    // Clean up temporary file
    if (tempFilePath && fs.existsSync(tempFilePath)) {
      try {
        fs.unlinkSync(tempFilePath);
      } catch (cleanupError) {
        console.error('Failed to cleanup temp file:', cleanupError);
      }
    }
  }
});

/**
 * POST /api/receipt-scan/add-items
 * Add parsed receipt items to session
 * 
 * Body: { 
 *   session_id: number,
 *   items: [{ name: string, price: number, quantity: number }]
 * }
 * 
 * Returns: Success confirmation
 */
router.post('/add-items', authenticateToken, async (req, res) => {
  try {
    const { session_id, items } = req.body;
    
    if (!session_id || !items || !Array.isArray(items)) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID and items array are required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Verify session exists and user is participant
    const session = await sessionQueries.findById(parseInt(session_id));
    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }
    
    const isParticipant = await participantQueries.isParticipant(parseInt(session_id), req.user.id);
    const isHost = session.organizer_id === req.user.id;
    
    if (!isParticipant && !isHost) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You must be a session participant to add items',
        timestamp: new Date().toISOString()
      });
    }
    
    // Add each item to the session (multiple rows for quantities > 1)
    const addedItems = [];
    for (const item of items) {
      const { name, price, quantity = 1 } = item;
      
      if (!name || price === undefined) {
        continue; // Skip invalid items
      }
      
      // Add multiple rows for quantity > 1
      for (let i = 0; i < quantity; i++) {
        const itemData = {
          session_id: parseInt(session_id),
          item_name: name,
          price: parseFloat(price),
          added_by_user_id: req.user.id,
          share: null
        };
        
        const newItem = await receiptQueries.create(itemData);
        addedItems.push(newItem);
      }
    }
    
    res.json({
      return_code: 'SUCCESS',
      message: `Successfully added ${addedItems.length} items to session`,
      data: {
        items_added: addedItems.length,
        items: addedItems
      },
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Add items error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to add items to session',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
