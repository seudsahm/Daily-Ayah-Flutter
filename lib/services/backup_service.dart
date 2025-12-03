import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'favorites_service.dart';
import '../models/favorite_ayah.dart';
import '../models/ayah_with_surah.dart';
import '../services/ayah_selector_service.dart';
import '../services/streak_service.dart';
import '../services/badge_service.dart';

class BackupService {
  final FavoritesService _favoritesService = FavoritesService();
  final AyahSelectorService _ayahSelectorService = AyahSelectorService();

  /// Export favorites to a JSON file and share it
  Future<void> exportFavorites(BuildContext context) async {
    try {
      await _favoritesService.initialize();
      final favorites = _favoritesService.getAllFavorites();

      if (favorites.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No favorites to export')),
          );
        }
        return;
      }

      // Convert favorites to JSON-encodable list
      final List<Map<String, dynamic>> jsonList = favorites.map((fav) {
        return {
          'surahId': fav.surahId,
          'ayahId': fav.ayahId,
          'timestamp': fav.timestamp.toIso8601String(),
        };
      }).toList();

      final jsonString = jsonEncode(jsonList);

      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/daily_ayah_favorites.json');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Daily Ayah Favorites Backup');

      // Increment share stats
      final streakService = StreakService();
      await streakService.initialize();
      await streakService.incrementShares();

      // Check for badges
      final badgeService = BadgeService();
      await badgeService.initialize();
      final newBadges = await badgeService.checkNewUnlocks();

      if (newBadges.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unlocked: ${newBadges.first.name} ${newBadges.first.icon}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.amber,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  /// Import favorites from a JSON file
  Future<void> importFavorites(BuildContext context) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return; // User canceled

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);

      await _favoritesService.initialize();
      int importedCount = 0;

      for (var item in jsonList) {
        if (item is Map<String, dynamic> &&
            item.containsKey('surahId') &&
            item.containsKey('ayahId')) {
          final surahId = item['surahId'] as int;
          final ayahId = item['ayahId'] as int;

          // Verify ayah exists
          try {
            final ayahWithSurah = _ayahSelectorService.getAyah(surahId, ayahId);
            if (!_favoritesService.isFavorite(surahId, ayahId)) {
              await _favoritesService.addFavorite(ayahWithSurah);
              importedCount++;
            }
          } catch (e) {
            // Skip invalid ayahs
            continue;
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importedCount favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
