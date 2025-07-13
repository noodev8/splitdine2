const express = require('express');
const router = express.Router();
const { splitItemQueries, participantChoiceQueries } = require('../utils/database');
const { authenticateToken, requireSessionParticipant } = require('../middleware/auth');

/**
 * Split Items Management Routes
 * All routes use POST method and return standardized JSON responses
 */

// Add split item
router.post('/add-item', authenticateToken, async (req, res) => {
  try {
    const { session_id, name, price, description, participants } = req.body;

    // DEBUG: Log all received parameters
    console.log('=== ADD SPLIT ITEM DEBUG ===');
    console.log('Received request body:', JSON.stringify(req.body, null, 2));
    console.log('session_id:', session_id, 'type:', typeof session_id);
    console.log('name:', name, 'type:', typeof name);
    console.log('price:', price, 'type:', typeof price);
    console.log('description:', description, 'type:', typeof description);
    console.log('participants:', participants, 'type:', typeof participants);
    console.log('User ID:', req.user?.id);
    console.log('============================');

    // Validate required fields
    if (!session_id || !name || !price) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID, name, and price are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price
    const parsedPrice = parseFloat(price);
    if (isNaN(parsedPrice) || parsedPrice <= 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a positive number',
        timestamp: new Date().toISOString()
      });
    }

    // Create split item data
    const itemData = {
      session_id: parseInt(session_id),
      name: name.trim(),
      price: parsedPrice,
      description: description ? description.trim() : null,
      added_by_user_id: req.user.id
    };

    console.log('Creating split item with data:', JSON.stringify(itemData, null, 2));
    const newItem = await splitItemQueries.create(itemData);

    console.log('Split item created successfully:', JSON.stringify(newItem, null, 2));

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Split item added successfully',
      item: {
        id: newItem.id,
        session_id: newItem.session_id,
        name: newItem.name,
        price: newItem.price,
        description: newItem.description,
        added_by_user_id: newItem.added_by_user_id,
        added_by_name: 'You', // Default for newly created items
        created_at: newItem.created_at,
        updated_at: newItem.updated_at || newItem.created_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Add split item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to add split item',
      timestamp: new Date().toISOString()
    });
  }
});

// Get session split items
router.post('/get-items', authenticateToken, async (req, res) => {
  try {
    console.log('=== SPLIT ITEMS GET-ITEMS DEBUG ===');
    console.log('Request body:', req.body);
    const { session_id } = req.body;
    console.log('Session ID:', session_id);

    // Get all split items for the session
    console.log('Getting split items from database...');
    const items = await splitItemQueries.getBySession(session_id);
    console.log('Split items found:', items.length);

    // Get participants for each item
    const itemsWithParticipants = await Promise.all(
      items.map(async (item) => {
        const participants = await participantChoiceQueries.getSplitItemParticipants(session_id, item.name);
        return {
          id: item.id,
          session_id: item.session_id,
          name: item.name,
          price: item.price,
          description: item.description,
          added_by_user_id: item.added_by_user_id,
          added_by_name: item.added_by_name,
          guest_id: item.guest_id, // Keep for backward compatibility
          participants: participants.map(p => ({
            user_id: p.user_id,
            user_name: p.user_name,
            assignment_id: p.id
          })),
          created_at: item.created_at,
          updated_at: item.updated_at
        };
      })
    );

    // Calculate totals
    const subtotal = items.reduce((sum, item) => sum + parseFloat(item.price), 0);
    const itemCount = items.length;

    res.json({
      return_code: 'SUCCESS',
      items: itemsWithParticipants,
      summary: {
        subtotal: subtotal,
        item_count: itemCount
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get split items error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get split items',
      timestamp: new Date().toISOString()
    });
  }
});

// Update split item
router.post('/update-item', authenticateToken, async (req, res) => {
  try {
    const { item_id, name, price, description } = req.body;

    // DEBUG: Log all received parameters
    console.log('=== UPDATE SPLIT ITEM DEBUG ===');
    console.log('Received request body:', JSON.stringify(req.body, null, 2));
    console.log('item_id:', item_id, 'type:', typeof item_id);
    console.log('name:', name, 'type:', typeof name);
    console.log('price:', price, 'type:', typeof price);
    console.log('description:', description, 'type:', typeof description);
    console.log('User ID:', req.user?.id);
    console.log('===============================');

    // Validate required fields
    if (!item_id || !name || !price) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID, name, and price are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate price
    const parsedPrice = parseFloat(price);
    if (isNaN(parsedPrice) || parsedPrice <= 0) {
      return res.status(400).json({
        return_code: 'INVALID_PRICE',
        message: 'Price must be a positive number',
        timestamp: new Date().toISOString()
      });
    }

    // Check if split item exists
    const existingItem = await splitItemQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Split item not found',
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

    // Check permissions: organizer can edit any item, guests can only edit their own
    if (!isHost && existingItem.added_by_user_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You can only edit items you added',
        timestamp: new Date().toISOString()
      });
    }

    // Update split item
    const updateData = {
      name: name.trim(),
      price: parsedPrice,
      description: description ? description.trim() : null
    };

    console.log('Updating split item with data:', JSON.stringify(updateData, null, 2));
    const updatedItem = await splitItemQueries.update(item_id, updateData);

    if (!updatedItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Split item not found',
        timestamp: new Date().toISOString()
      });
    }

    console.log('Split item updated successfully:', JSON.stringify(updatedItem, null, 2));

    res.json({
      return_code: 'SUCCESS',
      message: 'Split item updated successfully',
      item: {
        id: updatedItem.id,
        session_id: updatedItem.session_id,
        name: updatedItem.name,
        price: updatedItem.price,
        description: updatedItem.description,
        added_by_user_id: updatedItem.added_by_user_id,
        guest_id: updatedItem.guest_id,
        created_at: updatedItem.created_at,
        updated_at: updatedItem.updated_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update split item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update split item',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete split item
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

    // Check if split item exists
    const existingItem = await splitItemQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Split item not found',
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

    // Check permissions: organizer can delete any item, guests can only delete their own
    if (!isHost && existingItem.added_by_user_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You can only delete items you added',
        timestamp: new Date().toISOString()
      });
    }

    // Delete split item
    await splitItemQueries.delete(item_id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Split item deleted successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete split item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete split item',
      timestamp: new Date().toISOString()
    });
  }
});

