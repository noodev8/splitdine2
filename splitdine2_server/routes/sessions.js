const express = require('express');
const router = express.Router();
const { sessionQueries, participantQueries } = require('../utils/database');
const { authenticateToken, requireSessionHost, requireSessionParticipant } = require('../middleware/auth');

/**
 * Session Management Routes
 * All routes use POST method and return standardized JSON responses
 */

// Generate random 6-digit session code
const generateSessionCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Create new session
router.post('/create', authenticateToken, async (req, res) => {
  try {
    const { session_name, location, session_date, session_time, description, food_type } = req.body;

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

    // Generate unique session code (check only current/future sessions)
    let session_code;
    let existingSession;
    do {
      session_code = generateSessionCode();
      existingSession = await sessionQueries.findCurrentByCode(session_code);
    } while (existingSession);

    // Create session
    const newSession = await sessionQueries.create({
      organizer_id: req.user.id,
      session_name,
      location,
      session_date,
      session_time,
      description,
      food_type,
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
      FROM session s
      LEFT JOIN session_guest sp ON s.id = sp.session_id
      WHERE s.organizer_id = $1 OR sp.user_id = $1
      ORDER BY s.updated_at DESC
    `, [req.user.id]);

    res.json({
      return_code: 'SUCCESS',
      sessions: result.rows,
      app_info: {
        required_version: process.env.REQUIRED_APP_VERSION || '1.0.0'
      },
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

// Leave session
router.post('/leave', authenticateToken, async (req, res) => {
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

    // Check if user is the host (hosts cannot leave their own session unless they transfer first)
    if (session.organizer_id === req.user.id) {
      return res.status(400).json({
        return_code: 'HOST_CANNOT_LEAVE',
        message: 'Session host must transfer host privileges before leaving',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user is a participant
    const isParticipant = await participantQueries.isParticipant(session_id, req.user.id);
    if (!isParticipant) {
      return res.status(400).json({
        return_code: 'NOT_PARTICIPANT',
        message: 'You are not a participant in this session',
        timestamp: new Date().toISOString()
      });
    }

    // Remove user from session participants (set left_at timestamp)
    await participantQueries.leave(session_id, req.user.id);

    // Also remove all items for this user in this session
    const { query } = require('../config/database');
    await query(`
      DELETE FROM guest_choice
      WHERE session_id = $1 AND user_id = $2
    `, [session_id, req.user.id]);

    res.json({
      return_code: 'SUCCESS',
      message: 'Successfully left session',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Leave session error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to leave session',
      timestamp: new Date().toISOString()
    });
  }
});

// Remove participant from session (host only)
router.post('/remove-participant', authenticateToken, async (req, res) => {
  try {
    const { session_id, user_id } = req.body;

    // Validate required fields
    if (!session_id || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID and User ID are required',
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

    // Check if current user is the host
    if (session.organizer_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the session host can remove participants',
        timestamp: new Date().toISOString()
      });
    }

    // Cannot remove the host
    if (user_id === session.organizer_id) {
      return res.status(400).json({
        return_code: 'CANNOT_REMOVE_HOST',
        message: 'Cannot remove the session host',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user is a participant
    const isParticipant = await participantQueries.isParticipant(session_id, user_id);
    if (!isParticipant) {
      return res.status(400).json({
        return_code: 'NOT_PARTICIPANT',
        message: 'User is not a participant in this session',
        timestamp: new Date().toISOString()
      });
    }

    // Remove user from session participants (set left_at timestamp)
    await participantQueries.leave(session_id, user_id);

    // Also remove all items for this user in this session
    const { query } = require('../config/database');
    await query(`
      DELETE FROM guest_choice
      WHERE session_id = $1 AND user_id = $2
    `, [session_id, user_id]);

    res.json({
      return_code: 'SUCCESS',
      message: 'Participant removed successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Remove participant error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to remove participant',
      timestamp: new Date().toISOString()
    });
  }
});

// Transfer host privileges to another participant
router.post('/transfer-host', authenticateToken, async (req, res) => {
  try {
    const { session_id, new_host_user_id } = req.body;

    // Validate required fields
    if (!session_id || !new_host_user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID and new host user ID are required',
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

    // Check if current user is the host
    if (session.organizer_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the session host can transfer host privileges',
        timestamp: new Date().toISOString()
      });
    }

    // Cannot transfer to self
    if (new_host_user_id === req.user.id) {
      return res.status(400).json({
        return_code: 'INVALID_TRANSFER',
        message: 'Cannot transfer host privileges to yourself',
        timestamp: new Date().toISOString()
      });
    }

    // Check if new host is a participant
    const isParticipant = await participantQueries.isParticipant(session_id, new_host_user_id);
    if (!isParticipant) {
      return res.status(400).json({
        return_code: 'NOT_PARTICIPANT',
        message: 'New host must be a participant in the session',
        timestamp: new Date().toISOString()
      });
    }

    // Update session organizer
    const { query } = require('../config/database');
    await query(`
      UPDATE session
      SET organizer_id = $1, updated_at = NOW()
      WHERE id = $2
    `, [new_host_user_id, session_id]);

    res.json({
      return_code: 'SUCCESS',
      message: 'Host privileges transferred successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Transfer host error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to transfer host privileges',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete/cancel session (host only)
router.post('/delete', authenticateToken, async (req, res) => {
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

    // Check if current user is the host
    if (session.organizer_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the session host can delete the session',
        timestamp: new Date().toISOString()
      });
    }

    // Delete all related data in correct order (due to foreign key constraints)
    const { query } = require('../config/database');

    // Delete guest choices (items and split item assignments)
    await query('DELETE FROM guest_choice WHERE session_id = $1', [session_id]);

    // Delete split items
    await query('DELETE FROM split_items WHERE session_id = $1', [session_id]);

    // Delete session participants
    await query('DELETE FROM session_guest WHERE session_id = $1', [session_id]);

    // Delete final splits
    await query('DELETE FROM final_splits WHERE session_id = $1', [session_id]);

    // Delete session activity log
    await query('DELETE FROM session_activity_log WHERE session_id = $1', [session_id]);

    // Finally delete the session
    await query('DELETE FROM session WHERE id = $1', [session_id]);

    res.json({
      return_code: 'SUCCESS',
      message: 'Session deleted successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete session error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete session',
      timestamp: new Date().toISOString()
    });
  }
});

// Update session bill totals
router.post('/update-bill-totals', authenticateToken, async (req, res) => {
  try {
    const { session_id, item_amount, tax_amount, service_charge, extra_charge, total_amount } = req.body;

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

    // Check if user is participant or organizer
    const isHost = session.organizer_id === req.user.id;
    const isParticipant = await participantQueries.isParticipant(session_id, req.user.id);

    if (!isHost && !isParticipant) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You are not a participant in this session',
        timestamp: new Date().toISOString()
      });
    }

    // Update session bill totals
    const billData = {
      item_amount: parseFloat(item_amount) || 0.0,
      tax_amount: parseFloat(tax_amount) || 0.0,
      service_charge: parseFloat(service_charge) || 0.0,
      extra_charge: parseFloat(extra_charge) || 0.0,
      total_amount: parseFloat(total_amount) || 0.0
    };

    const updatedSession = await sessionQueries.updateBillTotals(session_id, billData);

    res.json({
      return_code: 'SUCCESS',
      message: 'Bill totals updated successfully',
      session: {
        id: updatedSession.id,
        organizer_id: updatedSession.organizer_id,
        session_name: updatedSession.session_name,
        location: updatedSession.location,
        session_date: updatedSession.session_date,
        session_time: updatedSession.session_time,
        description: updatedSession.description,
        join_code: updatedSession.join_code,
        receipt_processed: updatedSession.receipt_processed,
        total_amount: updatedSession.total_amount,
        tax_amount: updatedSession.tax_amount,
        tip_amount: updatedSession.tip_amount,
        service_charge: updatedSession.service_charge,
        item_amount: updatedSession.item_amount,
        extra_charge: updatedSession.extra_charge,
        created_at: updatedSession.created_at,
        updated_at: updatedSession.updated_at,
        is_host: isHost
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update bill totals error:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update bill totals',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
