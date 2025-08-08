import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

/// Member role enumeration
enum MemberRole {
  admin,
  member
}

/// Enhanced Trip Member model with SQLite integration
class TripMember extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? contactId; // For linking to device contacts
  final bool isFromContacts;
  final MemberRole role;
  final DateTime joinedAt;
  final bool isActive;

  const TripMember({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.contactId,
    this.isFromContacts = false,
    this.role = MemberRole.member,
    required this.joinedAt,
    this.isActive = true,
  });

  /// Create TripMember from SQLite database map
  factory TripMember.fromSQLite(Map<String, dynamic> data) {
    return TripMember(
      id: data['id'],
      name: data['name'],
      phone: data['phone'],
      email: data['email'],
      contactId: data['contact_id'],
      isFromContacts: data['is_from_contacts'] == 1,
      role: MemberRole.values.firstWhere(
        (e) => e.toString().split('.').last == (data['role'] ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      joinedAt: DateTime.parse(data['joined_at']),
      isActive: data['is_active'] == 1,
    );
  }

  /// Create TripMember from JSON
  factory TripMember.fromJson(Map<String, dynamic> json) {
    return TripMember(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      contactId: json['contactId'] as String?,
      isFromContacts: json['isFromContacts'] as bool? ?? false,
      role: MemberRole.values.firstWhere(
        (e) => e.toString().split('.').last == (json['role'] ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to SQLite-compatible map
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'contact_id': contactId,
      'is_from_contacts': isFromContacts ? 1 : 0,
      'role': role.toString().split('.').last,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'contactId': contactId,
      'isFromContacts': isFromContacts,
      'role': role.toString().split('.').last,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Factory constructor for creating a new member
  factory TripMember.create({
    required String name,
    required String phone,
    String? email,
    String? contactId,
    bool isFromContacts = false,
    MemberRole role = MemberRole.member,
  }) {
    return TripMember(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      email: email,
      contactId: contactId,
      isFromContacts: isFromContacts,
      role: role,
      joinedAt: DateTime.now(),
      isActive: true,
    );
  }

  /// Helper getters
  bool get isAdmin => role == MemberRole.admin;
  bool get isMember => role == MemberRole.member;

  /// Formatted phone display
  String get formattedPhone {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  /// Get display name with role indicator
  String get displayNameWithRole {
    return isAdmin ? '$name (Admin)' : name;
  }

  /// Create a copy with updated fields
  TripMember copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? contactId,
    bool? isFromContacts,
    MemberRole? role,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return TripMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      contactId: contactId ?? this.contactId,
      isFromContacts: isFromContacts ?? this.isFromContacts,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Deactivate member (soft delete)
  TripMember deactivate() {
    return copyWith(isActive: false);
  }

  /// Activate member
  TripMember activate() {
    return copyWith(isActive: true);
  }

  /// Promote to admin
  TripMember promoteToAdmin() {
    return copyWith(role: MemberRole.admin);
  }

  /// Demote to member
  TripMember demoteToMember() {
    return copyWith(role: MemberRole.member);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    contactId,
    isFromContacts,
    role,
    joinedAt,
    isActive,
  ];

  @override
  String toString() {
    return 'TripMember(id: $id, name: $name, phone: $phone, role: $role, active: $isActive)';
  }
}
