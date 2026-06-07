// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationModelAdapter extends TypeAdapter<MedicationModel> {
  @override
  final int typeId = 30;

  @override
  MedicationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicationModel(
      id: fields[0] as String,
      babyId: fields[1] as String,
      name: fields[2] as String,
      type: fields[3] as String,
      prescribedFor: fields[4] as String,
      scheduleType: fields[5] as String,
      times: (fields[6] as List).cast<String>(),
      doseAmount: fields[7] as double,
      doseUnit: fields[8] as String,
      totalQuantity: fields[9] as double,
      remainingQuantity: fields[10] as double,
      lowStockThreshold: fields[11] as double,
      startDate: fields[12] as DateTime,
      endDate: fields[13] as DateTime?,
      notes: fields[14] as String,
      isActive: fields[15] as bool,
      doctorName: fields[16] as String?,
      reason: fields[17] as String?,
      notifyBeforeMinutes: fields[18] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.babyId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.prescribedFor)
      ..writeByte(5)
      ..write(obj.scheduleType)
      ..writeByte(6)
      ..write(obj.times)
      ..writeByte(7)
      ..write(obj.doseAmount)
      ..writeByte(8)
      ..write(obj.doseUnit)
      ..writeByte(9)
      ..write(obj.totalQuantity)
      ..writeByte(10)
      ..write(obj.remainingQuantity)
      ..writeByte(11)
      ..write(obj.lowStockThreshold)
      ..writeByte(12)
      ..write(obj.startDate)
      ..writeByte(13)
      ..write(obj.endDate)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.isActive)
      ..writeByte(16)
      ..write(obj.doctorName)
      ..writeByte(17)
      ..write(obj.reason)
      ..writeByte(18)
      ..write(obj.notifyBeforeMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
