part of 'pomodoro_session.dart';

class PomodoroSessionAdapter extends TypeAdapter<PomodoroSession> {
  @override
  final int typeId = 2;

  @override
  PomodoroSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroSession(
      startTime: fields[0] as DateTime,
      endTime: fields[1] as DateTime,
      sessionType: fields[2] as SessionType,
      plannedDuration: fields[3] as int,
      actualDuration: fields[4] as int,
      completed: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.endTime)
      ..writeByte(2)
      ..write(obj.sessionType)
      ..writeByte(3)
      ..write(obj.plannedDuration)
      ..writeByte(4)
      ..write(obj.actualDuration)
      ..writeByte(5)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PomodoroSettingsAdapter extends TypeAdapter<PomodoroSettings> {
  @override
  final int typeId = 4;

  @override
  PomodoroSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroSettings(
      workDuration: fields[0] as int,
      shortBreakDuration: fields[1] as int,
      longBreakDuration: fields[2] as int,
      sessionsUntilLongBreak: fields[3] as int,
      autoStartBreaks: fields[4] as bool,
      autoStartWorkSessions: fields[5] as bool,
      soundEnabled: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.workDuration)
      ..writeByte(1)
      ..write(obj.shortBreakDuration)
      ..writeByte(2)
      ..write(obj.longBreakDuration)
      ..writeByte(3)
      ..write(obj.sessionsUntilLongBreak)
      ..writeByte(4)
      ..write(obj.autoStartBreaks)
      ..writeByte(5)
      ..write(obj.autoStartWorkSessions)
      ..writeByte(6)
      ..write(obj.soundEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionTypeAdapter extends TypeAdapter<SessionType> {
  @override
  final int typeId = 3;

  @override
  SessionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionType.work;
      case 1:
        return SessionType.shortBreak;
      case 2:
        return SessionType.longBreak;
      default:
        return SessionType.work;
    }
  }

  @override
  void write(BinaryWriter writer, SessionType obj) {
    switch (obj) {
      case SessionType.work:
        writer.writeByte(0);
        break;
      case SessionType.shortBreak:
        writer.writeByte(1);
        break;
      case SessionType.longBreak:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
