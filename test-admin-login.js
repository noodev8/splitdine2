const axios = require('axios');

async function testAdminLogin() {
  try {
    console.log('Testing admin login endpoint...');
    
    const response = await axios.post('http://localhost:3000/api/auth/admin-login', {
      email: 'your-email@example.com', // Replace with your email
      password: 'your-password' // Replace with your password
    });
    
    console.log('Success:', response.data);
  } catch (error) {
    if (error.response) {
      console.log('Error response:', error.response.status);
      console.log('Error data:', error.response.data);
    } else if (error.request) {
      console.log('No response received. Is the server running?');
    } else {
      console.log('Error:', error.message);
    }
  }
}

testAdminLogin();