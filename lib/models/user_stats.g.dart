// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStatsAdapter extends TypeAdapter<UserStats> {
  @override
  final int typeId = 5;

  @override
  UserStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserStats(
      currentStreak: fields[0] as int,
      longestStreak: fields[1] as int,
      totalDaysOpened: fields[2] as int,
      lastOpenedDate: fields[3] as DateTime?,
      totalFavorites: fields[4] as int,
      totalAyahsRead: fields[5] as int,
      joinDate: fields[6] as DateTime?,
      readAyahIds: (fields[7] as List?)?.cast<String>(),
      recentAyahIds: (fields[8] as List?)?.cast<String>(),
      totalShares: fields[9] == null ? 0 : fields[9] as int,
      totalPDFsGenerated: fields[10] == null ? 0 : fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserStats obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.currentStreak)
      ..writeByte(1)
      ..write(obj.longestStreak)
      ..writeByte(2)
      ..write(obj.totalDaysOpened)
      ..writeByte(3)
      ..write(obj.lastOpenedDate)
      ..writeByte(4)
      ..write(obj.totalFavorites)
      ..writeByte(5)
      ..write(obj.totalAyahsRead)
      ..writeByte(6)
      ..write(obj.joinDate)
      ..writeByte(7)
      ..write(obj.readAyahIds)
      ..writeByte(8)
      ..write(obj.recentAyahIds)
      ..writeByte(9)
      ..write(obj.totalShares)
      ..writeByte(10)
      ..write(obj.totalPDFsGenerated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
