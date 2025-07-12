import 'package:flutter/foundation.dart';
import '../models/item_assignment.dart';
import '../models/receipt_item.dart';
import 'assignment_service.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();
  
  List<ItemAssignment> _assignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ItemAssignment> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Load assignments for a session
  Future<bool> loadSessionAssignments(int sessionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _assignmentService.getSessionAssignments(sessionId);

      if (result['success']) {
        _assignments = result['assignments'] as List<ItemAssignment>;
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to load assignments: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Assign item to user
  Future<bool> assignItem(int sessionId, int itemId, int userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _assignmentService.assignItem(
        sessionId: sessionId,
        itemId: itemId,
        userId: userId,
      );

      if (result['success']) {
        final newAssignment = result['assignment'] as ItemAssignment;
        _assignments.add(newAssignment);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to assign item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Unassign item from user
  Future<bool> unassignItem(int sessionId, int itemId, int userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _assignmentService.unassignItem(
        sessionId: sessionId,
        itemId: itemId,
        userId: userId,
      );

      if (result['success']) {
        _assignments.removeWhere((assignment) => 
            assignment.itemId == itemId && assignment.userId == userId);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to unassign item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get assignments for a specific item
  List<ItemAssignment> getItemAssignments(int itemId) {
    return _assignments.where((assignment) => assignment.itemId == itemId).toList();
  }

  // Get assignments for a specific user
  List<ItemAssignment> getUserAssignments(int userId) {
    return _assignments.where((assignment) => assignment.userId == userId).toList();
  }

  // Check if an item is assigned to a specific user
  bool isItemAssignedToUser(int itemId, int userId) {
    return _assignments.any((assignment) => 
        assignment.itemId == itemId && assignment.userId == userId);
  }

  // Get total assigned amount for a user
  double getUserAssignedTotal(int userId, List<ReceiptItem> items) {
    final userAssignments = getUserAssignments(userId);
    double total = 0.0;
    
    for (final assignment in userAssignments) {
      final item = items.firstWhere(
        (item) => item.id == assignment.itemId,
        orElse: () => ReceiptItem(
          id: 0, sessionId: 0, itemName: '', price: 0.0, quantity: 0,
          addedByUserId: 0, addedByName: '', 
          createdAt: DateTime.now(), updatedAt: DateTime.now()
        ),
      );
      if (item.id != 0) {
        // Calculate proportional amount if item is shared
        final itemAssignments = getItemAssignments(assignment.itemId);
        final shareCount = itemAssignments.length;
        total += shareCount > 0 ? item.total / shareCount : item.total;
      }
    }
    
    return total;
  }

  // Get total allocated amount across all assignments
  double getTotalAllocatedAmount(List<ReceiptItem> items) {
    double total = 0.0;
    final processedItems = <int>{};
    
    for (final assignment in _assignments) {
      if (!processedItems.contains(assignment.itemId)) {
        final item = items.firstWhere(
          (item) => item.id == assignment.itemId,
          orElse: () => ReceiptItem(
            id: 0, sessionId: 0, itemName: '', price: 0.0, quantity: 0,
            addedByUserId: 0, addedByName: '', 
            createdAt: DateTime.now(), updatedAt: DateTime.now()
          ),
        );
        if (item.id != 0) {
          total += item.total;
          processedItems.add(assignment.itemId);
        }
      }
    }
    
    return total;
  }

  // Get unallocated items
  List<ReceiptItem> getUnallocatedItems(List<ReceiptItem> items) {
    final allocatedItemIds = _assignments.map((a) => a.itemId).toSet();
    return items.where((item) => !allocatedItemIds.contains(item.id)).toList();
  }

  // Clear all assignments (useful when switching sessions)
  void clearAssignments() {
    _assignments.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh assignments for current session
  Future<bool> refreshAssignments(int sessionId) async {
    return await loadSessionAssignments(sessionId);
  }
}
