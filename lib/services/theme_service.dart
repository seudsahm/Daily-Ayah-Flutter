import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/theme_mode.dart';

class ThemeService extends ChangeNotifier {
  static const String _boxName = 'theme_settings';
  static const String _themeKey = 'theme_mode';

  // Singleton pattern
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  Box? _settingsBox;
  AppThemeMode _currentThemeMode = AppThemeMode.system;

  AppThemeMode get currentThemeMode => _currentThemeMode;

  Future<void> initialize() async {
    if (_settingsBox != null && _settingsBox!.isOpen) return;

    _settingsBox = await Hive.openBox(_boxName);

    // Load saved theme mode
    final savedMode = _settingsBox!.get(
      _themeKey,
      defaultValue: AppThemeMode.system.index,
    );
    _currentThemeMode = AppThemeMode.values[savedMode];
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await initialize();
    _currentThemeMode = mode;
    await _settingsBox!.put(_themeKey, mode.index);
    notifyListeners();
  }

  ThemeMode getThemeMode() {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
