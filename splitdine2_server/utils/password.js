const bcrypt = require('bcryptjs');

/**
 * Password utility functions for hashing and verification
 */

// Hash password
const hashPassword = async (password) => {
  const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
  return await bcrypt.hash(password, saltRounds);
};

// Verify password
const verifyPassword = async (password, hashedPassword) => {
  return await bcrypt.compare(password, hashedPassword);
};

// Validate password strength (simplified for MVP)
const validatePassword = (password) => {
  const errors = [];

  if (!password) {
    errors.push('Password is required');
    return { isValid: false, errors };
  }

  if (password.length < 8) {
    errors.push('Password must be at least 8 characters long');
  }

  // Simplified: just require 8+ characters for MVP
  // Can be enhanced later for production

  return {
    isValid: errors.length === 0,
    errors
  };
};

module.exports = {
  hashPassword,
  verifyPassword,
  validatePassword
};
