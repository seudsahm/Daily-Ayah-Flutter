import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/app_settings.dart';
import 'models/favorite_ayah.dart';
import 'models/theme_mode.dart';
import 'models/collection.dart';
import 'screens/main_navigation.dart';
import 'services/favorites_service.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'services/theme_service.dart';
import 'services/streak_service.dart';
import 'services/badge_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(FavoriteAyahAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(AppThemeModeAdapter());
  Hive.registerAdapter(CollectionAdapter());

  // Initialize services
  final favoritesService = FavoritesService();
  await favoritesService.initialize();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Schedule daily notification if enabled
  final settingsBox = await Hive.openBox<AppSettings>('settings');
  final settings = settingsBox.get('app_settings');
  if (settings?.notificationsEnabled ?? true) {
    await notificationService.scheduleDailyNotification(
      hour: settings?.notificationHour ?? 9,
      minute: settings?.notificationMinute ?? 0,
    );
  }

  // Initialize and update widget
  final widgetService = WidgetService();
  await widgetService.initializeWidget();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  // Initialize gamification services
  final streakService = StreakService();
  await streakService.initialize();
  await streakService.checkDailyOpen(); // Update streak on app start

  final badgeService = BadgeService();
  await badgeService.initialize();
  await badgeService.checkNewUnlocks(); // Check for any immediate unlocks

  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;

  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'Daily Ayah',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.getThemeMode(),
          home: const MainNavigation(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
