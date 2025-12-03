// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_ayah.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoriteAyahAdapter extends TypeAdapter<FavoriteAyah> {
  @override
  final int typeId = 0;

  @override
  FavoriteAyah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteAyah(
      surahId: fields[0] as int,
      ayahId: fields[1] as int,
      arabicText: fields[2] as String,
      translation: fields[3] as String,
      surahName: fields[4] as String,
      reference: fields[5] as String,
      timestamp: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteAyah obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.surahId)
      ..writeByte(1)
      ..write(obj.ayahId)
      ..writeByte(2)
      ..write(obj.arabicText)
      ..writeByte(3)
      ..write(obj.translation)
      ..writeByte(4)
      ..write(obj.surahName)
      ..writeByte(5)
      ..write(obj.reference)
      ..writeByte(6)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteAyahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
