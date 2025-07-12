/**
 * Error Handling Middleware
 * Centralized error handling for the SplitDine API server
 */

const config = require('../config/config');

// Custom error class
class APIError extends Error {
  constructor(message, statusCode = 500, returnCode = 'SERVER_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.returnCode = returnCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

// Error handler middleware
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Error logging removed for production

  // Default error response
  let statusCode = 500;
  let returnCode = 'SERVER_ERROR';
  let message = 'Internal server error';

  // Handle specific error types
  if (err instanceof APIError) {
    statusCode = err.statusCode;
    returnCode = err.returnCode;
    message = err.message;
  } else if (err.name === 'ValidationError') {
    statusCode = 400;
    returnCode = 'VALIDATION_ERROR';
    message = 'Validation failed';
  } else if (err.name === 'CastError') {
    statusCode = 400;
    returnCode = 'INVALID_ID';
    message = 'Invalid ID format';
  } else if (err.code === 11000) {
    statusCode = 409;
    returnCode = 'DUPLICATE_ENTRY';
    message = 'Duplicate entry';
  } else if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    returnCode = 'INVALID_TOKEN';
    message = 'Invalid token';
  } else if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    returnCode = 'TOKEN_EXPIRED';
    message = 'Token expired';
  } else if (err.code === 'ECONNREFUSED') {
    statusCode = 503;
    returnCode = 'DATABASE_CONNECTION_ERROR';
    message = 'Database connection failed';
  }

  // Don't leak error details in production
  if (config.server.env === 'production' && statusCode === 500) {
    message = 'Internal server error';
  }

  res.status(statusCode).json({
    return_code: returnCode,
    message,
    timestamp: new Date().toISOString(),
    ...(config.server.env === 'development' && { stack: err.stack })
  });
};

// Async error wrapper
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// 404 handler
const notFoundHandler = (req, res) => {
  res.status(404).json({
    return_code: 'NOT_FOUND',
    message: `Route ${req.originalUrl} not found`,
    timestamp: new Date().toISOString()
  });
};

module.exports = {
  APIError,
  errorHandler,
  asyncHandler,
  notFoundHandler
};
