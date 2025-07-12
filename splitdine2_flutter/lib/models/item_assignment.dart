class ItemAssignment {
  final int id;
  final int sessionId;
  final int itemId;
  final int userId;
  final String userName;
  final DateTime createdAt;

  ItemAssignment({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory ItemAssignment.fromJson(Map<String, dynamic> json) {
    return ItemAssignment(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      itemId: json['item_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'item_id': itemId,
      'user_id': userId,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ItemAssignment copyWith({
    int? id,
    int? sessionId,
    int? itemId,
    int? userId,
    String? userName,
    DateTime? createdAt,
  }) {
    return ItemAssignment(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ItemAssignment(id: $id, itemId: $itemId, userId: $userId, userName: $userName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemAssignment && 
           other.id == id &&
           other.itemId == itemId &&
           other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, itemId, userId);
}
