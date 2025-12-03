import 'package:hive/hive.dart';

part 'user_stats.g.dart';

@HiveType(typeId: 5)
class UserStats extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  int longestStreak;

  @HiveField(2)
  int totalDaysOpened;

  @HiveField(3)
  DateTime? lastOpenedDate;

  @HiveField(4)
  int totalFavorites;

  @HiveField(5)
  int totalAyahsRead;

  @HiveField(6)
  DateTime joinDate;

  @HiveField(7)
  List<String> readAyahIds;

  @HiveField(8)
  List<String> recentAyahIds;

  @HiveField(9, defaultValue: 0)
  int totalShares;

  @HiveField(10, defaultValue: 0)
  int totalPDFsGenerated;

  UserStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalDaysOpened = 0,
    this.lastOpenedDate,
    this.totalFavorites = 0,
    this.totalAyahsRead = 0,
    DateTime? joinDate,
    List<String>? readAyahIds,
    List<String>? recentAyahIds,
    this.totalShares = 0,
    this.totalPDFsGenerated = 0,
  }) : joinDate = joinDate ?? DateTime.now(),
       readAyahIds = readAyahIds ?? [],
       recentAyahIds = recentAyahIds ?? [];
}
