import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home/home_screen_simple.dart';
import 'presentation/screens/trips/all_trips_screen_simple.dart';
import 'presentation/screens/expenses/expenses_screen_simple.dart';
import 'presentation/screens/settings/settings_screen_simple.dart';
import 'presentation/screens/trips/create_trip_screen_clean.dart';
import 'presentation/widgets/main_scaffold_simple.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(ProviderScope(child: FullTripApp()));
}

class FullTripApp extends StatelessWidget {
  FullTripApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/home',
    routes: [
      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffoldSimple(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreenSimple(),
          ),
          GoRoute(
            path: '/all-trips',
            name: 'all-trips',
            builder: (context, state) => const AllTripsScreenSimple(),
          ),
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (context, state) => const ExpensesScreenSimple(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreenSimple(),
          ),
        ],
      ),
      
      // Full screen routes
      GoRoute(
        path: '/create-trip',
        name: 'createTrip',
        builder: (context, state) => const CreateTripScreenClean(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Trip Expense Splitter',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
