const express = require('express');
const router = express.Router();
const { sessionReceiptQueries, sessionQueries, participantQueries, integrityQueries } = require('../utils/database');
const { query, pool } = require('../config/database');
const { authenticateToken, requireSessionParticipant } = require('../middleware/auth');

/**
 * Session Receipt Management Routes
 * All routes use POST method and return standardized JSON responses
 */

// Add session receipt item
router.post('/add-item', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { session_id, item_name, price } = req.body;

    // Validate required fields
    if (!session_id || !item_name || price === undefined || price === null) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'session_id, item_name, and price are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price is a number
    const numericPrice = parseFloat(price);
    if (isNaN(numericPrice) || numericPrice < 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a valid non-negative number',
        timestamp: new Date().toISOString()
      });
    }

    // Validate item name is not empty
    if (!item_name.trim()) {
      return res.status(400).json({
        return_code: 'INVALID_ITEM_NAME',
        message: 'Item name cannot be empty',
        timestamp: new Date().toISOString()
      });
    }

    const itemData = {
      session_id: parseInt(session_id),
      item_name: item_name.trim(),
      price: numericPrice
    };

    const newItem = await sessionReceiptQueries.create(itemData);

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Session receipt item added successfully',
      item: {
        id: newItem.id,
        session_id: newItem.session_id,
        item_name: newItem.item_name,
        price: newItem.price,
        created_at: newItem.created_at,
        updated_at: newItem.updated_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Add session receipt item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to add session receipt item',
      timestamp: new Date().toISOString()
    });
  }
});

