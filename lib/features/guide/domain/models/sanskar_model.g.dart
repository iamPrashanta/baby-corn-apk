// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sanskar_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SanskarRuleAdapter extends TypeAdapter<SanskarRule> {
  @override
  final int typeId = 3;

  @override
  SanskarRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SanskarRule(
      offset: fields[0] as int,
      unit: fields[1] as SanskarOffsetUnit,
      traditionalTimingText: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SanskarRule obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.offset)
      ..writeByte(1)
      ..write(obj.unit)
      ..writeByte(2)
      ..write(obj.traditionalTimingText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SanskarRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SanskarModelAdapter extends TypeAdapter<SanskarModel> {
  @override
  final int typeId = 2;

  @override
  SanskarModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SanskarModel(
      id: fields[0] as String,
      name: fields[1] as String,
      sanskritName: fields[2] as String,
      description: fields[3] as String,
      category: fields[4] as String,
      emojiIcon: fields[5] as String,
      defaultRule: fields[6] as SanskarRule,
      customDate: fields[7] as DateTime?,
      isCompleted: fields[8] as bool,
      notes: fields[9] as String,
      reminderEnabled: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SanskarModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sanskritName)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.emojiIcon)
      ..writeByte(6)
      ..write(obj.defaultRule)
      ..writeByte(7)
      ..write(obj.customDate)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.reminderEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SanskarModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SanskarOffsetUnitAdapter extends TypeAdapter<SanskarOffsetUnit> {
  @override
  final int typeId = 4;

  @override
  SanskarOffsetUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SanskarOffsetUnit.days;
      case 1:
        return SanskarOffsetUnit.months;
      case 2:
        return SanskarOffsetUnit.years;
      case 3:
        return SanskarOffsetUnit.beforeBirth;
      default:
        return SanskarOffsetUnit.days;
    }
  }

  @override
  void write(BinaryWriter writer, SanskarOffsetUnit obj) {
    switch (obj) {
      case SanskarOffsetUnit.days:
        writer.writeByte(0);
        break;
      case SanskarOffsetUnit.months:
        writer.writeByte(1);
        break;
      case SanskarOffsetUnit.years:
        writer.writeByte(2);
        break;
      case SanskarOffsetUnit.beforeBirth:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SanskarOffsetUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
