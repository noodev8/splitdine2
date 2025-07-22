const express = require('express');
const router = express.Router();
const { sessionReceiptQueries, sessionQueries, participantQueries, integrityQueries } = require('../utils/database');
const { query } = require('../config/database');
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

    // Update the price in guest_choice table for all assignments of this item
    try {
      // First, get the current assignments to check if it's a shared item
      const assignmentsResult = await query(
        'SELECT COUNT(DISTINCT user_id) as assignment_count, MAX(split_item) as is_shared FROM guest_choice WHERE session_id = $1 AND item_id = $2',
        [req.sessionId, item_id]
      );
      
      const assignments = assignmentsResult.rows[0];
      const assignmentCount = parseInt(assignments.assignment_count) || 0;
      const isShared = assignments.is_shared;
      
      if (assignmentCount > 0) {
        // Calculate the price per assignment
        let pricePerAssignment = numericPrice;
        if (isShared && assignmentCount > 0) {
          pricePerAssignment = numericPrice / assignmentCount;
        }
        
        // Update all guest_choice records for this item
        await query(
          'UPDATE guest_choice SET price = $1, name = $2, updated_at = NOW() WHERE session_id = $3 AND item_id = $4',
          [pricePerAssignment, item_name.trim(), req.sessionId, item_id]
        );
        
        console.log(`Updated ${assignmentCount} guest choice(s) with new price: ${pricePerAssignment} (shared: ${isShared})`);
      }
    } catch (updateError) {
      console.error('Warning: Failed to update guest choices after item update:', updateError);
      // Don't fail the request if guest_choice update fails
    }

    // Clean up any orphaned guest_choice records after updating item (in case item_id changed)
    try {
      const cleanedChoices = await integrityQueries.cleanupOrphanedGuestChoices(session_id);
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
      const cleanedChoices = await integrityQueries.cleanupOrphanedGuestChoices(session_id);
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
      const cleanedChoices = await integrityQueries.cleanupOrphanedGuestChoices(session_id);
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
