import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';

/// Mock expense repository for testing without Firebase
class MockExpenseRepository {
  static final MockExpenseRepository _instance = MockExpenseRepository._internal();
  factory MockExpenseRepository() => _instance;
  MockExpenseRepository._internal();

  // Mock expenses database
  final List<Expense> _expenses = [];
  final StreamController<List<Expense>> _expensesController = StreamController<List<Expense>>.broadcast();

  /// Initialize with sample data
  Future<void> initialize() async {
    if (_expenses.isEmpty) {
      _expenses.addAll(_generateSampleExpenses());
      _notifyListeners();
      
      if (kDebugMode) {
        print('🎭 Mock Expense Repository: Initialized with ${_expenses.length} sample expenses');
      }
    }
  }

  /// Get recent expenses for a trip
  Stream<List<Expense>> getRecentExpenses(String tripId, {int limit = 5}) {
    return _expensesController.stream.map((expenses) {
      return expenses
          .where((expense) => expense.tripId == tripId)
          .take(limit)
          .toList();
    });
  }

  /// Create expense
  Future<Expense> createExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    final newExpense = expense.copyWith(
      id: 'expense_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _expenses.insert(0, newExpense);
    _notifyListeners();
    
    if (kDebugMode) {
      print('🎭 Mock Expense Repository: Created expense "${newExpense.title}" - ₹${newExpense.amount}');
    }
    
    return newExpense;
  }

  /// Update expense
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense.copyWith(updatedAt: DateTime.now());
      _notifyListeners();
      
      if (kDebugMode) {
        print('🎭 Mock Expense Repository: Updated expense "${expense.title}"');
      }
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String expenseId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _expenses.removeWhere((expense) => expense.id == expenseId);
    _notifyListeners();
    
    if (kDebugMode) {
      print('🎭 Mock Expense Repository: Deleted expense $expenseId');
    }
  }

  /// Get all expenses for a trip
  Stream<List<Expense>> getTripExpenses(String tripId) {
    return _expensesController.stream.map((expenses) {
      return expenses
          .where((expense) => expense.tripId == tripId)
          .toList();
    });
  }

  /// Get expense by ID
  Stream<Expense?> getExpenseById(String expenseId) {
    return _expensesController.stream.map((expenses) {
      try {
        return expenses.firstWhere((expense) => expense.id == expenseId);
      } catch (e) {
        return null;
      }
    });
  }

  /// Get pending expenses
  Stream<List<Expense>> getPendingExpenses(String tripId) {
    return _expensesController.stream.map((expenses) {
      return expenses
          .where((expense) => expense.tripId == tripId && expense.status == ExpenseStatus.pending)
          .toList();
    });
  }

  /// Approve expense
  Future<void> approveExpense(String expenseId, String approvedBy) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final expense = _expenses[index];
      _expenses[index] = expense.copyWith(
        status: ExpenseStatus.approved,
        updatedAt: DateTime.now(),
      );
      _notifyListeners();
      
      if (kDebugMode) {
        print('🎭 Mock Expense Repository: Approved expense "${expense.title}" by $approvedBy');
      }
    }
  }

  /// Reject expense
  Future<void> rejectExpense(String expenseId, String rejectedBy) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final expense = _expenses[index];
      _expenses[index] = expense.copyWith(
        status: ExpenseStatus.rejected,
        updatedAt: DateTime.now(),
      );
      _notifyListeners();
      
      if (kDebugMode) {
        print('🎭 Mock Expense Repository: Rejected expense "${expense.title}" by $rejectedBy');
      }
    }
  }

  void _notifyListeners() {
    _expensesController.add(List.from(_expenses));
  }

  List<Expense> _generateSampleExpenses() {
    final now = DateTime.now();
    final random = Random();
    
    return [
      Expense(
        id: 'expense_demo_1',
        tripId: 'trip_active_demo',
        payerId: 'demo_user_1',
        title: 'Hotel Booking',
        description: 'Beach resort accommodation for 3 nights',
        amount: 15000.0,
        currency: 'INR',
        category: 'accommodation',
        date: now.subtract(const Duration(days: 2)),
        status: ExpenseStatus.approved,
        receiptPath: null,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 'expense_demo_2',
        tripId: 'trip_active_demo',
        payerId: 'demo_user_2',
        title: 'Flight Tickets',
        description: 'Round trip flights Mumbai to Goa',
        amount: 12000.0,
        currency: 'INR',
        category: 'transport',
        date: now.subtract(const Duration(days: 3)),
        status: ExpenseStatus.approved,
        receiptPath: null,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Expense(
        id: 'expense_demo_3',
        tripId: 'trip_active_demo',
        payerId: 'demo_user_1',
        title: 'Dinner at Beach Shack',
        description: 'Seafood dinner for the group',
        amount: 2500.0,
        currency: 'INR',
        category: 'food',
        date: now.subtract(const Duration(hours: 6)),
        status: ExpenseStatus.pending,
        receiptPath: null,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      Expense(
        id: 'expense_demo_4',
        tripId: 'trip_active_demo',
        payerId: 'demo_user_2',
        title: 'Scuba Diving',
        description: 'Adventure sports activity',
        amount: 8000.0,
        currency: 'INR',
        category: 'activities',
        date: now.subtract(const Duration(hours: 2)),
        status: ExpenseStatus.pending,
        receiptPath: null,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    _expensesController.close();
  }
}
