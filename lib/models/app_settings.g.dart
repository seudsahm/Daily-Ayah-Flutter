// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      notificationsEnabled: fields[0] as bool,
      notificationHour: fields[1] as int,
      notificationMinute: fields[2] as int,
      enableQuickGlance: fields[3] as bool,
      lastDailyAyahSurahId: fields[4] as int?,
      lastDailyAyahAyahId: fields[5] as int?,
      lastDailyAyahDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.notificationsEnabled)
      ..writeByte(1)
      ..write(obj.notificationHour)
      ..writeByte(2)
      ..write(obj.notificationMinute)
      ..writeByte(3)
      ..write(obj.enableQuickGlance)
      ..writeByte(4)
      ..write(obj.lastDailyAyahSurahId)
      ..writeByte(5)
      ..write(obj.lastDailyAyahAyahId)
      ..writeByte(6)
      ..write(obj.lastDailyAyahDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
