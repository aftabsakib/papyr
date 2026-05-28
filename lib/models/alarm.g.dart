// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmAdapter extends TypeAdapter<Alarm> {
  @override
  final int typeId = 0;

  @override
  Alarm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Alarm(
      id: fields[0] as String,
      label: fields[1] as String,
      hour: fields[2] as int,
      minute: fields[3] as int,
      repeatDays: (fields[4] as List).cast<bool>(),
      missionType: fields[5] as MissionType,
      homeLat: fields[6] as double,
      homeLng: fields[7] as double,
      targetLat: fields[8] as double,
      targetLng: fields[9] as double,
      radiusMeters: fields[10] as double,
      isActive: fields[11] as bool,
      missionLabel: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Alarm obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minute)
      ..writeByte(4)
      ..write(obj.repeatDays)
      ..writeByte(5)
      ..write(obj.missionType)
      ..writeByte(6)
      ..write(obj.homeLat)
      ..writeByte(7)
      ..write(obj.homeLng)
      ..writeByte(8)
      ..write(obj.targetLat)
      ..writeByte(9)
      ..write(obj.targetLng)
      ..writeByte(10)
      ..write(obj.radiusMeters)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.missionLabel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MissionTypeAdapter extends TypeAdapter<MissionType> {
  @override
  final int typeId = 2;

  @override
  MissionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MissionType.distance;
      case 1:
        return MissionType.pin;
      case 2:
        return MissionType.activity;
      default:
        return MissionType.distance;
    }
  }

  @override
  void write(BinaryWriter writer, MissionType obj) {
    switch (obj) {
      case MissionType.distance:
        writer.writeByte(0);
        break;
      case MissionType.pin:
        writer.writeByte(1);
        break;
      case MissionType.activity:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
