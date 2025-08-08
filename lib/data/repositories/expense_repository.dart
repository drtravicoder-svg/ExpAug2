import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;

  ExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

  // Get expense by ID
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

  // Get pending expenses for admin approval
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

  // Approve expense
  Future<void> approveExpense(String expenseId, String approvedBy) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'status': 'committed',
      'approvedBy': approvedBy,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Reject expense
  Future<void> rejectExpense(String expenseId, String rejectedBy, String? reason) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'status': 'rejected',
      'approvedBy': rejectedBy,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'adminComment': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get expenses by user
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

  // Get expenses paid by user
  Stream<List<Expense>> getExpensesPaidBy(String userId) {
    return _firestore
        .collection('expenses')
        .where('paidBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    });
  }
}
