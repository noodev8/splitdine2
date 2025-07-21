const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();
const { pool } = require('../config/database');

const { receiptScanQueries, sessionQueries, participantQueries, receiptQueries, integrityQueries } = require('../utils/database');
const { extractTextFromReceipt, parseReceiptText } = require('../utils/ocrService');
const { authenticateToken } = require('../middleware/auth');

/**
 * Receipt Scan Routes
 * All routes use POST method and return standardized JSON responses
 */

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
    
    // Save individual OCR detections to raw_scan table
    const { replace_scan = false } = req.body;
    
    const rawScanClient = await pool.connect();
    try {
      await rawScanClient.query('BEGIN');
      
      if (replace_scan) {
        await rawScanClient.query(
          'DELETE FROM raw_scan WHERE session_id = $1',
          [session_id]
        );
      }
      
      // Save individual OCR detections (skip the first one which is full text)
      if (ocrResult.detections && Array.isArray(ocrResult.detections)) {
        for (const detection of ocrResult.detections) {
          if (!detection.description) continue;
          
          await rawScanClient.query(
            'INSERT INTO raw_scan (session_id, detection_text, confidence, bounding_box) VALUES ($1, $2, $3, $4)',
            [
              parseInt(session_id),
              detection.description,
              detection.confidence || null,
              detection.boundingPoly ? JSON.stringify(detection.boundingPoly) : null
            ]
          );
        }
      }
      
      await rawScanClient.query('COMMIT');
    } catch (rawScanError) {
      await rawScanClient.query('ROLLBACK');
      console.error('Error saving raw scan detections:', rawScanError);
      // Continue processing even if raw scan save fails
    } finally {
      rawScanClient.release();
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

module.exports = router;
