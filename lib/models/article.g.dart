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
      ..createdAt = fields[6] as DateTime
      ..isBookmarked = fields[7] == null ? false : fields[7] as bool
      ..memo = fields[8] as String?;
  }

  @override
  void write(BinaryWriter writer, Article obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isBookmarked)
      ..writeByte(8)
      ..write(obj.memo);
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
      case 4:
        return Platform.x;
      case 5:
        return Platform.tiktok;
      case 6:
        return Platform.facebook;
      case 7:
        return Platform.linkedin;
      case 8:
        return Platform.github;
      case 9:
        return Platform.reddit;
      case 10:
        return Platform.naverBlog;
      case 11:
        return Platform.threads;
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
      case Platform.x:
        writer.writeByte(4);
        break;
      case Platform.tiktok:
        writer.writeByte(5);
        break;
      case Platform.facebook:
        writer.writeByte(6);
        break;
      case Platform.linkedin:
        writer.writeByte(7);
        break;
      case Platform.github:
        writer.writeByte(8);
        break;
      case Platform.reddit:
        writer.writeByte(9);
        break;
      case Platform.naverBlog:
        writer.writeByte(10);
        break;
      case Platform.threads:
        writer.writeByte(11);
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
