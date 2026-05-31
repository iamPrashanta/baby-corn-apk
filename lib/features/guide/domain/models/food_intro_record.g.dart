// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_intro_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodIntroRecordAdapter extends TypeAdapter<FoodIntroRecord> {
  @override
  final int typeId = 51;

  @override
  FoodIntroRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodIntroRecord(
      id: fields[0] as String,
      babyId: fields[1] as String,
      foodName: fields[2] as String,
      dateIntroduced: fields[3] as DateTime,
      status: fields[4] as FoodIntroStatus,
      symptoms: (fields[5] as List).cast<String>(),
      notes: fields[6] as String,
      ageInMonthsAtIntroduction: fields[7] as int,
      doctorNote: fields[8] as String?,
      doctorVisitDate: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodIntroRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.babyId)
      ..writeByte(2)
      ..write(obj.foodName)
      ..writeByte(3)
      ..write(obj.dateIntroduced)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.symptoms)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.ageInMonthsAtIntroduction)
      ..writeByte(8)
      ..write(obj.doctorNote)
      ..writeByte(9)
      ..write(obj.doctorVisitDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodIntroRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodIntroStatusAdapter extends TypeAdapter<FoodIntroStatus> {
  @override
  final int typeId = 50;

  @override
  FoodIntroStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FoodIntroStatus.observing;
      case 1:
        return FoodIntroStatus.safe;
      case 2:
        return FoodIntroStatus.reaction;
      case 3:
        return FoodIntroStatus.avoid;
      default:
        return FoodIntroStatus.observing;
    }
  }

  @override
  void write(BinaryWriter writer, FoodIntroStatus obj) {
    switch (obj) {
      case FoodIntroStatus.observing:
        writer.writeByte(0);
        break;
      case FoodIntroStatus.safe:
        writer.writeByte(1);
        break;
      case FoodIntroStatus.reaction:
        writer.writeByte(2);
        break;
      case FoodIntroStatus.avoid:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodIntroStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
