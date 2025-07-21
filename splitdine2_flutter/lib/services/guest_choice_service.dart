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

  // Update shared status for all assignments of an item
  Future<Map<String, dynamic>> updateItemSharedStatus({
    required int sessionId,
    required int itemId,
    required bool isShared,
    required double itemPrice,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest_choices/update_shared_status'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'item_id': itemId,
          'is_shared': isShared,
          'item_price': itemPrice,
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

  // Delete all assignments for an item
  Future<Map<String, dynamic>> deleteItemAssignments({
    required int sessionId,
    required int itemId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest_choices/delete_item_assignments'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
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

  // Get payment summary for session
  Future<Map<String, dynamic>> getPaymentSummary(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/guest_choices/get_payment_summary'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'bill_total': data['bill_total'],
          'allocated_total': data['allocated_total'],
          'remaining_total': data['remaining_total'],
          'participant_totals': data['participant_totals'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
