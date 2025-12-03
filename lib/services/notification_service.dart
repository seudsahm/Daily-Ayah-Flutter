import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigation will be handled by the app when it opens
    // The payload can be used to determine which screen to show
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Schedule daily notification at specific time
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    await initialize();

    // Cancel existing notifications first
    await cancelAllNotifications();

    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'daily_ayah_channel',
      'Daily Ayah Reminders',
      channelDescription: 'Daily reminders to read your ayah of the day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Schedule the notification
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0, // Notification ID
      'Daily Ayah Reminder',
      'Time to read today\'s ayah! 📖',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'today_screen',
    );

    print('Notification scheduled for $hour:$minute');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('All notifications cancelled');
  }

  /// Show a test notification immediately
  Future<void> showTestNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'daily_ayah_channel',
      'Daily Ayah Reminders',
      channelDescription: 'Daily reminders to read your ayah of the day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'Test Notification',
      'This is a test notification from Daily Ayah!',
      notificationDetails,
      payload: 'today_screen',
    );
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Show/update pinned quick glance notification
  Future<void> showQuickGlanceNotification(
    String arabicText,
    String translation,
    String reference,
  ) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'quick_glance_channel',
      'Quick Glance',
      channelDescription: 'Always visible notification showing today\'s ayah',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes it persistent
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1, // Different ID from daily reminder
      reference,
      '$arabicText\n$translation',
      notificationDetails,
      payload: 'today_screen',
    );
  }

  /// Cancel quick glance notification
  Future<void> cancelQuickGlance() async {
    await _notifications.cancel(1); // Same ID as quick glance
  }
}