// Add participant to split item (using participant_choice table)
router.post('/add-participant', authenticateToken, async (req, res) => {
  try {
    const { item_id, user_id } = req.body;

    // Validate required fields
    if (!item_id || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID and User ID are required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if split item exists
    const existingItem = await splitItemQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Split item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Check if assignment already exists
    const existingAssignment = await participantChoiceQueries.findSplitItemAssignment(
      existingItem.session_id,
      existingItem.name,
      user_id
    );
    if (existingAssignment) {
      return res.status(400).json({
        return_code: 'ASSIGNMENT_EXISTS',
        message: 'User is already assigned to this split item',
        timestamp: new Date().toISOString()
      });
    }

    // Create participant choice for split item
    const participantChoice = await participantChoiceQueries.create({
      session_id: existingItem.session_id,
      name: existingItem.name,
      price: existingItem.price,
      description: existingItem.description,
      user_id: user_id,
      split_item: true
    });

    res.json({
      return_code: 'SUCCESS',
      message: 'Participant added to split item successfully',
      participant_choice: participantChoice,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Add participant to split item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to add participant to split item',
      timestamp: new Date().toISOString()
    });
  }
});

// Remove participant from split item (using participant_choice table)
router.post('/remove-participant', authenticateToken, async (req, res) => {
  try {
    const { item_id, user_id } = req.body;

    // Validate required fields
    if (!item_id || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID and User ID are required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if split item exists
    const existingItem = await splitItemQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Split item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Check if assignment exists
    const existingAssignment = await participantChoiceQueries.findSplitItemAssignment(
      existingItem.session_id,
      existingItem.name,
      user_id
    );
    if (!existingAssignment) {
      return res.status(404).json({
        return_code: 'ASSIGNMENT_NOT_FOUND',
        message: 'User is not assigned to this split item',
        timestamp: new Date().toISOString()
      });
    }

    // Remove participant choice
    await participantChoiceQueries.removeSplitItemParticipant(
      existingItem.session_id,
      existingItem.name,
      user_id
    );

    res.json({
      return_code: 'SUCCESS',
      message: 'Participant removed from split item successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Remove participant from split item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to remove participant from split item',
      timestamp: new Date().toISOString()
    });
  }
});

// Get participants for a split item
router.post('/get-participants', authenticateToken, async (req, res) => {
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

    // Check if split item exists
    const existingItem = await splitItemQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Split item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Get participants for this split item
    const participants = await participantChoiceQueries.getSplitItemParticipants(
      existingItem.session_id,
      existingItem.name
    );

    res.json({
      return_code: 'SUCCESS',
      participants: participants,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get split item participants error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get split item participants',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete split item
router.post('/delete', authenticateToken, async (req, res) => {
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

    // Check if split item exists
    const existingItem = await splitItemQueries.findById(item_id);
    if (!existingItem) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Split item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Delete all participant choices for this split item first
    await participantChoiceQueries.deleteBySplitItem(existingItem.session_id, existingItem.name);

    // Delete the split item
    await splitItemQueries.delete(item_id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Split item deleted successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete split item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete split item',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
