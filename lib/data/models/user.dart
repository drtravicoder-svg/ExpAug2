import 'package:equatable/equatable.dart';

enum UserRole { admin, member }

class UserPreferences extends Equatable {
  final String currency;
  final bool notificationsEnabled;
  final String language;

  const UserPreferences({
    this.currency = 'USD',
    this.notificationsEnabled = true,
    this.language = 'en',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      currency: json['currency'] ?? 'USD',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
    };
  }

  UserPreferences copyWith({
    String? currency,
    bool? notificationsEnabled,
    String? language,
  }) {
    return UserPreferences(
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [currency, notificationsEnabled, language];
}

class User extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserPreferences preferences;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    this.phone,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences = const UserPreferences(),
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      displayName: json['displayName'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.member,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'])
          : const UserPreferences(),
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences.toJson(),
      'avatarUrl': avatarUrl,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Helper getters
  bool get isAdmin => role == UserRole.admin;
  bool get isMember => role == UserRole.member;
  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
    id,
    email,
    phone,
    displayName,
    role,
    createdAt,
    lastLoginAt,
    preferences,
    avatarUrl,
  ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, role: $role)';
  }
}
