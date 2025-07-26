const express = require('express');
const router = express.Router();
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const { pool } = require('../config/database');

/**
 * Menu Management Routes
 * All routes require admin authentication
 */

// Get all menu items
router.get('/items', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, created_at FROM menu_item ORDER BY name ASC'
    );

    res.json({
      return_code: 'SUCCESS',
      message: 'Menu items retrieved successfully',
      data: {
        items: result.rows
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get menu items error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to retrieve menu items',
      timestamp: new Date().toISOString()
    });
  }
});

// Create menu item
router.post('/items', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { name } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item name is required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if item already exists
    const existing = await pool.query(
      'SELECT id FROM menu_item WHERE LOWER(name) = LOWER($1)',
      [name.trim()]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        return_code: 'ITEM_EXISTS',
        message: 'Menu item already exists',
        timestamp: new Date().toISOString()
      });
    }

    // Create new item
    const result = await pool.query(
      'INSERT INTO menu_item (name) VALUES ($1) RETURNING id, name, created_at',
      [name.trim()]
    );

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Menu item created successfully',
      data: {
        item: result.rows[0]
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Create menu item error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to create menu item',
      timestamp: new Date().toISOString()
    });
  }
});

// Update menu item
router.put('/items/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Item name is required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if new name conflicts with existing item
    const existing = await pool.query(
      'SELECT id FROM menu_item WHERE LOWER(name) = LOWER($1) AND id != $2',
      [name.trim(), id]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        return_code: 'ITEM_EXISTS',
        message: 'Menu item with this name already exists',
        timestamp: new Date().toISOString()
      });
    }

    // Update item
    const result = await pool.query(
      'UPDATE menu_item SET name = $1 WHERE id = $2 RETURNING id, name, created_at',
      [name.trim(), id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Menu item not found',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Menu item updated successfully',
      data: {
        item: result.rows[0]
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Update menu item error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update menu item',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete menu item
router.delete('/items/:id', authenticateToken, requireAdmin, async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { id } = req.params;

    await client.query('BEGIN');

    // Delete all synonyms first
    await client.query('DELETE FROM menu_synonym WHERE menu_item_id = $1', [id]);

    // Delete the menu item
    const result = await client.query(
      'DELETE FROM menu_item WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Menu item not found',
        timestamp: new Date().toISOString()
      });
    }

    await client.query('COMMIT');

    res.json({
      return_code: 'SUCCESS',
      message: 'Menu item deleted successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Delete menu item error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete menu item',
      timestamp: new Date().toISOString()
    });
  } finally {
    client.release();
  }
});

// Get synonyms for a menu item
router.get('/items/:id/synonyms', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Check if menu item exists
    const menuItem = await pool.query(
      'SELECT id, name FROM menu_item WHERE id = $1',
      [id]
    );

    if (menuItem.rows.length === 0) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Menu item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Get synonyms
    const result = await pool.query(
      'SELECT id, synonym, created_at FROM menu_synonym WHERE menu_item_id = $1 ORDER BY synonym ASC',
      [id]
    );

    res.json({
      return_code: 'SUCCESS',
      message: 'Synonyms retrieved successfully',
      data: {
        menu_item: menuItem.rows[0],
        synonyms: result.rows
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get synonyms error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to retrieve synonyms',
      timestamp: new Date().toISOString()
    });
  }
});

// Create synonym
router.post('/items/:id/synonyms', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { synonym } = req.body;

    if (!synonym || synonym.trim().length === 0) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Synonym is required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate: only full words allowed (no spaces or phrases)
    if (synonym.trim().includes(' ')) {
      return res.status(400).json({
        return_code: 'INVALID_FORMAT',
        message: 'Only full words are allowed. No spaces or phrases.',
        timestamp: new Date().toISOString()
      });
    }

    // Check if menu item exists
    const menuItem = await pool.query(
      'SELECT id FROM menu_item WHERE id = $1',
      [id]
    );

    if (menuItem.rows.length === 0) {
      return res.status(404).json({
        return_code: 'ITEM_NOT_FOUND',
        message: 'Menu item not found',
        timestamp: new Date().toISOString()
      });
    }

    // Check if synonym already exists for this menu item
    const existing = await pool.query(
      'SELECT id FROM menu_synonym WHERE menu_item_id = $1 AND LOWER(synonym) = LOWER($2)',
      [id, synonym.trim()]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        return_code: 'SYNONYM_EXISTS',
        message: 'Synonym already exists for this menu item',
        timestamp: new Date().toISOString()
      });
    }

    // Create synonym
    const result = await pool.query(
      'INSERT INTO menu_synonym (menu_item_id, synonym) VALUES ($1, $2) RETURNING id, synonym, created_at',
      [id, synonym.trim()]
    );

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Synonym created successfully',
      data: {
        synonym: result.rows[0]
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Create synonym error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to create synonym',
      timestamp: new Date().toISOString()
    });
  }
});

