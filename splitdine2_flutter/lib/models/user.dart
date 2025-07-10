import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  final double defaultTipPercentage;
  final bool notifications;

  UserPreferences({
    this.defaultTipPercentage = 15.0,
    this.notifications = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'defaultTipPercentage': defaultTipPercentage,
      'notifications': notifications,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      defaultTipPercentage: (map['defaultTipPercentage'] ?? 15.0).toDouble(),
      notifications: map['notifications'] ?? true,
    );
  }
}

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final List<String>? paymentMethods;
  final UserPreferences preferences;

  AppUser({
    required this.id,
    this.email,
    this.phone,
    required this.displayName,
    this.isAnonymous = false,
    required this.createdAt,
    required this.lastActiveAt,
    this.paymentMethods,
    UserPreferences? preferences,
  }) : preferences = preferences ?? UserPreferences();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'paymentMethods': paymentMethods,
      'preferences': preferences.toMap(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      id: documentId,
      email: map['email'],
      phone: map['phone'],
      displayName: map['displayName'] ?? 'User',
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethods: map['paymentMethods'] != null
          ? List<String>.from(map['paymentMethods'])
          : null,
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
    );
  }

  AppUser copyWith({
    String? email,
    String? phone,
    String? displayName,
    bool? isAnonymous,
    DateTime? lastActiveAt,
    List<String>? paymentMethods,
    UserPreferences? preferences,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      preferences: preferences ?? this.preferences,
    );
  }
}
