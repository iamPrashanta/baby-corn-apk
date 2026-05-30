// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MomentModelAdapter extends TypeAdapter<MomentModel> {
  @override
  final int typeId = 20;

  @override
  MomentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MomentModel(
      id: fields[0] as String,
      babyId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      title: fields[3] as String,
      description: fields[4] as String,
      imagePath: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MomentModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.babyId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MomentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
