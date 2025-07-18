import 'dart:convert';
import 'dart:io';
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
   * Upload and scan receipt image
   * @param sessionId - Session ID to add items to
   * @param imageFile - Receipt image file
   * @returns Parsed receipt data with items and totals
   */
  static Future<Map<String, dynamic>> scanReceipt(
    int sessionId,
    File imageFile,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication required'
        };
      }

      final uri = Uri.parse('$baseUrl/receipt_scan/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add form fields
      request.fields['session_id'] = sessionId.toString();
      
      // Add image file
      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: 'receipt.jpg',
      );
      
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Parse response
      final data = jsonDecode(response.body);
      
      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to scan receipt'
        };
      }
      
    } catch (e) {
      print('Receipt scan error: $e');
      return {
        'success': false,
        'error': 'Network error: $e'
      };
    }
  }

  /**
   * Add parsed receipt items to session
   * @param sessionId - Session ID
   * @param items - List of items to add
   * @returns Success confirmation
   */
  static Future<Map<String, dynamic>> addReceiptItems(
    int sessionId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/receipt_scan/add-items'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'items': items,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to add items'
        };
      }

    } catch (e) {
      print('Add items error: $e');
      return {
        'success': false,
        'error': 'Network error: $e'
      };
    }
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
