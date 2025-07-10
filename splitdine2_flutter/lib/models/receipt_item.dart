import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCategory { food, drink, service, other }

class ReceiptItem {
  final String id;
  final String sessionId;
  final String name;
  final double price;
  final int quantity;
  final ItemCategory category;
  final String? description;
  final double parsedConfidence;
  final bool manuallyEdited;
  final DateTime createdAt;

  ReceiptItem({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category = ItemCategory.food,
    this.description,
    this.parsedConfidence = 0.0,
    this.manuallyEdited = false,
    required this.createdAt,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category.name,
      'description': description,
      'parsedConfidence': parsedConfidence,
      'manuallyEdited': manuallyEdited,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map, String documentId) {
    return ReceiptItem(
      id: documentId,
      sessionId: map['sessionId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      category: ItemCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ItemCategory.food,
      ),
      description: map['description'],
      parsedConfidence: (map['parsedConfidence'] ?? 0.0).toDouble(),
      manuallyEdited: map['manuallyEdited'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ReceiptItem copyWith({
    String? sessionId,
    String? name,
    double? price,
    int? quantity,
    ItemCategory? category,
    String? description,
    double? parsedConfidence,
    bool? manuallyEdited,
  }) {
    return ReceiptItem(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      description: description ?? this.description,
      parsedConfidence: parsedConfidence ?? this.parsedConfidence,
      manuallyEdited: manuallyEdited ?? this.manuallyEdited,
      createdAt: createdAt,
    );
  }
}
