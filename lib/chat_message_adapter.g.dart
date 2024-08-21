// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveChatMessageAdapter extends TypeAdapter<HiveChatMessage> {
  @override
  final int typeId = 0;

  @override
  HiveChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveChatMessage(
      userId: fields[0] as String,
      createdAt: fields[1] as DateTime,
      text: fields[2] as String,
      imagePath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveChatMessage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
