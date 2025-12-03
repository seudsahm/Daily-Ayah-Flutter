import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ayah_with_surah.dart';
import '../models/favorite_ayah.dart';
import 'streak_service.dart';
import 'badge_service.dart';

class FavoritesService {
  static const String _boxName = 'favorites';
  Box<FavoriteAyah>? _favoritesBox;

  /// Initialize the Hive box
  Future<void> initialize() async {
    if (_favoritesBox != null && _favoritesBox!.isOpen) return;
    _favoritesBox = await Hive.openBox<FavoriteAyah>(_boxName);
  }

  /// Get listenable for reactive UI updates
  ValueListenable<Box<FavoriteAyah>> get listenable {
    if (_favoritesBox == null || !_favoritesBox!.isOpen) {
      throw Exception('FavoritesService not initialized');
    }
    return _favoritesBox!.listenable();
  }

  /// Check if an ayah is favorited
  bool isFavorite(int surahId, int ayahId) {
    final key = '${surahId}_$ayahId';
    return _favoritesBox?.containsKey(key) ?? false;
  }

  /// Add an ayah to favorites
  Future<void> addFavorite(AyahWithSurah ayahWithSurah) async {
    await initialize();
    final favorite = FavoriteAyah.fromAyahWithSurah(ayahWithSurah);
    await _favoritesBox!.put(favorite.uniqueKey, favorite);
    await _updateStats();
  }

  /// Remove an ayah from favorites
  Future<void> removeFavorite(int surahId, int ayahId) async {
    await initialize();
    final key = '${surahId}_$ayahId';
    await _favoritesBox!.delete(key);
    await _updateStats();
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(AyahWithSurah ayahWithSurah) async {
    await initialize();
    final surahId = ayahWithSurah.surah.id;
    final ayahId = ayahWithSurah.ayah.id;

    if (isFavorite(surahId, ayahId)) {
      await removeFavorite(surahId, ayahId);
      return false;
    } else {
      await addFavorite(ayahWithSurah);
      return true;
    }
  }

  Future<void> _updateStats() async {
    final streakService = StreakService();
    await streakService.initialize();
    await streakService.updateFavoritesCount(_favoritesBox!.length);

    final badgeService = BadgeService();
    await badgeService.initialize();
    await badgeService.checkNewUnlocks();
  }

  /// Get all favorites sorted by timestamp (newest first)
  List<FavoriteAyah> getAllFavorites() {
    if (_favoritesBox == null || !_favoritesBox!.isOpen) return [];

    final favorites = _favoritesBox!.values.toList();
    favorites.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return favorites;
  }

  /// Get favorites count
  int get favoritesCount => _favoritesBox?.length ?? 0;

  /// Clear all favorites (for testing)
  Future<void> clearAll() async {
    await initialize();
    await _favoritesBox!.clear();
  }
}
