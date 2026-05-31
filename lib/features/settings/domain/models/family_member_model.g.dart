// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FamilyMemberModelAdapter extends TypeAdapter<FamilyMemberModel> {
  @override
  final int typeId = 40;

  @override
  FamilyMemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FamilyMemberModel(
      id: fields[0] as String,
      babyId: fields[1] as String,
      name: fields[2] as String,
      phoneNumber: fields[3] as String,
      email: fields[4] as String,
      role: fields[5] as String,
      status: fields[6] as String,
      invitedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyMemberModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.babyId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.invitedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
