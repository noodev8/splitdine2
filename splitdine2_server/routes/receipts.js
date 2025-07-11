const express = require('express');
const router = express.Router();
const { receiptQueries } = require('../utils/database');
const { authenticateToken, requireSessionParticipant } = require('../middleware/auth');

/**
 * Receipt Management Routes
 * All routes use POST method and return standardized JSON responses
 */

// Add receipt item
router.post('/add-item', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { session_id, item_name, price, quantity } = req.body;

    // Validate required fields
    if (!session_id || !item_name || !price || !quantity) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID, item name, price, and quantity are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price and quantity
    if (isNaN(price) || price <= 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a positive number',
        timestamp: new Date().toISOString()
      });
    }

    if (isNaN(quantity) || quantity <= 0 || !Number.isInteger(Number(quantity))) {
      return res.status(400).json({
        return_code: 'INVALID_QUANTITY',
        message: 'Quantity must be a positive integer',
        timestamp: new Date().toISOString()
      });
    }

    // Create receipt item
    const newItem = await receiptQueries.create({
      session_id,
      item_name: item_name.trim(),
      price: parseFloat(price),
      quantity: parseInt(quantity),
      added_by_user_id: req.user.id
    });

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Receipt item added successfully',
      item: {
        id: newItem.id,
        session_id: newItem.session_id,
        item_name: newItem.item_name,
        price: newItem.price,
        quantity: newItem.quantity,
        total: newItem.price * newItem.quantity,
        added_by_user_id: newItem.added_by_user_id,
        created_at: newItem.created_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Add receipt item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to add receipt item',
      timestamp: new Date().toISOString()
    });
  }
});

// Get session receipt items
router.post('/get-items', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { session_id } = req.body;

    // Get all receipt items for the session
    const items = await receiptQueries.getBySession(session_id);

    // Calculate totals
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const itemCount = items.reduce((sum, item) => sum + item.quantity, 0);

    res.json({
      return_code: 'SUCCESS',
      items: items.map(item => ({
        id: item.id,
        session_id: item.session_id,
        item_name: item.item_name,
        price: item.price,
        quantity: item.quantity,
        total: item.price * item.quantity,
        added_by_user_id: item.added_by_user_id,
        added_by_name: item.added_by_name,
        created_at: item.created_at,
        updated_at: item.updated_at
      })),
      summary: {
        item_count: itemCount,
        subtotal: subtotal,
        total_items: items.length
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get receipt items error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get receipt items',
      timestamp: new Date().toISOString()
    });
  }
});

// Update receipt item
router.post('/update-item', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { item_id, item_name, price, quantity } = req.body;

    // Validate required fields
    if (!item_id || !item_name || !price || !quantity) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID, item name, price, and quantity are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price and quantity
    if (isNaN(price) || price <= 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a positive number',
        timestamp: new Date().toISOString()
      });
    }

    if (isNaN(quantity) || quantity <= 0 || !Number.isInteger(Number(quantity))) {
      return res.status(400).json({
        return_code: 'INVALID_QUANTITY',
        message: 'Quantity must be a positive integer',
        timestamp: new Date().toISOString()
      });
    }

    // Update receipt item
    const updatedItem = await receiptQueries.update(item_id, {
      item_name: item_name.trim(),
      price: parseFloat(price),
      quantity: parseInt(quantity)
    });

    if (!updatedItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Receipt item not found',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Receipt item updated successfully',
      item: {
        id: updatedItem.id,
        session_id: updatedItem.session_id,
        item_name: updatedItem.item_name,
        price: updatedItem.price,
        quantity: updatedItem.quantity,
        total: updatedItem.price * updatedItem.quantity,
        updated_at: updatedItem.updated_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update receipt item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update receipt item',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete receipt item
router.post('/delete-item', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { item_id } = req.body;

    // Validate required fields
    if (!item_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID is required',
        timestamp: new Date().toISOString()
      });
    }

    // Delete receipt item
    await receiptQueries.delete(item_id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Receipt item deleted successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete receipt item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete receipt item',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
