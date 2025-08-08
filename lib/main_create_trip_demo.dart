import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/screens/trips/create_trip_screen_demo.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CreateTripDemoApp());
}

class CreateTripDemoApp extends StatelessWidget {
  const CreateTripDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Trip Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const CreateTripScreenDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}
