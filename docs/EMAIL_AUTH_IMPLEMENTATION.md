# Email Authentication Implementation Guide

This document provides a comprehensive guide to implement email verification and password reset functionality using Resend as the email service provider.

## Overview

This implementation adds:
- Email verification for new user registrations
- Password reset functionality via email
- Resend verification email capability
- Secure token-based authentication flows

## Backend Implementation

### 1. Dependencies

```bash
npm install resend
```

### 2. Environment Variables

Add to your `.env` file:

```env
# Resend API configuration
RESEND_API_KEY=re_your_api_key_here
FRONTEND_URL=https://your-frontend-domain.com
EMAIL_VERIFICATION_URL=https://your-api-domain.com

# Email configuration
EMAIL_FROM=no-reply@your-domain.com
EMAIL_NAME=Your App Name
```

### 3. Database Schema Changes

Add these columns to your `app_user` table:

```sql
ALTER TABLE app_user 
ADD COLUMN email_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN auth_token VARCHAR(255),
ADD COLUMN auth_token_expires TIMESTAMP WITH TIME ZONE;
```

### 4. File Structure

```
splitdine2_server/
├── services/
│   └── emailService.js          # Email sending logic
├── utils/
│   └── tokenUtils.js            # Token generation utilities
├── routes/
│   └── auth.js                  # Updated auth routes
└── utils/
    └── database.js              # Updated database queries
```

### 5. Core Files

#### `services/emailService.js`
Handles Resend integration and email templates:
- `sendVerificationEmail()` - Sends email verification link
- `sendPasswordResetEmail()` - Sends password reset link
- HTML and text email templates included

#### `utils/tokenUtils.js`
Secure token generation utilities:
- `generateToken(prefix)` - Creates secure random tokens
- `isTokenExpired(date)` - Checks token expiration
- `getTokenExpiry(hours)` - Calculates expiry timestamp

#### Updated `routes/auth.js`
New endpoints added:
- `GET /auth/verify-email` - Email verification
- `POST /auth/resend-verification` - Resend verification email
- `POST /auth/forgot-password` - Request password reset
- `POST /auth/reset-password` - Reset password with token

#### Updated `utils/database.js`
New database functions:
- `setAuthToken()` - Store auth token
- `findByAuthToken()` - Find user by token
- `clearAuthToken()` - Clear auth token
- `markEmailVerified()` - Mark email as verified
- `updatePassword()` - Update password and clear token

### 6. Security Features

- **Token prefixing**: Tokens include type prefix (`verify_` or `reset_`)
- **Expiration times**: 24 hours for verification, 1 hour for reset
- **Single-use tokens**: Tokens cleared after successful use
- **No user enumeration**: Same response for existing/non-existing emails
- **Secure token generation**: Using `crypto.randomBytes(32)`

### 7. API Endpoints

#### Register User (Updated)
```
POST /auth/register
```
Now sends verification email automatically.

#### Email Verification
```
GET /auth/verify-email?token=verify_xxxxx
```
Returns beautiful HTML success page instead of JSON.

#### Resend Verification
```
POST /auth/resend-verification
Body: { "email": "user@example.com" }
```

#### Forgot Password
```
POST /auth/forgot-password  
Body: { "email": "user@example.com" }
```

#### Password Reset Form
```
GET /auth/reset-password?token=reset_xxxxx
```
Serves interactive HTML form for password reset.

#### Reset Password
```
POST /auth/reset-password
Body: { 
  "token": "reset_xxxxx", 
  "new_password": "newPassword123" 
}
```
Processes password reset from HTML form or API call.

## Frontend Implementation (Flutter)

### 1. Updated AuthService

Added new methods to `lib/services/auth_service.dart`:
- `resendVerificationEmail(email)`
- `forgotPassword(email)`
- `resetPassword(token, newPassword)`

### 2. New Screens

#### Email Verification Screen
- `lib/screens/email_verification_screen.dart`
- Shows after registration
- Allows resending verification email
- Option to continue to app

#### Forgot Password Screen
- `lib/screens/forgot_password_screen.dart`
- Email input form
- Sends reset request

#### Reset Password Screen
- `lib/screens/reset_password_screen.dart`
- New password form with validation
- Token-based reset

### 3. Navigation Updates

#### Updated Login Screen
- Added "Forgot Password?" link
- Navigation to `ForgotPasswordScreen`

#### Updated Register Screen
- Now navigates to `EmailVerificationScreen` after registration

#### Route Configuration
Added to `main.dart`:
```dart
routes: {
  '/login': (context) => const LoginScreen(),
  '/reset-password': (context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final token = args?['token'] as String? ?? '';
    return ResetPasswordScreen(token: token);
  },
}
```

## Email Templates

### Verification Email
- Clean HTML design with CTA button
- Fallback text version
- 24-hour expiry notice
- App branding

### Password Reset Email
- Security-focused messaging
- 1-hour expiry notice
- Clear reset button
- Safety instructions

## Testing the Implementation

### Backend Testing
1. Start the server: `npm run dev`
2. Test registration endpoint - should send verification email
3. Check email logs for successful delivery
4. Test verification link functionality
5. Test password reset flow

