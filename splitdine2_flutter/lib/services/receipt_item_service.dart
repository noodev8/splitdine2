import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/receipt_item.dart';

class ReceiptItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new receipt item
  Future<ReceiptItem?> createReceiptItem({
    required String sessionId,
    required String name,
    required double price,
    int quantity = 1,
    ItemCategory category = ItemCategory.food,
    String? description,
    double parsedConfidence = 0.0,
    bool manuallyEdited = false,
  }) async {
    try {
      final itemId = _firestore.collection('receiptItems').doc().id;
      
      final receiptItem = ReceiptItem(
        id: itemId,
        sessionId: sessionId,
        name: name,
        price: price,
        quantity: quantity,
        category: category,
        description: description,
        parsedConfidence: parsedConfidence,
        manuallyEdited: manuallyEdited,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('receiptItems').doc(itemId).set(receiptItem.toMap());
      return receiptItem;
    } catch (e) {
      print('Error creating receipt item: $e');
      return null;
    }
  }

  // Get receipt item by ID
  Future<ReceiptItem?> getReceiptItem(String itemId) async {
    try {
      final doc = await _firestore.collection('receiptItems').doc(itemId).get();
      if (doc.exists) {
        return ReceiptItem.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting receipt item: $e');
      return null;
    }
  }

  // Get all receipt items for a session
  Future<List<ReceiptItem>> getSessionReceiptItems(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('receiptItems')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs
          .map((doc) => ReceiptItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting session receipt items: $e');
      return [];
    }
  }

  // Stream receipt items for a session
  Stream<List<ReceiptItem>> sessionReceiptItemsStream(String sessionId) {
    return _firestore
        .collection('receiptItems')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReceiptItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update receipt item
  Future<void> updateReceiptItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('receiptItems').doc(itemId).update(updates);
    } catch (e) {
      print('Error updating receipt item: $e');
    }
  }

  // Update receipt item details
  Future<void> updateReceiptItemDetails({
    required String itemId,
    String? name,
    double? price,
    int? quantity,
    ItemCategory? category,
    String? description,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (quantity != null) updates['quantity'] = quantity;
      if (category != null) updates['category'] = category.name;
      if (description != null) updates['description'] = description;
      
      // Mark as manually edited if any changes are made
      if (updates.isNotEmpty) {
        updates['manuallyEdited'] = true;
      }

      await updateReceiptItem(itemId, updates);
    } catch (e) {
      print('Error updating receipt item details: $e');
    }
  }

  // Delete receipt item
  Future<void> deleteReceiptItem(String itemId) async {
    try {
      await _firestore.collection('receiptItems').doc(itemId).delete();
    } catch (e) {
      print('Error deleting receipt item: $e');
    }
  }

  // Bulk create receipt items from parsed data
  Future<List<ReceiptItem>> createReceiptItemsFromParsedData(
    String sessionId,
    List<Map<String, dynamic>> parsedItems,
  ) async {
    try {
      final List<ReceiptItem> createdItems = [];
      
      for (final itemData in parsedItems) {
        final receiptItem = await createReceiptItem(
          sessionId: sessionId,
          name: itemData['name'] ?? 'Unknown Item',
          price: (itemData['price'] ?? 0.0).toDouble(),
          quantity: itemData['quantity'] ?? 1,
          category: _parseCategory(itemData['category']),
          description: itemData['description'],
          parsedConfidence: (itemData['confidence'] ?? 0.0).toDouble(),
          manuallyEdited: false,
        );
        
        if (receiptItem != null) {
          createdItems.add(receiptItem);
        }
      }
      
      return createdItems;
    } catch (e) {
      print('Error creating receipt items from parsed data: $e');
      return [];
    }
  }

  // Helper method to parse category from string
  ItemCategory _parseCategory(String? categoryString) {
    if (categoryString == null) return ItemCategory.food;
    
    switch (categoryString.toLowerCase()) {
      case 'drink':
      case 'beverage':
        return ItemCategory.drink;
      case 'service':
        return ItemCategory.service;
      case 'other':
        return ItemCategory.other;
      default:
        return ItemCategory.food;
    }
  }

  // Get total amount for session items
  Future<double> getSessionItemsTotal(String sessionId) async {
    try {
      final items = await getSessionReceiptItems(sessionId);
      return items.fold(0.0, (total, item) => total + item.totalPrice);
    } catch (e) {
      print('Error calculating session items total: $e');
      return 0.0;
    }
  }

  // Get items by category for a session
  Future<Map<ItemCategory, List<ReceiptItem>>> getSessionItemsByCategory(String sessionId) async {
    try {
      final items = await getSessionReceiptItems(sessionId);
      final Map<ItemCategory, List<ReceiptItem>> categorizedItems = {};
      
      for (final category in ItemCategory.values) {
        categorizedItems[category] = [];
      }
      
      for (final item in items) {
        categorizedItems[item.category]?.add(item);
      }
      
      return categorizedItems;
    } catch (e) {
      print('Error getting session items by category: $e');
      return {};
    }
  }

  // Search receipt items by name
  Future<List<ReceiptItem>> searchReceiptItems(String sessionId, String searchTerm) async {
    try {
      final items = await getSessionReceiptItems(sessionId);
      final searchTermLower = searchTerm.toLowerCase();
      
      return items.where((item) {
        return item.name.toLowerCase().contains(searchTermLower) ||
               (item.description?.toLowerCase().contains(searchTermLower) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching receipt items: $e');
      return [];
    }
  }
}
