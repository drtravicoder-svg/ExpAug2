import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Custom exception classes
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message';
}

class AuthException extends AppException {
  const AuthException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class NetworkException extends AppException {
  const NetworkException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class StorageException extends AppException {
  const StorageException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Global error handler
class ErrorHandler {
  /// Log error to console and crash reporting service
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Log to console in debug mode
      if (kDebugMode) {
        print('🚨 ERROR ${context != null ? '[$context]' : ''}: $error');
        if (stackTrace != null) {
          print('Stack trace: $stackTrace');
        }
        if (additionalData != null) {
          print('Additional data: $additionalData');
        }
      }

      // In production, you would log to crash reporting service
      // await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } catch (e) {
      // Fallback logging
      if (kDebugMode) {
        print('Failed to log error: $e');
      }
    }
  }

  /// Handle and convert errors to user-friendly exceptions
  static AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('HandshakeException')) {
      return NetworkException(
        'Network connection error. Please check your internet connection.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic error
    return AppException(
      'An unexpected error occurred. Please try again.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Show user-friendly error message
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if error is network related
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket');
  }

  /// Check if error requires authentication
  static bool isAuthError(dynamic error) {
    if (error is AuthException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') ||
           errorString.contains('unauthenticated') ||
           errorString.contains('permission denied');
  }
}
