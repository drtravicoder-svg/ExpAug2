import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

enum NotificationType {
  expenseApproved,
  expenseRejected,
  expenseAdded,
  tripClosed,
  memberJoined,
  memberLeft,
  balanceUpdated,
  settlementRequired,
}

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    String? tripId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    @Default(false) bool read,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      tripId: data['tripId'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.expenseAdded,
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: data['data'] as Map<String, dynamic>?,
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }
}

extension AppNotificationExtensions on AppNotification {
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tripId': tripId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get typeDisplayName {
    switch (type) {
      case NotificationType.expenseApproved:
        return 'Expense Approved';
      case NotificationType.expenseRejected:
        return 'Expense Rejected';
      case NotificationType.expenseAdded:
        return 'New Expense';
      case NotificationType.tripClosed:
        return 'Trip Closed';
      case NotificationType.memberJoined:
        return 'Member Joined';
      case NotificationType.memberLeft:
        return 'Member Left';
      case NotificationType.balanceUpdated:
        return 'Balance Updated';
      case NotificationType.settlementRequired:
        return 'Settlement Required';
    }
  }
}

class NotificationFactory {
  static AppNotification expenseApproved({
    required String userId,
    required String tripId,
    required String expenseDescription,
    required double amount,
    required String currency,
  }) {
    return AppNotification(
      id: '',
      userId: userId,
      tripId: tripId,
      type: NotificationType.expenseApproved,
      title: 'Expense Approved',
      body: 'Your expense "$expenseDescription" for $currency $amount has been approved.',
      data: {
        'expenseDescription': expenseDescription,
        'amount': amount,
        'currency': currency,
      },
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  static AppNotification expenseRejected({
    required String userId,
    required String tripId,
    required String expenseDescription,
    required double amount,
    required String currency,
    String? reason,
  }) {
    return AppNotification(
      id: '',
      userId: userId,
      tripId: tripId,
      type: NotificationType.expenseRejected,
      title: 'Expense Rejected',
      body: 'Your expense "$expenseDescription" for $currency $amount has been rejected.' +
          (reason != null ? ' Reason: $reason' : ''),
      data: {
        'expenseDescription': expenseDescription,
        'amount': amount,
        'currency': currency,
        'reason': reason,
      },
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  static AppNotification newExpenseAdded({
    required String userId,
    required String tripId,
    required String expenseDescription,
    required double amount,
    required String currency,
    required String addedBy,
  }) {
    return AppNotification(
      id: '',
      userId: userId,
      tripId: tripId,
      type: NotificationType.expenseAdded,
      title: 'New Expense Added',
      body: '$addedBy added a new expense: "$expenseDescription" for $currency $amount.',
      data: {
        'expenseDescription': expenseDescription,
        'amount': amount,
        'currency': currency,
        'addedBy': addedBy,
      },
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  static AppNotification tripClosed({
    required String userId,
    required String tripId,
    required String tripName,
  }) {
    return AppNotification(
      id: '',
      userId: userId,
      tripId: tripId,
      type: NotificationType.tripClosed,
      title: 'Trip Closed',
      body: 'The trip "$tripName" has been closed. Final settlements are now available.',
      data: {
        'tripName': tripName,
      },
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 90)),
    );
  }
}