// Update synonym
router.put('/items/:itemId/synonyms/:synonymId', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { itemId, synonymId } = req.params;
    const { synonym } = req.body;

    if (!synonym || synonym.trim().length === 0) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Synonym is required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate: only full words allowed (no spaces or phrases)
    if (synonym.trim().includes(' ')) {
      return res.status(400).json({
        return_code: 'INVALID_FORMAT',
        message: 'Only full words are allowed. No spaces or phrases.',
        timestamp: new Date().toISOString()
      });
    }

    // Check if synonym conflicts with existing
    const existing = await pool.query(
      'SELECT id FROM menu_synonym WHERE menu_item_id = $1 AND LOWER(synonym) = LOWER($2) AND id != $3',
      [itemId, synonym.trim(), synonymId]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        return_code: 'SYNONYM_EXISTS',
        message: 'Synonym already exists for this menu item',
        timestamp: new Date().toISOString()
      });
    }

    // Update synonym
    const result = await pool.query(
      'UPDATE menu_synonym SET synonym = $1 WHERE id = $2 AND menu_item_id = $3 RETURNING id, synonym, created_at',
      [synonym.trim(), synonymId, itemId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        return_code: 'SYNONYM_NOT_FOUND',
        message: 'Synonym not found',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Synonym updated successfully',
      data: {
        synonym: result.rows[0]
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Update synonym error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update synonym',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete synonym
router.delete('/items/:itemId/synonyms/:synonymId', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { itemId, synonymId } = req.params;

    const result = await pool.query(
      'DELETE FROM menu_synonym WHERE id = $1 AND menu_item_id = $2 RETURNING id',
      [synonymId, itemId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        return_code: 'SYNONYM_NOT_FOUND',
        message: 'Synonym not found',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Synonym deleted successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Delete synonym error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete synonym',
      timestamp: new Date().toISOString()
    });
  }
});

// Search for existing synonym mapping
router.get('/search-synonym', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { query } = req.query;

    if (!query || query.trim().length === 0) {
      return res.json({
        return_code: 'SUCCESS',
        message: 'No query provided',
        data: { mapping: null },
        timestamp: new Date().toISOString()
      });
    }

    // Search for exact synonym match
    const result = await pool.query(
      `SELECT ms.id as synonym_id, ms.synonym, mi.id as menu_item_id, mi.name as menu_item_name
       FROM menu_synonym ms
       JOIN menu_item mi ON mi.id = ms.menu_item_id
       WHERE LOWER(ms.synonym) = LOWER($1)`,
      [query.trim()]
    );

    res.json({
      return_code: 'SUCCESS',
      message: 'Search completed',
      data: {
        mapping: result.rows.length > 0 ? result.rows[0] : null
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Search synonym error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to search synonym',
      timestamp: new Date().toISOString()
    });
  }
});

// Map synonym to menu item (create or update mapping)
router.post('/map-synonym', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { synonym, menu_item_id, create_new_item, new_item_name } = req.body;

    if (!synonym || synonym.trim().length === 0) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Synonym is required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate: only full words allowed (no spaces or phrases)
    if (synonym.trim().includes(' ')) {
      return res.status(400).json({
        return_code: 'INVALID_FORMAT',
        message: 'Only full words are allowed. No spaces or phrases.',
        timestamp: new Date().toISOString()
      });
    }

    let targetMenuItemId = menu_item_id;

    // If creating new menu item
    if (create_new_item && new_item_name?.trim()) {
      // First check if menu item already exists
      const existingItemResult = await pool.query(
        'SELECT id FROM menu_item WHERE LOWER(name) = LOWER($1)',
        [new_item_name.trim()]
      );
      
      if (existingItemResult.rows.length > 0) {
        // Use existing menu item
        targetMenuItemId = existingItemResult.rows[0].id;
      } else {
        // Create new menu item (uppercase)
        const newItemResult = await pool.query(
          'INSERT INTO menu_item (name) VALUES ($1) RETURNING id, name',
          [new_item_name.trim().toUpperCase()]
        );
        targetMenuItemId = newItemResult.rows[0].id;
      }
    }

    if (!targetMenuItemId) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Menu item ID is required',
        timestamp: new Date().toISOString()
      });
    }

    // Check if synonym already exists
    const existingResult = await pool.query(
      'SELECT id, menu_item_id FROM menu_synonym WHERE UPPER(synonym) = UPPER($1)',
      [synonym.trim()]
    );

    if (existingResult.rows.length > 0) {
      // Check if it's already mapped to the same menu item
      if (existingResult.rows[0].menu_item_id === targetMenuItemId) {
        res.json({
          return_code: 'SUCCESS',
          message: 'Synonym already exists for this menu item',
          data: {
            synonym: { id: existingResult.rows[0].id, synonym: synonym.trim().toUpperCase() },
            action: 'already_exists'
          },
          timestamp: new Date().toISOString()
        });
        return;
      }

      // Update existing mapping to point to new menu item
      const updateResult = await pool.query(
        'UPDATE menu_synonym SET menu_item_id = $1 WHERE UPPER(synonym) = UPPER($2) RETURNING id, synonym',
        [targetMenuItemId, synonym.trim()]
      );

      res.json({
        return_code: 'SUCCESS',
        message: 'Synonym mapping updated successfully',
        data: {
          synonym: updateResult.rows[0],
          action: 'updated'
        },
        timestamp: new Date().toISOString()
      });
    } else {
      // Create new mapping (uppercase)
      const createResult = await pool.query(
        'INSERT INTO menu_synonym (menu_item_id, synonym) VALUES ($1, $2) RETURNING id, synonym',
        [targetMenuItemId, synonym.trim().toUpperCase()]
      );

      res.json({
        return_code: 'SUCCESS',
        message: 'Synonym mapping created successfully',
        data: {
          synonym: createResult.rows[0],
          action: 'created'
        },
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('Map synonym error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to map synonym',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;