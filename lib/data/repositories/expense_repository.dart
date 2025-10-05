// Firebase Firestore integration disabled (not installed)
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

/// Expense Repository - Firebase Firestore implementation (currently disabled)
/// Use MockExpenseRepository for testing without Firebase
class ExpenseRepository {
  // final FirebaseFirestore _firestore;

  ExpenseRepository();
  // ExpenseRepository({
  //   FirebaseFirestore? firestore
  // }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // All Firebase methods are commented out until Firebase is installed
  
  /*
  Stream<List<Expense>> getRecentExpenses(String tripId, {int limit = 5}) {
    return _firestore
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }

  Future<Expense> createExpense(Expense expense) async {
    final docRef = await _firestore.collection('expenses').add(expense.toMap());
    final doc = await docRef.get();
    return Expense.fromFirestore(doc);
  }

  Future<void> updateExpense(Expense expense) async {
    await _firestore.collection('expenses').doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  Stream<List<Expense>> getTripExpenses(String tripId) {
    return _firestore
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }

  Stream<Expense?> getExpenseById(String expenseId) {
    return _firestore
        .collection('expenses')
        .doc(expenseId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Expense.fromFirestore(doc);
      }
      return null;
    });
  }

  Stream<List<Expense>> getPendingExpenses(String tripId) {
    return _firestore
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }

  Future<void> approveExpense(String expenseId, String approvedBy) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'status': 'approved', // Fixed: was 'committed'
      'approvedBy': approvedBy,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> rejectExpense(String expenseId, String rejectedBy, String? reason) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'status': 'rejected',
      'rejectedBy': rejectedBy,
      'rejectedAt': Timestamp.fromDate(DateTime.now()),
      'adminComment': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<Expense>> getUserExpenses(String userId) {
    return _firestore
        .collection('expenses')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Expense>> getExpensesPaidBy(String userId) {
    return _firestore
        .collection('expenses')
        .where('payerId', isEqualTo: userId) // Fixed: was 'paidBy'
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }
  */
}
