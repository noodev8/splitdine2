class Participant {
  final int id;
  final int sessionId;
  final int userId;
  final String displayName;
  final String? email;
  final String role;
  final DateTime joinedAt;
  final DateTime? leftAt;

  Participant({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.displayName,
    this.email,
    required this.role,
    required this.joinedAt,
    this.leftAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      userId: json['user_id'] as int,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'guest',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'display_name': displayName,
      'email': email,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
    };
  }

  Participant copyWith({
    int? id,
    int? sessionId,
    int? userId,
    String? displayName,
    String? email,
    String? role,
    DateTime? joinedAt,
    DateTime? leftAt,
  }) {
    return Participant(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
    );
  }

  @override
  String toString() {
    return 'Participant(id: $id, userId: $userId, displayName: $displayName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Participant &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ sessionId.hashCode ^ userId.hashCode;
  }
}
