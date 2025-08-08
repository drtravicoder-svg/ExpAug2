import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/utils/storage_service.dart';
import 'core/utils/error_handler.dart';
import 'business_logic/services/mock_auth_service.dart';
import 'data/repositories/mock_trip_repository.dart';
import 'data/repositories/mock_expense_repository.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await _initializeServices();

  runApp(
    const ProviderScope(
      child: ExpenseSplitterApp(),
    ),
  );
}

/// Initialize all required services
Future<void> _initializeServices() async {
  try {
    // Initialize storage service first (needed by other services)
    await StorageService().initialize();

    // Initialize mock services for demo
    await MockAuthService().initialize();
    await MockTripRepository().initialize();
    await MockExpenseRepository().initialize();

    print('✅ All services initialized successfully (using mock data for demo)');
  } catch (error, stackTrace) {
    // Log initialization error
    await ErrorHandler.logError(
      error,
      stackTrace,
      context: 'App Initialization',
    );

    print('❌ Service initialization failed: $error');
    // Continue app startup even if some services fail
  }
}

class ExpenseSplitterApp extends ConsumerWidget {
  const ExpenseSplitterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: AppConfig.isDebug,
      routerConfig: router,

      // Global error handling
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          // Log error
          ErrorHandler.logError(
            errorDetails.exception,
            errorDetails.stack,
            context: 'Widget Error',
          );

          // Return custom error widget in production
          if (AppConfig.isRelease) {
            return Material(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please restart the app',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Return default error widget in debug mode
          return ErrorWidget(errorDetails.exception);
        };

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
