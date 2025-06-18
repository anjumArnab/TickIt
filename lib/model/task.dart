import 'package:flutter/material.dart';

class Task {
  final String title;
  final String time;
  final String progress;
  final Color flagColor;
  final List<String> subtasks;
  final DateTime date;

  Task({
    required this.title,
    required this.time,
    required this.progress,
    required this.flagColor,
    required this.subtasks,
    required this.date,
  });
}
