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
    const { session_name, location, session_date, session_time, description } = req.body;

    // Validate required fields
    if (!location || !session_date) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Location and session date are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate session date is not in the past
    const sessionDate = new Date(session_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (sessionDate < today) {
      return res.status(400).json({
        return_code: 'INVALID_DATE',
        message: 'Cannot create session with a date in the past',
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
      organizer_id: req.user.id,
      session_name,
      location,
      session_date,
      session_time,
      description,
      join_code: session_code
    });

    // Automatically add the organizer as a session participant
    await participantQueries.add(newSession.id, req.user.id);

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Session created successfully',
      session: {
        id: newSession.id,
        organizer_id: newSession.organizer_id,
        session_name: newSession.session_name,
        location: newSession.location,
        session_date: newSession.session_date,
        session_time: newSession.session_time,
        description: newSession.description,
        join_code: newSession.join_code,
        receipt_processed: newSession.receipt_processed,
        total_amount: newSession.total_amount,
        tax_amount: newSession.tax_amount,
        tip_amount: newSession.tip_amount,
        service_charge: newSession.service_charge,
        created_at: newSession.created_at,
        updated_at: newSession.updated_at,
        is_host: true
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
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

    // Check if session date is not in the past
    const sessionDate = new Date(session.session_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (sessionDate < today) {
      return res.status(400).json({
        return_code: 'SESSION_EXPIRED',
        message: 'Cannot join session with a date in the past',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user is already a participant
    const isAlreadyParticipant = await participantQueries.isParticipant(session.id, req.user.id);
    const isHost = session.organizer_id === req.user.id;

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
        organizer_id: session.organizer_id,
        session_name: session.session_name,
        location: session.location,
        session_date: session.session_date,
        session_time: session.session_time,
        description: session.description,
        join_code: session.join_code,
        receipt_processed: session.receipt_processed,
        total_amount: session.total_amount,
        tax_amount: session.tax_amount,
        tip_amount: session.tip_amount,
        service_charge: session.service_charge,
        created_at: session.created_at,
        updated_at: session.updated_at,
        is_host: isHost
      },
      participants,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
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
    const isHost = session.organizer_id === req.user.id;
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
        organizer_id: session.organizer_id,
        session_name: session.session_name,
        location: session.location,
        session_date: session.session_date,
        session_time: session.session_time,
        description: session.description,
        join_code: session.join_code,
        receipt_processed: session.receipt_processed,
        total_amount: session.total_amount,
        tax_amount: session.tax_amount,
        tip_amount: session.tip_amount,
        service_charge: session.service_charge,
        created_at: session.created_at,
        updated_at: session.updated_at,
        is_host: isHost
      },
      participants,
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
             CASE WHEN s.organizer_id = $1 THEN true ELSE false END as is_host
      FROM sessions s
      LEFT JOIN session_participants sp ON s.id = sp.session_id
      WHERE s.organizer_id = $1 OR sp.user_id = $1
      ORDER BY s.updated_at DESC
    `, [req.user.id]);

    res.json({
      return_code: 'SUCCESS',
      sessions: result.rows,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get user sessions',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
