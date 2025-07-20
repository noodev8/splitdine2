// Debug script to test email functionality
require('dotenv').config();
const { sendVerificationEmail, sendPasswordResetEmail } = require('./services/emailService');

console.log('=== EMAIL DEBUG SCRIPT ===');

// 1. Check environment variables
console.log('\n1. ENVIRONMENT VARIABLES:');
console.log('RESEND_API_KEY:', process.env.RESEND_API_KEY ? `${process.env.RESEND_API_KEY.substring(0, 10)}...` : 'NOT SET');
console.log('EMAIL_FROM:', process.env.EMAIL_FROM || 'NOT SET');
console.log('EMAIL_NAME:', process.env.EMAIL_NAME || 'NOT SET');
console.log('EMAIL_VERIFICATION_URL:', process.env.EMAIL_VERIFICATION_URL || 'NOT SET');
console.log('FRONTEND_URL:', process.env.FRONTEND_URL || 'NOT SET');

// 2. Test Resend initialization
console.log('\n2. TESTING RESEND INITIALIZATION:');
try {
  const { Resend } = require('resend');
  const resend = new Resend(process.env.RESEND_API_KEY);
  console.log('✅ Resend initialized successfully');
} catch (error) {
  console.log('❌ Resend initialization failed:', error.message);
  process.exit(1);
}

// 3. Test email sending
async function testEmailSending() {
  console.log('\n3. TESTING EMAIL SENDING:');
  
  const testEmail = 'test@example.com'; // Change this to your email
  const testToken = 'test_token_12345';
  
  try {
    console.log('Sending verification email...');
    const result = await sendVerificationEmail(testEmail, testToken);
    
    if (result.success) {
      console.log('✅ Verification email sent successfully');
      console.log('Email ID:', result.data?.id);
    } else {
      console.log('❌ Verification email failed:', result.error);
    }
  } catch (error) {
    console.log('❌ Email sending error:', error.message);
    console.log('Full error:', error);
  }
}

// Run the test
testEmailSending().then(() => {
  console.log('\n=== DEBUG COMPLETE ===');
  process.exit(0);
}).catch((error) => {
  console.log('❌ Debug script failed:', error);
  process.exit(1);
});