// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LabelAdapter extends TypeAdapter<Label> {
  @override
  final int typeId = 2;

  @override
  Label read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Label()
      ..name = fields[0] as String
      ..colorValue = fields[1] as int
      ..createdAt = fields[2] as DateTime
      ..notificationEnabled = fields[3] == null ? false : fields[3] as bool
      ..notificationDays =
          fields[4] == null ? [] : (fields[4] as List).cast<int>()
      ..notificationTime = fields[5] == null ? '09:00' : fields[5] as String
      ..firestoreId = fields[6] as String?
      ..updatedAt = fields[7] as DateTime?
      ..deletedAt = fields[8] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, Label obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.colorValue)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.notificationEnabled)
      ..writeByte(4)
      ..write(obj.notificationDays)
      ..writeByte(5)
      ..write(obj.notificationTime)
      ..writeByte(6)
      ..write(obj.firestoreId)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
