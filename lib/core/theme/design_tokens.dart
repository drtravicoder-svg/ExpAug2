import 'package:flutter/material.dart';

// Design system tokens based on the UI screens
class DesignTokens {
  // Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryColor = Color(0xFF2196F3); // Alias for primaryBlue
  static const Color inactiveGray = Color(0xFF9E9E9E);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color liveGreen = Color(0xFF4CAF50);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF757575);
  
  // Text Styles
  static const TextStyle header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: black,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: black,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: black,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: black,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: black,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static const TextStyle stats = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: black,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: white,
  );
  
  // Spacing
  static const double cardPadding = 16.0;
  static const double contentSpacing = 8.0;
  static const double sectionSpacing = 24.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Border Radius
  static const double borderRadius = 12.0;
  static const double borderRadius12 = 12.0;

  // Elevation
  static const double cardElevation = 2.0;
}
