import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/firebase_config.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/expense.dart';
import '../../data/models/trip.dart';
import '../../data/models/user.dart';
import '../../data/models/category.dart';

/// Service for advanced analytics and insights
class AnalyticsService {
  final FirebaseFirestore _firestore;

  AnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get comprehensive trip analytics
  Future<TripAnalytics> getTripAnalytics(String tripId) async {
    try {
      // Get trip data
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) {
        throw Exception('Trip not found');
      }
      final trip = Trip.fromFirestore(tripDoc);

      // Get all expenses for the trip
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .get();
      final expenses = expensesQuery.docs.map((doc) => Expense.fromFirestore(doc)).toList();

      // Calculate analytics
      final totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final averageExpense = expenses.isNotEmpty ? totalExpenses / expenses.length : 0.0;
      
      // Category breakdown
      final categoryBreakdown = <String, double>{};
      final categoryCount = <String, int>{};
      
      for (final expense in expenses) {
        final category = expense.categoryId;
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0.0) + expense.amount;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      // Daily spending
      final dailySpending = <DateTime, double>{};
      for (final expense in expenses) {
        final date = DateTime(expense.createdAt.year, expense.createdAt.month, expense.createdAt.day);
        dailySpending[date] = (dailySpending[date] ?? 0.0) + expense.amount;
      }

      // Member spending
      final memberSpending = <String, double>{};
      final memberExpenseCount = <String, int>{};
      
      for (final expense in expenses) {
        memberSpending[expense.paidBy] = (memberSpending[expense.paidBy] ?? 0.0) + expense.amount;
        memberExpenseCount[expense.paidBy] = (memberExpenseCount[expense.paidBy] ?? 0) + 1;
      }

      // Spending trends
      final spendingTrend = _calculateSpendingTrend(expenses);
      
      // Budget analysis
      final budgetAnalysis = _calculateBudgetAnalysis(trip, totalExpenses);

      return TripAnalytics(
        tripId: tripId,
        totalExpenses: totalExpenses,
        averageExpense: averageExpense,
        expenseCount: expenses.length,
        categoryBreakdown: categoryBreakdown,
        categoryCount: categoryCount,
        dailySpending: dailySpending,
        memberSpending: memberSpending,
        memberExpenseCount: memberExpenseCount,
        spendingTrend: spendingTrend,
        budgetAnalysis: budgetAnalysis,
        generatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get user spending analytics
  Future<UserAnalytics> getUserAnalytics(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('expenses')
          .where('paidBy', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final expensesQuery = await query.get();
      final expenses = expensesQuery.docs.map((doc) => Expense.fromFirestore(doc)).toList();

      // Calculate analytics
      final totalSpent = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final averageExpense = expenses.isNotEmpty ? totalSpent / expenses.length : 0.0;

      // Category preferences
      final categorySpending = <String, double>{};
      for (final expense in expenses) {
        categorySpending[expense.categoryId] = 
            (categorySpending[expense.categoryId] ?? 0.0) + expense.amount;
      }

      // Monthly spending
      final monthlySpending = <String, double>{};
      for (final expense in expenses) {
        final monthKey = '${expense.createdAt.year}-${expense.createdAt.month.toString().padLeft(2, '0')}';
        monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0.0) + expense.amount;
      }

      // Trip participation
      final tripParticipation = <String, int>{};
      for (final expense in expenses) {
        tripParticipation[expense.tripId] = (tripParticipation[expense.tripId] ?? 0) + 1;
      }

      return UserAnalytics(
        userId: userId,
        totalSpent: totalSpent,
        averageExpense: averageExpense,
        expenseCount: expenses.length,
        categorySpending: categorySpending,
        monthlySpending: monthlySpending,
        tripParticipation: tripParticipation,
        generatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get category insights
  Future<CategoryInsights> getCategoryInsights(String tripId) async {
    try {
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .get();
      final expenses = expensesQuery.docs.map((doc) => Expense.fromFirestore(doc)).toList();

      final categoryData = <String, CategoryData>{};
      
      for (final expense in expenses) {
        final category = expense.categoryId;
        if (!categoryData.containsKey(category)) {
          categoryData[category] = CategoryData(
            categoryId: category,
            totalAmount: 0.0,
            expenseCount: 0,
            averageAmount: 0.0,
            highestExpense: 0.0,
            lowestExpense: double.infinity,
            expenses: [],
          );
        }

        final data = categoryData[category]!;
        data.totalAmount += expense.amount;
        data.expenseCount++;
        data.highestExpense = max(data.highestExpense, expense.amount);
        data.lowestExpense = min(data.lowestExpense, expense.amount);
        data.expenses.add(expense);
      }

      // Calculate averages and fix infinity values
      for (final data in categoryData.values) {
        data.averageAmount = data.totalAmount / data.expenseCount;
        if (data.lowestExpense == double.infinity) {
          data.lowestExpense = 0.0;
        }
      }

      return CategoryInsights(
        tripId: tripId,
        categoryData: categoryData,
        generatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Get spending predictions
  Future<SpendingPrediction> getSpendingPrediction(String tripId) async {
    try {
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .orderBy('createdAt')
          .get();
      final expenses = expensesQuery.docs.map((doc) => Expense.fromFirestore(doc)).toList();

      if (expenses.length < 3) {
        return SpendingPrediction(
          tripId: tripId,
          predictedTotal: 0.0,
          dailyAverage: 0.0,
          trend: SpendingTrend.stable,
          confidence: 0.0,
          generatedAt: DateTime.now(),
        );
      }

      // Calculate daily spending
      final dailySpending = <DateTime, double>{};
      for (final expense in expenses) {
        final date = DateTime(expense.createdAt.year, expense.createdAt.month, expense.createdAt.day);
        dailySpending[date] = (dailySpending[date] ?? 0.0) + expense.amount;
      }

      final sortedDates = dailySpending.keys.toList()..sort();
      final spendingValues = sortedDates.map((date) => dailySpending[date]!).toList();

      // Simple linear regression for trend
      final n = spendingValues.length;
      final sumX = n * (n - 1) / 2;
      final sumY = spendingValues.fold(0.0, (sum, value) => sum + value);
      final sumXY = spendingValues.asMap().entries.fold(0.0, (sum, entry) => sum + (entry.key * entry.value));
      final sumX2 = n * (n - 1) * (2 * n - 1) / 6;

      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final dailyAverage = sumY / n;

      // Determine trend
      SpendingTrend trend;
      if (slope > 5) {
        trend = SpendingTrend.increasing;
      } else if (slope < -5) {
        trend = SpendingTrend.decreasing;
      } else {
        trend = SpendingTrend.stable;
      }

      // Calculate confidence based on data consistency
      final variance = spendingValues.fold(0.0, (sum, value) => sum + pow(value - dailyAverage, 2)) / n;
      final confidence = max(0.0, min(1.0, 1.0 - (variance / (dailyAverage * dailyAverage))));

      // Predict total (simple projection)
      final currentTotal = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final daysElapsed = sortedDates.length;
      final predictedTotal = currentTotal + (dailyAverage * 7); // Predict next 7 days

      return SpendingPrediction(
        tripId: tripId,
        predictedTotal: predictedTotal,
        dailyAverage: dailyAverage,
        trend: trend,
        confidence: confidence,
        generatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }

  /// Calculate spending trend
  SpendingTrend _calculateSpendingTrend(List<Expense> expenses) {
    if (expenses.length < 2) return SpendingTrend.stable;

    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final firstHalf = sortedExpenses.take(sortedExpenses.length ~/ 2).toList();
    final secondHalf = sortedExpenses.skip(sortedExpenses.length ~/ 2).toList();

    final firstHalfAverage = firstHalf.fold(0.0, (sum, expense) => sum + expense.amount) / firstHalf.length;
    final secondHalfAverage = secondHalf.fold(0.0, (sum, expense) => sum + expense.amount) / secondHalf.length;

    final difference = secondHalfAverage - firstHalfAverage;
    final threshold = firstHalfAverage * 0.1; // 10% threshold

    if (difference > threshold) {
      return SpendingTrend.increasing;
    } else if (difference < -threshold) {
      return SpendingTrend.decreasing;
    } else {
      return SpendingTrend.stable;
    }
  }

  /// Calculate budget analysis
  BudgetAnalysis _calculateBudgetAnalysis(Trip trip, double totalExpenses) {
    final budget = trip.budget ?? 0.0;
    final remaining = budget - totalExpenses;
    final percentageUsed = budget > 0 ? (totalExpenses / budget) * 100 : 0.0;

    BudgetStatus status;
    if (percentageUsed >= 100) {
      status = BudgetStatus.overBudget;
    } else if (percentageUsed >= 80) {
      status = BudgetStatus.nearLimit;
    } else {
      status = BudgetStatus.onTrack;
    }

    return BudgetAnalysis(
      budget: budget,
      spent: totalExpenses,
      remaining: remaining,
      percentageUsed: percentageUsed,
      status: status,
    );
  }

  /// Export analytics data
  Future<Map<String, dynamic>> exportAnalytics(String tripId) async {
    try {
      final analytics = await getTripAnalytics(tripId);
      final categoryInsights = await getCategoryInsights(tripId);
      final prediction = await getSpendingPrediction(tripId);

      return {
        'trip_analytics': analytics.toJson(),
        'category_insights': categoryInsights.toJson(),
        'spending_prediction': prediction.toJson(),
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (error, stackTrace) {
      throw ErrorHandler.handleError(error, stackTrace);
    }
  }
}

/// Trip analytics model
class TripAnalytics {
  final String tripId;
  final double totalExpenses;
  final double averageExpense;
  final int expenseCount;
  final Map<String, double> categoryBreakdown;
  final Map<String, int> categoryCount;
  final Map<DateTime, double> dailySpending;
  final Map<String, double> memberSpending;
  final Map<String, int> memberExpenseCount;
  final SpendingTrend spendingTrend;
  final BudgetAnalysis budgetAnalysis;
  final DateTime generatedAt;

  const TripAnalytics({
    required this.tripId,
    required this.totalExpenses,
    required this.averageExpense,
    required this.expenseCount,
    required this.categoryBreakdown,
    required this.categoryCount,
    required this.dailySpending,
    required this.memberSpending,
    required this.memberExpenseCount,
    required this.spendingTrend,
    required this.budgetAnalysis,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'totalExpenses': totalExpenses,
    'averageExpense': averageExpense,
    'expenseCount': expenseCount,
    'categoryBreakdown': categoryBreakdown,
    'categoryCount': categoryCount,
    'dailySpending': dailySpending.map((k, v) => MapEntry(k.toIso8601String(), v)),
    'memberSpending': memberSpending,
    'memberExpenseCount': memberExpenseCount,
    'spendingTrend': spendingTrend.toString(),
    'budgetAnalysis': budgetAnalysis.toJson(),
    'generatedAt': generatedAt.toIso8601String(),
  };
}

/// User analytics model
class UserAnalytics {
  final String userId;
  final double totalSpent;
  final double averageExpense;
  final int expenseCount;
  final Map<String, double> categorySpending;
  final Map<String, double> monthlySpending;
  final Map<String, int> tripParticipation;
  final DateTime generatedAt;

  const UserAnalytics({
    required this.userId,
    required this.totalSpent,
    required this.averageExpense,
    required this.expenseCount,
    required this.categorySpending,
    required this.monthlySpending,
    required this.tripParticipation,
    required this.generatedAt,
  });
}

/// Category insights model
class CategoryInsights {
  final String tripId;
  final Map<String, CategoryData> categoryData;
  final DateTime generatedAt;

  const CategoryInsights({
    required this.tripId,
    required this.categoryData,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'categoryData': categoryData.map((k, v) => MapEntry(k, v.toJson())),
    'generatedAt': generatedAt.toIso8601String(),
  };
}

/// Category data model
class CategoryData {
  final String categoryId;
  double totalAmount;
  int expenseCount;
  double averageAmount;
  double highestExpense;
  double lowestExpense;
  final List<Expense> expenses;

  CategoryData({
    required this.categoryId,
    required this.totalAmount,
    required this.expenseCount,
    required this.averageAmount,
    required this.highestExpense,
    required this.lowestExpense,
    required this.expenses,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'totalAmount': totalAmount,
    'expenseCount': expenseCount,
    'averageAmount': averageAmount,
    'highestExpense': highestExpense,
    'lowestExpense': lowestExpense,
  };
}

/// Spending prediction model
class SpendingPrediction {
  final String tripId;
  final double predictedTotal;
  final double dailyAverage;
  final SpendingTrend trend;
  final double confidence;
  final DateTime generatedAt;

  const SpendingPrediction({
    required this.tripId,
    required this.predictedTotal,
    required this.dailyAverage,
    required this.trend,
    required this.confidence,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'predictedTotal': predictedTotal,
    'dailyAverage': dailyAverage,
    'trend': trend.toString(),
    'confidence': confidence,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

/// Budget analysis model
class BudgetAnalysis {
  final double budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final BudgetStatus status;

  const BudgetAnalysis({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'budget': budget,
    'spent': spent,
    'remaining': remaining,
    'percentageUsed': percentageUsed,
    'status': status.toString(),
  };
}

/// Enums
enum SpendingTrend { increasing, decreasing, stable }
enum BudgetStatus { onTrack, nearLimit, overBudget }
