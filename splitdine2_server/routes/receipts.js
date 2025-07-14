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
    const { session_id, item_name, price, share } = req.body;

    // DEBUG: Log all received parameters
    console.log('=== ADD ITEM DEBUG ===');
    console.log('Received request body:', JSON.stringify(req.body, null, 2));
    console.log('session_id:', session_id, 'type:', typeof session_id);
    console.log('item_name:', item_name, 'type:', typeof item_name);
    console.log('price:', price, 'type:', typeof price);
    console.log('share:', share, 'type:', typeof share);
    console.log('User ID:', req.user?.id);
    console.log('======================');

    // Validate required fields (no quantity - multiple items are separate rows)
    if (!session_id || !item_name || price === undefined || price === null) {
      console.log('VALIDATION FAILED - Missing fields');
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID, item name, and price are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price (allow price = 0 for shareable items)
    if (isNaN(price) || price < 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a non-negative number',
        timestamp: new Date().toISOString()
      });
    }

    // Create receipt item (no quantity column - each item is a single row)
    const itemData = {
      session_id: parseInt(session_id),
      item_name: item_name.trim(),
      price: parseFloat(price),
      added_by_user_id: req.user.id,
      share: share || null
    };

    console.log('Creating item with data:', JSON.stringify(itemData, null, 2));
    const newItem = await receiptQueries.create(itemData);

    console.log('Item created successfully:', JSON.stringify(newItem, null, 2));

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Receipt item added successfully',
      item: {
        id: newItem.id,
        session_id: newItem.session_id,
        item_name: newItem.item_name,
        price: newItem.price,
        quantity: 1, // Always 1 in new structure (no quantity column)
        share: newItem.share,
        added_by_user_id: newItem.added_by_user_id,
        added_by_name: 'You', // Default for newly created items
        created_at: newItem.created_at,
        updated_at: newItem.updated_at || newItem.created_at
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
router.post('/update-item', authenticateToken, async (req, res) => {
  try {
    const { item_id, item_name, price, share } = req.body;

    // DEBUG: Log all received parameters
    console.log('=== UPDATE ITEM DEBUG ===');
    console.log('Received request body:', JSON.stringify(req.body, null, 2));
    console.log('item_id:', item_id, 'type:', typeof item_id);
    console.log('item_name:', item_name, 'type:', typeof item_name);
    console.log('price:', price, 'type:', typeof price);
    console.log('share:', share, 'type:', typeof share);
    console.log('User ID:', req.user?.id);
    console.log('=========================');

    // Validate required fields (no quantity - it's represented by multiple rows)
    if (!item_id || !item_name || price === undefined || price === null) {
      console.log('VALIDATION FAILED - Missing fields');
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID, item name, and price are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price (allow price = 0 for shareable items)
    if (isNaN(price) || price < 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a non-negative number',
        timestamp: new Date().toISOString()
      });
    }

    // Get the item to check ownership and get session info
    const existingItem = await receiptQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Receipt item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Get session to check if user is participant
    const { sessionQueries, participantQueries } = require('../utils/database');
    const session = await sessionQueries.findById(existingItem.session_id);

    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user is host or participant
    const isHost = session.organizer_id === req.user.id;
    const isParticipant = await participantQueries.isParticipant(existingItem.session_id, req.user.id);

    if (!isHost && !isParticipant) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You are not a participant in this session',
        timestamp: new Date().toISOString()
      });
    }

    // Any participant can edit any item in the session

    // Update receipt item (no quantity column - multiple items are separate rows)
    const updateData = {
      item_name: item_name.trim(),
      price: parseFloat(price),
      share: share || null
    };

    console.log('Updating item with data:', JSON.stringify(updateData, null, 2));
    const updatedItem = await receiptQueries.update(item_id, updateData);

    if (!updatedItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Receipt item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Get the updated item with user info for proper response
    const itemWithUser = await receiptQueries.getBySession(existingItem.session_id);
    const updatedItemWithUser = itemWithUser.find(item => item.id === updatedItem.id);

    console.log('Item updated successfully:', JSON.stringify(updatedItem, null, 2));

    res.json({
      return_code: 'SUCCESS',
      message: 'Receipt item updated successfully',
      item: {
        id: updatedItem.id,
        session_id: updatedItem.session_id,
        item_name: updatedItem.item_name,
        price: updatedItem.price,
        quantity: 1, // Always 1 in new structure (no quantity column)
        share: updatedItem.share,
        added_by_user_id: updatedItem.added_by_user_id,
        added_by_name: updatedItemWithUser?.added_by_name || 'Unknown',
        created_at: updatedItem.created_at,
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
router.post('/delete-item', authenticateToken, async (req, res) => {
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

    // Get the item to check ownership and get session info
    const existingItem = await receiptQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Receipt item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Get session to check if user is participant
    const { sessionQueries, participantQueries } = require('../utils/database');
    const session = await sessionQueries.findById(existingItem.session_id);

    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user is host or participant
    const isHost = session.organizer_id === req.user.id;
    const isParticipant = await participantQueries.isParticipant(existingItem.session_id, req.user.id);

    if (!isHost && !isParticipant) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You are not a participant in this session',
        timestamp: new Date().toISOString()
      });
    }

    // Any participant can delete any item in the session

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
