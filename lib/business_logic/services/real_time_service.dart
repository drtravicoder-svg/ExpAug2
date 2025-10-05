// Firestore is not installed - all Firebase code is commented out
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import '../../core/config/firebase_config.dart';
// import '../../core/utils/error_handler.dart';
// import '../../data/models/expense.dart';
// import '../../data/models/trip.dart';
// import '../../data/models/user.dart';
// import '../../data/models/notification.dart';

/// Service for managing real-time updates and live data synchronization - DISABLED
/// This app uses SQLite and mock repositories instead of Firestore
class RealTimeService {
  RealTimeService() {
    print('ℹ️ RealTimeService is disabled - using SQLite and mock data');
  }
  
  // All Firestore code is commented out
  // final FirebaseFirestore _firestore;
  // final Map<String, StreamSubscription> _subscriptions = {};

  // RealTimeService({FirebaseFirestore? firestore})
  //     : _firestore = firestore ?? FirebaseFirestore.instance;

  // All methods are commented out...
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

// Real-time event model - disabled
// class RealTimeEvent {
//   final String id;
//   final String type;
//   final String tripId;
//   final String userId;
//   final Map<String, dynamic> data;
//   final DateTime timestamp;
//
//   const RealTimeEvent({
//     required this.id,
//     required this.type,
//     required this.tripId,
//     required this.userId,
//     required this.data,
//     required this.timestamp,
//   });
//
//   factory RealTimeEvent.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return RealTimeEvent(
//       id: doc.id,
//       type: data['type'] ?? '',
//       tripId: data['tripId'] ?? '',
//       userId: data['userId'] ?? '',
//       data: Map<String, dynamic>.from(data['data'] ?? {}),
//       timestamp: (data['timestamp'] as Timestamp).toDate(),
//     );
//   }
//
//   Map<String, dynamic> toFirestore() {
//     return {
//       'type': type,
//       'tripId': tripId,
//       'userId': userId,
//       'data': data,
//       'timestamp': Timestamp.fromDate(timestamp),
//     };
//   }
// }
