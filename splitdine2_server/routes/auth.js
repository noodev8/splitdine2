const express = require('express');
const router = express.Router();
const { userQueries } = require('../utils/database');
const { hashPassword, verifyPassword, validatePassword } = require('../utils/password');
const { generateToken, authenticateToken } = require('../middleware/auth');

/**
 * Authentication Routes
 * All routes use POST method and return standardized JSON responses
 */

// User Registration
router.post('/register', async (req, res) => {
  try {
    const { email, phone, display_name, password } = req.body;

    // Validate required fields
    if (!email || !display_name || !password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Email, display name, and password are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        return_code: 'INVALID_EMAIL',
        message: 'Please provide a valid email address',
        timestamp: new Date().toISOString()
      });
    }

    // Validate password strength
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      return res.status(400).json({
        return_code: 'WEAK_PASSWORD',
        message: 'Password does not meet requirements',
        errors: passwordValidation.errors,
        timestamp: new Date().toISOString()
      });
    }

    // Check if user already exists
    const existingUser = await userQueries.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({
        return_code: 'USER_EXISTS',
        message: 'User with this email already exists',
        timestamp: new Date().toISOString()
      });
    }

    // Hash password
    const password_hash = await hashPassword(password);

    // Create user
    const newUser = await userQueries.create({
      email,
      phone,
      display_name,
      password_hash,
      is_anonymous: false
    });

    // Generate JWT token
    const token = generateToken(newUser.id, newUser.email);

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'User registered successfully',
      user: {
        id: newUser.id,
        email: newUser.email,
        display_name: newUser.display_name,
        is_anonymous: newUser.is_anonymous
      },
      token,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Registration failed',
      timestamp: new Date().toISOString()
    });
  }
});

// User Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Email and password are required',
        timestamp: new Date().toISOString()
      });
    }

    // Find user by email
    const user = await userQueries.findByEmail(email);
    if (!user) {
      return res.status(401).json({
        return_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
        timestamp: new Date().toISOString()
      });
    }

    // Verify password
    const isValidPassword = await verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        return_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
        timestamp: new Date().toISOString()
      });
    }

    // Generate JWT token
    const token = generateToken(user.id, user.email);

    // Update last active timestamp
    await userQueries.updateLastActive(user.id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        is_anonymous: user.is_anonymous
      },
      token,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Login failed',
      timestamp: new Date().toISOString()
    });
  }
});

// Anonymous User Creation
router.post('/anonymous', async (req, res) => {
  try {
    const { display_name } = req.body;

    // Validate required fields
    if (!display_name) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Display name is required',
        timestamp: new Date().toISOString()
      });
    }

    // Create anonymous user
    const newUser = await userQueries.create({
      email: null,
      phone: null,
      display_name,
      password_hash: null,
      is_anonymous: true
    });

    // Generate JWT token
    const token = generateToken(newUser.id, null);

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Anonymous user created successfully',
      user: {
        id: newUser.id,
        display_name: newUser.display_name,
        is_anonymous: newUser.is_anonymous
      },
      token,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to create anonymous user',
      timestamp: new Date().toISOString()
    });
  }
});

// Token Validation
router.post('/validate', async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Token is required',
        timestamp: new Date().toISOString()
      });
    }

    const { verifyToken } = require('../middleware/auth');
    const decoded = verifyToken(token);
    
    // Get user from database
    const user = await userQueries.findById(decoded.userId);
    
    if (!user) {
      return res.status(401).json({
        return_code: 'INVALID_TOKEN',
        message: 'User not found',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Token is valid',
      user: {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        is_anonymous: user.is_anonymous
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    res.status(401).json({
      return_code: 'INVALID_TOKEN',
      message: 'Invalid or expired token',
      timestamp: new Date().toISOString()
    });
  }
});

// Update Profile
router.post('/update-profile', authenticateToken, async (req, res) => {
  try {
    const { display_name } = req.body;

    // Validate required fields
    if (!display_name || display_name.trim().length === 0) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Display name is required',
        timestamp: new Date().toISOString()
      });
    }

    // Update user display name
    const updatedUser = await userQueries.updateDisplayName(req.user.id, display_name.trim());

    if (!updatedUser) {
      return res.status(404).json({
        return_code: 'USER_NOT_FOUND',
        message: 'User not found',
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'Profile updated successfully',
      user: updatedUser,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update profile error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to update profile',
      timestamp: new Date().toISOString()
    });
  }
});

// Delete Account
router.post('/delete-account', authenticateToken, async (req, res) => {
  try {
    // Only allow registered users to delete their account
    if (req.user.is_anonymous) {
      return res.status(400).json({
        return_code: 'INVALID_REQUEST',
        message: 'Guest users cannot delete their account',
        timestamp: new Date().toISOString()
      });
    }

    // Delete user and all related data
    await userQueries.deleteUser(req.user.id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Account deleted successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete account error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to delete account',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
