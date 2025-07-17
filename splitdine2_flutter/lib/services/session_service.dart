import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
import '../models/participant.dart';
import '../config/app_config.dart';

class SessionService {
  static String get baseUrl => AppConfig.baseUrl;

  // Get authorization header with stored token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token'); // Match AuthService token key
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get user's sessions
  Future<Map<String, dynamic>> getMySessions() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/my-sessions'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final sessions = (data['sessions'] as List)
            .map((sessionJson) => Session.fromJson(sessionJson))
            .toList();
        
        return {'success': true, 'sessions': sessions};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create new session
  Future<Map<String, dynamic>> createSession({
    String? sessionName,
    required String location,
    required DateTime sessionDate,
    String? sessionTime,
    String? description,
    String? foodType,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/create'),
        headers: headers,
        body: jsonEncode({
          'session_name': sessionName,
          'location': location,
          'session_date': sessionDate.toIso8601String().split('T')[0], // Date only
          'session_time': sessionTime,
          'description': description,
          'food_type': foodType,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final session = Session.fromJson(data['session']);
        return {'success': true, 'session': session};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Join session by code
  Future<Map<String, dynamic>> joinSession(String sessionCode) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/join'),
        headers: headers,
        body: jsonEncode({
          'session_code': sessionCode.toUpperCase(),
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final session = Session.fromJson(data['session']);
        return {'success': true, 'session': session};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get session details
  Future<Map<String, dynamic>> getSessionDetails(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/details'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final session = Session.fromJson(data['session']);
        return {'success': true, 'session': session};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // End session (host only)
  Future<Map<String, dynamic>> endSession(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/end'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
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

  // Get session participants
  Future<Map<String, dynamic>> getSessionParticipants(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/details'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final participants = (data['participants'] as List)
            .map((participant) => Participant.fromJson(participant))
            .toList();
        return {'success': true, 'participants': participants};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Leave session
  Future<Map<String, dynamic>> leaveSession(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/leave'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
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

  // Remove participant from session (organizer only)
  Future<Map<String, dynamic>> removeParticipant(int sessionId, int userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/remove-participant'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
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

  // Transfer host privileges to another participant
  Future<Map<String, dynamic>> transferHost(int sessionId, int newHostUserId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/transfer-host'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'new_host_user_id': newHostUserId,
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

  // Delete/cancel session (host only)
  Future<Map<String, dynamic>> deleteSession(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/delete'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
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

  // Update session bill totals
  Future<Map<String, dynamic>> updateBillTotals({
    required int sessionId,
    required double itemAmount,
    required double taxAmount,
    required double serviceCharge,
    required double extraCharge,
    required double totalAmount,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/update-bill-totals'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
          'item_amount': itemAmount,
          'tax_amount': taxAmount,
          'service_charge': serviceCharge,
          'extra_charge': extraCharge,
          'total_amount': totalAmount,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final session = Session.fromJson(data['session']);
        return {'success': true, 'session': session};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
