import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class GuestChoiceService {
  static String get baseUrl => AppConfig.baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

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

  // Assign item to user (add guest choice)
  Future<Map<String, dynamic>> assignItem({
    required int sessionId,
    required int itemId,
    required int userId,
    bool splitItem = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest_choices/assign'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'item_id': itemId,
          'user_id': userId,
          'split_item': splitItem,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {'success': true, 'choice': data['choice']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Unassign item from user (remove guest choice)
  Future<Map<String, dynamic>> unassignItem({
    required int sessionId,
    required int itemId,
    required int userId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest_choices/unassign'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'item_id': itemId,
          'user_id': userId,
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

  // Get assignments for a specific item
  Future<Map<String, dynamic>> getItemAssignments({
    required int sessionId,
    required int itemId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest_choices/get_item_assignments'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'item_id': itemId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'assignments': data['assignments'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get all assignments for a session grouped by item_id
  Future<Map<String, dynamic>> getSessionAssignments(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest_choices/get_session_assignments'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'assignments': data['assignments'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
