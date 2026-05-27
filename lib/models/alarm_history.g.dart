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

class AlarmStatusAdapter extends TypeAdapter<AlarmStatus> {
  @override
  final int typeId = 3;

  @override
  AlarmStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlarmStatus.completed;
      case 1:
        return AlarmStatus.cheated;
      case 2:
        return AlarmStatus.missed;
      default:
        return AlarmStatus.completed;
    }
  }

  @override
  void write(BinaryWriter writer, AlarmStatus obj) {
    switch (obj) {
      case AlarmStatus.completed:
        writer.writeByte(0);
        break;
      case AlarmStatus.cheated:
        writer.writeByte(1);
        break;
      case AlarmStatus.missed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
