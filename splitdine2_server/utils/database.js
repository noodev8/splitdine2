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
  },

  // Update user display name
  updateDisplayName: async (userId, displayName) => {
    const result = await query(
      'UPDATE app_user SET display_name = $1 WHERE id = $2 RETURNING id, email, display_name, is_anonymous, created_at',
      [displayName, userId]
    );
    return result.rows[0];
  },

  // Delete user and all related data
  deleteUser: async (userId) => {
    // Delete in order to respect foreign key constraints
    // Delete item assignments
    await query('DELETE FROM item_assignments WHERE user_id = $1', [userId]);

    // Delete session participants
    await query('DELETE FROM session_guest WHERE user_id = $1', [userId]);

    // Delete final splits
    await query('DELETE FROM final_splits WHERE user_id = $1', [userId]);

    // Delete sessions organized by this user (and their related data)
    const userSessions = await query('SELECT id FROM session WHERE organizer_id = $1', [userId]);
    for (const session of userSessions.rows) {
      // Delete session-related data
      await query('DELETE FROM item_assignments WHERE session_id = $1', [session.id]);
      await query('DELETE FROM receipt_items WHERE session_id = $1', [session.id]);
      await query('DELETE FROM session_guest WHERE session_id = $1', [session.id]);
      await query('DELETE FROM final_splits WHERE session_id = $1', [session.id]);
      await query('DELETE FROM session_activity_log WHERE session_id = $1', [session.id]);
    }

    // Delete sessions organized by this user
    await query('DELETE FROM session WHERE organizer_id = $1', [userId]);

    // Finally delete the user
    await query('DELETE FROM app_user WHERE id = $1', [userId]);
  }
};

// Session operations
const sessionQueries = {
  // Create new session
  create: async (sessionData) => {
    const { organizer_id, session_name, location, session_date, session_time, description, join_code } = sessionData;
    const result = await query(
      `INSERT INTO session (organizer_id, session_name, location, session_date, session_time, description, join_code)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [organizer_id, session_name, location, session_date, session_time, description, join_code]
    );
    return result.rows[0];
  },

  // Find session by code
  findByCode: async (sessionCode) => {
    const result = await query(
      'SELECT * FROM session WHERE join_code = $1',
      [sessionCode]
    );
    return result.rows[0];
  },

  // Find current session by code (not expired)
  findCurrentByCode: async (sessionCode) => {
    const result = await query(
      'SELECT * FROM session WHERE join_code = $1 AND session_date >= CURRENT_DATE',
      [sessionCode]
    );
    return result.rows[0];
  },

  // Find session by ID
  findById: async (sessionId) => {
    const result = await query(
      'SELECT * FROM session WHERE id = $1',
      [sessionId]
    );
    return result.rows[0];
  },

  // Update session
  update: async (sessionId, updateData) => {
    const { session_name, location, session_date, session_time, description } = updateData;
    const result = await query(
      `UPDATE session
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
      'DELETE FROM session WHERE id = $1 RETURNING *',
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
      `INSERT INTO session_guest (session_id, user_id)
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
       FROM session_guest sp
       JOIN app_user u ON sp.user_id = u.id
       WHERE sp.session_id = $1 AND sp.left_at IS NULL
       ORDER BY sp.joined_at`,
      [sessionId]
    );
    return result.rows;
  },

  // Check if user is participant
  isParticipant: async (sessionId, userId) => {
    const result = await query(
      'SELECT id FROM session_guest WHERE session_id = $1 AND user_id = $2 AND left_at IS NULL',
      [sessionId, userId]
    );
    return result.rows.length > 0;
  },

  // Leave session (set left_at timestamp)
  leave: async (sessionId, userId) => {
    const result = await query(
      `UPDATE session_guest
       SET left_at = NOW()
       WHERE session_id = $1 AND user_id = $2 AND left_at IS NULL
       RETURNING *`,
      [sessionId, userId]
    );
    return result.rows[0];
  }
};

