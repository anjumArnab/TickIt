import 'package:hive/hive.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 2)
class PomodoroSession extends HiveObject {
  @HiveField(0)
  DateTime startTime;

  @HiveField(1)
  DateTime endTime;

  @HiveField(2)
  SessionType sessionType;

  @HiveField(3)
  int plannedDuration; // in seconds

  @HiveField(4)
  int actualDuration; // in seconds

  @HiveField(5)
  bool completed;

  PomodoroSession({
    required this.startTime,
    required this.endTime,
    required this.sessionType,
    required this.plannedDuration,
    required this.actualDuration,
    required this.completed,
  });

  @override
  String toString() {
    return 'PomodoroSession(startTime: $startTime, endTime: $endTime, sessionType: $sessionType, completed: $completed)';
  }
}

@HiveType(typeId: 3)
enum SessionType {
  @HiveField(0)
  work,

  @HiveField(1)
  shortBreak,

  @HiveField(2)
  longBreak,
}

@HiveType(typeId: 4)
class PomodoroSettings extends HiveObject {
  @HiveField(0)
  int workDuration; // in seconds

  @HiveField(1)
  int shortBreakDuration; // in seconds

  @HiveField(2)
  int longBreakDuration; // in seconds

  @HiveField(3)
  int sessionsUntilLongBreak;

  @HiveField(4)
  bool autoStartBreaks;

  @HiveField(5)
  bool autoStartWorkSessions;

  @HiveField(6)
  bool soundEnabled;

  PomodoroSettings({
    this.workDuration = 25 * 60,
    this.shortBreakDuration = 5 * 60,
    this.longBreakDuration = 15 * 60,
    this.sessionsUntilLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartWorkSessions = false,
    this.soundEnabled = true,
  });
}
