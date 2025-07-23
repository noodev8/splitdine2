class AuthConfig {
  // Skip token validation in development for easier testing
  static const bool skipTokenValidation = false; // Set to false in production
  
  // Token expiry buffer (in seconds) - refresh token if it expires within this time
  static const int tokenExpiryBuffer = 3600; // 1 hour
}