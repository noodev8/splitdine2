import 'package:flutter/foundation.dart';
import 'package:splitdine2_flutter/models/split_item.dart';
import 'package:splitdine2_flutter/services/split_item_service.dart';

class SplitItemProvider with ChangeNotifier {
  final SplitItemService _splitItemService = SplitItemService();
  
  List<SplitItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _summary;

  List<SplitItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get summary => _summary;
  double get subtotal {
    final subtotalValue = _summary?['subtotal'];
    if (subtotalValue == null) return 0.0;
    if (subtotalValue is double) return subtotalValue;
    if (subtotalValue is int) return subtotalValue.toDouble();
    if (subtotalValue is String) return double.tryParse(subtotalValue) ?? 0.0;
    return 0.0;
  }
  int get itemCount => _summary?['item_count'] ?? 0;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Load split items for a session
  Future<void> loadItems(int sessionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _splitItemService.getSplitItems(sessionId);

      if (result['success']) {
        _items = result['items'] as List<SplitItem>;
        _summary = result['summary'];
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Failed to load split items: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add split item
  Future<bool> addItem({
    required int sessionId,
    required String name,
    required double price,
    String? description,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _splitItemService.addSplitItem(
        sessionId: sessionId,
        name: name,
        price: price,
        description: description,
      );

      if (result['success']) {
        final newItem = result['splitItem'] as SplitItem;
        _items.insert(0, newItem); // Add to beginning of list
        _updateSummary();
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to add split item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update split item
  Future<bool> updateItem({
    required int itemId,
    required String name,
    required double price,
    String? description,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _splitItemService.updateSplitItem(
        itemId: itemId,
        name: name,
        price: price,
        description: description,
      );

      if (result['success']) {
        final updatedItem = result['splitItem'] as SplitItem;
        final index = _items.indexWhere((item) => item.id == itemId);
        if (index != -1) {
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
      _setError('Failed to update split item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete split item
  Future<bool> deleteItem(int itemId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _splitItemService.deleteSplitItem(itemId);

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
      _setError('Failed to delete split item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add participant to split item
  Future<bool> addParticipant({
    required int itemId,
    required int userId,
    required int sessionId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _splitItemService.addParticipant(
        itemId: itemId,
        userId: userId,
      );

      if (result['success']) {
        // Refresh the items to get updated participant list
        await loadItems(sessionId);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to add participant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove participant from split item
  Future<bool> removeParticipant(int itemId, int userId, int sessionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _splitItemService.removeParticipant(itemId, userId);

      if (result['success']) {
        // Refresh the items to get updated participant list
        await loadItems(sessionId);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to remove participant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update summary calculations
  void _updateSummary() {
    final subtotal = _items.fold(0.0, (sum, item) => sum + item.price);
    final itemCount = _items.length;

    _summary = {
      'subtotal': subtotal,
      'item_count': itemCount,
    };
  }

  // Clear all data
  void clear() {
    _items.clear();
    _summary = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
