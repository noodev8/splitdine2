const jwt = require('jsonwebtoken');
const { userQueries } = require('../utils/database');

/**
 * JWT Authentication Middleware
 * Validates JWT tokens and attaches user information to request object
 */

// Generate JWT token
const generateToken = (userId, email) => {
  const payload = {
    userId,
    email,
    iat: Math.floor(Date.now() / 1000)
  };

  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h'
  });
};

// Verify JWT token
const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid token');
  }
};

// Authentication middleware
const authenticateToken = async (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        return_code: 'MISSING_TOKEN',
        message: 'Access token is required',
        timestamp: new Date().toISOString()
      });
    }

    // Verify token
    const decoded = verifyToken(token);
    
    // Get user from database to ensure user still exists
    const user = await userQueries.findById(decoded.userId);
    
    if (!user) {
      return res.status(401).json({
        return_code: 'INVALID_TOKEN',
        message: 'User not found',
        timestamp: new Date().toISOString()
      });
    }

    // Update user's last active timestamp
    await userQueries.updateLastActive(user.id);

    // Attach user info to request object
    req.user = {
      id: user.id,
      email: user.email,
      display_name: user.display_name,
      is_anonymous: user.is_anonymous
    };

    next();
  } catch (error) {
    console.error('Authentication error:', error.message);
    
    return res.status(401).json({
      return_code: 'INVALID_TOKEN',
      message: 'Invalid or expired token',
      timestamp: new Date().toISOString()
    });
  }
};

// Optional authentication middleware (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      const decoded = verifyToken(token);
      const user = await userQueries.findById(decoded.userId);
      
      if (user) {
        await userQueries.updateLastActive(user.id);
        req.user = {
          id: user.id,
          email: user.email,
          display_name: user.display_name,
          is_anonymous: user.is_anonymous
        };
      }
    }

    next();
  } catch (error) {
    // Continue without authentication if token is invalid
    next();
  }
};

// Check if user is session host
const requireSessionHost = async (req, res, next) => {
  try {
    const sessionId = req.body.session_id;
    
    if (!sessionId) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID is required',
        timestamp: new Date().toISOString()
      });
    }

    const { sessionQueries } = require('../utils/database');
    const session = await sessionQueries.findById(sessionId);

    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }

    if (session.host_user_id !== req.user.id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only session host can perform this action',
        timestamp: new Date().toISOString()
      });
    }

    req.session = session;
    next();
  } catch (error) {
    console.error('Session host check error:', error.message);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Error checking session permissions',
      timestamp: new Date().toISOString()
    });
  }
};

// Check if user is session participant
const requireSessionParticipant = async (req, res, next) => {
  try {
    const sessionId = req.body.session_id;
    
    if (!sessionId) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Session ID is required',
        timestamp: new Date().toISOString()
      });
    }

    const { sessionQueries, participantQueries } = require('../utils/database');
    const session = await sessionQueries.findById(sessionId);

    if (!session) {
      return res.status(404).json({
        return_code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user is host or participant
    const isHost = session.host_user_id === req.user.id;
    const isParticipant = await participantQueries.isParticipant(sessionId, req.user.id);

    if (!isHost && !isParticipant) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You are not a participant in this session',
        timestamp: new Date().toISOString()
      });
    }

    req.session = session;
    req.isHost = isHost;
    next();
  } catch (error) {
    console.error('Session participant check error:', error.message);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'Error checking session permissions',
      timestamp: new Date().toISOString()
    });
  }
};

module.exports = {
  generateToken,
  verifyToken,
  authenticateToken,
  optionalAuth,
  requireSessionHost,
  requireSessionParticipant
};
