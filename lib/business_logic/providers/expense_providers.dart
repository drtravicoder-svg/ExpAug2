import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/mock_expense_repository.dart';
import '../../data/models/expense.dart';
import 'trip_providers.dart';

// Use mock repository for demo/testing
final expenseRepositoryProvider = Provider<MockExpenseRepository>((ref) {
  return MockExpenseRepository();
});

final recentExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, tripId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getRecentExpenses(tripId);
});

final tripExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, tripId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getTripExpenses(tripId);
});

// Provider to track the total expenses for a trip
final tripTotalExpensesProvider = Provider.family<double, String>((ref, tripId) {
  final expenses = ref.watch(tripExpensesProvider(tripId));
  return expenses.when(
    data: (expenses) => expenses.fold(0.0, (sum, expense) => sum + expense.amount),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// Provider for a specific expense
final expenseProvider = StreamProvider.family<Expense?, String>((ref, expenseId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getExpenseById(expenseId);
});

// Provider for pending expenses (admin approval needed)
final pendingExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, tripId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.getPendingExpenses(tripId);
});

// Provider for expense statistics
final expenseStatsProvider = Provider.family<ExpenseStats, String>((ref, tripId) {
  final expenses = ref.watch(tripExpensesProvider(tripId));

  return expenses.when(
    data: (expenseList) => ExpenseStats.calculate(expenseList),
    loading: () => const ExpenseStats.empty(),
    error: (_, __) => const ExpenseStats.empty(),
  );
});

class ExpenseStats {
  final double totalAmount;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final double averageAmount;

  const ExpenseStats({
    required this.totalAmount,
    required this.totalCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.averageAmount,
  });

  const ExpenseStats.empty()
      : totalAmount = 0.0,
        totalCount = 0,
        pendingCount = 0,
        approvedCount = 0,
        rejectedCount = 0,
        averageAmount = 0.0;

  static ExpenseStats calculate(List<Expense> expenses) {
    if (expenses.isEmpty) return const ExpenseStats.empty();

    final totalAmount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final totalCount = expenses.length;
    final pendingCount = expenses.where((e) => e.status == ExpenseStatus.pending).length;
    final approvedCount = expenses.where((e) => e.status == ExpenseStatus.committed).length;
    final rejectedCount = expenses.where((e) => e.status == ExpenseStatus.rejected).length;
    final averageAmount = totalCount > 0 ? totalAmount / totalCount : 0.0;

    return ExpenseStats(
      totalAmount: totalAmount,
      totalCount: totalCount,
      pendingCount: pendingCount,
      approvedCount: approvedCount,
      rejectedCount: rejectedCount,
      averageAmount: averageAmount,
    );
  }
}
