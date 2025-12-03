import '../models/ayah_with_surah.dart';
import '../services/ayah_selector_service.dart';

class SearchService {
  final AyahSelectorService _ayahService = AyahSelectorService();
  List<AyahWithSurah> _allAyahs = [];
  bool _indexed = false;

  // Singleton pattern
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  /// Initialize and index all ayahs
  Future<void> initialize() async {
    if (_indexed) return;

    await _ayahService.initialize();
    // Get all ayahs by iterating through surahs
    final allAyahs = <AyahWithSurah>[];
    for (int surahId = 1; surahId <= 114; surahId++) {
      // Try to get ayahs - most surahs have fewer than 300 ayahs
      for (int ayahId = 1; ayahId <= 300; ayahId++) {
        final ayah = await _ayahService.getSpecificAyah(surahId, ayahId);
        if (ayah != null) {
          allAyahs.add(ayah);
        } else {
          break; // No more ayahs in this surah
        }
      }
    }
    _allAyahs = allAyahs;
    _indexed = true;
  }

  /// Search ayahs by query (Arabic or English)
  Future<List<AyahWithSurah>> search(
    String query, {
    bool favoritesOnly = false,
  }) async {
    await initialize();

    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    return _allAyahs.where((ayah) {
      // Search in Arabic text (case-sensitive for Arabic)
      final arabicMatch = ayah.ayah.text.contains(query);

      // Search in English translation (case-insensitive)
      final translationMatch = ayah.ayah.translation.toLowerCase().contains(
        lowerQuery,
      );

      // Search in surah name
      final surahMatch = ayah.surah.name.toLowerCase().contains(lowerQuery);

      return arabicMatch || translationMatch || surahMatch;
    }).toList();
  }

  /// Get highlighted text for search results
  String getHighlightedText(String text, String query) {
    if (query.isEmpty) return text;

    // For display purposes, we'll just return the text
    // Actual highlighting will be done in the UI
    return text;
  }
}
