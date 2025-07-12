import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_assignment.dart';
import '../config/app_config.dart';

class AssignmentService {
  static String get baseUrl => AppConfig.baseUrl;

  // Get authorization header with stored token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Assign item to user
  Future<Map<String, dynamic>> assignItem({
    required int sessionId,
    required int itemId,
    required int userId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/assign'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'item_id': itemId,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final assignment = ItemAssignment.fromJson(data['assignment']);
        return {'success': true, 'assignment': assignment};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Unassign item from user
  Future<Map<String, dynamic>> unassignItem({
    required int sessionId,
    required int itemId,
    required int userId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/unassign'),
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

  // Get all assignments for a session
  Future<Map<String, dynamic>> getSessionAssignments(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/get-session-assignments'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final assignments = (data['assignments'] as List)
            .map((assignment) => ItemAssignment.fromJson(assignment))
            .toList();
        return {'success': true, 'assignments': assignments};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get assignments for a specific item
  Future<Map<String, dynamic>> getItemAssignments(int itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/get-item-assignments'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final assignments = (data['assignments'] as List)
            .map((assignment) => ItemAssignment.fromJson(assignment))
            .toList();
        return {'success': true, 'assignments': assignments};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
