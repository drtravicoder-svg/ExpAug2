// Firebase/Firestore is not installed - analytics service is disabled
// import 'dart:async';
// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// import '../../core/config/firebase_config.dart';
// import '../../core/utils/error_handler.dart';
import '../../data/models/expense.dart';
import '../../data/models/trip.dart';
// import '../../data/models/user.dart';
// import '../../data/models/category.dart';

/// Service for advanced analytics and insights - DISABLED (Firebase not installed)
/// This app uses local SQLite data instead
class AnalyticsService {
  AnalyticsService() {
    print('ℹ️ AnalyticsService is disabled - Firebase not installed');
  }
  
  // All Firebase/Firestore code is commented out
  // Use local repositories for basic analytics instead
}

/// Spending trend enumeration
enum SpendingTrend {
  increasing,
  decreasing,
  stable,
}

/// Budget status enumeration
enum BudgetStatus {
  onTrack,
  nearLimit,
  overBudget,
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
    'status': status.toString().split('.').last,
  };
}

/// Category data model
class CategoryData {
  String categoryId;
  double totalAmount;
  int expenseCount;
  double averageAmount;
  double highestExpense;
  double lowestExpense;
  List<Expense> expenses;

  CategoryData({
    required this.categoryId,
    required this.totalAmount,
    required this.expenseCount,
    required this.averageAmount,
    required this.highestExpense,
    required this.lowestExpense,
    required this.expenses,
  });
}
