import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_stats.dart';

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  late Box<UserStats> _box;
  static const String _boxName = 'user_stats';
  static const String _statsKey = 'current_stats';
  bool _isInitialized = false;

  Future<void> initialize() async {
    // Return immediately if already initialized
    if (_isInitialized) return;

    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(UserStatsAdapter());
    }

    // Check if box is already open
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<UserStats>(_boxName);
    } else {
      _box = await Hive.openBox<UserStats>(_boxName);
    }

    if (!_box.containsKey(_statsKey)) {
      await _box.put(_statsKey, UserStats());
    }

    _isInitialized = true;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get stats - will throw if not initialized. Use getStatsAsync for safe access.
  UserStats get stats {
    if (!_isInitialized) {
      throw StateError(
        'StreakService not initialized. Call initialize() first or use getStatsAsync()',
      );
    }
    return _box.get(_statsKey) ?? UserStats();
  }

  /// Async safe getter that ensures initialization
  Future<UserStats> getStatsAsync() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _box.get(_statsKey) ?? UserStats();
  }

  ValueListenable<Box<UserStats>> get listenable => _box.listenable();

  Future<bool> checkDailyOpen() async {
    final currentStats = stats;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (currentStats.lastOpenedDate == null) {
      // First ever open
      currentStats.currentStreak = 1;
      currentStats.longestStreak = 1;
      currentStats.totalDaysOpened = 1;
      currentStats.lastOpenedDate = today;
      await currentStats.save();
      return true; // Streak increased
    }

    final lastOpened = currentStats.lastOpenedDate!;
    final lastDate = DateTime(
      lastOpened.year,
      lastOpened.month,
      lastOpened.day,
    );

    if (lastDate.isAtSameMomentAs(today)) {
      // Already opened today
      return false;
    }

    final difference = today.difference(lastDate).inDays;

    if (difference == 1) {
      // Consecutive day
      currentStats.currentStreak++;
      if (currentStats.currentStreak > currentStats.longestStreak) {
        currentStats.longestStreak = currentStats.currentStreak;
      }
    } else {
      // Streak broken
      currentStats.currentStreak = 1;
    }

    currentStats.totalDaysOpened++;
    currentStats.lastOpenedDate = today;
    await currentStats.save();

    return difference == 1; // True if streak increased
  }

  Future<void> incrementAyahsRead(int surahId, int ayahId) async {
    final currentStats = stats;
    final ayahKey = '${surahId}_$ayahId';

    if (!currentStats.readAyahIds.contains(ayahKey)) {
      currentStats.readAyahIds.add(ayahKey);
      currentStats.totalAyahsRead = currentStats.readAyahIds.length;
    }

    // Track recent ayahs for weekly digest (keep last 10)
    currentStats.recentAyahIds.remove(
      ayahKey,
    ); // Remove if exists to move to top
    currentStats.recentAyahIds.insert(0, ayahKey);
    if (currentStats.recentAyahIds.length > 10) {
      currentStats.recentAyahIds = currentStats.recentAyahIds.sublist(0, 10);
    }

    await currentStats.save();
  }

  Future<void> incrementShares() async {
    final currentStats = _box.get(_statsKey) ?? UserStats();
    currentStats.totalShares++;
    await currentStats.save();
  }

  Future<void> incrementPDFsGenerated() async {
    final currentStats = _box.get(_statsKey) ?? UserStats();
    currentStats.totalPDFsGenerated++;
    await currentStats.save();
  }

  Future<void> updateFavoritesCount(int count) async {
    final currentStats = stats;
    currentStats.totalFavorites = count;
    await currentStats.save();
  }
}
