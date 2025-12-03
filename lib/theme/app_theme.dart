import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color _lightPrimary = Color(0xFF1B5E20);
  static const Color _lightSecondary = Color(0xFF388E3C);
  static const Color _lightBackground = Color(0xFFF5F5F5);
  static const Color _lightSurface = Colors.white;
  static const Color _lightTextPrimary = Color(0xFF212121);
  static const Color _lightTextSecondary = Color(0xFF757575);

  // Dark theme colors
  static const Color _darkPrimary = Color(0xFF66BB6A);
  static const Color _darkSecondary = Color(0xFF81C784);
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
      background: _lightBackground,
      surface: _lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: _lightTextPrimary,
      onSurface: _lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _lightTextPrimary),
      bodyMedium: TextStyle(color: _lightTextSecondary),
      titleLarge: TextStyle(
        color: _lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const IconThemeData(color: _lightTextPrimary),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _lightPrimary,
      unselectedItemColor: Colors.grey,
      backgroundColor: _lightSurface,
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
      background: _darkBackground,
      surface: _darkSurface,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: _darkTextPrimary,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _darkTextPrimary),
      bodyMedium: TextStyle(color: _darkTextSecondary),
      titleLarge: TextStyle(
        color: _darkTextPrimary,
        fontWeight: FontWeight.w600,
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
