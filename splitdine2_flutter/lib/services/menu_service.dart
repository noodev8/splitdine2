import 'dart:async';
import 'api_service.dart';

class MenuService {
  // Timer for debouncing
  Timer? _debounceTimer;
  
  // Search for menu items (with debouncing)
  Future<Map<String, dynamic>> searchMenuItems(
    String query, {
    Duration debounce = const Duration(milliseconds: 300),
  }) async {
    // Cancel any existing timer
    _debounceTimer?.cancel();
    
    // Create a completer to handle the debounced result
    final completer = Completer<Map<String, dynamic>>();
    
    // Set up the debounce timer
    _debounceTimer = Timer(debounce, () async {
      try {
        // Only search if query is 2+ characters (WhatsApp-style)
        if (query.trim().length < 2) {
          completer.complete({
            'success': true,
            'suggestions': [],
          });
          return;
        }
        
        final response = await ApiService.get(
          '/menu/search?query=${Uri.encodeQueryComponent(query)}',
        );
        
        if (response['return_code'] == 0) {
          completer.complete({
            'success': true,
            'suggestions': response['suggestions'] ?? [],
          });
        } else {
          completer.complete({
            'success': false,
            'message': response['message'] ?? 'Search failed',
            'suggestions': [],
          });
        }
      } catch (e) {
        completer.complete({
          'success': false,
          'message': e.toString(),
          'suggestions': [],
        });
      }
    });
    
    return completer.future;
  }
  
  // Search without debouncing (for immediate results)
  Future<Map<String, dynamic>> searchMenuItemsNow(String query) async {
    try {
      // Only search if query is 2+ characters (WhatsApp-style)
      if (query.trim().length < 2) {
        return {
          'success': true,
          'suggestions': [],
        };
      }
      
      final response = await ApiService.get(
        '/menu/search?query=${Uri.encodeQueryComponent(query)}',
      );
      
      if (response['return_code'] == 0) {
        return {
          'success': true,
          'suggestions': response['suggestions'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Search failed',
          'suggestions': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'suggestions': [],
      };
    }
  }
  
  // Log a search after user submits
  static Future<Map<String, dynamic>> logSearch({
    required String userInput,
    int? matchedMenuItemId,
    required int guestId,
  }) async {
    try {
      final response = await ApiService.post('/menu/log-search', {
        'user_input': userInput,
        'matched_menu_item_id': matchedMenuItemId,
        'guest_id': guestId,
      });
      
      return {
        'success': response['return_code'] == 0,
        'message': response['message'] ?? 'Log search failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
  
  // Cancel any pending searches
  void cancelSearch() {
    _debounceTimer?.cancel();
  }
  
  // Dispose of resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}