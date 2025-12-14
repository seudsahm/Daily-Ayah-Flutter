import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  tz.Location? _localTimezone;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tzdata.initializeTimeZones();

    // Try to detect device timezone, fallback to Africa/Addis_Ababa for Ethiopia
    try {
      // Get device's timezone offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Find timezone that matches the offset (Ethiopia is +3:00)
      if (offset.inHours == 3 && offset.inMinutes % 60 == 0) {
        _localTimezone = tz.getLocation('Africa/Addis_Ababa');
      } else {
        // Try to find matching timezone by offset
        _localTimezone = _findTimezoneByOffset(offset);
      }

      tz.setLocalLocation(_localTimezone!);

      if (kDebugMode) {
        print(
          'Timezone set to: ${_localTimezone!.name} (offset: ${offset.inHours}h ${offset.inMinutes % 60}m)',
        );
      }
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      _localTimezone = tz.getLocation('Africa/Addis_Ababa');
      tz.setLocalLocation(_localTimezone!);
      if (kDebugMode) {
        print('Timezone detection failed, using Africa/Addis_Ababa: $e');
      }
    }

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

  /// Find timezone by offset
  tz.Location _findTimezoneByOffset(Duration offset) {
    // Common timezones by offset
    final timezoneMap = {
      3: 'Africa/Addis_Ababa', // Ethiopia, Kenya, etc.
      0: 'UTC',
      1: 'Europe/Paris',
      2: 'Europe/Athens',
      4: 'Asia/Dubai',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      7: 'Asia/Bangkok',
      8: 'Asia/Singapore',
      9: 'Asia/Tokyo',
      -5: 'America/New_York',
      -6: 'America/Chicago',
      -7: 'America/Denver',
      -8: 'America/Los_Angeles',
    };

    final hours = offset.inHours;
    final tzName = timezoneMap[hours] ?? 'UTC';
    return tz.getLocation(tzName);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigation will be handled by the app when it opens
    // The payload can be used to determine which screen to show
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
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

    if (kDebugMode) {
      final formattedHour = hour.toString().padLeft(2, '0');
      final formattedMinute = minute.toString().padLeft(2, '0');
      print(
        'Notification scheduled for $formattedHour:$formattedMinute (${_localTimezone?.name ?? "local"})',
      );
      print('Next notification at: $scheduledDate');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    if (kDebugMode) {
      print('All notifications cancelled');
    }
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
