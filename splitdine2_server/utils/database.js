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
    // Delete guest choices (items)
    await query('DELETE FROM guest_choice WHERE user_id = $1', [userId]);

    // Delete session participants
    await query('DELETE FROM session_guest WHERE user_id = $1', [userId]);

    // Delete final splits
    await query('DELETE FROM final_splits WHERE user_id = $1', [userId]);

    // Delete sessions organized by this user (and their related data)
    const userSessions = await query('SELECT id FROM session WHERE organizer_id = $1', [userId]);
    for (const session of userSessions.rows) {
      // Delete session-related data
      await query('DELETE FROM guest_choice WHERE session_id = $1', [session.id]);
      await query('DELETE FROM split_items WHERE session_id = $1', [session.id]);
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

// Receipt item operations (now using guest_choice table)
const receiptQueries = {
  // Create receipt item
  create: async (itemData) => {
    const { session_id, item_name, price, added_by_user_id, share } = itemData;

    // Create a single item (no quantity - multiple items are separate rows)
    const result = await query(
      `INSERT INTO guest_choice (session_id, name, price, description, user_id, split_item)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [session_id, item_name, price, share, added_by_user_id, false]
    );

    const newItem = result.rows[0];

    // Get the user name for the response
    const userResult = await query('SELECT display_name FROM app_user WHERE id = $1', [added_by_user_id]);
    const addedByName = userResult.rows[0]?.display_name || 'Unknown User';

    // Return the item with correct field names for Flutter
    return {
      id: newItem.id,
      session_id: newItem.session_id,
      item_name: newItem.name,
      price: newItem.price,
      added_by_user_id: newItem.user_id,
      added_by_name: addedByName,
      share: newItem.description,
      created_at: newItem.created_at,
      updated_at: newItem.updated_at
    };
  },

  // Get items by session
  getBySession: async (sessionId) => {
    const result = await query(
      `SELECT gc.id, gc.session_id, gc.name as item_name, gc.price, gc.description as share,
              gc.user_id as added_by_user_id, u.display_name as added_by_name,
              gc.created_at, gc.updated_at
       FROM guest_choice gc
       JOIN app_user u ON gc.user_id = u.id
       WHERE gc.session_id = $1 AND (gc.split_item = false OR gc.split_item IS NULL)
       ORDER BY gc.created_at DESC`,
      [sessionId]
    );

    // Group items by name and user to calculate quantities
    const itemGroups = {};
    result.rows.forEach(item => {
      const key = `${item.item_name}_${item.added_by_user_id}_${item.price}`;
      if (!itemGroups[key]) {
        itemGroups[key] = {
          ...item,
          quantity: 0
        };
      }
      itemGroups[key].quantity += 1;
    });

    return Object.values(itemGroups);
  },

  // Find receipt item by ID
  findById: async (itemId) => {
    const result = await query(
      'SELECT * FROM guest_choice WHERE id = $1 AND (split_item = false OR split_item IS NULL)',
      [itemId]
    );
    return result.rows[0];
  },

  // Update receipt item
  update: async (itemId, updateData) => {
    const { item_name, price, quantity, share } = updateData;
    const result = await query(
      `UPDATE guest_choice
       SET name = $1, price = $2, description = $3, updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [item_name, price, share, itemId]
    );

    // Get the user name for the response
    const item = result.rows[0];
    const userResult = await query('SELECT display_name FROM app_user WHERE id = $1', [item.user_id]);
    const addedByName = userResult.rows[0]?.display_name || 'Unknown User';

    // Return with correct field names for Flutter
    return {
      id: item.id,
      session_id: item.session_id,
      item_name: item.name,
      price: item.price,
      quantity: 1, // Always 1 in new structure
      added_by_user_id: item.user_id,
      added_by_name: addedByName,
      share: item.description,
      created_at: item.created_at,
      updated_at: item.updated_at
    };
  },

  // Delete receipt item
  delete: async (itemId) => {
    await query('DELETE FROM guest_choice WHERE id = $1', [itemId]);
  }
};

// Assignment queries - now simplified since items are stored directly in guest_choice
const assignmentQueries = {
  // Get user items for a session (from guest_choice)
  getByUserAndSession: async (userId, sessionId) => {
    const result = await query(
      `SELECT gc.*, gc.name as item_name, 1 as quantity
       FROM guest_choice gc
       WHERE gc.user_id = $1 AND gc.session_id = $2 AND (gc.split_item = false OR gc.split_item IS NULL)
       ORDER BY gc.created_at`,
      [userId, sessionId]
    );
    return result.rows;
  },

  // Get all assignments for a session (compatibility function)
  getBySession: async (sessionId) => {
    const result = await query(
      `SELECT gc.id, gc.session_id, gc.id as item_id, gc.user_id, u.display_name as user_name, gc.created_at
       FROM guest_choice gc
       JOIN app_user u ON gc.user_id = u.id
       WHERE gc.session_id = $1 AND (gc.split_item = false OR gc.split_item IS NULL)
       ORDER BY gc.created_at`,
      [sessionId]
    );
    return result.rows;
  },

  // Find assignment by item and user (compatibility function)
  findByItemAndUser: async (itemId, userId) => {
    const result = await query(
      'SELECT * FROM guest_choice WHERE id = $1 AND user_id = $2 AND (split_item = false OR split_item IS NULL)',
      [itemId, userId]
    );
    return result.rows[0];
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
