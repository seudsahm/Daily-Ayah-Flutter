import 'package:hive/hive.dart';

part 'theme_mode.g.dart';

@HiveType(typeId: 3)
enum AppThemeMode {
  @HiveField(0)
  light,

  @HiveField(1)
  dark,

  @HiveField(2)
  system,
}
