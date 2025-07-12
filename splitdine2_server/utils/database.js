const { query } = require('../config/database');

/**
 * Database utility functions for common operations
 */

// User operations
const userQueries = {
  // Find user by email
  findByEmail: async (email) => {
    const result = await query(
      'SELECT * FROM app_user WHERE email = $1',
      [email]
    );
    return result.rows[0];
  },

  // Find user by ID
  findById: async (id) => {
    const result = await query(
      'SELECT * FROM app_user WHERE id = $1',
      [id]
    );
    return result.rows[0];
  },

  // Create new user
  create: async (userData) => {
    const { email, phone, display_name, password_hash, is_anonymous } = userData;
    const result = await query(
      `INSERT INTO app_user (email, phone, display_name, password_hash, is_anonymous)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, email, display_name, is_anonymous, created_at`,
      [email, phone, display_name, password_hash, is_anonymous || false]
    );
    return result.rows[0];
  },

  // Update last active timestamp
  updateLastActive: async (userId) => {
    await query(
      'UPDATE app_user SET last_active_at = NOW() WHERE id = $1',
      [userId]
    );
  }
};

// Session operations
const sessionQueries = {
  // Create new session
  create: async (sessionData) => {
    const { organizer_id, session_name, location, session_date, session_time, description, join_code } = sessionData;
    const result = await query(
      `INSERT INTO sessions (organizer_id, session_name, location, session_date, session_time, description, join_code)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [organizer_id, session_name, location, session_date, session_time, description, join_code]
    );
    return result.rows[0];
  },

  // Find session by code
  findByCode: async (sessionCode) => {
    const result = await query(
      'SELECT * FROM sessions WHERE join_code = $1',
      [sessionCode]
    );
    return result.rows[0];
  },

  // Find session by ID
  findById: async (sessionId) => {
    const result = await query(
      'SELECT * FROM sessions WHERE id = $1',
      [sessionId]
    );
    return result.rows[0];
  },

  // Update session
  update: async (sessionId, updateData) => {
    const { session_name, location, session_date, session_time, description } = updateData;
    const result = await query(
      `UPDATE sessions
       SET session_name = $1, location = $2, session_date = $3, session_time = $4, description = $5, updated_at = NOW()
       WHERE id = $6
       RETURNING *`,
      [session_name, location, session_date, session_time, description, sessionId]
    );
    return result.rows[0];
  },

  // Delete session
  delete: async (sessionId) => {
    const result = await query(
      'DELETE FROM sessions WHERE id = $1 RETURNING *',
      [sessionId]
    );
    return result.rows[0];
  }
};

// Session participant operations
const participantQueries = {
  // Add participant to session
  add: async (sessionId, userId) => {
    const result = await query(
      `INSERT INTO session_participants (session_id, user_id)
       VALUES ($1, $2)
       RETURNING *`,
      [sessionId, userId]
    );
    return result.rows[0];
  },

  // Get session participants
  getBySession: async (sessionId) => {
    const result = await query(
      `SELECT sp.*, u.display_name, u.email
       FROM session_participants sp
       JOIN app_user u ON sp.user_id = u.id
       WHERE sp.session_id = $1`,
      [sessionId]
    );
    return result.rows;
  },

  // Check if user is participant
  isParticipant: async (sessionId, userId) => {
    const result = await query(
      'SELECT id FROM session_participants WHERE session_id = $1 AND user_id = $2',
      [sessionId, userId]
    );
    return result.rows.length > 0;
  }
};

// Receipt item operations
const receiptQueries = {
  // Create receipt item
  create: async (itemData) => {
    const { session_id, item_name, price, quantity, added_by_user_id } = itemData;
    const result = await query(
      `INSERT INTO receipt_item (session_id, item_name, price, quantity, added_by_user_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [session_id, item_name, price, quantity, added_by_user_id]
    );
    return result.rows[0];
  },

  // Get items by session
  getBySession: async (sessionId) => {
    const result = await query(
      `SELECT ri.*, u.display_name as added_by_name
       FROM receipt_item ri
       JOIN app_user u ON ri.added_by_user_id = u.id
       WHERE ri.session_id = $1
       ORDER BY ri.created_at`,
      [sessionId]
    );
    return result.rows;
  },

  // Update receipt item
  update: async (itemId, updateData) => {
    const { item_name, price, quantity } = updateData;
    const result = await query(
      `UPDATE receipt_item 
       SET item_name = $1, price = $2, quantity = $3, updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [item_name, price, quantity, itemId]
    );
    return result.rows[0];
  },

  // Delete receipt item
  delete: async (itemId) => {
    await query('DELETE FROM receipt_item WHERE id = $1', [itemId]);
  }
};

module.exports = {
  userQueries,
  sessionQueries,
  participantQueries,
  receiptQueries
};