// Add multiple session receipt items in bulk
router.post('/add-items-bulk', authenticateToken, requireSessionParticipant, async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { session_id, items } = req.body;
    
    // Validate inputs
    if (!session_id || !items || !Array.isArray(items)) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'session_id and items array are required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Validate session exists
    const session = await sessionQueries.findById(parseInt(session_id));
    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }
    
    // Validate each item in the array
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (!item.item_name || item.price === undefined || item.price === null) {
        return res.status(400).json({
          return_code: 'INVALID_ITEM',
          message: `Item at index ${i} is missing required fields (item_name, price)`,
          timestamp: new Date().toISOString()
        });
      }
      
      const numericPrice = parseFloat(item.price);
      if (isNaN(numericPrice) || numericPrice < 0) {
        return res.status(400).json({
          return_code: 'INVALID_PRICE',
          message: `Item at index ${i} has invalid price`,
          timestamp: new Date().toISOString()
        });
      }
      
      if (!item.item_name.trim()) {
        return res.status(400).json({
          return_code: 'INVALID_ITEM_NAME',
          message: `Item at index ${i} has empty name`,
          timestamp: new Date().toISOString()
        });
      }
    }
    
    // Begin transaction
    await client.query('BEGIN');
    
    const addedItems = [];
    
    // Insert each item
    for (const item of items) {
      const result = await client.query(
        `INSERT INTO session_receipt (session_id, item_name, price)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [parseInt(session_id), item.item_name.trim(), parseFloat(item.price)]
      );
      addedItems.push(result.rows[0]);
    }
    
    // Commit transaction
    await client.query('COMMIT');
    
    res.status(201).json({
      return_code: 'SUCCESS',
      message: `Added ${addedItems.length} items successfully`,
      data: {
        session_id: parseInt(session_id),
        items: addedItems.map(item => ({
          id: item.id,
          session_id: item.session_id,
          item_name: item.item_name,
          price: parseFloat(item.price),
          created_at: item.created_at,
          updated_at: item.updated_at
        })),
        total_items: addedItems.length
      },
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Bulk add items error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to add items in bulk',
      timestamp: new Date().toISOString()
    });
  } finally {
    client.release();
  }
});

// Get session receipt items - COPIED FROM WORKING receipts.js
router.post('/get-items', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { session_id } = req.body;

    // Get all session receipt items for the session
    const items = await sessionReceiptQueries.getBySession(session_id);

    // Calculate totals
    const subtotal = items.reduce((sum, item) => sum + parseFloat(item.price), 0);
    const itemCount = items.length;

    res.json({
      return_code: 'SUCCESS',
      items: items.map(item => ({
        id: item.id,
        session_id: item.session_id,
        item_name: item.item_name,
        price: parseFloat(item.price),
        created_at: item.created_at,
        updated_at: item.updated_at
      })),
      totals: {
        subtotal: subtotal,
        item_count: itemCount
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get session receipt items error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to retrieve session receipt items',
      timestamp: new Date().toISOString()
    });
  }
});

// Update session receipt item
router.post('/update-item', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { item_id, item_name, price } = req.body;

    // Validate required fields
    if (!item_id || !item_name || price === undefined || price === null) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'item_id, item_name, and price are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price is a number
    const numericPrice = parseFloat(price);
    if (isNaN(numericPrice) || numericPrice < 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a valid non-negative number',
        timestamp: new Date().toISOString()
      });
    }

    // Validate item name is not empty
    if (!item_name.trim()) {
      return res.status(400).json({
        return_code: 'INVALID_ITEM_NAME',
        message: 'Item name cannot be empty',
        timestamp: new Date().toISOString()
      });
    }

    // Check if item exists
    const existingItem = await sessionReceiptQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Session receipt item not found',
        timestamp: new Date().toISOString()
      });
    }

    const updateData = {
      item_name: item_name.trim(),
      price: numericPrice
    };

    const updatedItem = await sessionReceiptQueries.update(item_id, updateData);

    // Clean up any orphaned guest_choice records after updating item (in case item_id changed)
    try {
      const cleanedChoices = await integrityQueries.cleanupOrphanedGuestChoices(req.sessionId);
      if (cleanedChoices.length > 0) {
        console.log(`Cleaned up ${cleanedChoices.length} orphaned guest choices after item update`);
      }
    } catch (cleanupError) {
      console.error('Warning: Failed to cleanup orphaned guest choices after update:', cleanupError);
      // Don't fail the request if cleanup fails
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Session receipt item updated successfully',
      item: {
        id: updatedItem.id,
        session_id: updatedItem.session_id,
        item_name: updatedItem.item_name,
        price: updatedItem.price,
        created_at: updatedItem.created_at,
        updated_at: updatedItem.updated_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update session receipt item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update session receipt item',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete session receipt item
router.post('/delete-item', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { item_id } = req.body;

    if (!item_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'item_id is required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if item exists
    const existingItem = await sessionReceiptQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Session receipt item not found',
        timestamp: new Date().toISOString()
      });
    }

    await sessionReceiptQueries.delete(item_id);

    // Clean up any orphaned guest_choice records after deleting item
    try {
      const cleanedChoices = await integrityQueries.cleanupOrphanedGuestChoices(req.sessionId);
      if (cleanedChoices.length > 0) {
        console.log(`Cleaned up ${cleanedChoices.length} orphaned guest choices after item deletion`);
      }
    } catch (cleanupError) {
      console.error('Warning: Failed to cleanup orphaned guest choices after deletion:', cleanupError);
      // Don't fail the request if cleanup fails
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Session receipt item deleted successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete session receipt item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete session receipt item',
      timestamp: new Date().toISOString()
    });
  }
});

// Clear all session receipt items for a session
router.post('/clear-items', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { session_id } = req.body;

    if (!session_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'session_id is required',
        timestamp: new Date().toISOString()
      });
    }

    const deletedItems = await sessionReceiptQueries.deleteBySession(session_id);

    // Clean up any orphaned guest_choice records after clearing all items
    try {
      const cleanedChoices = await integrityQueries.cleanupOrphanedGuestChoices(req.sessionId);
      if (cleanedChoices.length > 0) {
        console.log(`Cleaned up ${cleanedChoices.length} orphaned guest choices after clearing items`);
      }
    } catch (cleanupError) {
      console.error('Warning: Failed to cleanup orphaned guest choices after clearing:', cleanupError);
      // Don't fail the request if cleanup fails
    }

    res.json({
      return_code: 'SUCCESS',
      message: `Cleared ${deletedItems.length} session receipt items`,
      data: {
        items_cleared: deletedItems.length
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Clear session receipt items error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to clear session receipt items',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
