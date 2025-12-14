import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/app_settings.dart';
import 'models/favorite_ayah.dart';
import 'models/theme_mode.dart';
import 'models/collection.dart';
import 'models/hive_adapters.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'services/theme_service.dart';
import 'services/streak_service.dart';
import 'services/badge_service.dart';
import 'services/app_initialization_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  final ThemeService _themeService = ThemeService();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Initialize Hive
    await Hive.initFlutter();

    // 2. Register Adapters
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(AyahAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SurahAdapter());
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FavoriteAyahAdapter());
    }
    // Note: Assuming adapter IDs based on previous code context or standard usage
    // Using try-catch or checks for safety if IDs unknown, but typically:
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(AppThemeModeAdapter());
    Hive.registerAdapter(CollectionAdapter());

    // 3. Initialize Theme (fast)
    await _themeService.initialize();

    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      // Return a container that matches the native splash background
      // or a simple white/colored screen to prevent "Black Screen"
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(color: Colors.white), // Match splash color
        ),
      );
    }

    return MyApp(themeService: _themeService);
  }
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
          home: const AppLoadingScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Loading screen that initializes all services before showing main app
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  String _loadingStatus = 'Initializing...';
  double _progress = 0.1;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize core app services (Now checks DB or imports JSON)
      setState(() {
        _loadingStatus = 'Setting up Quran data...';
        _progress = 0.3;
      });

      final appInit = AppInitializationService();
      await appInit.initialize();

      // Initialize notification service
      setState(() {
        _loadingStatus = 'Checking notifications...';
        _progress = 0.5;
      });
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();

      // Schedule daily notification if enabled
      Box<AppSettings> settingsBox;
      if (Hive.isBoxOpen('settings')) {
        settingsBox = Hive.box<AppSettings>('settings');
      } else {
        settingsBox = await Hive.openBox<AppSettings>('settings');
      }
      final settings = settingsBox.get('app_settings');
      if (settings?.notificationsEnabled ?? true) {
        await notificationService.scheduleDailyNotification(
          hour: settings?.notificationHour ?? 9,
          minute: settings?.notificationMinute ?? 0,
        );
      }

      // Initialize and update widget
      setState(() {
        _loadingStatus = 'Updating widgets...';
        _progress = 0.7;
      });
      final widgetService = WidgetService();
      await widgetService.initializeWidget();

      // Update streak and check for badges
      setState(() {
        _loadingStatus = 'Syncing progress...';
        _progress = 0.9;
      });
      final streakService = StreakService();
      await streakService.checkDailyOpen();
      // Only do badge check after streak service
      final badgeService = BadgeService();
      await badgeService.checkNewUnlocks();

      // Mark as ready
      setState(() {
        _loadingStatus = 'Ready!';
        _progress = 1.0;
      });

      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      setState(() => _loadingStatus = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 32),
              const Text(
                'Daily Ayah',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _loadingStatus,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
