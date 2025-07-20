const express = require('express');
const router = express.Router();
const { userQueries } = require('../utils/database');
const { hashPassword, verifyPassword, validatePassword } = require('../utils/password');
const { generateToken, authenticateToken } = require('../middleware/auth');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../services/emailService');
const { generateToken: generateAuthToken, getTokenExpiry } = require('../utils/tokenUtils');

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

    // Generate email verification token
    const verificationToken = generateAuthToken('verify');
    const tokenExpiry = getTokenExpiry(24); // 24 hours
    
    await userQueries.setAuthToken(newUser.id, verificationToken, tokenExpiry);

    // Send verification email
    console.log('🔄 Attempting to send verification email to:', email);
    console.log('🔄 Verification token:', verificationToken.substring(0, 20) + '...');
    
    const emailResult = await sendVerificationEmail(email, verificationToken);
    
    if (emailResult.success) {
      console.log('✅ Verification email sent successfully');
      console.log('📧 Email ID:', emailResult.data?.id);
    } else {
      console.error('❌ Failed to send verification email:', emailResult.error);
      console.error('📧 Full error details:', emailResult);
    }

    // Generate JWT token
    const token = generateToken(newUser.id, newUser.email);

    res.status(201).json({
      return_code: 'SUCCESS',
      message: 'User registered successfully. Please check your email to verify your account.',
      user: {
        id: newUser.id,
        email: newUser.email,
        display_name: newUser.display_name,
        is_anonymous: newUser.is_anonymous,
        email_verified: false
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
        is_anonymous: user.is_anonymous,
        email_verified: user.email_verified || false
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

// Email Verification
router.get('/verify-email', async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Verification token is required',
        timestamp: new Date().toISOString()
      });
    }

    // Find user by token
    const user = await userQueries.findByAuthToken(token);
    
    if (!user) {
      return res.status(400).json({
        return_code: 'INVALID_TOKEN',
        message: 'Invalid or expired verification token',
        timestamp: new Date().toISOString()
      });
    }

    // Check if token is for verification
    if (!token.startsWith('verify_')) {
      return res.status(400).json({
        return_code: 'INVALID_TOKEN',
        message: 'Invalid verification token',
        timestamp: new Date().toISOString()
      });
    }

    // Mark email as verified
    await userQueries.markEmailVerified(user.id);

    // Return a nice HTML page instead of JSON
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Email Verified - SplitDine</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .container {
            background: white;
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 400px;
            width: 100%;
          }
          .icon {
            font-size: 64px;
            margin-bottom: 20px;
          }
          h1 {
            color: #2d3748;
            margin-bottom: 16px;
            font-size: 24px;
          }
          p {
            color: #718096;
            margin-bottom: 30px;
            line-height: 1.6;
          }
          .button {
            background: #3182ce;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            display: inline-block;
            font-weight: 500;
            transition: background 0.2s;
          }
          .button:hover {
            background: #2c5aa0;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="icon">✅</div>
          <h1>Email Verified!</h1>
          <p>Your email address has been successfully verified. You can now enjoy all features of SplitDine.</p>
          <a href="https://splitdine.noodev8.com" class="button">Open SplitDine App</a>
        </div>
      </body>
      </html>
    `);

  } catch (error) {
    console.error('Email verification error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Email verification failed',
      timestamp: new Date().toISOString()
    });
  }
});

// Resend Verification Email
router.post('/resend-verification', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Email is required',
        timestamp: new Date().toISOString()
      });
    }

    // Find user by email
    const user = await userQueries.findByEmail(email);
    
    // Always return success to prevent email enumeration
    if (!user) {
      return res.json({
        return_code: 'SUCCESS',
        message: 'If the email exists in our system, a verification email has been sent',
        timestamp: new Date().toISOString()
      });
    }

    // Check if already verified
    if (user.email_verified) {
      return res.json({
        return_code: 'SUCCESS',
        message: 'Email is already verified',
        timestamp: new Date().toISOString()
      });
    }

    // Generate new verification token
    const verificationToken = generateAuthToken('verify');
    const tokenExpiry = getTokenExpiry(24); // 24 hours
    
    await userQueries.setAuthToken(user.id, verificationToken, tokenExpiry);

    // Send verification email
    const emailResult = await sendVerificationEmail(email, verificationToken);
    
    if (!emailResult.success) {
      console.error('Failed to resend verification email:', emailResult.error);
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'If the email exists in our system, a verification email has been sent',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Resend verification error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to resend verification email',
      timestamp: new Date().toISOString()
    });
  }
});

// Forgot Password
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Email is required',
        timestamp: new Date().toISOString()
      });
    }

    // Find user by email
    const user = await userQueries.findByEmail(email);
    
    // Always return success to prevent email enumeration
    if (!user || user.is_anonymous) {
      return res.json({
        return_code: 'SUCCESS',
        message: 'If the email exists in our system, a password reset email has been sent',
        timestamp: new Date().toISOString()
      });
    }

    // Generate password reset token
    const resetToken = generateAuthToken('reset');
    const tokenExpiry = getTokenExpiry(1); // 1 hour
    
    await userQueries.setAuthToken(user.id, resetToken, tokenExpiry);

    // Send password reset email
    const emailResult = await sendPasswordResetEmail(email, resetToken);
    
    if (!emailResult.success) {
      console.error('Failed to send password reset email:', emailResult.error);
    }

    res.json({
      return_code: 'SUCCESS',
      message: 'If the email exists in our system, a password reset email has been sent',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Forgot password error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Failed to process password reset request',
      timestamp: new Date().toISOString()
    });
  }
});

// Reset Password
router.post('/reset-password', async (req, res) => {
  try {
    const { token, new_password } = req.body;

    if (!token || !new_password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Token and new password are required',
        timestamp: new Date().toISOString()
      });
    }

    // Validate password strength
    const passwordValidation = validatePassword(new_password);
    if (!passwordValidation.isValid) {
      return res.status(400).json({
        return_code: 'WEAK_PASSWORD',
        message: 'Password does not meet requirements',
        errors: passwordValidation.errors,
        timestamp: new Date().toISOString()
      });
    }

    // Find user by token
    const user = await userQueries.findByAuthToken(token);
    
    if (!user) {
      return res.status(400).json({
        return_code: 'INVALID_TOKEN',
        message: 'Invalid or expired reset token',
        timestamp: new Date().toISOString()
      });
    }

    // Check if token is for password reset
    if (!token.startsWith('reset_')) {
      return res.status(400).json({
        return_code: 'INVALID_TOKEN',
        message: 'Invalid reset token',
        timestamp: new Date().toISOString()
      });
    }

    // Hash new password
    const password_hash = await hashPassword(new_password);

    // Update password and clear token
    await userQueries.updatePassword(user.id, password_hash);

    res.json({
      return_code: 'SUCCESS',
      message: 'Password reset successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Reset password error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Password reset failed',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
