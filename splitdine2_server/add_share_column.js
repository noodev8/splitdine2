const { query } = require('./config/database');

async function addShareColumn() {
  try {
    console.log('Checking if share column exists...');
    
    // Check if column exists
    const checkResult = await query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'item_assignments' 
      AND column_name = 'share'
    `);
    
    if (checkResult.rows.length > 0) {
      console.log('Share column already exists!');
      return;
    }
    
    console.log('Adding share column to item_assignments table...');
    
    // Add the share column
    await query(`
      ALTER TABLE item_assignments 
      ADD COLUMN share VARCHAR(10)
    `);
    
    console.log('Share column added successfully!');
    
    // Show the updated table structure
    const tableInfo = await query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'item_assignments' 
      ORDER BY ordinal_position
    `);
    
    console.log('\nUpdated table structure:');
    console.table(tableInfo.rows);
    
  } catch (error) {
    console.error('Error adding share column:', error);
  } finally {
    process.exit(0);
  }
}

addShareColumn();
