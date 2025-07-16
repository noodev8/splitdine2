import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class GuestChoiceService {
  static String get baseUrl => AppConfig.baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Add new item to guest_choice table
  Future<Map<String, dynamic>> addItem({
    required int sessionId,
    required String name,
    required double price,
    String? description,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest-choice/add-item'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'name': name,
          'price': price,
          if (description != null) 'description': description,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {'success': true, 'item': data['item']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user's items from guest_choice table
  Future<Map<String, dynamic>> getUserItems({
    required int sessionId,
    required int userId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest-choice/get-user-items'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'items': data['items'],
          'total': data['total'] ?? 0.0,
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update existing item in guest_choice table
  Future<Map<String, dynamic>> updateItem({
    required int itemId,
    required String name,
    required double price,
    String? description,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest-choice/update-item'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
          'name': name,
          'price': price,
          if (description != null) 'description': description,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {'success': true, 'item': data['item']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete item from guest_choice table
  Future<Map<String, dynamic>> deleteItem(int itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest-choice/delete-item'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