// Receipt item operations
const receiptQueries = {
  // Create receipt item
  create: async (itemData) => {
    const { session_id, item_name, price, quantity, added_by_user_id, share } = itemData;
    const result = await query(
      `INSERT INTO receipt_items (session_id, name, price, quantity, added_by_user_id, share)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [session_id, item_name, price, quantity, added_by_user_id, share]
    );
    return result.rows[0];
  },

  // Get items by session
  getBySession: async (sessionId) => {
    const result = await query(
      `SELECT ri.*, u.display_name as added_by_name
       FROM receipt_items ri
       JOIN app_user u ON ri.added_by_user_id = u.id
       WHERE ri.session_id = $1
       ORDER BY ri.created_at DESC`,
      [sessionId]
    );
    return result.rows;
  },

  // Find receipt item by ID
  findById: async (itemId) => {
    const result = await query(
      'SELECT * FROM receipt_items WHERE id = $1',
      [itemId]
    );
    return result.rows[0];
  },

  // Update receipt item
  update: async (itemId, updateData) => {
    const { item_name, price, quantity, share } = updateData;
    const result = await query(
      `UPDATE receipt_items
       SET name = $1, price = $2, quantity = $3, share = $4, updated_at = NOW()
       WHERE id = $5
       RETURNING *`,
      [item_name, price, quantity, share, itemId]
    );
    return result.rows[0];
  },

  // Delete receipt item
  delete: async (itemId) => {
    await query('DELETE FROM receipt_items WHERE id = $1', [itemId]);
  }
};

// Assignment queries
const assignmentQueries = {
  // Create assignment
  create: async (assignmentData) => {
    const { session_id, item_id, user_id } = assignmentData;
    const result = await query(
      `INSERT INTO item_assignments (session_id, item_id, user_id)
       VALUES ($1, $2, $3)
       RETURNING id, session_id, item_id, user_id, created_at, updated_at`,
      [session_id, item_id, user_id]
    );

    // Get the assignment with user name
    const assignmentWithUser = await query(
      `SELECT ia.*, u.display_name as user_name
       FROM item_assignments ia
       JOIN app_user u ON ia.user_id = u.id
       WHERE ia.id = $1`,
      [result.rows[0].id]
    );

    return assignmentWithUser.rows[0];
  },

  // Find assignment by item and user
  findByItemAndUser: async (itemId, userId) => {
    const result = await query(
      'SELECT * FROM item_assignments WHERE item_id = $1 AND user_id = $2',
      [itemId, userId]
    );
    return result.rows[0];
  },

  // Get assignments by session
  getBySession: async (sessionId) => {
    const result = await query(
      `SELECT ia.*, u.display_name as user_name
       FROM item_assignments ia
       JOIN app_user u ON ia.user_id = u.id
       WHERE ia.session_id = $1
       ORDER BY ia.created_at`,
      [sessionId]
    );
    return result.rows;
  },

  // Get assignments by item
  getByItem: async (itemId) => {
    const result = await query(
      `SELECT ia.*, u.display_name as user_name
       FROM item_assignments ia
       JOIN app_user u ON ia.user_id = u.id
       WHERE ia.item_id = $1
       ORDER BY ia.created_at`,
      [itemId]
    );
    return result.rows;
  },

  // Get split item participants (assignments with share = 'Y')
  getSplitItemParticipants: async (itemId) => {
    const result = await query(
      `SELECT ia.*, u.display_name as user_name
       FROM item_assignments ia
       JOIN app_user u ON ia.user_id = u.id
       WHERE ia.item_id = $1 AND ia.share = 'Y'
       ORDER BY ia.created_at`,
      [itemId]
    );
    return result.rows;
  },

  // Delete assignment by item and user
  deleteByItemAndUser: async (itemId, userId) => {
    await query(
      'DELETE FROM item_assignments WHERE item_id = $1 AND user_id = $2',
      [itemId, userId]
    );
  },

  // Delete split item assignment by item and user (only share = 'Y')
  deleteSplitItemAssignment: async (itemId, userId) => {
    await query(
      'DELETE FROM item_assignments WHERE item_id = $1 AND user_id = $2 AND share = \'Y\'',
      [itemId, userId]
    );
  },

  // Delete all assignments for an item
  deleteByItem: async (itemId) => {
    await query('DELETE FROM item_assignments WHERE item_id = $1', [itemId]);
  },

  // Delete all split item assignments for an item (only share = 'Y')
  deleteSplitItemAssignments: async (itemId) => {
    await query(
      'DELETE FROM item_assignments WHERE item_id = $1 AND share = \'Y\'',
      [itemId]
    );
  },

  // Get user assignments for a session
  getByUserAndSession: async (userId, sessionId) => {
    const result = await query(
      `SELECT ia.*, ri.name as item_name, ri.price, ri.quantity
       FROM item_assignments ia
       JOIN receipt_items ri ON ia.item_id = ri.id
       WHERE ia.user_id = $1 AND ia.session_id = $2
       ORDER BY ia.created_at`,
      [userId, sessionId]
    );
    return result.rows;
  }
};

// Split item operations
const splitItemQueries = {
  // Create split item
  create: async (itemData) => {
    const { session_id, name, price, description, added_by_user_id } = itemData;
    const result = await query(
      `INSERT INTO split_items (session_id, name, price, description, added_by_user_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [session_id, name, price, description, added_by_user_id]
    );
    return result.rows[0];
  },

  // Get split items by session
  getBySession: async (sessionId) => {
    const result = await query(
      `SELECT si.*, u.display_name as added_by_name
       FROM split_items si
       JOIN app_user u ON si.added_by_user_id = u.id
       WHERE si.session_id = $1
       ORDER BY si.created_at DESC`,
      [sessionId]
    );
    return result.rows;
  },

  // Find split item by ID
  findById: async (itemId) => {
    const result = await query(
      'SELECT * FROM split_items WHERE id = $1',
      [itemId]
    );
    return result.rows[0];
  },

  // Update split item
  update: async (itemId, updateData) => {
    const { name, price, description } = updateData;
    const result = await query(
      `UPDATE split_items
       SET name = $1, price = $2, description = $3, updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [name, price, description, itemId]
    );
    return result.rows[0];
  },

  // Delete split item
  delete: async (itemId) => {
    await query('DELETE FROM split_items WHERE id = $1', [itemId]);
  },

  // Add participant to split item
  addParticipant: async (itemId, userId) => {
    const result = await query(
      `UPDATE split_items SET guest_id = $1 WHERE id = $2 RETURNING *`,
      [userId, itemId]
    );
    return result.rows[0];
  },

  // Remove participant from split item
  removeParticipant: async (itemId) => {
    const result = await query(
      `UPDATE split_items SET guest_id = NULL WHERE id = $1 RETURNING *`,
      [itemId]
    );
    return result.rows[0];
  }
};

// Participant Choice Queries (for split item assignments)
const participantChoiceQueries = {
  // Create a participant choice for a split item
  create: async (choiceData) => {
    const { session_id, name, price, description, user_id, split_item } = choiceData;
    const result = await query(
      `INSERT INTO guest_choice (session_id, name, price, description, user_id, split_item, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
       RETURNING *`,
      [session_id, name, price, description, user_id, split_item]
    );
    return result.rows[0];
  },

  // Get participants for a split item
  getSplitItemParticipants: async (sessionId, splitItemName) => {
    const result = await query(
      `SELECT pc.*, u.display_name as user_name
       FROM guest_choice pc
       JOIN app_user u ON pc.user_id = u.id
       WHERE pc.session_id = $1 AND pc.name = $2 AND pc.split_item = true
       ORDER BY pc.created_at`,
      [sessionId, splitItemName]
    );
    return result.rows;
  },

  // Remove participant from split item
  removeSplitItemParticipant: async (sessionId, splitItemName, userId) => {
    await query(
      `DELETE FROM guest_choice
       WHERE session_id = $1 AND name = $2 AND user_id = $3 AND split_item = true`,
      [sessionId, splitItemName, userId]
    );
  },

  // Check if user is already assigned to split item
  findSplitItemAssignment: async (sessionId, splitItemName, userId) => {
    const result = await query(
      `SELECT * FROM guest_choice
       WHERE session_id = $1 AND name = $2 AND user_id = $3 AND split_item = true`,
      [sessionId, splitItemName, userId]
    );
    return result.rows[0];
  },

  // Delete all participant choices for a split item
  deleteBySplitItem: async (sessionId, splitItemName) => {
    await query(
      `DELETE FROM guest_choice
       WHERE session_id = $1 AND name = $2 AND split_item = true`,
      [sessionId, splitItemName]
    );
  }
};

module.exports = {
  userQueries,
  sessionQueries,
  participantQueries,
  receiptQueries,
  assignmentQueries,
  splitItemQueries,
  participantChoiceQueries
};
