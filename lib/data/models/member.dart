import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
class Member with _$Member {
  const factory Member({
    required String id,
    required String tripId,
    required String userId,
    required String displayName,
    required String email,
    String? phone,
    @Default(0) int dependentsCount,
    required DateTime joinedAt,
    @Default(true) bool isActive,
    @Default([]) List<String> permissions,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      dependentsCount: data['dependentsCount'] ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      permissions: List<String>.from(data['permissions'] ?? []),
    );
  }
}

@freezed
class Dependent with _$Dependent {
  const factory Dependent({
    required String id,
    required String parentMemberId,
    required String name,
    required String relationship,
    int? age,
    required DateTime createdAt,
  }) = _Dependent;

  factory Dependent.fromJson(Map<String, dynamic> json) => _$DependentFromJson(json);

  factory Dependent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dependent(
      id: doc.id,
      parentMemberId: data['parentMemberId'] ?? '',
      name: data['name'] ?? '',
      relationship: data['relationship'] ?? '',
      age: data['age'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

extension MemberExtensions on Member {
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'dependentsCount': dependentsCount,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'permissions': permissions,
    };
  }

  int get totalParticipants => 1 + dependentsCount;
}

extension DependentExtensions on Dependent {
  Map<String, dynamic> toFirestore() {
    return {
      'parentMemberId': parentMemberId,
      'name': name,
      'relationship': relationship,
      'age': age,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
