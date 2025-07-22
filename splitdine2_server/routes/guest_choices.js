const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { authenticateToken, requireSessionParticipant } = require('../middleware/auth');

/**
 * Guest Choice Management Routes
 * All routes use POST method and return standardized JSON responses
 */

// Assign item to user (add guest choice)
router.post('/assign', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { item_id, user_id, split_item } = req.body;

    // Validate required fields
    if (!item_id || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID and user_id are required',
        timestamp: new Date().toISOString()
      });
    }

    // Verify the item exists in session_receipt
    const itemCheck = await query(
      'SELECT id, item_name, price FROM session_receipt WHERE id = $1 AND session_id = $2',
      [item_id, req.sessionId]
    );

    if (itemCheck.rows.length === 0) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Receipt item not found',
        timestamp: new Date().toISOString()
      });
    }

    const receiptItem = itemCheck.rows[0];

    // Check if assignment already exists
    const existingChoice = await query(
      'SELECT id FROM guest_choice WHERE session_id = $1 AND item_id = $2 AND user_id = $3',
      [req.sessionId, item_id, user_id]
    );

    if (existingChoice.rows.length > 0) {
      return res.status(400).json({
        return_code: 'ALREADY_ASSIGNED',
        message: 'Item is already assigned to this user',
        timestamp: new Date().toISOString()
      });
    }

    // Create assignment record in guest_choice (without name and price)
    const result = await query(
      `INSERT INTO guest_choice (session_id, item_id, user_id, split_item, created_at, updated_at)
       VALUES ($1, $2, $3, $4, NOW(), NOW())
       RETURNING *`,
      [req.sessionId, item_id, user_id, split_item || false]
    );

    const choice = result.rows[0];

    // Calculate the effective price for this assignment
    let effectivePrice = receiptItem.price;
    if (split_item) {
      // For shared items, calculate split price based on total assignments
      const countResult = await query(
        'SELECT COUNT(*) as assignment_count FROM guest_choice WHERE session_id = $1 AND item_id = $2',
        [req.sessionId, item_id]
      );
      const totalAssignments = parseInt(countResult.rows[0].assignment_count);
      effectivePrice = receiptItem.price / totalAssignments;
    }

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Item assigned successfully',
      choice: {
        id: choice.id,
        session_id: choice.session_id,
        item_id: choice.item_id,
        name: receiptItem.item_name,  // From session_receipt
        price: effectivePrice,         // Calculated price
        user_id: choice.user_id,
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
    const { item_id, user_id } = req.body;

    // Validate required fields
    if (!item_id || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID and user_id are required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if this is a shared item before deletion
    const assignmentCheck = await query(
      'SELECT split_item FROM guest_choice WHERE session_id = $1 AND item_id = $2 AND user_id = $3',
      [req.sessionId, item_id, user_id]
    );

    if (assignmentCheck.rows.length === 0) {
      return res.status(404).json({
        return_code: 'NOT_FOUND',
        message: 'Assignment not found',
        timestamp: new Date().toISOString()
      });
    }

    const isSharedItem = assignmentCheck.rows[0].split_item;

    // Delete assignment record from guest_choice
    const result = await query(
      'DELETE FROM guest_choice WHERE session_id = $1 AND item_id = $2 AND user_id = $3 RETURNING *',
      [req.sessionId, item_id, user_id]
    );

    // If it was a shared item, recalculate prices for remaining assignments
    if (isSharedItem) {
      // Get the original item price
      const itemResult = await query(
        'SELECT price FROM session_receipt WHERE id = $1 AND session_id = $2',
        [item_id, req.sessionId]
      );

      if (itemResult.rows.length > 0) {
        const originalPrice = itemResult.rows[0].price;

        // Get remaining assignment count
        const countResult = await query(
          'SELECT COUNT(*) as assignment_count FROM guest_choice WHERE session_id = $1 AND item_id = $2',
          [req.sessionId, item_id]
        );

        const remainingAssignments = parseInt(countResult.rows[0].assignment_count);

        if (remainingAssignments > 0) {
          const newSplitPrice = originalPrice / remainingAssignments;

          // Update remaining assignments with new split price
          await query(
            'UPDATE guest_choice SET price = $1, updated_at = NOW() WHERE session_id = $2 AND item_id = $3',
            [newSplitPrice, req.sessionId, item_id]
          );
        }
      }
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
    const { item_id } = req.body;

    // Validate required fields
    if (!item_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID is required',
        timestamp: new Date().toISOString()
      });
    }

    // Get all assignments for the item using item_id
    const result = await query(
      `SELECT gc.*, u.display_name as user_name
       FROM guest_choice gc
       JOIN app_user u ON gc.user_id = u.id
       WHERE gc.session_id = $1 AND gc.item_id = $2
       ORDER BY gc.created_at`,
      [req.sessionId, item_id]
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
      item_id: row.item_id,
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

// Update prices for all assignments of an item
router.post('/update_item_prices', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { item_id, new_price, is_shared } = req.body;

    // Validate required fields
    if (!item_id || new_price === undefined || is_shared === undefined) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID, new price, and shared status are required',
        timestamp: new Date().toISOString()
      });
    }

    // Get count of assignments for this item to calculate split price
    const countResult = await query(
      'SELECT COUNT(*) as assignment_count FROM guest_choice WHERE session_id = $1 AND item_id = $2',
      [req.sessionId, item_id]
    );

    const assignmentCount = parseInt(countResult.rows[0].assignment_count);

    if (assignmentCount === 0) {
      return res.json({
        return_code: 'SUCCESS',
        message: 'No assignments to update',
        timestamp: new Date().toISOString()
      });
    }

    // Calculate the price per assignment
    const pricePerAssignment = is_shared && assignmentCount > 0
      ? parseFloat(new_price) / assignmentCount
      : parseFloat(new_price);

    // Update only the split_item flag (price is now stored in session_receipt)
    const result = await query(
      'UPDATE guest_choice SET split_item = $1, updated_at = NOW() WHERE session_id = $2 AND item_id = $3',
      [is_shared, req.sessionId, item_id]
    );

    res.json({
      return_code: 'SUCCESS',
      message: `Updated ${result.rowCount} assignment prices`,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error updating item prices:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update item prices',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete all assignments for an item
router.post('/delete_item_assignments', authenticateToken, requireSessionParticipant, async (req, res) => {
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

    // Delete all assignments for this item
    const result = await query(
      'DELETE FROM guest_choice WHERE session_id = $1 AND item_id = $2',
      [req.sessionId, item_id]
    );

    res.json({
      return_code: 'SUCCESS',
      message: `Deleted ${result.rowCount} assignments`,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error deleting item assignments:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete item assignments',
      timestamp: new Date().toISOString()
    });
  }
});

// Update shared status for all assignments of an item
router.post('/update_shared_status', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    const { item_id, is_shared, item_price } = req.body;

    // Validate required fields
    if (!item_id || is_shared === undefined || item_price === undefined) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item ID, shared status, and item price are required',
        timestamp: new Date().toISOString()
      });
    }

    // Get count of assignments for this item
    const countResult = await query(
      'SELECT COUNT(*) as assignment_count FROM guest_choice WHERE session_id = $1 AND item_id = $2',
      [req.sessionId, item_id]
    );

    const assignmentCount = parseInt(countResult.rows[0].assignment_count);

    if (assignmentCount === 0) {
      return res.json({
        return_code: 'SUCCESS',
        message: 'No assignments to update',
        timestamp: new Date().toISOString()
      });
    }

    // Calculate the price per assignment
    const pricePerAssignment = is_shared && assignmentCount > 0
      ? parseFloat(item_price) / assignmentCount
      : parseFloat(item_price);

    // Update only the split_item flag (price is now stored in session_receipt)
    const result = await query(
      'UPDATE guest_choice SET split_item = $1, updated_at = NOW() WHERE session_id = $2 AND item_id = $3',
      [is_shared, req.sessionId, item_id]
    );

    res.json({
      return_code: 'SUCCESS',
      message: `Updated ${result.rowCount} assignments`,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error updating shared status:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update shared status',
      timestamp: new Date().toISOString()
    });
  }
});

