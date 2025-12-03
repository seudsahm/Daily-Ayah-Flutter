import 'package:hive/hive.dart';

part 'badge.g.dart';

@HiveType(typeId: 6)
class Badge extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String icon; // Emoji or asset path

  @HiveField(4)
  final String category; // 'streak', 'collection', 'explorer', 'special'

  @HiveField(5)
  bool isUnlocked;

  @HiveField(6)
  DateTime? unlockedDate;

  @HiveField(7)
  final int requiredValue; // e.g., 7 days, 100 favorites

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.isUnlocked = false,
    this.unlockedDate,
    required this.requiredValue,
  });
}
