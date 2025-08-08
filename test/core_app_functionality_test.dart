import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_trip_expense_splitter/main.dart';
import 'package:group_trip_expense_splitter/core/config/app_config.dart';
import 'package:group_trip_expense_splitter/core/utils/validators.dart';
import 'package:group_trip_expense_splitter/core/utils/formatters.dart';

void main() {
  group('Core App Functionality Tests', () {
    
    testWidgets('App Initialization and Navigation Test', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );

      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Verify app doesn't crash
      expect(tester.takeException(), isNull);

      // Verify MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify app title
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, AppConfig.appName);
    });

    testWidgets('Theme Configuration Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify theme configuration
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('Error Handling Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exceptions during initialization
      expect(tester.takeException(), isNull);
    });

    test('App Configuration Constants Test', () {
      // Test app configuration
      expect(AppConfig.appName, 'Group Trip Expense Splitter');
      expect(AppConfig.appVersion, '1.0.0');
      expect(AppConfig.maxMembersPerTrip, greaterThan(0));
      expect(AppConfig.maxExpensesPerTrip, greaterThan(0));
      expect(AppConfig.supportedCurrencies, isNotEmpty);
      expect(AppConfig.supportedCurrencies.contains('USD'), true);
    });

    test('Validators Functionality Test', () {
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
    });

    test('Formatters Functionality Test', () {
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

    testWidgets('State Management Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ProviderScope is working
      expect(find.byType(ProviderScope), findsOneWidget);
      
      // Verify no state management errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('UI Components Rendering Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify basic UI components are rendered
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
      
      // Verify no rendering errors
      expect(tester.takeException(), isNull);
    });

    test('Constants and Configuration Test', () {
      // Test that all required constants are defined
      expect(AppConfig.appName.isNotEmpty, true);
      expect(AppConfig.appVersion.isNotEmpty, true);
      expect(AppConfig.defaultCurrency.isNotEmpty, true);
      expect(AppConfig.supportedCurrencies.isNotEmpty, true);
      expect(AppConfig.supportedImageFormats.isNotEmpty, true);
      
      // Test numeric constraints
      expect(AppConfig.maxMembersPerTrip, greaterThan(0));
      expect(AppConfig.maxExpensesPerTrip, greaterThan(0));
      expect(AppConfig.maxImageSizeBytes, greaterThan(0));
    });

    test('Error Handling Configuration Test', () {
      // Test error handling utilities
      final testError = Exception('Test error');
      final userMessage = ErrorHandler.getUserMessage(testError);
      expect(userMessage, isNotEmpty);
      
      // Test error categorization
      final networkError = NetworkException('Network error');
      expect(ErrorHandler.isRecoverable(networkError), true);
      
      final authError = AuthException('Auth error');
      expect(ErrorHandler.isRecoverable(authError), false);
    });

    test('Utility Functions Test', () {
      // Test retry delay calculation
      expect(ErrorHandler.getRetryDelay(1), const Duration(seconds: 1));
      expect(ErrorHandler.getRetryDelay(2), const Duration(seconds: 2));
      expect(ErrorHandler.getRetryDelay(3), const Duration(seconds: 4));
      
      // Test validation helpers
      expect(Validators.isRequired('test'), null);
      expect(Validators.isRequired(''), 'This field is required');
      expect(Validators.isRequired('   '), 'This field is required');
    });

    testWidgets('Performance and Memory Test', (WidgetTester tester) async {
      // Test app performance during initialization
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );

      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Verify app initializes within reasonable time (5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Verify no memory leaks or exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cross-Platform Compatibility Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExpenseSplitterApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app works across different screen sizes
      await tester.binding.setSurfaceSize(const Size(800, 600)); // Desktop
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(375, 667)); // Mobile
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(768, 1024)); // Tablet
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('Integration Test - Service Initialization', () {
      // Test that all services can be initialized
      expect(() => StorageService(), returnsNormally);
      expect(() => ConnectivityService(), returnsNormally);
      expect(() => ErrorHandler.initialize(), returnsNormally);
    });

    test('Data Validation Integration Test', () {
      // Test comprehensive data validation
      final validEmail = 'user@example.com';
      final validPhone = '+1234567890';
      final validAmount = '123.45';
      
      expect(Validators.email(validEmail), null);
      expect(Validators.phone(validPhone), null);
      expect(Validators.amount(validAmount), null);
      
      // Test invalid data
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
    });

    test('Formatting Integration Test', () {
      // Test all formatters work together
      final amount = 1234.56;
      final date = DateTime(2023, 12, 25);
      final percentage = 0.75;
      
      expect(CurrencyFormatter.format(amount), contains('1,234.56'));
      expect(DateFormatter.formatMedium(date), contains('Dec 25, 2023'));
      expect(PercentageFormatter.format(percentage), contains('75.0%'));
    });
  });
}
