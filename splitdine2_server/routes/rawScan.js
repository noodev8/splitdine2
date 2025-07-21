const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { analyzeMenuItems } = require('../utils/menuItemAnalyzer');

/**
 * POST /api/raw_scan/save
 * Save individual OCR detections from Vision API
 * 
 * Request body:
 * {
 *   "session_id": "123",
 *   "detections": [
 *     {
 *       "text": "BURGER",
 *       "confidence": 0.95,
 *       "bounding_box": {...}
 *     }
 *   ],
 *   "replace": true/false  // Whether to replace existing scan or add to it
 * }
 * 
 * Response:
 * {
 *   "return_code": 200,
 *   "message": "Raw scan detections saved successfully",
 *   "data": {
 *     "inserted_count": 25
 *   }
 * }
 */
router.post('/save', authenticateToken, async (req, res) => {
    const { session_id, detections, replace = false } = req.body;

    if (!session_id || !Array.isArray(detections)) {
        return res.status(400).json({
            return_code: 400,
            message: 'Missing required fields: session_id and detections array',
            data: null,
            timestamp: new Date()
        });
    }

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // If replace is true, delete existing raw scans for this session
        if (replace) {
            await client.query(
                'DELETE FROM raw_scan WHERE session_id = $1',
                [parseInt(session_id)]
            );
        }

        // Insert individual detections
        let insertedCount = 0;
        for (const detection of detections) {
            const { text, confidence, bounding_box } = detection;
            
            if (!text) continue; // Skip empty detections
            
            const insertQuery = `
                INSERT INTO raw_scan (session_id, detection_text, confidence, bounding_box)
                VALUES ($1, $2, $3, $4)
            `;
            
            await client.query(insertQuery, [
                parseInt(session_id),
                text,
                confidence || null,
                bounding_box ? JSON.stringify(bounding_box) : null
            ]);
            
            insertedCount++;
        }

        await client.query('COMMIT');

        res.json({
            return_code: 200,
            message: replace ? 'Raw scan detections replaced successfully' : 'Raw scan detections added successfully',
            data: {
                inserted_count: insertedCount
            },
            timestamp: new Date()
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error saving raw scan detections:', error);
        res.status(500).json({
            return_code: 500,
            message: 'Failed to save raw scan detections',
            data: null,
            timestamp: new Date()
        });
    } finally {
        client.release();
    }
});

/**
 * GET /api/raw_scan/:session_id
 * Get all raw scans for a session
 * 
 * Response:
 * {
 *   "return_code": 200,
 *   "message": "Raw scans retrieved successfully",
 *   "data": [
 *     {
 *       "id": 1,
 *       "session_id": "123",
 *       "scan_text": "Raw OCR text..."
 *     }
 *   ]
 * }
 */
router.get('/:session_id', authenticateToken, async (req, res) => {
    const { session_id } = req.params;

    try {
        const query = 'SELECT * FROM raw_scan WHERE session_id = $1 ORDER BY id';
        const result = await pool.query(query, [parseInt(session_id)]);

        res.json({
            return_code: 200,
            message: 'Raw scans retrieved successfully',
            data: result.rows,
            timestamp: new Date()
        });
    } catch (error) {
        console.error('Error fetching raw scans:', error);
        res.status(500).json({
            return_code: 500,
            message: 'Failed to fetch raw scans',
            data: null,
            timestamp: new Date()
        });
    }
});

/**
 * DELETE /api/raw_scan/:session_id
 * Delete all raw scans for a session
 * 
 * Response:
 * {
 *   "return_code": 200,
 *   "message": "Raw scans deleted successfully",
 *   "data": {
 *     "deleted_count": 2
 *   }
 * }
 */
router.delete('/:session_id', authenticateToken, async (req, res) => {
    const { session_id } = req.params;

    try {
        const result = await pool.query(
            'DELETE FROM raw_scan WHERE session_id = $1',
            [parseInt(session_id)]
        );

        res.json({
            return_code: 200,
            message: 'Raw scans deleted successfully',
            data: {
                deleted_count: result.rowCount
            },
            timestamp: new Date()
        });
    } catch (error) {
        console.error('Error deleting raw scans:', error);
        res.status(500).json({
            return_code: 500,
            message: 'Failed to delete raw scans',
            data: null,
            timestamp: new Date()
        });
    }
});

/**
 * POST /api/raw_scan/analyze/:session_id
 * Analyze OCR detections to extract intelligent menu items
 * 
 * Response:
 * {
 *   "return_code": 200,
 *   "message": "Menu items analyzed successfully",
 *   "data": {
 *     "menuItems": [
 *       {
 *         "name": "Curry Mutton Small",
 *         "price": 10.00,
 *         "confidence": 0.95,
 *         "foodScore": 0.6,
 *         "isLikelyMenuItem": true
 *       }
 *     ],
 *     "metadata": {
 *       "totalDetections": 45,
 *       "menuItemsFound": 6
 *     }
 *   }
 * }
 */
router.post('/analyze/:session_id', authenticateToken, async (req, res) => {
    const { session_id } = req.params;

    try {
        // Get all raw scan detections for the session
        const query = 'SELECT * FROM raw_scan WHERE session_id = $1 ORDER BY id';
        const result = await pool.query(query, [parseInt(session_id)]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                return_code: 404,
                message: 'No raw scan data found for this session',
                data: null,
                timestamp: new Date()
            });
        }

        // Analyze the detections to extract menu items
        const analysisResult = analyzeMenuItems(result.rows);

        if (!analysisResult.success) {
            return res.status(400).json({
                return_code: 400,
                message: `Analysis failed: ${analysisResult.error}`,
                data: null,
                timestamp: new Date()
            });
        }

        res.json({
            return_code: 200,
            message: 'Menu items analyzed successfully',
            data: {
                menuItems: analysisResult.menuItems,
                metadata: analysisResult.metadata
            },
            timestamp: new Date()
        });
    } catch (error) {
        console.error('Error analyzing menu items:', error);
        res.status(500).json({
            return_code: 500,
            message: 'Failed to analyze menu items',
            data: null,
            timestamp: new Date()
        });
    }
});

module.exports = router;