### Frontend Testing
1. Run Flutter app: `flutter run`
2. Test registration flow → email verification screen
3. Test login → forgot password → reset flow
4. Test email verification enforcement (unverified users blocked at login)
5. Verify all navigation paths work correctly

### Email Verification Enforcement

⚠️ **IMPORTANT**: Keep this implementation SIMPLE. Only block at login, not auto-login.

#### Quick Implementation Guide
For future apps, only these changes are needed:

1. **User Model**: Add `emailVerified` boolean field that reads from server's `email_verified` field

2. **AuthProvider Login Method**: After successful server login, check if user is registered (not anonymous) and email is not verified. If so, show error message directing them to continue as guest instead.

3. **That's it!** Do NOT modify splash screen, do NOT add redirects, do NOT complicate the flow.

#### Implementation Details
- **User Model**: Added `emailVerified` field from server response
- **Login Check ONLY**: Unverified users blocked with clear error message at login
- **Guest Option**: Users directed to continue as guest if not verified
- **Auto-login**: Previously verified users can auto-login (no re-check needed)
- **No Redirects**: Do not redirect users to verification screens during normal app flow

#### User Experience
1. **Login (Unverified)**: Shows error "Email not verified. Please check your email or continue as guest."
2. **Guest Alternative**: User can immediately switch to guest mode using existing UI
3. **Auto-login**: Works normally for previously verified users (no interruption)
4. **Anonymous Users**: Skip verification entirely (no email to verify)

#### What NOT to Do
- ❌ Do NOT modify splash screen auto-login flow
- ❌ Do NOT add verification checks everywhere
- ❌ Do NOT redirect to verification screens during login
- ❌ Do NOT overcomplicate with refresh methods and complex state management

## Security Considerations

### Token Security
- Tokens are 64-character hex strings
- Prefixed by type for validation
- Single-use only
- Time-limited expiration

### Email Security
- No sensitive data in emails
- Generic responses prevent user enumeration
- Rate limiting on email endpoints (recommended)

### Database Security
- Tokens stored hashed (optional enhancement)
- Expired tokens cleaned up automatically
- Parameterized queries prevent SQL injection

## Configuration for Production

### Resend Setup
1. Create account at resend.com
2. Verify your sending domain
3. Generate API key
4. Configure SPF/DKIM records

### Environment Variables
```env
RESEND_API_KEY=re_live_xxxxx
FRONTEND_URL=https://your-production-domain.com
EMAIL_VERIFICATION_URL=https://api.your-domain.com
EMAIL_FROM=no-reply@your-domain.com
EMAIL_NAME=Your App Name
```

### Email Links
- Email verification: `{EMAIL_VERIFICATION_URL}/api/auth/verify-email?token={token}`
- Password reset: `{EMAIL_VERIFICATION_URL}/api/auth/reset-password?token={token}`

### HTML Pages

The implementation includes beautiful, responsive HTML pages served directly by the API:

#### Email Verification Success Page
- Accessible via: `GET /api/auth/verify-email?token={verification_token}`
- Shows success message after email verification
- Modern design with gradient background
- Mobile-responsive layout
- No dependencies on frontend

#### Password Reset Form Page  
- Accessible via: `GET /api/auth/reset-password?token={reset_token}`
- Interactive password reset form with validation
- Real-time password strength checking
- Responsive design for desktop and mobile
- Handles invalid/expired tokens gracefully
- JavaScript form submission to API endpoint
- Success/error message display

Both pages feature:
- Consistent SplitDine branding
- Modern CSS with gradient backgrounds
- Mobile-first responsive design
- Clean, accessible typography
- Proper error handling and user feedback

## Customization Options

### Email Templates
- Modify HTML/CSS in `emailService.js`
- Add company branding
- Customize messaging and styling
- Button colors: Use `#2563eb` for blue buttons (matches form styling)
- Consistent color scheme across email and web pages

### Token Expiration
- Adjust in `tokenUtils.js`
- Verification: 24 hours (recommended)
- Reset: 1 hour (recommended)

### Additional Features
- Email change verification
- Account deletion confirmation
- Welcome email sequences
- Email preferences management

## Troubleshooting

### Common Issues
1. **Emails not sending**: Check Resend API key and domain verification
2. **Links not working**: Verify FRONTEND_URL and EMAIL_VERIFICATION_URL
3. **Token errors**: Check token expiration and database timezone settings
4. **Navigation issues**: Ensure Flutter routes are properly configured

### Debug Steps
1. Check server logs for email service errors
2. Verify environment variables are loaded
3. Test database token operations
4. Validate email template rendering

## Future Enhancements

- Rate limiting for email endpoints
- Email template customization UI
- Multi-language email support
- Email delivery tracking
- Advanced security options (2FA, etc.)

## Dependencies

### Backend
- `resend` - Email service
- `crypto` (built-in) - Token generation
- `bcryptjs` - Password hashing
- `jsonwebtoken` - JWT tokens

### Frontend
- `http` - API calls
- `shared_preferences` - Local storage
- `provider` - State management

This implementation provides a secure, user-friendly email authentication system that can be easily adapted to other projects.