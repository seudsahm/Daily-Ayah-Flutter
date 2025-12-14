import 'package:hive/hive.dart';
import 'ayah.dart';
import 'surah.dart';

class AyahAdapter extends TypeAdapter<Ayah> {
  @override
  final int typeId = 10;

  @override
  Ayah read(BinaryReader reader) {
    return Ayah(
      id: reader.readInt(),
      text: reader.readString(),
      translation: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Ayah obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.text);
    writer.writeString(obj.translation);
  }
}

class SurahAdapter extends TypeAdapter<Surah> {
  @override
  final int typeId = 11;

  @override
  Surah read(BinaryReader reader) {
    // Read list of ayahs
    final int versesCount = reader.readInt();
    final List<Ayah> verses = [];
    for (int i = 0; i < versesCount; i++) {
      verses.add(AyahAdapter().read(reader));
    }

    return Surah(
      id: reader.readInt(),
      name: reader.readString(),
      transliteration: reader.readString(),
      translation: reader.readString(),
      type: reader.readString(),
      totalVerses: reader.readInt(),
      verses: verses,
    );
  }

  @override
  void write(BinaryWriter writer, Surah obj) {
    // Write list of ayahs explicitly to avoid registering another adapter dependency if possible,
    // though cleaner to delegating.
    // However, Hive usually handles nested logic if type is known.
    // For manual adapter, let's write list length then items.
    writer.writeInt(obj.verses.length);
    for (var ayah in obj.verses) {
      AyahAdapter().write(writer, ayah);
    }

    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.transliteration);
    writer.writeString(obj.translation);
    writer.writeString(obj.type);
    writer.writeInt(obj.totalVerses);
  }
}
