import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/surah.dart';

// Top-level function for isolate
List<Surah> _parseQuranData(String jsonString) {
  final List<dynamic> data = json.decode(jsonString);
  return data
      .map((json) => Surah.fromJson(json as Map<String, dynamic>))
      .toList();
}

class JsonService {
  static const String _quranPath = 'assets/data/quran_en.json';

  // Singleton pattern
  static final JsonService _instance = JsonService._internal();
  factory JsonService() => _instance;
  JsonService._internal();

  // In-memory cache
  List<Surah>? _cachedSurahs;
  bool _isLoading = false;
  Future<List<Surah>>? _loadingFuture;

  Future<List<Surah>> loadQuranData() async {
    // Return cached data if available
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    // If already loading, return the same future to avoid duplicate work
    if (_isLoading && _loadingFuture != null) {
      return _loadingFuture!;
    }

    _isLoading = true;
    _loadingFuture = _loadQuranDataInternal();

    try {
      _cachedSurahs = await _loadingFuture!;
      return _cachedSurahs!;
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Surah>> _loadQuranDataInternal() async {
    try {
      // Load JSON string from assets (fast, on main thread)
      final String jsonString = await rootBundle.loadString(_quranPath);

      // Parse JSON in background isolate (slow work off main thread)
      final surahs = await compute(_parseQuranData, jsonString);

      return surahs;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading Quran JSON: $e');
      }
      rethrow;
    }
  }

  // Clear cache if needed (for testing or memory management)
  void clearCache() {
    _cachedSurahs = null;
  }
}
