class SessionReceiptItem {
  final int id;
  final int sessionId;
  final String itemName;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionReceiptItem({
    required this.id,
    required this.sessionId,
    required this.itemName,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionReceiptItem.fromJson(Map<String, dynamic> json) {
    return SessionReceiptItem(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      itemName: json['item_name'] as String,
      price: _parsePrice(json['price']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _parsePrice(dynamic price) {
    if (price is num) {
      return price.toDouble();
    } else if (price is String) {
      return double.tryParse(price) ?? 0.0;
    } else {
      return 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'item_name': itemName,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SessionReceiptItem copyWith({
    int? id,
    int? sessionId,
    String? itemName,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionReceiptItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionReceiptItem &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.itemName == itemName &&
        other.price == price &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sessionId,
      itemName,
      price,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'SessionReceiptItem(id: $id, sessionId: $sessionId, itemName: $itemName, price: $price, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
