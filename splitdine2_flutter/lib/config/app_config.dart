class AppConfig {
  // Simple configuration - change this IP address as needed
  static const String baseUrl = 'http://192.168.1.88:3000/api';

  // App Configuration
  static const String appName = 'Split Dine';

  // Debug Configuration - always false to remove debug banner
  static const bool isDebugMode = false;

  // Logging Configuration
  static const bool enableLogging = true;

  // Timeout Configuration
  static const Duration apiTimeout = Duration(seconds: 30);

  // Helper method to log current configuration
  static void printConfig() {
    if (enableLogging) {
      print('=== App Configuration ===');
      print('Base URL: $baseUrl');
      print('App Name: $appName');
      print('Debug Mode: $isDebugMode');
      print('API Timeout: ${apiTimeout.inSeconds}s');
      print('========================');
    }
  }
}
