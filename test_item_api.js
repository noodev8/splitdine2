const http = require('http');

// Test data
const testData = {
  session_id: 1, // Assuming session 1 exists
  item_name: 'Test Item',
  price: 12.50,
  share: null
};

// Helper function to make HTTP requests
function makeRequest(path, data, token = null) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        ...(token && { 'Authorization': `Bearer ${token}` })
      }
    };

    const req = http.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          resolve({ statusCode: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ statusCode: res.statusCode, data: responseData });
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(postData);
    req.end();
  });
}

// Test function
async function testItemAPI() {
  console.log('Testing Item API - Quantity Field Fix');
  console.log('=====================================');
  
  try {
    // First, let's try to get a valid token by logging in
    console.log('\n1. Attempting to login...');
    const loginResponse = await makeRequest('/api/auth/login', {
      email: 'test@example.com',
      password: 'password123'
    });

    console.log('Login response:', loginResponse.data);


    
    let token = null;
    if (loginResponse.data.return_code === 'SUCCESS') {
      token = loginResponse.data.token;
    } else {
      // Try to register
      const registerResponse = await makeRequest('/api/auth/register', {
        email: 'test@example.com',
        password: 'password123',
        display_name: 'Test User'
      });
      if (registerResponse.data.return_code === 'SUCCESS') {
        token = registerResponse.data.token;
      }
    }
    
    if (!token) {
      console.log('No token received. Cannot test authenticated endpoints.');
      return;
    }
    
    console.log('\n2. Creating a test session...');
    const sessionResponse = await makeRequest('/api/sessions/create', {
      session_name: 'Test Session',
      location: 'Test Restaurant',
      session_date: '2025-07-14',
      session_time: '19:00',
      description: 'Test session for API testing'
    }, token);

    console.log('Session Response:', sessionResponse.data);

    if (sessionResponse.data.return_code !== 'SUCCESS') {
      console.log('❌ Could not create session:', sessionResponse.data.message);
      return;
    }

    const sessionId = sessionResponse.data.session.id;
    testData.session_id = sessionId;

    console.log('\n3. Testing Add Item API...');
    const addResponse = await makeRequest('/api/receipts/add-item', testData, token);
    console.log('Add Item Response Status:', addResponse.statusCode);
    console.log('Add Item Response Data:', JSON.stringify(addResponse.data, null, 2));
    
    // Check if quantity field is present and is 1
    if (addResponse.data.return_code === 'SUCCESS' && addResponse.data.item) {
      const item = addResponse.data.item;
      console.log('\n✓ Checking quantity field...');
      console.log('Quantity value:', item.quantity);
      console.log('Quantity type:', typeof item.quantity);
      
      if (item.quantity === 1) {
        console.log('✅ SUCCESS: Quantity field is correctly set to 1');
      } else {
        console.log('❌ ERROR: Quantity field is not 1, got:', item.quantity);
      }
      
      // Test update if add was successful
      if (item.id) {
        console.log('\n4. Testing Update Item API...');
        const updateResponse = await makeRequest('/api/receipts/update-item', {
          item_id: item.id,
          item_name: 'Updated Test Item',
          price: 15.00,
          share: null
        }, token);
        
        console.log('Update Item Response Status:', updateResponse.statusCode);
        console.log('Update Item Response Data:', JSON.stringify(updateResponse.data, null, 2));
        
        if (updateResponse.data.return_code === 'SUCCESS' && updateResponse.data.item) {
          const updatedItem = updateResponse.data.item;
          console.log('\n✓ Checking quantity field in update response...');
          console.log('Quantity value:', updatedItem.quantity);
          console.log('Quantity type:', typeof updatedItem.quantity);
          
          if (updatedItem.quantity === 1) {
            console.log('✅ SUCCESS: Update response quantity field is correctly set to 1');
          } else {
            console.log('❌ ERROR: Update response quantity field is not 1, got:', updatedItem.quantity);
          }
        }
      }
    } else {
      console.log('❌ Add item failed:', addResponse.data.message);
    }
    
  } catch (error) {
    console.error('Test failed with error:', error);
  }
}

// Run the test
testItemAPI();
