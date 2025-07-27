const express = require('express');
const router = express.Router();
const { userQueries } = require('../utils/database');
const { hashPassword, verifyPassword, validatePassword } = require('../utils/password');
const { generateToken, authenticateToken } = require('../middleware/auth');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../services/emailService');
const { generateToken: generateAuthToken, getTokenExpiry } = require('../utils/tokenUtils');
const fs = require('fs');
const path = require('path');

/**
 * Authentication Routes
 * All routes use POST method and return standardized JSON responses
 */

// Helper function to render email verification HTML
const renderVerificationPage = (type, title, message) => {
  const templatePath = path.join(__dirname, '..', 'views', 'email-verification.html');
  let template = fs.readFileSync(templatePath, 'utf8');
  
  const icons = {
    success: '✓',
    error: '✗',
    already_verified: 'ℹ'
  };
  
  const content = `
    <div class="icon ${type}">
      ${icons[type] || icons.success}
    </div>
    <h1>${title}</h1>
    <p>${message}</p>
  `;
  
  return template.replace('{{CONTENT}}', content);
};

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
    const emailResult = await sendVerificationEmail(email, verificationToken);
    
    if (!emailResult.success) {
      console.error('Failed to send verification email:', emailResult.error);
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


// Verify Email (GET request from email link)
router.get('/verify-email', async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      const html = renderVerificationPage(
        'error', 
        'Verification Failed', 
        'No verification token provided. Please check your email link and try again.'
      );
      return res.status(400).send(html);
    }

    // Find user by token
    const user = await userQueries.findByAuthToken(token);
    
    if (!user) {
      const html = renderVerificationPage(
        'error', 
        'Verification Failed', 
        'This verification link is invalid or has expired. Please request a new verification email.'
      );
      return res.status(400).send(html);
    }

    // Check if token is for email verification
    if (!token.startsWith('verify_')) {
      const html = renderVerificationPage(
        'error', 
        'Verification Failed', 
        'This verification link is not valid. Please check your email and try again.'
      );
      return res.status(400).send(html);
    }

    // Check if already verified
    if (user.email_verified) {
      const html = renderVerificationPage(
        'already_verified', 
        'Already Verified', 
        'Your email address has already been verified. You can now use all features of SplitDine.'
      );
      return res.send(html);
    }

    // Mark email as verified and clear token
    await userQueries.markEmailVerified(user.id);

    const html = renderVerificationPage(
      'success', 
      'Email Verified!', 
      'Thank you! Your email address has been successfully verified. You can now access all features of SplitDine.'
    );
    res.send(html);

  } catch (error) {
    console.error('Email verification error:', error.message);
    const html = renderVerificationPage(
      'error', 
      'Verification Failed', 
      'An unexpected error occurred while verifying your email. Please try again or contact support.'
    );
    res.status(500).send(html);
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

// Verify Reset Token and Show Reset Form (GET request from email link)
router.get('/reset-password', async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      const html = renderVerificationPage(
        'error', 
        'Reset Failed', 
        'No reset token provided. Please check your email link and try again.'
      );
      return res.status(400).send(html);
    }

    // Verify token exists and is valid
    const user = await userQueries.findByAuthToken(token);
    
    if (!user || !token.startsWith('reset_')) {
      const html = renderVerificationPage(
        'error', 
        'Reset Failed', 
        'This password reset link is invalid or has expired. Please request a new password reset.'
      );
      return res.status(400).send(html);
    }

    // Token is valid - serve the reset password form
    const templatePath = path.join(__dirname, '..', 'views', 'reset-password.html');
    const html = fs.readFileSync(templatePath, 'utf8');
    res.send(html);

  } catch (error) {
    console.error('Reset token verification error:', error.message);
    const html = renderVerificationPage(
      'error', 
      'Reset Failed', 
      'An unexpected error occurred. Please try again or contact support.'
    );
    res.status(500).send(html);
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

// Admin Login
router.post('/admin-login', async (req, res) => {
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

    // Check if user is admin
    if (!user.admin) {
      return res.status(403).json({
        return_code: 'NOT_ADMIN',
        message: 'Access denied. Admin privileges required.',
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

    // Generate JWT token with admin flag
    const token = generateToken(user.id, user.email);

    // Update last active timestamp
    await userQueries.updateLastActive(user.id);

    res.json({
      return_code: 'SUCCESS',
      message: 'Admin login successful',
      user: {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        admin: user.admin
      },
      token,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Admin login error:', error.message);
    res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Login failed',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
