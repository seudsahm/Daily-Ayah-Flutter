import 'package:hive/hive.dart';

part 'collection.g.dart';

@HiveType(typeId: 4)
class Collection extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  List<String> ayahKeys; // Format: "surahId_ayahId"

  Collection({
    required this.id,
    required this.name,
    required this.createdAt,
    List<String>? ayahKeys,
  }) : ayahKeys = ayahKeys ?? [];
}
