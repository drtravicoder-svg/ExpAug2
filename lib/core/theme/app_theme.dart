import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: DesignTokens.primaryBlue,
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.primaryBlue,
        foregroundColor: DesignTokens.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: DesignTokens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
        ),
        margin: EdgeInsets.all(DesignTokens.cardPadding),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.cardPadding,
          vertical: DesignTokens.contentSpacing,
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: DesignTokens.header,
        titleMedium: DesignTokens.subtitle,
        bodyLarge: DesignTokens.stats,
        labelLarge: DesignTokens.buttonText,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DesignTokens.white,
        selectedItemColor: DesignTokens.primaryBlue,
        unselectedItemColor: DesignTokens.inactiveGray,
      ),
    );
  }
}
