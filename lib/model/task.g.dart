part of 'task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
        title: fields[0] as String,
        time: fields[1] as String,
        progress: fields[2] as String,
        subtasks: (fields[4] as List).cast<String>(),
        date: fields[5] as DateTime,
        workspace: fields[6] as String?,
        flagColor: Color(fields[3] as int),
      )
      ..flagColorValue = fields[3] as int
      ..workspaceColorValue = fields[7] as int?;
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.progress)
      ..writeByte(3)
      ..write(obj.flagColorValue)
      ..writeByte(4)
      ..write(obj.subtasks)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.workspace)
      ..writeByte(7)
      ..write(obj.workspaceColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
