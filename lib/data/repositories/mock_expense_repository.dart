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
        approvedBy: [...expense.approvedBy, approvedBy],
        updatedAt: DateTime.now(),
      );
      _notifyListeners();
      
      if (kDebugMode) {
        print('🎭 Mock Expense Repository: Approved expense "${expense.title}"');
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
        rejectedBy: [...expense.rejectedBy, rejectedBy],
        updatedAt: DateTime.now(),
      );
      _notifyListeners();
      
      if (kDebugMode) {
        print('🎭 Mock Expense Repository: Rejected expense "${expense.title}"');
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
        title: 'Hotel Booking',
        description: 'Beach resort accommodation for 3 nights',
        amount: 15000.0,
        categoryId: 'accommodation',
        paidBy: 'demo_user_1',
        splitBetween: {'demo_user_1': 7500.0, 'demo_user_2': 7500.0},
        receiptUrl: null,
        status: ExpenseStatus.approved,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        approvedBy: ['demo_user_1'],
        rejectedBy: [],
        tags: ['accommodation', 'hotel'],
        location: 'Goa, India',
        notes: 'Beachfront hotel with pool',
      ),
      Expense(
        id: 'expense_demo_2',
        tripId: 'trip_active_demo',
        title: 'Flight Tickets',
        description: 'Round trip flights Mumbai to Goa',
        amount: 12000.0,
        categoryId: 'transport',
        paidBy: 'demo_user_2',
        splitBetween: {'demo_user_1': 6000.0, 'demo_user_2': 6000.0},
        receiptUrl: null,
        status: ExpenseStatus.approved,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
        approvedBy: ['demo_user_1'],
        rejectedBy: [],
        tags: ['transport', 'flight'],
        location: 'Mumbai Airport',
        notes: 'IndiGo flights',
      ),
      Expense(
        id: 'expense_demo_3',
        tripId: 'trip_active_demo',
        title: 'Dinner at Beach Shack',
        description: 'Seafood dinner for the group',
        amount: 2500.0,
        categoryId: 'food',
        paidBy: 'demo_user_1',
        splitBetween: {'demo_user_1': 1250.0, 'demo_user_2': 1250.0},
        receiptUrl: null,
        status: ExpenseStatus.pending,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        approvedBy: [],
        rejectedBy: [],
        tags: ['food', 'dinner'],
        location: 'Baga Beach, Goa',
        notes: 'Amazing seafood platter',
      ),
      Expense(
        id: 'expense_demo_4',
        tripId: 'trip_active_demo',
        title: 'Scuba Diving',
        description: 'Adventure sports activity',
        amount: 8000.0,
        categoryId: 'activities',
        paidBy: 'demo_user_2',
        splitBetween: {'demo_user_1': 4000.0, 'demo_user_2': 4000.0},
        receiptUrl: null,
        status: ExpenseStatus.pending,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        approvedBy: [],
        rejectedBy: [],
        tags: ['activities', 'adventure'],
        location: 'Grande Island, Goa',
        notes: 'Professional diving with instructor',
      ),
    ];
  }

  /// Dispose resources
  void dispose() {
    _expensesController.close();
  }
}
