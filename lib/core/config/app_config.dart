import 'package:flutter/foundation.dart';

/// Application configuration and constants
class AppConfig {
  // App Information
  static const String appName = 'Group Trip Expense Splitter';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // Environment
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;
  
  // API Configuration
  static const String baseUrl = 'https://api.grouptripexpenses.com';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Storage Configuration
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxReceiptImages = 5;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const int maxMembersPerTrip = 50;
  static const int maxExpensesPerTrip = 1000;
  
  // Currency Configuration
  static const String defaultCurrency = 'USD';
  static const List<String> supportedCurrencies = [
    'USD', 'EUR', 'GBP', 'INR', 'CAD', 'AUD', 'JPY', 'CNY', 'SGD', 'HKD'
  ];
  
  // Notification Configuration
  static const Duration notificationDelay = Duration(seconds: 1);
  static const int maxNotificationsPerUser = 100;
  
  // Security Configuration
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  
  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  // Development Configuration
  static const bool enableDebugLogs = kDebugMode;
  static const bool enablePerformanceMonitoring = !kDebugMode;
  static const bool enableTestMode = kDebugMode;
}

/// Application constants
class AppConstants {
  // Routes
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String tripsRoute = '/trips';
  static const String expensesRoute = '/expenses';
  static const String settingsRoute = '/settings';
  static const String profileRoute = '/profile';
  static const String tripDetailsRoute = '/trip-details';
  static const String expenseDetailsRoute = '/expense-details';
  static const String addExpenseRoute = '/add-expense';
  static const String createTripRoute = '/create-trip';
  static const String inviteMembersRoute = '/invite-members';
  
  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyOfflineModeEnabled = 'offline_mode_enabled';
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorPermission = 'Permission denied. Please grant required permissions.';
  static const String errorFileSize = 'File size too large. Maximum size is 10MB.';
  static const String errorFileFormat = 'Unsupported file format.';
  static const String errorMaxMembers = 'Maximum 50 members allowed per trip.';
  static const String errorMaxExpenses = 'Maximum 1000 expenses allowed per trip.';
  
  // Success Messages
  static const String successTripCreated = 'Trip created successfully!';
  static const String successExpenseAdded = 'Expense added successfully!';
  static const String successMemberInvited = 'Member invited successfully!';
  static const String successExpenseApproved = 'Expense approved successfully!';
  static const String successTripCompleted = 'Trip completed successfully!';
  static const String successReceiptUploaded = 'Receipt uploaded successfully!';
  
  // Loading Messages
  static const String loadingGeneric = 'Loading...';
  static const String loadingTrips = 'Loading trips...';
  static const String loadingExpenses = 'Loading expenses...';
  static const String loadingMembers = 'Loading members...';
  static const String loadingBalances = 'Loading balances...';
  static const String uploadingReceipt = 'Uploading receipt...';
  static const String processingPayment = 'Processing payment...';
  
  // Empty State Messages
  static const String emptyTrips = 'No trips found. Create your first trip!';
  static const String emptyExpenses = 'No expenses found. Add your first expense!';
  static const String emptyMembers = 'No members found. Invite members to join!';
  static const String emptyNotifications = 'No notifications found.';
  static const String emptyReceipts = 'No receipts uploaded.';
  
  // Validation Messages
  static const String validationRequired = 'This field is required';
  static const String validationEmail = 'Please enter a valid email address';
  static const String validationPhone = 'Please enter a valid phone number';
  static const String validationAmount = 'Please enter a valid amount';
  static const String validationMinAmount = 'Amount must be greater than 0';
  static const String validationMaxAmount = 'Amount is too large';
  static const String validationTripName = 'Trip name must be at least 3 characters';
  static const String validationDescription = 'Description must be at least 5 characters';
  
  // Date Formats
  static const String dateFormatShort = 'MMM dd';
  static const String dateFormatMedium = 'MMM dd, yyyy';
  static const String dateFormatLong = 'MMMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Number Formats
  static const String currencyFormat = '#,##0.00';
  static const String percentageFormat = '#0.0%';
  static const String numberFormat = '#,##0';
}

/// Environment-specific configuration
class EnvironmentConfig {
  static String get environment {
    if (kDebugMode) return 'development';
    if (kProfileMode) return 'staging';
    return 'production';
  }
  
  static String get apiBaseUrl {
    switch (environment) {
      case 'development':
        return 'https://dev-api.grouptripexpenses.com';
      case 'staging':
        return 'https://staging-api.grouptripexpenses.com';
      default:
        return 'https://api.grouptripexpenses.com';
    }
  }
  
  static bool get enableLogging => environment != 'production';
  static bool get enableCrashReporting => environment == 'production';
  static bool get enableAnalytics => environment == 'production';
}
