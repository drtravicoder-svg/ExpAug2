import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/trips/create_trip_screen_clean.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: CleanTripApp()));
}

class CleanTripApp extends StatelessWidget {
  const CleanTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Expense Splitter',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const CreateTripScreenClean(),
      debugShowCheckedModeBanner: false,
    );
  }
}
