import 'dart:math';

import '../models/ayah_with_surah.dart';
import '../models/surah.dart';
import 'json_service.dart';

class AyahSelectorService {
  List<Surah>? _surahs;
  List<AyahWithSurah>? _flatAyahList;

  final JsonService _jsonService = JsonService();
  final Random _random = Random();

  /// Load all surahs from JSON
  Future<void> initialize() async {
    if (_surahs != null) return; // Already initialized

    _surahs = await _jsonService.loadQuranData();
    _buildFlatAyahList();
  }

  /// Build a flat list of all ayahs with their surah context
  void _buildFlatAyahList() {
    _flatAyahList = [];

    for (var surah in _surahs!) {
      for (var ayah in surah.verses) {
        _flatAyahList!.add(AyahWithSurah(ayah: ayah, surah: surah));
      }
    }
  }

  /// Get total number of ayahs in the Quran
  int get totalAyahs => _flatAyahList?.length ?? 0;

  /// Get ayah of the day using deterministic formula: YYYYMMDD % totalAyahs
  Future<AyahWithSurah> getAyahOfTheDay({DateTime? date}) async {
    await initialize();

    final targetDate = date ?? DateTime.now();
    final dateNumber = _dateToNumber(targetDate);
    final index = dateNumber % totalAyahs;

    return _flatAyahList![index];
  }

  /// Get a specific ayah by Surah ID and Ayah ID
  AyahWithSurah getAyah(int surahId, int ayahId) {
    if (_surahs == null) {
      throw Exception('AyahSelectorService not initialized');
    }

    final surah = _surahs!.firstWhere(
      (s) => s.id == surahId,
      orElse: () => throw Exception('Surah not found'),
    );

    final ayah = surah.verses.firstWhere(
      (a) => a.id == ayahId,
      orElse: () => throw Exception('Ayah not found'),
    );

    return AyahWithSurah(ayah: ayah, surah: surah);
  }

  /// Get a random ayah that hasn't been read yet
  Future<AyahWithSurah> getUniqueRandomAyah(List<String> excludeIds) async {
    await initialize();

    // Filter out read ayahs
    final availableAyahs = _flatAyahList!.where((ayah) {
      final key = '${ayah.surah.id}_${ayah.ayah.id}';
      return !excludeIds.contains(key);
    }).toList();

    if (availableAyahs.isEmpty) {
      // All ayahs read! Reset cycle or just return random
      // For now, return purely random
      return getRandomAyah();
    }

    final index = _random.nextInt(availableAyahs.length);
    return availableAyahs[index];
  }

  /// Get random ayah (fallback)
  Future<AyahWithSurah> getRandomAyah() async {
    await initialize();
    final index = _random.nextInt(totalAyahs);
    return _flatAyahList![index];
  }

  /// Get unique ayah of the day (skips seen ones)
  Future<AyahWithSurah> getUniqueAyahOfTheDay(List<String> excludeIds) async {
    await initialize();

    final now = DateTime.now();
    int dateNumber = _dateToNumber(now);

    // Try to find a deterministic unique ayah
    // We loop up to totalAyahs times to find the next unseen one
    for (int i = 0; i < totalAyahs; i++) {
      final index = (dateNumber + i) % totalAyahs;
      final candidate = _flatAyahList![index];
      final key = '${candidate.surah.id}_${candidate.ayah.id}';

      if (!excludeIds.contains(key)) {
        return candidate;
      }
    }

    // If all seen, return standard daily ayah
    return getAyahOfTheDay();
  }

  /// Convert date to YYYYMMDD number
  int _dateToNumber(DateTime date) {
    return (date.year * 10000) + (date.month * 100) + date.day;
  }

  /// Get ayah by global index (0-based)
  AyahWithSurah? getAyahByIndex(int index) {
    if (_flatAyahList == null || index < 0 || index >= totalAyahs) {
      return null;
    }
    return _flatAyahList![index];
  }

  /// Get specific ayah by Surah ID and Ayah ID
  Future<AyahWithSurah?> getSpecificAyah(int surahId, int ayahId) async {
    await initialize();

    try {
      return _flatAyahList!.firstWhere(
        (item) => item.surah.id == surahId && item.ayah.id == ayahId,
      );
    } catch (e) {
      return null;
    }
  }
}
