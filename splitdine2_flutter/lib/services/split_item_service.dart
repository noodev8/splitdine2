import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitdine2_flutter/config/app_config.dart';
import 'package:splitdine2_flutter/models/split_item.dart';

class SplitItemService {
  static const String baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Add split item
  Future<Map<String, dynamic>> addSplitItem({
    required int sessionId,
    required String name,
    required double price,
    String? description,
  }) async {
    print('=== ADD SPLIT ITEM SERVICE DEBUG ===');
    print('Adding split item - Session ID: $sessionId, Name: $name, Price: $price');

    try {
      final headers = await _getAuthHeaders();
      print('Auth headers: $headers');

      final requestBody = {
        'session_id': sessionId,
        'name': name,
        'price': price,
        'description': description,
      };
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/split-items/add-item'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final splitItem = SplitItem.fromJson(data['item']);
        print('Successfully created split item: ${splitItem.name}');
        return {'success': true, 'splitItem': splitItem};
      } else {
        print('API returned error: ${data['message']}');
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      print('Exception in addSplitItem: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      print('====================================');
    }
  }

  // Get split items for session
  Future<Map<String, dynamic>> getSplitItems(int sessionId) async {
    print('=== SPLIT ITEM SERVICE DEBUG ===');
    print('Getting split items for session ID: $sessionId');

    try {
      final headers = await _getAuthHeaders();
      print('Auth headers: $headers');

      final requestBody = {
        'session_id': sessionId,
      };
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/split-items/get-items'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final items = (data['items'] as List)
            .map((item) => SplitItem.fromJson(item))
            .toList();
        print('Successfully parsed ${items.length} split items');
        return {
          'success': true,
          'items': items,
          'summary': data['summary']
        };
      } else {
        print('API returned error: ${data['message']}');
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      print('Exception in getSplitItems: $e');
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      print('================================');
    }
  }

  // Update split item
  Future<Map<String, dynamic>> updateSplitItem({
    required int itemId,
    required String name,
    required double price,
    String? description,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/split-items/update-item'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
          'name': name,
          'price': price,
          'description': description,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final splitItem = SplitItem.fromJson(data['item']);
        return {'success': true, 'splitItem': splitItem};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete split item
  Future<Map<String, dynamic>> deleteSplitItem(int itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/split-items/delete-item'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add participant to split item
  Future<Map<String, dynamic>> addParticipant({
    required int itemId,
    required int userId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/split-items/add-participant'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {'success': true, 'participant_choice': data['participant_choice']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Remove participant from split item
  Future<Map<String, dynamic>> removeParticipant(int itemId, int userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/split-items/remove-participant'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
          'user_id': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user's split item assignments
  Future<Map<String, dynamic>> getUserSplitItems(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/split-items/get-user-assignments'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'items': data['items'],
          'total': data['total'] ?? 0.0,
          'item_count': data['item_count'] ?? 0,
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

}
