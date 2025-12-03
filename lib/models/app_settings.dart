import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool notificationsEnabled;

  @HiveField(1)
  int notificationHour;

  @HiveField(2)
  int notificationMinute;

  @HiveField(3)
  bool enableQuickGlance;

  AppSettings({
    this.notificationsEnabled = true,
    this.notificationHour = 9,
    this.notificationMinute = 0,
    this.enableQuickGlance = false,
    this.lastDailyAyahSurahId,
    this.lastDailyAyahAyahId,
    this.lastDailyAyahDate,
  });

  @HiveField(4)
  int? lastDailyAyahSurahId;

  @HiveField(5)
  int? lastDailyAyahAyahId;

  @HiveField(6)
  DateTime? lastDailyAyahDate;

  String get notificationTimeString {
    final hour = notificationHour.toString().padLeft(2, '0');
    final minute = notificationMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
