const express = require('express');
const router = express.Router();
const { query } = require('../utils/database');
const { authenticateToken, requireSessionParticipant } = require('../middleware/auth');

/**
 * Guest Choice Management Routes
 * All routes use POST method and return standardized JSON responses
 */

// Assign item to user (add guest choice)
router.post('/assign', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { name, price, user_id, description, split_item } = req.body;

    // Validate required fields
    if (!name || price === undefined || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item name, price, and user_id are required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if assignment already exists
    const existingChoice = await query(
      'SELECT id FROM guest_choice WHERE session_id = $1 AND name = $2 AND user_id = $3',
      [req.sessionId, name, user_id]
    );

    if (existingChoice.rows.length > 0) {
      return res.status(400).json({
        return_code: 'ALREADY_ASSIGNED',
        message: 'Item is already assigned to this user',
        timestamp: new Date().toISOString()
      });
    }

    // Create guest choice
    const result = await query(
      `INSERT INTO guest_choice (session_id, name, price, user_id, description, split_item, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
       RETURNING *`,
      [req.sessionId, name, parseFloat(price), user_id, description, split_item || false]
    );

    const choice = result.rows[0];

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Item assigned successfully',
      choice: {
        id: choice.id,
        session_id: choice.session_id,
        name: choice.name,
        price: choice.price,
        user_id: choice.user_id,
        description: choice.description,
        split_item: choice.split_item,
        created_at: choice.created_at,
        updated_at: choice.updated_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error assigning item:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to assign item',
      timestamp: new Date().toISOString()
    });
  }
});

// Unassign item from user (remove guest choice)
router.post('/unassign', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { name, user_id } = req.body;

    // Validate required fields
    if (!name || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item name and user_id are required',
        timestamp: new Date().toISOString()
      });
    }

    // Delete guest choice
    const result = await query(
      'DELETE FROM guest_choice WHERE session_id = $1 AND name = $2 AND user_id = $3 RETURNING *',
      [req.sessionId, name, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        return_code: 'NOT_FOUND',
        message: 'Assignment not found',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Item unassigned successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error unassigning item:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to unassign item',
      timestamp: new Date().toISOString()
    });
  }
});

// Get assignments for a specific item
router.post('/get_item_assignments', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { name } = req.body;

    // Validate required fields
    if (!name) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item name is required',
        timestamp: new Date().toISOString()
      });
    }

    // Get all assignments for the item
    const result = await query(
      `SELECT gc.*, u.display_name as user_name
       FROM guest_choice gc
       JOIN app_user u ON gc.user_id = u.id
       WHERE gc.session_id = $1 AND gc.name = $2
       ORDER BY gc.created_at`,
      [req.sessionId, name]
    );

    const assignments = result.rows.map(row => ({
      id: row.id,
      session_id: row.session_id,
      name: row.name,
      price: row.price,
      user_id: row.user_id,
      user_name: row.user_name,
      description: row.description,
      split_item: row.split_item,
      created_at: row.created_at,
      updated_at: row.updated_at
    }));

    res.json({
      return_code: 'SUCCESS',
      assignments: assignments,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error getting item assignments:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get item assignments',
      timestamp: new Date().toISOString()
    });
  }
});

// Get all guest choices for a session
router.post('/get_session_assignments', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    // Get all assignments for the session
    const result = await query(
      `SELECT gc.*, u.display_name as user_name
       FROM guest_choice gc
       JOIN app_user u ON gc.user_id = u.id
       WHERE gc.session_id = $1
       ORDER BY gc.name, gc.created_at`,
      [req.sessionId]
    );

    const assignments = result.rows.map(row => ({
      id: row.id,
      session_id: row.session_id,
      name: row.name,
      price: row.price,
      user_id: row.user_id,
      user_name: row.user_name,
      description: row.description,
      split_item: row.split_item,
      created_at: row.created_at,
      updated_at: row.updated_at
    }));

    res.json({
      return_code: 'SUCCESS',
      assignments: assignments,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error getting session assignments:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get session assignments',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
