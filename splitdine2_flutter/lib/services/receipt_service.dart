import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_item.dart';
import '../config/app_config.dart';

class ReceiptService {
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

  // Add new receipt item
  Future<Map<String, dynamic>> addItem({
    required int sessionId,
    required String itemName,
    required double price,
    required int quantity,
    String? share,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final requestBody = {
        'session_id': sessionId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
        if (share != null) 'share': share,
      };

      // DEBUG: Log the request being sent
      print('=== FLUTTER ADD ITEM DEBUG ===');
      print('Request URL: $baseUrl/receipts/add-item');
      print('Request body: ${jsonEncode(requestBody)}');
      print('Headers: $headers');
      print('===============================');

      final response = await http.post(
        Uri.parse('$baseUrl/receipts/add-item'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final item = ReceiptItem.fromJson(data['item']);
        return {'success': true, 'item': item};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get all items for a session
  Future<Map<String, dynamic>> getItems(int sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/receipts/get-items'),
        headers: headers,
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final items = (data['items'] as List)
            .map((item) => ReceiptItem.fromJson(item))
            .toList();
        final summary = data['summary'];
        return {
          'success': true,
          'items': items,
          'summary': summary,
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update existing receipt item
  Future<Map<String, dynamic>> updateItem({
    required int itemId,
    required String itemName,
    required double price,
    required int quantity,
    String? share,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final requestBody = {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
        if (share != null) 'share': share,
      };

      // DEBUG: Log the request being sent
      print('=== FLUTTER UPDATE ITEM DEBUG ===');
      print('Request URL: $baseUrl/receipts/update-item');
      print('Request body: ${jsonEncode(requestBody)}');
      print('Headers: $headers');
      print('==================================');

      final response = await http.post(
        Uri.parse('$baseUrl/receipts/update-item'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (data['return_code'] == 'SUCCESS') {
        final item = ReceiptItem.fromJson(data['item']);
        return {'success': true, 'item': item};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete receipt item
  Future<Map<String, dynamic>> deleteItem(int itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/receipts/delete-item'),
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
