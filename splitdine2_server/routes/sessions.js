const express = require('express');
const router = express.Router();
const { sessionQueries, participantQueries } = require('../utils/database');
const { authenticateToken, requireSessionHost, requireSessionParticipant } = require('../middleware/auth');

/**
 * Session Management Routes
 * All routes use POST method and return standardized JSON responses
 */

// Generate random session code
const generateSessionCode = () => {
  return Math.random().toString(36).substring(2, 8).toUpperCase();
};

// Create new session
router.post('/create', authenticateToken, async (req, res) => {
  try {
    const { session_name, restaurant_name } = req.body;

    // Validate required fields
    if (!session_name || !restaurant_name) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session name and restaurant name are required',
        timestamp: new Date().toISOString()
      });
    }

    // Generate unique session code
    let session_code;
    let existingSession;
    do {
      session_code = generateSessionCode();
      existingSession = await sessionQueries.findByCode(session_code);
    } while (existingSession);

    // Create session
    const newSession = await sessionQueries.create({
      host_user_id: req.user.id,
      session_name,
      restaurant_name,
      session_code
    });

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Session created successfully',
      session: {
        id: newSession.id,
        session_name: newSession.session_name,
        restaurant_name: newSession.restaurant_name,
        session_code: newSession.session_code,
        status: newSession.status,
        host_user_id: newSession.host_user_id,
        created_at: newSession.created_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Session creation error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to create session',
      timestamp: new Date().toISOString()
    });
  }
});

// Join session by code
router.post('/join', authenticateToken, async (req, res) => {
  try {
    const { session_code } = req.body;

    // Validate required fields
    if (!session_code) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session code is required',
        timestamp: new Date().toISOString()
      });
    }

    // Find session by code
    const session = await sessionQueries.findByCode(session_code.toUpperCase());
    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found with this code',
        timestamp: new Date().toISOString()
      });
    }

    // Check if session is active
    if (session.status !== 'active') {
      return res.status(400).json({
        return_code: 'SESSION_INACTIVE',
        message: 'This session is no longer active',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user is already a participant
    const isAlreadyParticipant = await participantQueries.isParticipant(session.id, req.user.id);
    const isHost = session.host_user_id === req.user.id;

    if (!isAlreadyParticipant && !isHost) {
      // Add user as participant
      await participantQueries.add(session.id, req.user.id);
    }

    // Get all participants
    const participants = await participantQueries.getBySession(session.id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Successfully joined session',
      session: {
        id: session.id,
        session_name: session.session_name,
        restaurant_name: session.restaurant_name,
        session_code: session.session_code,
        status: session.status,
        host_user_id: session.host_user_id,
        created_at: session.created_at
      },
      participants,
      is_host: isHost,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Session join error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to join session',
      timestamp: new Date().toISOString()
    });
  }
});

// Get session details
router.post('/details', authenticateToken, async (req, res) => {
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

    // Find session
    const session = await sessionQueries.findById(session_id);
    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user has access to this session
    const isHost = session.host_user_id === req.user.id;
    const isParticipant = await participantQueries.isParticipant(session.id, req.user.id);

    if (!isHost && !isParticipant) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You do not have access to this session',
        timestamp: new Date().toISOString()
      });
    }

    // Get participants
    const participants = await participantQueries.getBySession(session.id);

    res.json({
      return_code: 'SUCCESS',
      session: {
        id: session.id,
        session_name: session.session_name,
        restaurant_name: session.restaurant_name,
        session_code: session.session_code,
        status: session.status,
        host_user_id: session.host_user_id,
        created_at: session.created_at,
        updated_at: session.updated_at
      },
      participants,
      is_host: isHost,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Session details error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get session details',
      timestamp: new Date().toISOString()
    });
  }
});

// End session (host only)
router.post('/end', authenticateToken, requireSessionHost, async (req, res) => {
  try {
    const { session_id } = req.body;

    // Update session status to ended
    const updatedSession = await sessionQueries.updateStatus(session_id, 'ended');

    res.json({
      return_code: 'SUCCESS',
      message: 'Session ended successfully',
      session: {
        id: updatedSession.id,
        status: updatedSession.status,
        updated_at: updatedSession.updated_at
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Session end error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to end session',
      timestamp: new Date().toISOString()
    });
  }
});

// Get user's sessions
router.post('/my-sessions', authenticateToken, async (req, res) => {
  try {
    const { query } = require('../config/database');
    
    // Get sessions where user is host or participant
    const result = await query(`
      SELECT DISTINCT s.*, 
             CASE WHEN s.host_user_id = $1 THEN true ELSE false END as is_host
      FROM session s
      LEFT JOIN session_participant sp ON s.id = sp.session_id
      WHERE s.host_user_id = $1 OR sp.user_id = $1
      ORDER BY s.updated_at DESC
    `, [req.user.id]);

    res.json({
      return_code: 'SUCCESS',
      sessions: result.rows,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('My sessions error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get user sessions',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
