class User {
  final int id;
  final String? email;
  final String displayName;
  final bool isAnonymous;
  final bool emailVerified;

  User({
    required this.id,
    this.email,
    required this.displayName,
    required this.isAnonymous,
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'],
      isAnonymous: json['is_anonymous'] ?? false,
      emailVerified: json['email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'is_anonymous': isAnonymous,
      'email_verified': emailVerified,
    };
  }
}
