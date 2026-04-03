// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArticleAdapter extends TypeAdapter<Article> {
  @override
  final int typeId = 0;

  @override
  Article read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Article()
      ..url = fields[0] as String
      ..title = fields[1] as String
      ..thumbnailUrl = fields[2] as String?
      ..platform = fields[3] as Platform
      ..topicLabels = (fields[4] as List).cast<String>()
      ..isRead = fields[5] as bool
      ..createdAt = fields[6] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Article obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.thumbnailUrl)
      ..writeByte(3)
      ..write(obj.platform)
      ..writeByte(4)
      ..write(obj.topicLabels)
      ..writeByte(5)
      ..write(obj.isRead)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlatformAdapter extends TypeAdapter<Platform> {
  @override
  final int typeId = 1;

  @override
  Platform read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Platform.youtube;
      case 1:
        return Platform.instagram;
      case 2:
        return Platform.blog;
      case 3:
        return Platform.etc;
      default:
        return Platform.youtube;
    }
  }

  @override
  void write(BinaryWriter writer, Platform obj) {
    switch (obj) {
      case Platform.youtube:
        writer.writeByte(0);
        break;
      case Platform.instagram:
        writer.writeByte(1);
        break;
      case Platform.blog:
        writer.writeByte(2);
        break;
      case Platform.etc:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
