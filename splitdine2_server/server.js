const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

// Import configuration and middleware
const config = require('./config/config');
const { testConnection } = require('./config/database');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const { generalLimiter, authLimiter, sessionLimiter } = require('./middleware/rateLimiter');

const app = express();
const PORT = config.port;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// CORS configuration
app.use(cors({
  origin: config.corsOrigin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
app.use(generalLimiter);

// Body parsing middleware
app.use(express.json({
  limit: '10mb',
  strict: true
}));
app.use(express.urlencoded({
  extended: true,
  limit: '10mb'
}));

// Routes
app.get('/', (req, res) => {
  res.json({
    return_code: 'SUCCESS',
    message: 'SplitDine API Server is running',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    return_code: 'SUCCESS',
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Import route modules
const authRoutes = require('./routes/auth');
const sessionRoutes = require('./routes/sessions');
const receiptRoutes = require('./routes/receipts');
const assignmentRoutes = require('./routes/assignments');
const splitItemRoutes = require('./routes/split_items');

// Apply rate limiting to specific routes
app.use('/api/auth', authLimiter);
app.use('/api/sessions/create', sessionLimiter);

// Use route modules
app.use('/api/auth', authRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/receipts', receiptRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/split-items', splitItemRoutes);
app.use('/api/receipt-scan', require('./routes/receipt_scan'));



// 404 handler
app.use('*', notFoundHandler);

// Global error handler (must be last)
app.use(errorHandler);

// Start server with database connection test
const startServer = async () => {
  try {
    // Test database connection
    const dbConnected = await testConnection();
    if (!dbConnected) {
      console.error('Failed to connect to database. Server not started.');
      process.exit(1);
    }

    // Start server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`SplitDine API Server Started on port ${PORT}`);
    });

  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received. Shutting down gracefully...');
  process.exit(0);
});

startServer();

module.exports = app;
