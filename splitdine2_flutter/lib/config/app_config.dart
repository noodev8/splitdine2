class AppConfig {
  // Change this URL for your environment
  // static const String baseUrl = 'http://192.168.1.88:3000/api'; // Development
  static const String baseUrl = 'https://splitdine.noodev8.com/api'; // Production

  static const String appName = 'Split Dine';
  static const bool isDebugMode = false;
  static const Duration apiTimeout = Duration(seconds: 30);
}
