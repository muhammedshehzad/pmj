// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PeopleListViewHome.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class personHomeAdapter extends TypeAdapter<personHome> {
  @override
  final int typeId = 0;

  @override
  personHome read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return personHome(
      name: fields[0] as String,
      date: fields[1] as String,
      amount: fields[2] as int,
      donorId: fields[3] as String,
      method: fields[4] as String,
      month: fields[5] as String,
      year: fields[6] as String,
      status: fields[7] as String,
      documentPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, personHome obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.donorId)
      ..writeByte(4)
      ..write(obj.method)
      ..writeByte(5)
      ..write(obj.month)
      ..writeByte(6)
      ..write(obj.year)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.documentPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is personHomeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
