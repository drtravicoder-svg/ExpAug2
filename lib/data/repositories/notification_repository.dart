import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import '../../core/utils/error_handler.dart';
import '../../core/config/firebase_config.dart';

/// Repository for managing user notifications
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get notifications for a user
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    try {
      return _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to recent 50 notifications
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    try {
      return _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Create a new notification
  Future<AppNotification> createNotification(AppNotification notification) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .add(notification.toFirestore());
      
      final doc = await docRef.get();
      return AppNotification.fromFirestore(doc);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final unreadNotifications = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final userNotifications = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Send notification to multiple users
  Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    String? tripId,
    String? expenseId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final userId in userIds) {
        final notification = AppNotification(
          id: '', // Will be set by Firestore
          userId: userId,
          title: title,
          body: body,
          type: type,
          tripId: tripId,
          expenseId: expenseId,
          data: data ?? {},
          isRead: false,
          createdAt: now,
        );

        final docRef = _firestore
            .collection(FirebaseConstants.notificationsCollection)
            .doc();
        batch.set(docRef, notification.toFirestore());
      }

      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get notifications by type
  Stream<List<AppNotification>> getNotificationsByType(
    String userId,
    NotificationType type,
  ) {
    try {
      return _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toString())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get trip-related notifications
  Stream<List<AppNotification>> getTripNotifications(String userId, String tripId) {
    try {
      return _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('tripId', isEqualTo: tripId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Clean up old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Create expense-related notifications
  Future<void> createExpenseNotifications({
    required String expenseId,
    required String tripId,
    required String createdBy,
    required List<String> memberIds,
    required String expenseTitle,
    required double amount,
    required NotificationType type,
  }) async {
    try {
      final notifications = <AppNotification>[];
      final now = DateTime.now();

      // Don't notify the creator
      final membersToNotify = memberIds.where((id) => id != createdBy).toList();

      for (final memberId in membersToNotify) {
        String title;
        String body;

        switch (type) {
          case NotificationType.expenseAdded:
            title = 'New Expense Added';
            body = 'New expense "$expenseTitle" (\$${amount.toStringAsFixed(2)}) was added to the trip';
            break;
          case NotificationType.expenseUpdated:
            title = 'Expense Updated';
            body = 'Expense "$expenseTitle" was updated';
            break;
          case NotificationType.expenseApproved:
            title = 'Expense Approved';
            body = 'Expense "$expenseTitle" has been approved';
            break;
          case NotificationType.expenseRejected:
            title = 'Expense Rejected';
            body = 'Expense "$expenseTitle" was rejected';
            break;
          default:
            title = 'Expense Update';
            body = 'There was an update to expense "$expenseTitle"';
        }

        notifications.add(AppNotification(
          id: '',
          userId: memberId,
          title: title,
          body: body,
          type: type,
          tripId: tripId,
          expenseId: expenseId,
          data: {
            'expenseTitle': expenseTitle,
            'amount': amount,
            'createdBy': createdBy,
          },
          isRead: false,
          createdAt: now,
        ));
      }

      // Batch create notifications
      if (notifications.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final notification in notifications) {
          final docRef = _firestore
              .collection(FirebaseConstants.notificationsCollection)
              .doc();
          batch.set(docRef, notification.toFirestore());
        }

        await batch.commit();
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Create trip-related notifications
  Future<void> createTripNotifications({
    required String tripId,
    required String createdBy,
    required List<String> memberIds,
    required String tripName,
    required NotificationType type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notifications = <AppNotification>[];
      final now = DateTime.now();

      // Don't notify the creator
      final membersToNotify = memberIds.where((id) => id != createdBy).toList();

      for (final memberId in membersToNotify) {
        String title;
        String body;

        switch (type) {
          case NotificationType.tripInvitation:
            title = 'Trip Invitation';
            body = 'You\'ve been invited to join "$tripName" trip';
            break;
          case NotificationType.tripUpdated:
            title = 'Trip Updated';
            body = 'Trip "$tripName" has been updated';
            break;
          case NotificationType.memberJoined:
            title = 'New Member Joined';
            body = 'A new member joined "$tripName" trip';
            break;
          case NotificationType.memberLeft:
            title = 'Member Left';
            body = 'A member left "$tripName" trip';
            break;
          default:
            title = 'Trip Update';
            body = 'There was an update to "$tripName" trip';
        }

        notifications.add(AppNotification(
          id: '',
          userId: memberId,
          title: title,
          body: body,
          type: type,
          tripId: tripId,
          data: {
            'tripName': tripName,
            'createdBy': createdBy,
            ...?additionalData,
          },
          isRead: false,
          createdAt: now,
        ));
      }

      // Batch create notifications
      if (notifications.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final notification in notifications) {
          final docRef = _firestore
              .collection(FirebaseConstants.notificationsCollection)
              .doc();
          batch.set(docRef, notification.toFirestore());
        }

        await batch.commit();
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }
}
