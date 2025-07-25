import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;

  // Get stored JWT token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Get authorization headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }



  /**
   * Generic POST request helper
   * @param endpoint - API endpoint (without base URL)
   * @param data - Request body data
   * @returns API response
   */
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);

    } catch (e) {
      print('API POST error: $e');
      return {
        'return_code': 'NETWORK_ERROR',
        'message': 'Network error: $e'
      };
    }
  }

  /**
   * Generic GET request helper
   * @param endpoint - API endpoint (without base URL)
   * @returns API response
   */
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return jsonDecode(response.body);

    } catch (e) {
      print('API GET error: $e');
      return {
        'return_code': 'NETWORK_ERROR',
        'message': 'Network error: $e'
      };
    }
  }
}
