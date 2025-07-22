const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const router = express.Router();
const { pool } = require('../config/database');

const { receiptScanQueries, sessionQueries, participantQueries, receiptQueries, integrityQueries } = require('../utils/database');
const { extractTextFromReceipt } = require('../utils/azureOcrService');
const { analyzeMenuItems } = require('../utils/menuItemAnalyzer');
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
    
    // Use intelligent analysis to extract menu items from raw detections
    let analysisResult;
    try {
      // Get the raw detections we just saved
      const rawDetectionsQuery = 'SELECT * FROM raw_scan WHERE session_id = $1 ORDER BY id DESC';
      const rawDetectionsData = await pool.query(rawDetectionsQuery, [parseInt(session_id)]);
      
      // Analyze the detections to extract menu items
      analysisResult = analyzeMenuItems(rawDetectionsData.rows);
      
      if (!analysisResult.success) {
        throw new Error(analysisResult.error || 'Analysis failed');
      }
    } catch (analysisError) {
      console.error('Intelligent analysis failed:', analysisError);
      
      // Update scan record with analysis error but still save OCR data
      await receiptScanQueries.updateOcrResults(receiptScan.id, {
        processing_status: 'failed',
        ocr_text: ocrResult.text,
        ocr_confidence: ocrResult.confidence,
        parsed_items: JSON.stringify({
          menuItems: [],
          fullTextAnnotation: ocrResult.fullTextAnnotation, // Save OCR data even on analysis failure
          detections: ocrResult.detections,
          error: analysisError.message
        }),
        total_amount: null,
        tax_amount: null,
        service_charge: null
      });
      
      return res.status(400).json({
        return_code: 'ANALYSIS_FAILED',
        message: `Intelligent analysis failed: ${analysisError.message}`,
        timestamp: new Date().toISOString()
      });
    }
    
    // Calculate totals from intelligent analysis
    const intelligentItems = analysisResult.menuItems;
    const totalAmount = intelligentItems.reduce((sum, item) => sum + (item.price || 0), 0);
    
    // Update scan record with intelligent analysis results
    const updateData = {
      processing_status: 'completed',
      ocr_text: ocrResult.text,
      ocr_confidence: ocrResult.confidence,
      parsed_items: JSON.stringify({
        menuItems: intelligentItems,
        fullTextAnnotation: ocrResult.fullTextAnnotation, // Include the structured OCR data
        detections: ocrResult.detections // Include individual detections
      }),
      total_amount: totalAmount > 0 ? totalAmount : null,
      tax_amount: null, // Will be calculated from totals if needed
      service_charge: null
    };
    
    const updatedScan = await receiptScanQueries.updateOcrResults(receiptScan.id, updateData);

    // Convert intelligent analysis to Flutter format
    const itemsForFrontend = intelligentItems
      .filter(item => item.isLikelyMenuItem && item.price > 0) // Only include likely menu items with prices
      .map(item => ({
        name: item.name,
        price: item.price,
        quantity: 1, // Each analyzed item is treated as quantity 1
        confidence: item.enhancedConfidence,
        foodScore: item.foodScore
      }));

    // Return intelligent analysis results
    res.json({
      return_code: 'SUCCESS',
      message: 'Receipt analyzed successfully with intelligent parsing',
      data: {
        scan_id: updatedScan.id,
        items: itemsForFrontend,
        totals: {
          total_amount: totalAmount > 0 ? totalAmount : null,
          tax_amount: null,
          service_charge: null
        },
        ocr_confidence: ocrResult.confidence,
        analysis_metadata: analysisResult.metadata,
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
