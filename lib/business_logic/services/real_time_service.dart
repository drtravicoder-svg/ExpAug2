import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/firebase_config.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/expense.dart';
import '../../data/models/trip.dart';
import '../../data/models/user.dart';
import '../../data/models/notification.dart';

/// Service for managing real-time updates and live data synchronization
class RealTimeService {
  final FirebaseFirestore _firestore;
  final Map<String, StreamSubscription> _subscriptions = {};

  RealTimeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of real-time expense updates for a trip
  Stream<List<Expense>> getExpenseUpdates(String tripId) {
    try {
      return _firestore
          .collection(FirebaseConstants.expensesCollection)
          .where('tripId', isEqualTo: tripId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Stream of real-time trip updates
  Stream<Trip?> getTripUpdates(String tripId) {
    try {
      return _firestore
          .collection(FirebaseConstants.tripsCollection)
          .doc(tripId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return Trip.fromFirestore(doc);
        }
        return null;
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Stream of real-time user presence updates
  Stream<Map<String, UserPresence>> getUserPresenceUpdates(String tripId) {
    try {
      return _firestore
          .collection('presence')
          .where('tripId', isEqualTo: tripId)
          .snapshots()
          .map((snapshot) {
        final presenceMap = <String, UserPresence>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          presenceMap[doc.id] = UserPresence(
            userId: doc.id,
            isOnline: data['isOnline'] ?? false,
            lastSeen: data['lastSeen'] != null
                ? (data['lastSeen'] as Timestamp).toDate()
                : DateTime.now(),
            currentActivity: data['currentActivity'],
          );
        }
        return presenceMap;
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Stream of real-time notifications for a user
  Stream<List<AppNotification>> getNotificationUpdates(String userId) {
    try {
      return _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Stream of real-time balance updates for a trip
  Stream<Map<String, double>> getBalanceUpdates(String tripId) {
    try {
      return _firestore
          .collection('balances')
          .where('tripId', isEqualTo: tripId)
          .snapshots()
          .map((snapshot) {
        final balanceMap = <String, double>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          balanceMap[data['userId']] = (data['netBalance'] ?? 0.0).toDouble();
        }
        return balanceMap;
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Update user presence
  Future<void> updateUserPresence({
    required String userId,
    required String tripId,
    required bool isOnline,
    String? currentActivity,
  }) async {
    try {
      await _firestore.collection('presence').doc(userId).set({
        'tripId': tripId,
        'isOnline': isOnline,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
        'currentActivity': currentActivity,
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Send real-time notification
  Future<void> sendRealTimeNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? tripId,
    String? expenseId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        tripId: tripId,
        expenseId: expenseId,
        data: data ?? {},
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .add(notification.toFirestore());

      // Log analytics event
      await FirebaseConfig.logEvent(
        'notification_sent',
        {
          'type': type.toString(),
          'user_id': userId,
          'trip_id': tripId,
        },
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Broadcast expense update to all trip members
  Future<void> broadcastExpenseUpdate({
    required String tripId,
    required String expenseId,
    required String updatedBy,
    required ExpenseUpdateType updateType,
    required List<String> memberIds,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Create notifications for all members except the updater
      final membersToNotify = memberIds.where((id) => id != updatedBy).toList();

      for (final memberId in membersToNotify) {
        String title;
        String body;

        switch (updateType) {
          case ExpenseUpdateType.created:
            title = 'New Expense Added';
            body = 'A new expense was added to the trip';
            break;
          case ExpenseUpdateType.updated:
            title = 'Expense Updated';
            body = 'An expense was updated in the trip';
            break;
          case ExpenseUpdateType.approved:
            title = 'Expense Approved';
            body = 'Your expense has been approved';
            break;
          case ExpenseUpdateType.rejected:
            title = 'Expense Rejected';
            body = 'Your expense was rejected';
            break;
          case ExpenseUpdateType.deleted:
            title = 'Expense Deleted';
            body = 'An expense was deleted from the trip';
            break;
        }

        final notification = AppNotification(
          id: '',
          userId: memberId,
          title: title,
          body: body,
          type: NotificationType.expenseUpdated,
          tripId: tripId,
          expenseId: expenseId,
          data: {
            'updateType': updateType.toString(),
            'updatedBy': updatedBy,
          },
          isRead: false,
          createdAt: now,
        );

        final docRef = _firestore
            .collection(FirebaseConstants.notificationsCollection)
            .doc();
        batch.set(docRef, notification.toFirestore());
      }

      await batch.commit();

      // Log analytics event
      await FirebaseConfig.logEvent(
        'expense_broadcast',
        {
          'trip_id': tripId,
          'expense_id': expenseId,
          'update_type': updateType.toString(),
          'member_count': membersToNotify.length,
        },
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Subscribe to real-time updates with automatic cleanup
  void subscribeToUpdates(String subscriptionId, Stream stream, Function(dynamic) onData) {
    // Cancel existing subscription if any
    _subscriptions[subscriptionId]?.cancel();

    // Create new subscription
    _subscriptions[subscriptionId] = stream.listen(
      onData,
      onError: (error, stackTrace) {
        ErrorHandler.logError(error, stackTrace, context: 'Real-time subscription: $subscriptionId');
      },
    );
  }

  /// Unsubscribe from specific updates
  void unsubscribe(String subscriptionId) {
    _subscriptions[subscriptionId]?.cancel();
    _subscriptions.remove(subscriptionId);
  }

  /// Unsubscribe from all updates
  void unsubscribeAll() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Get connection status
  Stream<bool> getConnectionStatus() {
    return _firestore
        .collection('.info/connected')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      if (!kIsWeb) {
        await _firestore.enablePersistence();
      }
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Enable Offline Persistence');
    }
  }

  /// Dispose of all resources
  void dispose() {
    unsubscribeAll();
  }
}

/// User presence model
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final String? currentActivity;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    this.currentActivity,
  });

  bool get isRecentlyActive {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes < 5;
  }

  String get statusText {
    if (isOnline) return 'Online';
    if (isRecentlyActive) return 'Recently active';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Expense update types
enum ExpenseUpdateType {
  created,
  updated,
  approved,
  rejected,
  deleted,
}

/// Real-time event model
class RealTimeEvent {
  final String id;
  final String type;
  final String tripId;
  final String userId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const RealTimeEvent({
    required this.id,
    required this.type,
    required this.tripId,
    required this.userId,
    required this.data,
    required this.timestamp,
  });

  factory RealTimeEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RealTimeEvent(
      id: doc.id,
      type: data['type'] ?? '',
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'tripId': tripId,
      'userId': userId,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
