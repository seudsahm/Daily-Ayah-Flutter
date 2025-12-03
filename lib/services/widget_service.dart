import 'package:home_widget/home_widget.dart';
import 'ayah_selector_service.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  final AyahSelectorService _ayahService = AyahSelectorService();

  /// Initialize widget on app launch
  Future<void> initializeWidget() async {
    await updateWidget();
  }

  /// Update widget with today's ayah
  Future<void> updateWidget() async {
    try {
      // Get today's ayah
      final ayah = await _ayahService.getAyahOfTheDay();

      // Save data for widget
      await HomeWidget.saveWidgetData<String>('arabic_text', ayah.arabicText);
      await HomeWidget.saveWidgetData<String>('translation', ayah.translation);
      await HomeWidget.saveWidgetData<String>('reference', ayah.reference);

      // Update widget
      await HomeWidget.updateWidget(androidName: 'DailyAyahWidgetProvider');

      print('Widget updated successfully');
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