// Get payment summary for session
router.post('/get_payment_summary', authenticateToken, requireSessionParticipant, async (req, res) => {
  try {
    // Get bill total from session_receipt
    const billTotalResult = await query(
      'SELECT COALESCE(SUM(price), 0) as bill_total FROM session_receipt WHERE session_id = $1',
      [req.sessionId]
    );
    
    const billTotal = parseFloat(billTotalResult.rows[0].bill_total);

    // Get allocated total and participant totals by joining guest_choice with session_receipt
    const participantTotalsResult = await query(
      `SELECT sg.user_id, u.display_name as user_name, u.email,
              COALESCE(SUM(
                CASE 
                  WHEN gc.split_item = true THEN sr.price / item_counts.assignment_count
                  ELSE sr.price
                END
              ), 0) as total_amount
       FROM session_guest sg
       JOIN app_user u ON sg.user_id = u.id
       LEFT JOIN guest_choice gc ON sg.user_id = gc.user_id AND gc.session_id = sg.session_id
       LEFT JOIN session_receipt sr ON gc.item_id = sr.id AND gc.session_id = sr.session_id
       LEFT JOIN (
         SELECT session_id, item_id, COUNT(*) as assignment_count
         FROM guest_choice
         WHERE split_item = true
         GROUP BY session_id, item_id
       ) item_counts ON gc.session_id = item_counts.session_id AND gc.item_id = item_counts.item_id AND gc.split_item = true
       WHERE sg.session_id = $1 AND sg.left_at IS NULL
       GROUP BY sg.user_id, u.display_name, u.email
       ORDER BY u.display_name`,
      [req.sessionId]
    );

    // Calculate allocated total from participant totals
    const allocatedTotal = participantTotalsResult.rows.reduce((sum, row) => sum + parseFloat(row.total_amount), 0);
    const remainingTotal = billTotal - allocatedTotal;

    const participantTotals = participantTotalsResult.rows.map(row => ({
      user_id: row.user_id,
      user_name: row.user_name,
      email: row.email,
      total_amount: parseFloat(row.total_amount)
    }));

    res.json({
      return_code: 'SUCCESS',
      bill_total: billTotal,
      allocated_total: allocatedTotal,
      remaining_total: remainingTotal,
      participant_totals: participantTotals,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error getting payment summary:', error);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to get payment summary',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
