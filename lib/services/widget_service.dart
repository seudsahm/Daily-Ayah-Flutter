import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../widgets/home_screen_widget.dart';

import 'streak_service.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  /// Initialize widget on app launch
  Future<void> initializeWidget() async {
    await updateWidget();
  }

  /// Update widget with streak and ayahs data
  Future<void> updateWidget() async {
    try {
      // Get streak data using async getter (ensures initialization)
      final streakService = StreakService();
      final userStats = await streakService.getStatsAsync();
      final streak = userStats.currentStreak;
      final uniqueAyahsRead = userStats.readAyahIds.length;

      // Render the widget to an image
      // Note: renderFlutterWidget renders the widget as a PNG image
      final path = await HomeWidget.renderFlutterWidget(
        DailyAyahHomeWidget(streak: streak, ayahsRead: uniqueAyahsRead),
        key: 'widget_image',
        logicalSize: const Size(330, 165),
        pixelRatio: 3.0, // Ultra high quality
      );

      if (path != null) {
        // Save the image path
        await HomeWidget.saveWidgetData<String>('widget_image_path', path);
      } else {
        if (kDebugMode) {
          print('Error rendering widget: Path is null');
        }
      }

      // Update widget
      // We pass the class name of the Android WidgetProvider
      await HomeWidget.updateWidget(androidName: 'DailyAyahWidgetProvider');

      if (kDebugMode) {
        print(
          'Widget updated - Streak: $streak, Ayahs: $uniqueAyahsRead, Path: $path',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating widget: $e');
      }
    }
  }

  /// Handle widget tap (opens app)
  static Future<void> onWidgetTapped(Uri? uri) async {
    // The app will open automatically when widget is tapped
    // This method can be used for custom navigation if needed
    if (kDebugMode) {
      print('Widget tapped: $uri');
    }
  }
}
