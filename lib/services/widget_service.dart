import 'package:home_widget/home_widget.dart';

import 'streak_service.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  /// Initialize widget on app launch
  Future<void> initializeWidget() async {
    await updateWidget();
  }

  /// Update widget with streak data
  Future<void> updateWidget() async {
    try {
      // Get streak data
      final streakService = StreakService();
      await streakService.initialize();
      final streak = streakService.stats.currentStreak;

      // Save data for widget
      await HomeWidget.saveWidgetData<String>(
        'streak_count',
        streak.toString(),
      );
      await HomeWidget.saveWidgetData<String>('streak_label', 'Day Streak');

      // Update widget
      await HomeWidget.updateWidget(androidName: 'DailyAyahWidgetProvider');

      print('Widget updated successfully with streak: $streak');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Handle widget tap (opens app)
  static Future<void> onWidgetTapped(Uri? uri) async {
    // The app will open automatically when widget is tapped
    // This method can be used for custom navigation if needed
    print('Widget tapped: $uri');
  }
}
