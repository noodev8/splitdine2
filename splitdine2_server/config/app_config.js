/**
 * Simple Application Configuration
 * Change these values as needed for your environment
 */

const config = {
  // Server Configuration - Change as needed
  server: {
    port: 3000,
    env: 'production', // 'development' or 'production'
    host: '0.0.0.0' // Listen on all interfaces
  },

  // Database Configuration - Update your connection string here
  database: {
    url: 'postgresql://splitdine_prod_user:Jwg3!h54@217.154.35.5:5432/splitdine_prod',
    ssl: true, // Set to true for production, false for local development
    pool: {
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000
    }
  },

  // JWT Configuration
  jwt: {
    secret: 'This5432frisjyttWtTytr54EWhjUoiE', // Change this to your secret
    expiresIn: '24h',
    algorithm: 'HS256'
  },

  // Security Configuration
  security: {
    bcryptRounds: 12,
    rateLimitWindowMs: 15 * 60 * 1000, // 15 minutes
    rateLimitMax: 100, // limit each IP to 100 requests per windowMs
    corsOrigin: '*' // Change to your domain for production: 'https://splitdine.noodev8.com'
  },

  // API Configuration
  api: {
    prefix: '/api',
    version: 'v1',
    requestSizeLimit: '10mb'
  },

  // Logging Configuration
  logging: {
    level: 'info',
    format: 'combined'
  }
};

module.exports = config;
