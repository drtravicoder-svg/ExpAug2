import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/balance.dart';
import '../models/expense.dart';
import '../../core/utils/error_handler.dart';

/// Repository for managing user balances and settlements
class BalanceRepository {
  final FirebaseFirestore _firestore;

  BalanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get balance for a specific user in a trip
  Future<Balance?> getUserBalance(String tripId, String userId) async {
    try {
      final doc = await _firestore
          .collection('balances')
          .doc('${tripId}_$userId')
          .get();
      
      if (doc.exists) {
        return Balance.fromFirestore(doc);
      }
      return null;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get all balances for a trip
  Stream<List<Balance>> getTripBalances(String tripId) {
    try {
      return _firestore
          .collection('balances')
          .where('tripId', isEqualTo: tripId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Balance.fromFirestore(doc)).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Create or update user balance
  Future<void> updateUserBalance(Balance balance) async {
    try {
      await _firestore
          .collection('balances')
          .doc('${balance.tripId}_${balance.userId}')
          .set(balance.toFirestore(), SetOptions(merge: true));
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Calculate and update balances for a trip based on expenses
  Future<void> recalculateBalances(String tripId, List<Expense> expenses) async {
    try {
      final batch = _firestore.batch();
      final userBalances = <String, Balance>{};

      // Initialize balances for all users involved
      final allUserIds = <String>{};
      for (final expense in expenses) {
        allUserIds.add(expense.paidBy);
        allUserIds.addAll(expense.splitBetween.keys);
      }

      for (final userId in allUserIds) {
        userBalances[userId] = Balance(
          id: '${tripId}_$userId',
          tripId: tripId,
          userId: userId,
          totalPaid: 0.0,
          totalOwed: 0.0,
          netBalance: 0.0,
          lastUpdated: DateTime.now(),
        );
      }

      // Calculate balances from expenses
      for (final expense in expenses) {
        if (expense.status != ExpenseStatus.committed) continue;

        // Add to paid amount for the payer
        final payer = userBalances[expense.paidBy]!;
        userBalances[expense.paidBy] = payer.copyWith(
          totalPaid: payer.totalPaid + expense.amount,
        );

        // Add to owed amounts for split participants
        for (final entry in expense.splitBetween.entries) {
          final userId = entry.key;
          final owedAmount = entry.value;
          
          final user = userBalances[userId]!;
          userBalances[userId] = user.copyWith(
            totalOwed: user.totalOwed + owedAmount,
          );
        }
      }

      // Calculate net balances and save
      for (final balance in userBalances.values) {
        final netBalance = balance.totalPaid - balance.totalOwed;
        final updatedBalance = balance.copyWith(
          netBalance: netBalance,
          lastUpdated: DateTime.now(),
        );

        final docRef = _firestore
            .collection('balances')
            .doc('${tripId}_${balance.userId}');
        batch.set(docRef, updatedBalance.toFirestore());
      }

      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get settlement suggestions for a trip
  Future<List<Settlement>> getSettlementSuggestions(String tripId) async {
    try {
      final balances = await getTripBalances(tripId).first;
      return _calculateSettlements(balances);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Calculate optimal settlements to minimize transactions
  List<Settlement> _calculateSettlements(List<Balance> balances) {
    final settlements = <Settlement>[];
    
    // Separate creditors (positive balance) and debtors (negative balance)
    final creditors = balances.where((b) => b.netBalance > 0.01).toList();
    final debtors = balances.where((b) => b.netBalance < -0.01).toList();
    
    // Sort by amount (largest first)
    creditors.sort((a, b) => b.netBalance.compareTo(a.netBalance));
    debtors.sort((a, b) => a.netBalance.compareTo(b.netBalance));
    
    int creditorIndex = 0;
    int debtorIndex = 0;
    
    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      
      final creditAmount = creditor.netBalance;
      final debtAmount = -debtor.netBalance;
      final settlementAmount = creditAmount < debtAmount ? creditAmount : debtAmount;
      
      if (settlementAmount > 0.01) {
        settlements.add(Settlement(
          fromUserId: debtor.userId,
          toUserId: creditor.userId,
          amount: settlementAmount,
          tripId: creditor.tripId,
        ));
        
        // Update balances
        creditors[creditorIndex] = creditor.copyWith(
          netBalance: creditor.netBalance - settlementAmount,
        );
        debtors[debtorIndex] = debtor.copyWith(
          netBalance: debtor.netBalance + settlementAmount,
        );
      }
      
      // Move to next creditor or debtor
      if (creditors[creditorIndex].netBalance <= 0.01) {
        creditorIndex++;
      }
      if (debtors[debtorIndex].netBalance >= -0.01) {
        debtorIndex++;
      }
    }
    
    return settlements;
  }

  /// Mark settlement as completed
  Future<void> markSettlementCompleted(Settlement settlement) async {
    try {
      // Create settlement record
      await _firestore.collection('settlements').add({
        'tripId': settlement.tripId,
        'fromUserId': settlement.fromUserId,
        'toUserId': settlement.toUserId,
        'amount': settlement.amount,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'status': 'completed',
      });

      // Update balances to reflect the settlement
      final batch = _firestore.batch();
      
      // Update payer balance
      final payerDoc = _firestore
          .collection('balances')
          .doc('${settlement.tripId}_${settlement.fromUserId}');
      batch.update(payerDoc, {
        'netBalance': FieldValue.increment(settlement.amount),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
      
      // Update receiver balance
      final receiverDoc = _firestore
          .collection('balances')
          .doc('${settlement.tripId}_${settlement.toUserId}');
      batch.update(receiverDoc, {
        'netBalance': FieldValue.increment(-settlement.amount),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
      
      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get settlement history for a trip
  Stream<List<CompletedSettlement>> getSettlementHistory(String tripId) {
    try {
      return _firestore
          .collection('settlements')
          .where('tripId', isEqualTo: tripId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return CompletedSettlement(
            id: doc.id,
            tripId: data['tripId'],
            fromUserId: data['fromUserId'],
            toUserId: data['toUserId'],
            amount: data['amount'].toDouble(),
            completedAt: (data['completedAt'] as Timestamp).toDate(),
          );
        }).toList();
      });
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Delete all balances for a trip
  Future<void> deleteTripBalances(String tripId) async {
    try {
      final batch = _firestore.batch();
      
      final balances = await _firestore
          .collection('balances')
          .where('tripId', isEqualTo: tripId)
          .get();
      
      for (final doc in balances.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }
}

/// Settlement suggestion model
class Settlement {
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String tripId;

  const Settlement({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.tripId,
  });
}

/// Completed settlement model
class CompletedSettlement {
  final String id;
  final String tripId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime completedAt;

  const CompletedSettlement({
    required this.id,
    required this.tripId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.completedAt,
  });
}
