const { Pool } = require('pg');

// Database configuration
const dbConfig = {
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 2000, // Return an error after 2 seconds if connection could not be established
};

// Create connection pool
const pool = new Pool(dbConfig);

// Handle pool errors
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Database connection test
const testConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('Database connected successfully');
    
    // Test query to verify database structure
    const result = await client.query('SELECT NOW() as current_time');
    console.log('Database test query successful:', result.rows[0].current_time);
    
    client.release();
    return true;
  } catch (err) {
    console.error('Database connection failed:', err.message);
    return false;
  }
};

// Query helper function
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Executed query', { text, duration, rows: res.rowCount });
    return res;
  } catch (err) {
    console.error('Query error:', err.message);
    throw err;
  }
};

// Transaction helper function
const transaction = async (callback) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

// Graceful shutdown
const closePool = async () => {
  try {
    await pool.end();
    console.log('Database pool closed');
  } catch (err) {
    console.error('Error closing database pool:', err);
  }
};

// Handle process termination
process.on('SIGINT', closePool);
process.on('SIGTERM', closePool);

module.exports = {
  pool,
  query,
  transaction,
  testConnection,
  closePool
};
