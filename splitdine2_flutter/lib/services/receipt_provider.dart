import 'package:flutter/foundation.dart';
import '../models/receipt_item.dart';
import 'receipt_service.dart';

class ReceiptProvider with ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();
  
  List<ReceiptItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _summary;

  List<ReceiptItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get summary => _summary;

  double get subtotal => _summary?['subtotal']?.toDouble() ?? 0.0;
  int get totalItemCount => _summary?['item_count'] ?? 0;
  int get uniqueItemCount => _summary?['total_items'] ?? 0;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Load items for a session
  Future<bool> loadItems(int sessionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _receiptService.getItems(sessionId);

      if (result['success']) {
        _items = result['items'] as List<ReceiptItem>;
        _summary = result['summary'];
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to load items: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add new item
  Future<bool> addItem({
    required int sessionId,
    required String itemName,
    required double price,
    String? share,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _receiptService.addItem(
        sessionId: sessionId,
        itemName: itemName,
        price: price,
        share: share,
      );

      if (result['success']) {
        final newItem = result['item'] as ReceiptItem;
        _items.add(newItem);
        _updateSummary();
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to add item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing item
  Future<bool> updateItem({
    required int itemId,
    required String itemName,
    required double price,
    String? share,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _receiptService.updateItem(
        itemId: itemId,
        itemName: itemName,
        price: price,
        share: share,
      );

      if (result['success']) {
        final updatedItem = result['item'] as ReceiptItem;
        final index = _items.indexWhere((item) => item.id == itemId);
        if (index >= 0) {
          _items[index] = updatedItem;
          _updateSummary();
          notifyListeners();
        }
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete item
  Future<bool> deleteItem(int itemId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _receiptService.deleteItem(itemId);

      if (result['success']) {
        _items.removeWhere((item) => item.id == itemId);
        _updateSummary();
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update local summary calculations
  void _updateSummary() {
    final subtotal = _items.fold<double>(0.0, (sum, item) => sum + item.total);
    final itemCount = _items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    _summary = {
      'subtotal': subtotal,
      'item_count': itemCount,
      'total_items': _items.length,
    };
  }

  // Clear all items (useful when switching sessions)
  void clearItems() {
    _items.clear();
    _summary = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh items for current session
  Future<bool> refreshItems(int sessionId) async {
    return await loadItems(sessionId);
  }

  // Check if user can edit/delete a specific item
  bool canEditItem(ReceiptItem item, int currentUserId, bool isHost) {
    return isHost || item.addedByUserId == currentUserId;
  }

  // Get items added by a specific user
  List<ReceiptItem> getItemsByUser(int userId) {
    return _items.where((item) => item.addedByUserId == userId).toList();
  }

  // Get total amount for items added by a specific user
  double getTotalByUser(int userId) {
    return getItemsByUser(userId).fold<double>(0.0, (sum, item) => sum + item.total);
  }
}
