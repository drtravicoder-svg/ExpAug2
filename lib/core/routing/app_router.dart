import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../utils/error_handler.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/trips/all_trips_screen.dart';
import '../../presentation/screens/expenses/expenses_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/trips/trip_details_screen.dart';
import '../../presentation/screens/expenses/expense_details_screen.dart';
import '../../presentation/screens/expenses/add_expense_screen.dart';
import '../../presentation/screens/trips/create_trip_screen.dart';
import '../../presentation/screens/debug_screen.dart';
import '../../presentation/widgets/main_scaffold.dart';
import '../../business_logic/providers/auth_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: AppConfig.isDebug,

    // Global redirect logic for authentication (disabled for demo)
    redirect: (context, state) {
      try {
        // For demo purposes, allow access to all routes
        // In production, uncomment the authentication logic below

        /*
        final isLoggedIn = authState.asData?.value != null;
        final isLoggingIn = state.location == AppRoutes.login;

        // Redirect to login if not authenticated
        if (!isLoggedIn && !isLoggingIn) {
          return AppRoutes.login;
        }

        // Redirect to home if already authenticated and trying to access login
        if (isLoggedIn && isLoggingIn) {
          return AppRoutes.home;
        }
        */

        return null; // Allow all routes for demo
      } catch (error, stackTrace) {
        ErrorHandler.logError(error, stackTrace, context: 'Router Redirect');
        return null; // Continue to requested route
      }
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/all-trips',
            name: 'all-trips',
            builder: (context, state) => const AllTripsScreen(),
          ),
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      
      // Detail routes (full screen)
      GoRoute(
        path: '/trip/:tripId',
        name: 'tripDetails',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return TripDetailsScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/expense/:expenseId',
        name: 'expenseDetails',
        builder: (context, state) {
          final expenseId = state.pathParameters['expenseId']!;
          return ExpenseDetailsScreen(expenseId: expenseId);
        },
      ),
      
      // Action routes (full screen)
      GoRoute(
        path: '/add-expense',
        name: 'addExpense',
        builder: (context, state) {
          final tripId = state.queryParameters['tripId'];
          return AddExpenseScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/create-trip',
        name: 'createTrip',
        builder: (context, state) => const CreateTripScreen(),
      ),
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),
    ],
    // Enhanced error handling
    errorBuilder: (context, state) {
      // Log navigation error
      ErrorHandler.logError(
        'Navigation Error: ${state.error}',
        null,
        context: 'Router Error',
        additionalData: {
          'location': state.location,
          'path': state.path,
          'fullPath': state.fullPath,
        },
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Page Not Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The page you are looking for does not exist or has been moved.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (AppConfig.isDebug) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Debug Info: ${state.location}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.home),
                      label: const Text('Go Home'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
});

// Route names for easy navigation
class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String trips = '/trips';
  static const String expenses = '/expenses';
  static const String settings = '/settings';
  static const String tripDetails = '/trip';
  static const String expenseDetails = '/expense';
  static const String addExpense = '/add-expense';
  static const String createTrip = '/create-trip';
}

// Custom page transitions
class AppPageTransitions {
  static CustomTransitionPage<T> slideTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Offset begin = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: begin, end: Offset.zero).chain(
              CurveTween(curve: Curves.easeInOut),
            ),
          ),
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage<T> fadeTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
    );
  }
}

// Navigation helpers
extension GoRouterExtension on GoRouter {
  void goToTripDetails(String tripId) {
    go('${AppRoutes.tripDetails}/$tripId');
  }

  void goToExpenseDetails(String expenseId) {
    go('${AppRoutes.expenseDetails}/$expenseId');
  }

  void goToAddExpense({String? tripId}) {
    final uri = Uri(
      path: AppRoutes.addExpense,
      queryParameters: tripId != null ? {'tripId': tripId} : null,
    );
    go(uri.toString());
  }

  void pushToTripDetails(String tripId) {
    push('${AppRoutes.tripDetails}/$tripId');
  }

  void pushToExpenseDetails(String expenseId) {
    push('${AppRoutes.expenseDetails}/$expenseId');
  }

  void pushToAddExpense({String? tripId}) {
    final uri = Uri(
      path: AppRoutes.addExpense,
      queryParameters: tripId != null ? {'tripId': tripId} : null,
    );
    push(uri.toString());
  }

  void pushToCreateTrip() {
    push(AppRoutes.createTrip);
  }

  // Safe navigation with error handling
  void safeGo(String location, {Object? extra}) {
    try {
      go(location, extra: extra);
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Navigation Error',
        additionalData: {'location': location},
      );
      // Fallback to home
      go(AppRoutes.home);
    }
  }

  void safePush(String location, {Object? extra}) {
    try {
      push(location, extra: extra);
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace,
        context: 'Navigation Error',
        additionalData: {'location': location},
      );
      // Fallback to go instead of push
      go(location, extra: extra);
    }
  }
}

// Context extension for easy navigation
extension BuildContextNavigation on BuildContext {
  void goToHome() => go(AppRoutes.home);
  void goToTrips() => go(AppRoutes.trips);
  void goToExpenses() => go(AppRoutes.expenses);
  void goToSettings() => go(AppRoutes.settings);
  void goToLogin() => go(AppRoutes.login);

  void goToTripDetails(String tripId) => go('${AppRoutes.tripDetails}/$tripId');
  void goToExpenseDetails(String expenseId) => go('${AppRoutes.expenseDetails}/$expenseId');

  void pushToCreateTrip() => push(AppRoutes.createTrip);
  void pushToAddExpense({String? tripId}) {
    final uri = Uri(
      path: AppRoutes.addExpense,
      queryParameters: tripId != null ? {'tripId': tripId} : null,
    );
    push(uri.toString());
  }
}
