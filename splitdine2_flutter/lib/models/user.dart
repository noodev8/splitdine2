class User {
  final int id;
  final String? email;
  final String displayName;
  final bool isAnonymous;

  User({
    required this.id,
    this.email,
    required this.displayName,
    required this.isAnonymous,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'],
      isAnonymous: json['is_anonymous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'is_anonymous': isAnonymous,
    };
  }
}
