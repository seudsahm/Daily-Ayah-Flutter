import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color _lightPrimary = Color(0xFF1B5E20); // Deep Islamic Green
  static const Color _lightSecondary = Color(0xFF2E7D32); // Rich Green
  static const Color _lightTertiary = Color(0xFFD4AF37); // Metallic Gold
  static const Color _lightBackground = Color(0xFFFAFAF7); // Warm Pearl White
  static const Color _lightSurface = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF1A1C19);
  static const Color _lightTextSecondary = Color(0xFF424740);

  // Dark theme colors
  static const Color _darkPrimary = Color(0xFF81C784);
  static const Color _darkSecondary = Color(0xFF4CAF50);
  static const Color _darkTertiary = Color(0xFFFFD700); // Bright Gold
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkTextPrimary = Color(0xFFE0E0E0);
  static const Color _darkTextSecondary = Color(0xFFB0B0B0);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _lightPrimary,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: ColorScheme.light(
      primary: _lightPrimary,
      secondary: _lightSecondary,
      tertiary: _lightTertiary,
      surface: _lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: _lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _lightTextPrimary),
      bodyMedium: TextStyle(color: _lightTextSecondary),
      titleLarge: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _lightPrimary,
        fontWeight: FontWeight.bold,
        fontFamily: 'Amiri',
      ),
    ),
    iconTheme: const IconThemeData(color: _lightTextPrimary),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _lightPrimary,
      unselectedItemColor: _lightTextSecondary,
      backgroundColor: _lightSurface,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _darkPrimary,
    scaffoldBackgroundColor: _darkBackground,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimary,
      secondary: _darkSecondary,
      tertiary: _darkTertiary,
      surface: _darkSurface,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onSurface: _darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: _darkTextPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _darkTextPrimary),
      bodyMedium: TextStyle(color: _darkTextSecondary),
      titleLarge: TextStyle(
        color: _darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _darkPrimary,
        fontWeight: FontWeight.bold,
        fontFamily: 'Amiri',
      ),
    ),
    iconTheme: const IconThemeData(color: _darkTextPrimary),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _darkPrimary,
      unselectedItemColor: _darkTextSecondary,
      backgroundColor: _darkSurface,
    ),
  );
}
