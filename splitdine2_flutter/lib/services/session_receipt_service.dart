import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_receipt_item.dart';
import '../config/app_config.dart';

class SessionReceiptService {
  static String get baseUrl => AppConfig.baseUrl;

  // Get authentication headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token'); // Fixed: was 'auth_token'

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Add session receipt item
  static Future<Map<String, dynamic>> addItem({
    required int sessionId,
    required String itemName,
    required double price,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final requestBody = {
        'session_id': sessionId,
        'item_name': itemName,
        'price': price,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/session_receipt/add-item'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final item = SessionReceiptItem.fromJson(data['item']);
        return {'success': true, 'item': item};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get session receipt items
  static Future<Map<String, dynamic>> getItems(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$baseUrl/session_receipt/get-items';

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'session_id': sessionId}),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final items = (data['items'] as List)
            .map((item) => SessionReceiptItem.fromJson(item))
            .toList();

        return {
          'success': true,
          'items': items,
          'totals': data['totals'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update session receipt item
  static Future<Map<String, dynamic>> updateItem({
    required int itemId,
    required int sessionId,
    required String itemName,
    required double price,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final requestBody = {
        'item_id': itemId,
        'session_id': sessionId,
        'item_name': itemName,
        'price': price,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/session_receipt/update-item'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final item = SessionReceiptItem.fromJson(data['item']);
        return {'success': true, 'item': item};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete session receipt item
  static Future<Map<String, dynamic>> deleteItem(int itemId, int sessionId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/session_receipt/delete-item'),
        headers: headers,
        body: jsonEncode({
          'item_id': itemId,
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

  // Clear all session receipt items
  static Future<Map<String, dynamic>> clearItems(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/session_receipt/clear-items'),
        headers: headers,
        body: jsonEncode({'session_id': sessionId}),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        return {
          'success': true,
          'message': data['message'],
          'items_cleared': data['data']['items_cleared'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add multiple items from parsed receipt
  static Future<Map<String, dynamic>> addItemsFromReceipt({
    required int sessionId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final List<SessionReceiptItem> addedItems = [];
      final List<String> errors = [];

      for (final item in items) {
        final result = await addItem(
          sessionId: sessionId,
          itemName: item['name'] ?? '',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
        );

        if (result['success']) {
          addedItems.add(result['item']);
        } else {
          errors.add('Failed to add ${item['name']}: ${result['message']}');
        }
      }

      return {
        'success': errors.isEmpty,
        'items_added': addedItems.length,
        'items': addedItems,
        'errors': errors,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error adding items: $e'};
    }
  }
}
