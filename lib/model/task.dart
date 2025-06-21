import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String time;

  @HiveField(2)
  String progress;

  @HiveField(3)
  int flagColorValue; // Store color as int value

  @HiveField(4)
  List<String> subtasks;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? workspace;

  @HiveField(7)
  int? workspaceColorValue; // Store color as int value

  Task({
    required this.title,
    required this.time,
    required this.progress,
    required Color flagColor,
    required this.subtasks,
    required this.date,
    this.workspace,
    Color? workspaceColor,
  }) : flagColorValue = flagColor.value,
       workspaceColorValue = workspaceColor?.value;

  // Getters to convert int values back to Colors
  Color get flagColor => Color(flagColorValue);
  Color? get workspaceColor =>
      workspaceColorValue != null ? Color(workspaceColorValue!) : null;

  // Setters to update colors
  set flagColor(Color color) => flagColorValue = color.value;
  set workspaceColor(Color? color) => workspaceColorValue = color?.value;
}
