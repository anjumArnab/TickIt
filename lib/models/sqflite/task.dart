import '/models/sqflite/subtask.dart';

class Task {
  int? id;
  String title;
  String time;
  bool isMainTaskCompleted;
  int flagColorValue;
  List<Subtask> subtasks;
  DateTime date;
  String? workspace;
  int? workspaceColorValue;

  Task({
    this.id,
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

  // Convert Task to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'isMainTaskCompleted': isMainTaskCompleted ? 1 : 0,
      'flagColorValue': flagColorValue,
      'date': date.toIso8601String(),
      'workspace': workspace,
      'workspaceColorValue': workspaceColorValue,
    };
  }

  // Create Task from Map (without subtasks - they're loaded separately)
  factory Task.fromMap(Map<String, dynamic> map, {List<Subtask>? subtasks}) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      time: map['time'] as String,
      isMainTaskCompleted: map['isMainTaskCompleted'] == 1,
      flagColorValue: map['flagColorValue'] as int,
      subtasks: subtasks ?? [],
      date: DateTime.parse(map['date'] as String),
      workspace: map['workspace'] as String?,
      workspaceColorValue: map['workspaceColorValue'] as int?,
    );
  }
}