const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route GET /api/menu/search
 * @description Search for menu items based on user input (3+ characters)
 * @body {
 *   query: String (required, min 3 characters)
 * }
 * @returns {
 *   return_code: 0/1,
 *   message: String,
 *   suggestions: Array of {id: Number, name: String}
 * }
 */
router.get('/search', authenticateToken, async (req, res) => {
  try {
    const { query } = req.query;

    // Validate query
    if (!query || query.trim().length < 3) {
      return res.json({
        return_code: 1,
        message: 'Query must be at least 3 characters',
        suggestions: []
      });
    }

    const searchTerm = query.trim().toUpperCase();
    
    console.log('=== MENU SEARCH DEBUG ===');
    console.log('Original query:', query);
    console.log('Search term (uppercase):', searchTerm);

    // Use the SQL from Item_Search_SQL.txt
    const searchQuery = `
      SELECT DISTINCT ON (mi.id) mi.id, mi.name
      FROM menu_synonym ms
      JOIN menu_item mi ON mi.id = ms.menu_item_id
      WHERE
        ms.synonym LIKE $1 || '%'           -- fast prefix match
        OR ms.synonym LIKE '%' || $1 || '%' -- substring match
        OR (ms.synonym % $1)                -- fuzzy match
      ORDER BY mi.id, similarity(ms.synonym, $1) DESC
      LIMIT 3
    `;

    console.log('SQL Query:', searchQuery);
    console.log('Query parameters:', [searchTerm]);

    const result = await pool.query(searchQuery, [searchTerm]);
    
    console.log('Database result rows:', result.rows.length);
    console.log('Database result:', JSON.stringify(result.rows, null, 2));

    const response = {
      return_code: 0,
      message: 'Search completed',
      suggestions: result.rows.map(row => ({
        id: row.id,
        name: row.name
      }))
    };
    
    console.log('API Response:', JSON.stringify(response, null, 2));
    console.log('=== END DEBUG ===\n');

    res.json(response);

  } catch (error) {
    console.error('Menu search error:', error);
    res.status(500).json({
      return_code: 1,
      message: 'Error searching menu items',
      suggestions: []
    });
  }
});

/**
 * @route POST /api/menu/log-search
 * @description Log a completed search to menu_search_log
 * @body {
 *   user_input: String (required),
 *   matched_menu_item_id: Number (optional),
 *   guest_id: Number (required)
 * }
 * @returns {
 *   return_code: 0/1,
 *   message: String
 * }
 */
router.post('/log-search', authenticateToken, async (req, res) => {
  try {
    const { user_input, matched_menu_item_id, guest_id } = req.body;

    if (!user_input || !guest_id) {
      return res.status(400).json({
        return_code: 1,
        message: 'user_input and guest_id are required'
      });
    }

    // Insert into menu_search_log
    const insertQuery = `
      INSERT INTO menu_search_log (
        user_input, 
        matched_menu_item_id, 
        guest_id, 
        matched
      ) VALUES ($1, $2, $3, $4)
    `;

    await pool.query(insertQuery, [
      user_input,
      matched_menu_item_id || null,
      guest_id,
      !!matched_menu_item_id
    ]);

    res.json({
      return_code: 0,
      message: 'Search logged successfully'
    });

  } catch (error) {
    console.error('Log search error:', error);
    res.status(500).json({
      return_code: 1,
      message: 'Error logging search'
    });
  }
});

module.exports = router;