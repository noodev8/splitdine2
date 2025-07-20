const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

const sendEmail = async ({ to, subject, html, text }) => {
  try {
    console.log('📧 Email Service - Starting send process');
    console.log('📧 To:', to);
    console.log('📧 From:', `${process.env.EMAIL_NAME} <${process.env.EMAIL_FROM}>`);
    console.log('📧 Subject:', subject);
    
    const data = await resend.emails.send({
      from: `${process.env.EMAIL_NAME} <${process.env.EMAIL_FROM}>`,
      to: [to],
      subject,
      html,
      text
    });
    
    console.log('✅ Email sent successfully');
    console.log('📧 Response data:', data);
    return { success: true, data };
  } catch (error) {
    console.error('❌ Email send error:', error);
    console.error('❌ Error details:', {
      message: error.message,
      status: error.status,
      statusText: error.statusText,
      body: error.body
    });
    return { success: false, error: error.message };
  }
};

const sendVerificationEmail = async (email, verificationToken) => {
  const verificationUrl = `${process.env.EMAIL_VERIFICATION_URL}/api/auth/verify-email?token=${verificationToken}`;
  
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2>Welcome to ${process.env.EMAIL_NAME}!</h2>
      <p>Please verify your email address by clicking the link below:</p>
      <div style="margin: 30px 0;">
        <a href="${verificationUrl}" 
           style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
          Verify Email Address
        </a>
      </div>
      <p>Or copy and paste this link into your browser:</p>
      <p style="word-break: break-all; color: #666;">${verificationUrl}</p>
      <p style="color: #666; margin-top: 30px;">This link will expire in 24 hours.</p>
      <hr style="margin-top: 40px; border: none; border-top: 1px solid #eee;">
      <p style="color: #999; font-size: 12px;">If you didn't create an account, you can safely ignore this email.</p>
    </div>
  `;
  
  const text = `
Welcome to ${process.env.EMAIL_NAME}!

Please verify your email address by visiting this link:
${verificationUrl}

This link will expire in 24 hours.

If you didn't create an account, you can safely ignore this email.
  `;
  
  return sendEmail({
    to: email,
    subject: `Verify your ${process.env.EMAIL_NAME} account`,
    html,
    text
  });
};

const sendPasswordResetEmail = async (email, resetToken) => {
  const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
  
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2>Password Reset Request</h2>
      <p>You requested to reset your password for your ${process.env.EMAIL_NAME} account.</p>
      <div style="margin: 30px 0;">
        <a href="${resetUrl}" 
           style="background-color: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
          Reset Password
        </a>
      </div>
      <p>Or copy and paste this link into your browser:</p>
      <p style="word-break: break-all; color: #666;">${resetUrl}</p>
      <p style="color: #666; margin-top: 30px;">This link will expire in 1 hour.</p>
      <hr style="margin-top: 40px; border: none; border-top: 1px solid #eee;">
      <p style="color: #999; font-size: 12px;">If you didn't request a password reset, you can safely ignore this email.</p>
    </div>
  `;
  
  const text = `
Password Reset Request

You requested to reset your password for your ${process.env.EMAIL_NAME} account.

Reset your password by visiting this link:
${resetUrl}

This link will expire in 1 hour.

If you didn't request a password reset, you can safely ignore this email.
  `;
  
  return sendEmail({
    to: email,
    subject: `Reset your ${process.env.EMAIL_NAME} password`,
    html,
    text
  });
};

module.exports = {
  sendEmail,
  sendVerificationEmail,
  sendPasswordResetEmail
};