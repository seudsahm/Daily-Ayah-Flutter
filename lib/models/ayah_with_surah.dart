import 'ayah.dart';
import 'surah.dart';

class AyahWithSurah {
  final Ayah ayah;
  final Surah surah;

  AyahWithSurah({required this.ayah, required this.surah});

  String get surahName => surah.transliteration;
  String get arabicText => ayah.text;
  String get translation => ayah.translation;
  int get ayahNumber => ayah.id;

  String get reference => '$surahName ${surah.id}:${ayah.id}';
}
