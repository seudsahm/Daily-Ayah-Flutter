import 'package:hive/hive.dart';
import 'ayah_with_surah.dart';

part 'favorite_ayah.g.dart';

@HiveType(typeId: 0)
class FavoriteAyah extends HiveObject {
  @HiveField(0)
  final int surahId;

  @HiveField(1)
  final int ayahId;

  @HiveField(2)
  final String arabicText;

  @HiveField(3)
  final String translation;

  @HiveField(4)
  final String surahName;

  @HiveField(5)
  final String reference;

  @HiveField(6)
  final DateTime timestamp;

  FavoriteAyah({
    required this.surahId,
    required this.ayahId,
    required this.arabicText,
    required this.translation,
    required this.surahName,
    required this.reference,
    required this.timestamp,
  });

  factory FavoriteAyah.fromAyahWithSurah(AyahWithSurah ayahWithSurah) {
    return FavoriteAyah(
      surahId: ayahWithSurah.surah.id,
      ayahId: ayahWithSurah.ayah.id,
      arabicText: ayahWithSurah.arabicText,
      translation: ayahWithSurah.translation,
      surahName: ayahWithSurah.surahName,
      reference: ayahWithSurah.reference,
      timestamp: DateTime.now(),
    );
  }

  String get uniqueKey => '${surahId}_$ayahId';
}
