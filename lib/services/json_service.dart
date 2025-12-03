import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah.dart';

class JsonService {
  static const String _quranPath = 'assets/data/quran_en.json';

  Future<List<Surah>> loadQuranData() async {
    try {
      final String jsonString = await rootBundle.loadString(_quranPath);
      final List<dynamic> data = json.decode(jsonString);
      return data
          .map((json) => Surah.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading Quran JSON: $e');
      rethrow;
    }
  }
}
