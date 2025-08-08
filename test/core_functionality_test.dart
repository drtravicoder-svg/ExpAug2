import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/main.dart';
import '../lib/core/config/app_config.dart';
import '../lib/core/utils/storage_service.dart';
import '../lib/core/utils/connectivity_service.dart';
import '../lib/core/utils/error_handler.dart';
import '../lib/core/utils/validators.dart';
import '../lib/core/utils/formatters.dart';

void main() {
  group('Core Functionality Tests', () {
    
    test('App Configuration Test', () {
      // Test app configuration constants
      expect(AppConfig.appName, 'Group Trip Expense Splitter');
      expect(AppConfig.appVersion, '1.0.0');
      expect(AppConfig.maxMembersPerTrip, 50);
      expect(AppConfig.maxExpensesPerTrip, 1000);
      expect(AppConfig.supportedCurrencies.contains('USD'), true);
      expect(AppConfig.supportedCurrencies.contains('EUR'), true);
      expect(AppConfig.supportedCurrencies.contains('INR'), true);
    });

    test('Validators Test', () {
      // Test email validation
      expect(Validators.isValidEmail('test@example.com'), true);
      expect(Validators.isValidEmail('invalid-email'), false);
      expect(Validators.isValidEmail(''), false);
      
      // Test phone validation
      expect(Validators.isValidPhone('+1234567890'), true);
      expect(Validators.isValidPhone('1234567890'), true);
      expect(Validators.isValidPhone('123'), false);
      
      // Test amount validation
      expect(Validators.isValidAmount('100.50'), true);
      expect(Validators.isValidAmount('0'), false);
      expect(Validators.isValidAmount('-10'), false);
      expect(Validators.isValidAmount('abc'), false);
      
      // Test required field validation
      expect(Validators.isRequired('test'), null);
      expect(Validators.isRequired(''), 'This field is required');
      expect(Validators.isRequired('   '), 'This field is required');
    });

    test('Formatters Test', () {
      // Test currency formatting
      expect(CurrencyFormatter.format(1234.56), '\$1,234.56');
      expect(CurrencyFormatter.format(0), '\$0.00');
      expect(CurrencyFormatter.format(1000000), '\$1,000,000.00');
      
      // Test date formatting
      final testDate = DateTime(2023, 12, 25, 14, 30);
      expect(DateFormatter.formatShort(testDate), 'Dec 25');
      expect(DateFormatter.formatMedium(testDate), 'Dec 25, 2023');
      expect(DateFormatter.formatTime(testDate), '2:30 PM');
      
      // Test percentage formatting
      expect(PercentageFormatter.format(0.1234), '12.3%');
      expect(PercentageFormatter.format(1.0), '100.0%');
      expect(PercentageFormatter.format(0), '0.0%');
    });

    test('Error Handler Test', () {
      // Test error message extraction
      final testError = Exception('Test error message');
      final userMessage = ErrorHandler.getUserMessage(testError);
      expect(userMessage, isNotEmpty);
      
      // Test recoverable error detection
      final networkError = NetworkException('Network error');
      expect(ErrorHandler.isRecoverable(networkError), true);
      
      final authError = AuthException('Auth error');
      expect(ErrorHandler.isRecoverable(authError), false);
      
      // Test retry delay calculation
      expect(ErrorHandler.getRetryDelay(1), const Duration(seconds: 1));
      expect(ErrorHandler.getRetryDelay(2), const Duration(seconds: 2));
      expect(ErrorHandler.getRetryDelay(3), const Duration(seconds: 4));
      expect(ErrorHandler.getRetryDelay(10), const Duration(seconds: 16)); // Max 16 seconds
    });

    test('Storage Service Constants Test', () {
      // Test storage key constants
      expect(AppConstants.keyUserId, 'user_id');
      expect(AppConstants.keyUserEmail, 'user_email');
      expect(AppConstants.keyUserName, 'user_name');
      expect(AppConstants.keyIsFirstLaunch, 'is_first_launch');
      expect(AppConstants.keyThemeMode, 'theme_mode');
      expect(AppConstants.keyLanguage, 'language');
    });

    test('Route Constants Test', () {
      // Test route constants
      expect(AppConstants.homeRoute, '/');
      expect(AppConstants.loginRoute, '/login');
      expect(AppConstants.tripsRoute, '/trips');
      expect(AppConstants.expensesRoute, '/expenses');
      expect(AppConstants.settingsRoute, '/settings');
      expect(AppConstants.profileRoute, '/profile');
    });

    test('Error Messages Test', () {
      // Test error message constants
      expect(AppConstants.errorGeneric, 'Something went wrong. Please try again.');
      expect(AppConstants.errorNetwork, 'Network error. Please check your connection.');
      expect(AppConstants.errorAuth, 'Authentication failed. Please login again.');
      expect(AppConstants.errorPermission, 'Permission denied. Please grant required permissions.');
    });

    test('Success Messages Test', () {
      // Test success message constants
      expect(AppConstants.successTripCreated, 'Trip created successfully!');
      expect(AppConstants.successExpenseAdded, 'Expense added successfully!');
      expect(AppConstants.successMemberInvited, 'Member invited successfully!');
      expect(AppConstants.successExpenseApproved, 'Expense approved successfully!');
    });

    test('Validation Messages Test', () {
      // Test validation message constants
      expect(AppConstants.validationRequired, 'This field is required');
      expect(AppConstants.validationEmail, 'Please enter a valid email address');
      expect(AppConstants.validationPhone, 'Please enter a valid phone number');
      expect(AppConstants.validationAmount, 'Please enter a valid amount');
    });

    test('Date Format Constants Test', () {
      // Test date format constants
      expect(AppConstants.dateFormatShort, 'MMM dd');
      expect(AppConstants.dateFormatMedium, 'MMM dd, yyyy');
      expect(AppConstants.dateFormatLong, 'MMMM dd, yyyy');
      expect(AppConstants.dateTimeFormat, 'MMM dd, yyyy HH:mm');
      expect(AppConstants.timeFormat, 'HH:mm');
    });

    test('Number Format Constants Test', () {
      // Test number format constants
      expect(AppConstants.currencyFormat, '#,##0.00');
      expect(AppConstants.percentageFormat, '#0.0%');
      expect(AppConstants.numberFormat, '#,##0');
    });
  });

  group('Widget Tests', () {
    testWidgets('App Initialization Test', (WidgetTester tester) async {
      // Test that the app builds without crashing
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );
      
      // Wait for the app to settle
      await tester.pumpAndSettle();
      
      // Verify that the app doesn't crash during initialization
      expect(tester.takeException(), isNull);
    });

    testWidgets('Material App Configuration Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );
      
      // Find the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify app configuration
      expect(materialApp.title, AppConfig.appName);
      expect(materialApp.debugShowCheckedModeBanner, AppConfig.isDebug);
    });

    testWidgets('Theme Configuration Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );
      
      // Find the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify theme configuration
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('Error Widget Builder Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );
      
      // Find the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify error widget builder is configured
      expect(materialApp.builder, isNotNull);
    });
  });

  group('Integration Tests', () {
    test('Service Integration Test', () async {
      // Test that services can be initialized without errors
      try {
        final storageService = StorageService();
        final connectivityService = ConnectivityService();
        
        // These should not throw exceptions
        expect(storageService, isNotNull);
        expect(connectivityService, isNotNull);
        
        // Test connectivity service properties
        expect(connectivityService.currentStatus, isNotNull);
        expect(connectivityService.currentType, isNotNull);
      } catch (e) {
        fail('Service initialization failed: $e');
      }
    });

    test('Configuration Integration Test', () {
      // Test that all configurations are consistent
      expect(AppConfig.maxMembersPerTrip, greaterThan(0));
      expect(AppConfig.maxExpensesPerTrip, greaterThan(0));
      expect(AppConfig.maxImageSizeBytes, greaterThan(0));
      expect(AppConfig.supportedCurrencies, isNotEmpty);
      expect(AppConfig.supportedImageFormats, isNotEmpty);
      
      // Test that default currency is in supported currencies
      expect(AppConfig.supportedCurrencies.contains(AppConfig.defaultCurrency), true);
    });

    test('Constants Consistency Test', () {
      // Test that route constants are properly formatted
      expect(AppConstants.homeRoute.startsWith('/'), true);
      expect(AppConstants.loginRoute.startsWith('/'), true);
      expect(AppConstants.tripsRoute.startsWith('/'), true);
      expect(AppConstants.expensesRoute.startsWith('/'), true);
      
      // Test that storage keys are non-empty
      expect(AppConstants.keyUserId.isNotEmpty, true);
      expect(AppConstants.keyUserEmail.isNotEmpty, true);
      expect(AppConstants.keyUserName.isNotEmpty, true);
      
      // Test that error messages are non-empty
      expect(AppConstants.errorGeneric.isNotEmpty, true);
      expect(AppConstants.errorNetwork.isNotEmpty, true);
      expect(AppConstants.errorAuth.isNotEmpty, true);
    });
  });
}
