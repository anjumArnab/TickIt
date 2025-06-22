import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String time;

  @HiveField(2)
  bool isMainTaskCompleted;

  @HiveField(3)
  int flagColorValue;

  @HiveField(4)
  List<Subtask> subtasks;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? workspace;

  @HiveField(7)
  int? workspaceColorValue;

  // Constructor
  Task({
    required this.title,
    required this.time,
    this.isMainTaskCompleted = false,
    required this.flagColorValue,
    required this.subtasks,
    required this.date,
    this.workspace,
    this.workspaceColorValue,
  });

  // Automatically calculated progress
  String get progress {
    if (subtasks.isEmpty) return "0/0";
    int completed = subtasks.where((s) => s.isCompleted).length;
    return "$completed/${subtasks.length}";
  }

  // Check if all subtasks are done
  bool get allSubtasksCompleted =>
      subtasks.isNotEmpty && subtasks.every((s) => s.isCompleted);
}

@HiveType(typeId: 1)
class Subtask {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isCompleted;

  Subtask({required this.title, this.isCompleted = false});
}
