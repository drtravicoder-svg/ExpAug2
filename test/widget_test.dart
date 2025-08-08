// Group Trip Expense Splitter Widget Tests
//
// This file contains widget tests for the Group Trip Expense Splitter app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:group_trip_expense_splitter/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseSplitterApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app builds without crashing
    expect(tester.takeException(), isNull);

    // Verify that we have a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App title test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseSplitterApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Find the MaterialApp widget
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    
    // Verify the app title
    expect(materialApp.title, 'Group Trip Expense Splitter');
  });

  testWidgets('Theme configuration test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseSplitterApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Find the MaterialApp widget
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    
    // Verify theme configuration
    expect(materialApp.theme, isNotNull);
    expect(materialApp.darkTheme, isNotNull);
    expect(materialApp.themeMode, ThemeMode.system);
  });
}
