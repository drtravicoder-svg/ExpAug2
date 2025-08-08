import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/firebase_config.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/user.dart';
import 'real_time_service.dart';

/// Service for tracking user activities and live updates
class ActivityTrackerService {
  final FirebaseFirestore _firestore;
  final RealTimeService _realTimeService;
  
  Timer? _presenceTimer;
  String? _currentUserId;
  String? _currentTripId;
  String? _currentActivity;

  ActivityTrackerService({
    FirebaseFirestore? firestore,
    RealTimeService? realTimeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _realTimeService = realTimeService ?? RealTimeService();

  /// Start tracking user activity
  Future<void> startTracking({
    required String userId,
    required String tripId,
  }) async {
    try {
      _currentUserId = userId;
      _currentTripId = tripId;

      // Set user as online
      await _updatePresence(isOnline: true);

      // Start periodic presence updates
      _startPresenceTimer();

      // Log analytics event
      await FirebaseConfig.logEvent('activity_tracking_started', {
        'user_id': userId,
        'trip_id': tripId,
      });

      debugPrint('Activity tracking started for user: $userId');
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Stop tracking user activity
  Future<void> stopTracking() async {
    try {
      if (_currentUserId != null && _currentTripId != null) {
        // Set user as offline
        await _updatePresence(isOnline: false);

        // Log analytics event
        await FirebaseConfig.logEvent('activity_tracking_stopped', {
          'user_id': _currentUserId,
          'trip_id': _currentTripId,
        });
      }

      // Stop presence timer
      _presenceTimer?.cancel();
      _presenceTimer = null;

      _currentUserId = null;
      _currentTripId = null;
      _currentActivity = null;

      debugPrint('Activity tracking stopped');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Stop Activity Tracking');
    }
  }

  /// Update current activity
  Future<void> updateActivity(String activity) async {
    try {
      if (_currentUserId == null || _currentTripId == null) return;

      _currentActivity = activity;
      await _updatePresence(isOnline: true, activity: activity);

      // Log activity change
      await _logActivity(ActivityType.activityChanged, {
        'activity': activity,
      });

      debugPrint('Activity updated: $activity');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Update Activity');
    }
  }

  /// Track expense creation
  Future<void> trackExpenseCreated({
    required String expenseId,
    required String expenseTitle,
    required double amount,
  }) async {
    try {
      await _logActivity(ActivityType.expenseCreated, {
        'expense_id': expenseId,
        'expense_title': expenseTitle,
        'amount': amount,
      });

      await updateActivity('Creating expense');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Track Expense Created');
    }
  }

  /// Track expense update
  Future<void> trackExpenseUpdated({
    required String expenseId,
    required String expenseTitle,
  }) async {
    try {
      await _logActivity(ActivityType.expenseUpdated, {
        'expense_id': expenseId,
        'expense_title': expenseTitle,
      });

      await updateActivity('Updating expense');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Track Expense Updated');
    }
  }

  /// Track expense approval
  Future<void> trackExpenseApproved({
    required String expenseId,
    required String expenseTitle,
  }) async {
    try {
      await _logActivity(ActivityType.expenseApproved, {
        'expense_id': expenseId,
        'expense_title': expenseTitle,
      });

      await updateActivity('Reviewing expenses');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Track Expense Approved');
    }
  }

  /// Track page view
  Future<void> trackPageView(String pageName) async {
    try {
      await _logActivity(ActivityType.pageView, {
        'page_name': pageName,
      });

      await updateActivity('Viewing $pageName');
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Track Page View');
    }
  }

  /// Track user interaction
  Future<void> trackInteraction({
    required String action,
    String? target,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _logActivity(ActivityType.userInteraction, {
        'action': action,
        'target': target,
        ...?metadata,
      });
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Track Interaction');
    }
  }

  /// Get recent activities for a trip
  Stream<List<ActivityLog>> getRecentActivities(String tripId, {int limit = 20}) {
    try {
      return _firestore
          .collection('activities')
          .where('tripId', isEqualTo: tripId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => ActivityLog.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get user activities
  Stream<List<ActivityLog>> getUserActivities(String userId, {int limit = 50}) {
    try {
      return _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => ActivityLog.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Start presence timer
  void _startPresenceTimer() {
    _presenceTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updatePresence(isOnline: true);
    });
  }

  /// Update user presence
  Future<void> _updatePresence({
    required bool isOnline,
    String? activity,
  }) async {
    if (_currentUserId == null || _currentTripId == null) return;

    await _realTimeService.updateUserPresence(
      userId: _currentUserId!,
      tripId: _currentTripId!,
      isOnline: isOnline,
      currentActivity: activity ?? _currentActivity,
    );
  }

  /// Log activity
  Future<void> _logActivity(ActivityType type, Map<String, dynamic> data) async {
    if (_currentUserId == null || _currentTripId == null) return;

    try {
      final activity = ActivityLog(
        id: '',
        userId: _currentUserId!,
        tripId: _currentTripId!,
        type: type,
        data: data,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('activities').add(activity.toFirestore());

      // Log analytics event
      await FirebaseConfig.logEvent('user_activity', {
        'activity_type': type.toString(),
        'user_id': _currentUserId,
        'trip_id': _currentTripId,
        ...data,
      });
    } catch (error, stackTrace) {
      await ErrorHandler.logError(error, stackTrace, context: 'Log Activity');
    }
  }

  /// Dispose of resources
  void dispose() {
    stopTracking();
  }
}

/// Activity types
enum ActivityType {
  pageView,
  expenseCreated,
  expenseUpdated,
  expenseApproved,
  expenseRejected,
  expenseDeleted,
  tripUpdated,
  memberInvited,
  memberJoined,
  memberLeft,
  userInteraction,
  activityChanged,
}

/// Activity log model
class ActivityLog {
  final String id;
  final String userId;
  final String tripId;
  final ActivityType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const ActivityLog({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      tripId: data['tripId'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => ActivityType.userInteraction,
      ),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tripId': tripId,
      'type': type.toString(),
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  String get displayText {
    switch (type) {
      case ActivityType.expenseCreated:
        return 'Created expense "${data['expense_title']}"';
      case ActivityType.expenseUpdated:
        return 'Updated expense "${data['expense_title']}"';
      case ActivityType.expenseApproved:
        return 'Approved expense "${data['expense_title']}"';
      case ActivityType.expenseRejected:
        return 'Rejected expense "${data['expense_title']}"';
      case ActivityType.expenseDeleted:
        return 'Deleted expense "${data['expense_title']}"';
      case ActivityType.tripUpdated:
        return 'Updated trip details';
      case ActivityType.memberInvited:
        return 'Invited ${data['member_name']} to the trip';
      case ActivityType.memberJoined:
        return 'Joined the trip';
      case ActivityType.memberLeft:
        return 'Left the trip';
      case ActivityType.pageView:
        return 'Viewed ${data['page_name']}';
      case ActivityType.userInteraction:
        return 'Performed ${data['action']}';
      case ActivityType.activityChanged:
        return 'Changed activity to ${data['activity']}';
      default:
        return 'Performed an action';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
