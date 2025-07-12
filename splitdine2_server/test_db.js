require('dotenv').config();
const { Pool } = require('pg');

async function testDatabase() {
  console.log('Testing database connection...');
  console.log('DATABASE_URL:', process.env.DATABASE_URL ? 'Set' : 'Not set');
  
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: false
  });

  try {
    // Test basic connection
    const client = await pool.connect();
    console.log('✅ Database connected successfully');
    
    // Test basic query
    const result = await client.query('SELECT NOW()');
    console.log('✅ Basic query successful:', result.rows[0]);
    
    // Test sessions table exists
    const tableCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'sessions'
    `);
    console.log('✅ Sessions table exists:', tableCheck.rows.length > 0);
    
    // Test app_user table exists
    const userTableCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'app_user'
    `);
    console.log('✅ App_user table exists:', userTableCheck.rows.length > 0);
    
    // Test session_participants table exists
    const participantsTableCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'session_participants'
    `);
    console.log('✅ Session_participants table exists:', participantsTableCheck.rows.length > 0);
    
    // Test if there are any users
    const userCount = await client.query('SELECT COUNT(*) FROM app_user');
    console.log('✅ Users in database:', userCount.rows[0].count);
    
    // Test if there are any sessions
    const sessionCount = await client.query('SELECT COUNT(*) FROM sessions');
    console.log('✅ Sessions in database:', sessionCount.rows[0].count);
    
    client.release();
    
  } catch (error) {
    console.error('❌ Database error:', error.message);
    console.error('Full error:', error);
  } finally {
    await pool.end();
  }
}

testDatabase();
