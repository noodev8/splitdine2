class SplitItemParticipant {
  final int userId;
  final String userName;
  final int assignmentId;

  SplitItemParticipant({
    required this.userId,
    required this.userName,
    required this.assignmentId,
  });

  factory SplitItemParticipant.fromJson(Map<String, dynamic> json) {
    return SplitItemParticipant(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      assignmentId: json['assignment_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'assignment_id': assignmentId,
    };
  }
}

class SplitItem {
  final int id;
  final int sessionId;
  final String name;
  final double price;
  final String? description;
  final int addedByUserId;
  final String addedByName;
  final int? guestId; // Keep for backward compatibility
  final List<SplitItemParticipant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  SplitItem({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.price,
    this.description,
    required this.addedByUserId,
    required this.addedByName,
    this.guestId,
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SplitItem.fromJson(Map<String, dynamic> json) {
    List<SplitItemParticipant> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => SplitItemParticipant.fromJson(p))
          .toList();
    }

    return SplitItem(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      name: json['name'] as String,
      price: double.parse((json['price'] ?? 0.0).toString()),
      description: json['description'] as String?,
      addedByUserId: json['added_by_user_id'] as int,
      addedByName: json['added_by_name'] as String,
      guestId: json['guest_id'] != null ? json['guest_id'] as int : null,
      participants: participants,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'name': name,
      'price': price,
      'description': description,
      'added_by_user_id': addedByUserId,
      'added_by_name': addedByName,
      'guest_id': guestId,
      'participants': participants.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SplitItem copyWith({
    int? id,
    int? sessionId,
    String? name,
    double? price,
    String? description,
    int? addedByUserId,
    String? addedByName,
    int? guestId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SplitItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedByName: addedByName ?? this.addedByName,
      guestId: guestId ?? this.guestId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SplitItem(id: $id, name: $name, price: $price, guestId: $guestId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SplitItem &&
        other.id == id &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ sessionId.hashCode;
  }
}
