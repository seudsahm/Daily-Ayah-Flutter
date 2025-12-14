import 'package:flutter/foundation.dart';
import 'ayah_selector_service.dart';
import 'streak_service.dart';
import 'badge_service.dart';
import 'favorites_service.dart';
import 'collections_service.dart';

/// Centralized service to initialize all critical services at app startup
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Initialize all critical services
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    try {
      if (kDebugMode) {
        print('Starting app initialization...');
      }

      // Initialize services in parallel where possible
      await Future.wait([
        // Core data service (heavy JSON loading)
        _initializeAyahSelector(),

        // User data services (Hive boxes)
        _initializeUserServices(),
      ]);

      _isInitialized = true;

      if (kDebugMode) {
        print('App initialization complete!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during initialization: $e');
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _initializeAyahSelector() async {
    final service = AyahSelectorService();
    await service.initialize();
  }

  Future<void> _initializeUserServices() async {
    // Initialize all Hive-based services in parallel
    await Future.wait([
      StreakService().initialize(),
      BadgeService().initialize(),
      FavoritesService().initialize(),
      CollectionsService().initialize(),
    ]);
  }

  /// Check if services are ready
  bool get isReady => _isInitialized;
}
