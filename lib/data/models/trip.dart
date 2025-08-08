import 'package:equatable/equatable.dart';
import 'trip_member.dart';

/// Trip status enumeration with SQLite-friendly values
enum TripStatus {
  planning,
  active,
  closed,
  archived
}

/// Enhanced Trip model with SQLite integration and additional features
class Trip extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? origin;
  final String? destination;
  final DateTime startDate;
  final DateTime endDate;
  final String currency;
  final TripStatus status;
  final String adminId;
  final List<TripMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TripSettings settings;
  final double budgetAmount;
  final bool isDeleted;

  const Trip({
    required this.id,
    required this.name,
    this.description,
    this.origin,
    this.destination,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.status,
    required this.adminId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
    this.budgetAmount = 0.0,
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    origin,
    destination,
    startDate,
    endDate,
    currency,
    status,
    adminId,
    members,
    createdAt,
    updatedAt,
    settings,
    budgetAmount,
    isDeleted,
  ];

  /// Create Trip from SQLite database map
  factory Trip.fromSQLite(Map<String, dynamic> data, List<TripMember> members) {
    return Trip(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      origin: data['origin'],
      destination: data['destination'],
      startDate: DateTime.parse(data['start_date']),
      endDate: DateTime.parse(data['end_date']),
      currency: data['currency'] ?? 'INR',
      status: TripStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TripStatus.planning,
      ),
      adminId: data['admin_id'] ?? '',
      members: members,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      settings: TripSettings(
        allowMemberCategories: data['allow_member_categories'] == 1,
        requireReceiptApproval: data['require_receipt_approval'] == 1,
        autoApproveExpenses: data['auto_approve_expenses'] == 1,
      ),
      budgetAmount: (data['budget_amount'] as num?)?.toDouble() ?? 0.0,
      isDeleted: data['is_deleted'] == 1,
    );
  }

  /// Create Trip from JSON (for API compatibility)
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      origin: json['origin'],
      destination: json['destination'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      currency: json['currency'] ?? 'INR',
      status: TripStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TripStatus.planning,
      ),
      adminId: json['adminId'] ?? '',
      members: (json['members'] as List<dynamic>?)
          ?.map((memberData) => TripMember.fromJson(memberData as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      settings: TripSettings.fromMap(json['settings'] ?? {}),
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  /// Convert Trip to SQLite-compatible map
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'origin': origin,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'currency': currency,
      'status': status.toString().split('.').last,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'allow_member_categories': settings.allowMemberCategories ? 1 : 0,
      'require_receipt_approval': settings.requireReceiptApproval ? 1 : 0,
      'auto_approve_expenses': settings.autoApproveExpenses ? 1 : 0,
      'budget_amount': budgetAmount,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Convert Trip to JSON (for API compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'origin': origin,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'currency': currency,
      'status': status.toString().split('.').last,
      'adminId': adminId,
      'members': members.map((member) => member.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'settings': settings.toMap(),
      'budgetAmount': budgetAmount,
      'isDeleted': isDeleted,
    };
  }

  // Enhanced helper methods with new fields

  /// Check if this trip is active
  bool get isActive => status == TripStatus.active;

  /// Check if this trip is in planning phase
  bool get isPlanning => status == TripStatus.planning;

  /// Check if this trip is closed
  bool get isClosed => status == TripStatus.closed;

  /// Check if this trip is archived
  bool get isArchived => status == TripStatus.archived;

  /// Get trip duration in days
  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Check if trip is currently ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && isActive;
  }

  /// Check if trip is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startDate);
  }

  /// Check if trip is past
  bool get isPast {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }

  /// Get member count
  int get memberCount => members.length;

  /// Check if user is admin of this trip
  bool isAdmin(String userId) => adminId == userId;

  /// Check if user is member of this trip
  bool isMember(String userId) => members.any((member) => member.id == userId);

  /// Add a member to the trip
  Trip addMember(TripMember member) {
    return copyWith(
      members: [...members, member],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a member from the trip
  Trip removeMember(String memberId) {
    return copyWith(
      members: members.where((member) => member.id != memberId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update trip status
  Trip updateStatus(TripStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Update trip budget
  Trip updateBudget(double newBudget) {
    return copyWith(
      budgetAmount: newBudget,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark trip as deleted (soft delete)
  Trip markAsDeleted() {
    return copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Restore deleted trip
  Trip restore() {
    return copyWith(
      isDeleted: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy of this trip with updated fields
  Trip copyWith({
    String? id,
    String? name,
    String? description,
    String? origin,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    TripStatus? status,
    String? adminId,
    List<TripMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    TripSettings? settings,
    double? budgetAmount,
    bool? isDeleted,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      adminId: adminId ?? this.adminId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      settings: settings ?? this.settings,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'Trip(id: $id, name: $name, status: $status, members: ${members.length}, budget: $budgetAmount)';
  }
}

/// Enhanced Trip Settings with SQLite integration
class TripSettings extends Equatable {
  final bool allowMemberCategories;
  final bool requireReceiptApproval;
  final bool autoApproveExpenses;

  const TripSettings({
    this.allowMemberCategories = false,
    this.requireReceiptApproval = true,
    this.autoApproveExpenses = false,
  });

  /// Create TripSettings from JSON/Map
  factory TripSettings.fromMap(Map<String, dynamic> map) {
    return TripSettings(
      allowMemberCategories: map['allowMemberCategories'] ?? false,
      requireReceiptApproval: map['requireReceiptApproval'] ?? true,
      autoApproveExpenses: map['autoApproveExpenses'] ?? false,
    );
  }

  /// Create TripSettings from SQLite integer values
  factory TripSettings.fromSQLite({
    required int allowMemberCategories,
    required int requireReceiptApproval,
    required int autoApproveExpenses,
  }) {
    return TripSettings(
      allowMemberCategories: allowMemberCategories == 1,
      requireReceiptApproval: requireReceiptApproval == 1,
      autoApproveExpenses: autoApproveExpenses == 1,
    );
  }

  /// Convert to JSON/Map
  Map<String, dynamic> toMap() {
    return {
      'allowMemberCategories': allowMemberCategories,
      'requireReceiptApproval': requireReceiptApproval,
      'autoApproveExpenses': autoApproveExpenses,
    };
  }

  /// Convert to SQLite integer values
  Map<String, int> toSQLiteMap() {
    return {
      'allow_member_categories': allowMemberCategories ? 1 : 0,
      'require_receipt_approval': requireReceiptApproval ? 1 : 0,
      'auto_approve_expenses': autoApproveExpenses ? 1 : 0,
    };
  }

  /// Create a copy with updated values
  TripSettings copyWith({
    bool? allowMemberCategories,
    bool? requireReceiptApproval,
    bool? autoApproveExpenses,
  }) {
    return TripSettings(
      allowMemberCategories: allowMemberCategories ?? this.allowMemberCategories,
      requireReceiptApproval: requireReceiptApproval ?? this.requireReceiptApproval,
      autoApproveExpenses: autoApproveExpenses ?? this.autoApproveExpenses,
    );
  }

  @override
  List<Object?> get props => [
    allowMemberCategories,
    requireReceiptApproval,
    autoApproveExpenses,
  ];

  @override
  String toString() {
    return 'TripSettings(allowMemberCategories: $allowMemberCategories, requireReceiptApproval: $requireReceiptApproval, autoApproveExpenses: $autoApproveExpenses)';
  }
}
