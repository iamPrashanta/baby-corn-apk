// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationLogModelAdapter extends TypeAdapter<MedicationLogModel> {
  @override
  final int typeId = 31;

  @override
  MedicationLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationLogModel(
      id: fields[0] as String,
      medicationId: fields[1] as String,
      scheduledTime: fields[2] as DateTime,
      actualTime: fields[3] as DateTime?,
      status: fields[4] as String,
      note: fields[5] as String,
      takenBy: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicationId)
      ..writeByte(2)
      ..write(obj.scheduledTime)
      ..writeByte(3)
      ..write(obj.actualTime)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.takenBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
