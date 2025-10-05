// Firebase/Firestore is not installed - balance repository is disabled
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/balance.dart';
import '../models/expense.dart';
// import '../../core/utils/error_handler.dart';

/// Repository for managing user balances and settlements - DISABLED (Firebase not installed)
/// This app uses SQLite and mock data instead
class BalanceRepository {
  BalanceRepository() {
    print('ℹ️ BalanceRepository is disabled - Firebase not installed');
  }
  
  // All Firebase/Firestore code is commented out
  // Use local SQLite database for balance calculations instead
}

/// Settlement model
class Settlement {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const Settlement({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'amount': amount,
  };
}
