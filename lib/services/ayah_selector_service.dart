import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/ayah_with_surah.dart';
import '../models/surah.dart';
import 'json_service.dart';

class AyahSelectorService {
  static const String _boxName = 'quran_surahs';
  static const String _metaBoxName = 'quran_metadata';
  static const String _metaKeyCounts = 'surah_verse_counts';
  static const String _metaKeyTotal = 'total_ayahs';
  static const String _metaKeyInitialized = 'is_db_initialized';

  bool _isInitialized = false;
  bool _isInitializing = false;

  // Metadata cache (small footprint)
  List<int>? _surahVerseCounts;
  int _totalAyahs = 6236; // Default fallback

  final JsonService _jsonService = JsonService();
  final Random _random = Random();

  /// Initialize service - checks DB and imports if needed
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    try {
      // Open metadata box first to check status
      final metaBox = await Hive.openBox(_metaBoxName);
      final isDbInitialized = metaBox.get(
        _metaKeyInitialized,
        defaultValue: false,
      );

      if (!isDbInitialized) {
        if (kDebugMode) print('First run: Importing Quran JSON to Hive DB...');
        await _importData(metaBox);
      } else {
        if (kDebugMode) print('DB initialized. Loading metadata only.');
        try {
          _loadMetadata(metaBox);
          // Open lazy box for future reads - verify it opens
          if (!Hive.isBoxOpen(_boxName)) {
            await Hive.openLazyBox<Surah>(_boxName);
          }
        } catch (e) {
          if (kDebugMode) print('Metadata corrupted ($e). Re-importing...');
          // Self-healing: corrupted metadata/DB -> re-import
          await metaBox.put(_metaKeyInitialized, false);
          _surahVerseCounts = null;
          await _importData(metaBox);
        }
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) print('Initialization error: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Import JSON data into Hive (One-time operation)
  Future<void> _importData(Box metaBox) async {
    // 1. Load JSON (slow path)
    final surahs = await _jsonService.loadQuranData();

    // 2. Save Surahs to LazyBox
    // Ensure box is open (might be closed if re-importing)
    LazyBox<Surah> surahBox;
    if (Hive.isBoxOpen(_boxName)) {
      surahBox = Hive.lazyBox<Surah>(_boxName);
    } else {
      surahBox = await Hive.openLazyBox<Surah>(_boxName);
    }

    // Clear existing data just in case
    await surahBox.clear();

    final verseCounts = <int>[];
    int total = 0;

    for (var surah in surahs) {
      await surahBox.put(surah.id, surah);
      verseCounts.add(surah.verses.length);
      total += surah.verses.length;
    }

    // 3. Save metadata
    await metaBox.put(_metaKeyCounts, verseCounts);
    await metaBox.put(_metaKeyTotal, total);
    await metaBox.put(_metaKeyInitialized, true);

    // 4. Update memory cache
    _surahVerseCounts = verseCounts;
    _totalAyahs = total;

    // 5. Clear JSON memory to free RAM
    _jsonService.clearCache();
  }

  void _loadMetadata(Box metaBox) {
    final dynamic counts = metaBox.get(_metaKeyCounts);
    if (counts is List) {
      // Safe casting for strict mode
      _surahVerseCounts = counts.map((e) => e as int).toList();
    } else {
      throw Exception('Invalid metadata format');
    }

    _totalAyahs = metaBox.get(_metaKeyTotal, defaultValue: 6236);

    if (_surahVerseCounts == null || _surahVerseCounts!.isEmpty) {
      throw Exception('Empty metadata');
    }
  }

  /// Get total number of ayahs
  int get totalAyahs => _totalAyahs;

  /// Get ayah of the day (Deterministic)
  Future<AyahWithSurah> getAyahOfTheDay({DateTime? date}) async {
    await initialize();

    final targetDate = date ?? DateTime.now();
    final dateNumber = _dateToNumber(targetDate);
    final index = dateNumber % totalAyahs;

    return _getAyahByGlobalIndex(index);
  }

  /// Get random unique ayah
  Future<AyahWithSurah> getUniqueRandomAyah(List<String> excludeIds) async {
    await initialize();

    // Safety brake to prevent infinite loop if most are read
    if (excludeIds.length >= _totalAyahs * 0.9) {
      return getRandomAyah();
    }

    // Try finding a random unread one
    for (int i = 0; i < 50; i++) {
      final candidate = await getRandomAyah();
      final key = '${candidate.surah.id}_${candidate.ayah.id}';
      if (!excludeIds.contains(key)) {
        return candidate;
      }
    }

    return getRandomAyah();
  }

  /// Get purely random ayah
  Future<AyahWithSurah> getRandomAyah() async {
    await initialize();
    final index = _random.nextInt(totalAyahs);
    return _getAyahByGlobalIndex(index);
  }

  /// Get unique ayah of the day (skips seen ones)
  Future<AyahWithSurah> getUniqueAyahOfTheDay(List<String> excludeIds) async {
    await initialize();

    final now = DateTime.now();
    int dateNumber = _dateToNumber(now);

    // Try to find a deterministic unique ayah
    for (int i = 0; i < totalAyahs; i++) {
      final index = (dateNumber + i) % totalAyahs;
      // We need to check if this index is excluded without loading the whole object if possible?
      // But we need the ID to check exclusion.
      // Loading 1 ayah is fast enough.

      // Optimization: Calculate Surah/Ayah ID from index from metadata BEFORE loading from DB
      final coords = _getCoordsFromIndex(index);
      final key = '${coords.surahId}_${coords.ayahId}';

      if (!excludeIds.contains(key)) {
        return _getAyahByGlobalIndex(index);
      }
    }

    return getAyahOfTheDay();
  }

  /// Internal helper to get Ayah by global index (0-6235)
  Future<AyahWithSurah> _getAyahByGlobalIndex(int index) async {
    final coords = _getCoordsFromIndex(index);
    final value = await getSpecificAyah(coords.surahId, coords.ayahId);
    if (value == null) {
      throw Exception('Ayah not found at index $index');
    }
    return value;
  }

  ({int surahId, int ayahId}) _getCoordsFromIndex(int index) {
    if (_surahVerseCounts == null) throw Exception('Metadata not loaded');

    int remaining = index;
    for (int i = 0; i < _surahVerseCounts!.length; i++) {
      final count = _surahVerseCounts![i];
      if (remaining < count) {
        return (surahId: i + 1, ayahId: remaining + 1);
      }
      remaining -= count;
    }
    return (surahId: 1, ayahId: 1); // Fallback
  }

  /// Get specific ayah by Surah ID and Ayah ID
  Future<AyahWithSurah?> getSpecificAyah(int surahId, int ayahId) async {
    await initialize();

    try {
      final box = Hive.lazyBox<Surah>(_boxName);
      final surah = await box.get(surahId);

      if (surah == null) return null;

      final ayah = surah.verses.firstWhere(
        (a) => a.id == ayahId,
        orElse: () => throw Exception('Ayah not found'),
      );

      return AyahWithSurah(ayah: ayah, surah: surah);
    } catch (e) {
      if (kDebugMode) print('Error getting ayah: $e');
      return null;
    }
  }

  /// Convert date to YYYYMMDD number
  int _dateToNumber(DateTime date) {
    return (date.year * 10000) + (date.month * 100) + date.day;
  }
}
