class ReceiptItem {
  final int id;
  final int sessionId;
  final String itemName;
  final double price;
  final int quantity;
  final int addedByUserId;
  final String addedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceiptItem({
    required this.id,
    required this.sessionId,
    required this.itemName,
    required this.price,
    required this.quantity,
    required this.addedByUserId,
    required this.addedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  double get total => price * quantity;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      itemName: json['item_name'] as String,
      price: double.parse((json['price'] ?? 0.0).toString()),
      quantity: json['quantity'] as int,
      addedByUserId: json['added_by_user_id'] as int,
      addedByName: json['added_by_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
      'added_by_user_id': addedByUserId,
      'added_by_name': addedByName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReceiptItem copyWith({
    int? id,
    int? sessionId,
    String? itemName,
    double? price,
    int? quantity,
    int? addedByUserId,
    String? addedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedByName: addedByName ?? this.addedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReceiptItem(id: $id, itemName: $itemName, price: $price, quantity: $quantity, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
