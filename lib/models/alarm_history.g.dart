// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmHistoryAdapter extends TypeAdapter<AlarmHistory> {
  @override
  final int typeId = 1;

  @override
  AlarmHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmHistory(
      id: fields[0] as String,
      alarmId: fields[1] as String,
      firedAt: fields[2] as DateTime,
      status: fields[3] as AlarmStatus,
      photoPath: fields[4] as String?,
      secondsToComplete: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmHistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.alarmId)
      ..writeByte(2)
      ..write(obj.firedAt)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.photoPath)
      ..writeByte(5)
      ..write(obj.secondsToComplete);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
