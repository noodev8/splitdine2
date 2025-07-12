const express = require('express');
const router = express.Router();
const { assignmentQueries } = require('../utils/database');
const { authenticateToken, requireSessionParticipant } = require('../middleware/auth');

// Assign item to user
router.post('/assign', authenticateToken, requireSessionParticipant, async (req, res) => {
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

    // Check if assignment already exists
    const existingAssignment = await assignmentQueries.findByItemAndUser(item_id, user_id);
    if (existingAssignment) {
      return res.status(400).json({
        return_code: 'ALREADY_ASSIGNED',
        message: 'Item is already assigned to this user',
        timestamp: new Date().toISOString()
      });
    }

    // Permission check: participants can only assign to themselves, organizers can assign to anyone
    if (!req.isHost && user_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You can only assign items to yourself',
        timestamp: new Date().toISOString()
      });
    }

    // Create assignment
    const assignment = await assignmentQueries.create({
      session_id: req.sessionId,
      item_id,
      user_id
    });

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Item assigned successfully',
      assignment: {
        id: assignment.id,
        session_id: assignment.session_id,
        item_id: assignment.item_id,
        user_id: assignment.user_id,
        user_name: assignment.user_name,
        created_at: assignment.created_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Assign item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to assign item',
      timestamp: new Date().toISOString()
    });
  }
});

// Remove assignment
router.post('/unassign', authenticateToken, requireSessionParticipant, async (req, res) => {
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

    // Check if assignment exists
    const existingAssignment = await assignmentQueries.findByItemAndUser(item_id, user_id);
    if (!existingAssignment) {
      return res.status(404).json({
        return_code: 'NOT_FOUND',
        message: 'Assignment not found',
        timestamp: new Date().toISOString()
      });
    }

    // Permission check: participants can only unassign themselves, organizers can unassign anyone
    if (!req.isHost && user_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You can only unassign items from yourself',
        timestamp: new Date().toISOString()
      });
    }

    // Remove assignment
    await assignmentQueries.deleteByItemAndUser(item_id, user_id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Item unassigned successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Unassign item error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to unassign item',
      timestamp: new Date().toISOString()
    });
  }
});

// Get assignments for a session
router.post('/get-session-assignments', authenticateToken, requireSessionParticipant, async (req, res) => {
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

    // Get all assignments for the session
    const assignments = await assignmentQueries.getBySession(session_id);

    res.json({
      return_code: 'SUCCESS',
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        session_id: assignment.session_id,
        item_id: assignment.item_id,
        user_id: assignment.user_id,
        user_name: assignment.user_name,
        created_at: assignment.created_at
      })),
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get session assignments error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get assignments',
      timestamp: new Date().toISOString()
    });
  }
});

// Get assignments for a specific item
router.post('/get-item-assignments', authenticateToken, requireSessionParticipant, async (req, res) => {
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

    // Get all assignments for the item
    const assignments = await assignmentQueries.getByItem(item_id);

    res.json({
      return_code: 'SUCCESS',
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        session_id: assignment.session_id,
        item_id: assignment.item_id,
        user_id: assignment.user_id,
        user_name: assignment.user_name,
        created_at: assignment.created_at
      })),
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get item assignments error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get item assignments',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
