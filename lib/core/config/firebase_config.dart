import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  static FirebaseAnalytics? _analytics;
  static FirebasePerformance? _performance;

  // Demo Firebase configuration - replace with your actual config
  static const FirebaseOptions defaultOptions = FirebaseOptions(
    apiKey: 'demo-api-key-for-testing',
    appId: '1:123456789:web:demo-app-id',
    messagingSenderId: '123456789',
    projectId: 'expense-splitter-demo',
    authDomain: 'expense-splitter-demo.firebaseapp.com',
    storageBucket: 'expense-splitter-demo.appspot.com',
  );

  /// Initialize Firebase services
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(options: defaultOptions);

      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;

      // Initialize Performance Monitoring
      _performance = FirebasePerformance.instance;

      // Initialize Crashlytics
      if (!kDebugMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Get Firebase Analytics instance
  static FirebaseAnalytics? get analytics => _analytics;

  /// Get Firebase Performance instance
  static FirebasePerformance? get performance => _performance;

  /// Log analytics event
  static Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      print('Analytics event logging failed: $e');
    }
  }

  /// Set user properties for analytics
  static Future<void> setUserProperties(Map<String, String> properties) async {
    try {
      for (final entry in properties.entries) {
        await _analytics?.setUserProperty(name: entry.key, value: entry.value);
      }
    } catch (e) {
      print('Setting user properties failed: $e');
    }
  }

  /// Log custom error to Crashlytics
  static Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason}) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      print('Error logging to Crashlytics failed: $e');
    }
  }

  /// Set user identifier for Crashlytics
  static Future<void> setUserId(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      print('Setting user ID failed: $e');
    }
  }

  /// Set custom key-value pairs for Crashlytics
  static Future<void> setCustomKey(String key, Object value) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      print('Setting custom key failed: $e');
    }
  }
}

/// Firebase configuration constants
class FirebaseConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String expensesCollection = 'expenses';
  static const String membersCollection = 'members';
  static const String balancesCollection = 'balances';
  static const String categoriesCollection = 'categories';
  static const String notificationsCollection = 'notifications';
  static const String auditLogsCollection = 'audit_logs';

  // Storage paths
  static const String receiptImagesPath = 'receipts';
  static const String profileImagesPath = 'profiles';
  static const String tripImagesPath = 'trips';

  // Analytics events
  static const String eventTripCreated = 'trip_created';
  static const String eventExpenseAdded = 'expense_added';
  static const String eventMemberInvited = 'member_invited';
  static const String eventExpenseApproved = 'expense_approved';
  static const String eventTripCompleted = 'trip_completed';
  static const String eventReceiptUploaded = 'receipt_uploaded';

  // Performance traces
  static const String traceAppStart = 'app_start';
  static const String traceExpenseCreation = 'expense_creation';
  static const String traceTripLoading = 'trip_loading';
  static const String traceImageUpload = 'image_upload';
}
