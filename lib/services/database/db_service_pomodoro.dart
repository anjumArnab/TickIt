// services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '/models/pomodoro/pomodoro_session.dart';

class DBServicePomodoro {
  static const String _sessionsBoxName = 'pomodoro_sessions';
  static const String _settingsBoxName = 'pomodoro_settings';
  static const String _statisticsBoxName = 'pomodoro_statistics';

  static Box<PomodoroSession>? _sessionsBox;
  static Box<PomodoroSettings>? _settingsBox;
  static Box? _statisticsBox;

  // Initialize Hive
  static Future<void> initHive() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(PomodoroSessionAdapter());
    Hive.registerAdapter(SessionTypeAdapter());
    Hive.registerAdapter(PomodoroSettingsAdapter());

    // Open boxes
    _sessionsBox = await Hive.openBox<PomodoroSession>(_sessionsBoxName);
    _settingsBox = await Hive.openBox<PomodoroSettings>(_settingsBoxName);
    _statisticsBox = await Hive.openBox(_statisticsBoxName);
  }

  // Session Management
  static Future<void> saveSession(PomodoroSession session) async {
    await _sessionsBox?.add(session);
  }

  static List<PomodoroSession> getAllSessions() {
    return _sessionsBox?.values.toList() ?? [];
  }

  static List<PomodoroSession> getSessionsForDate(DateTime date) {
    final sessions = getAllSessions();
    return sessions.where((session) {
      return session.startTime.year == date.year &&
          session.startTime.month == date.month &&
          session.startTime.day == date.day;
    }).toList();
  }

  static List<PomodoroSession> getSessionsForDateRange(
    DateTime start,
    DateTime end,
  ) {
    final sessions = getAllSessions();
    return sessions.where((session) {
      return session.startTime.isAfter(start) &&
          session.startTime.isBefore(end);
    }).toList();
  }

  static Future<void> deleteSession(int index) async {
    await _sessionsBox?.deleteAt(index);
  }

  static Future<void> clearAllSessions() async {
    await _sessionsBox?.clear();
  }

  // Settings Management
  static PomodoroSettings getSettings() {
    return _settingsBox?.get('settings') ?? PomodoroSettings();
  }

  static Future<void> saveSettings(PomodoroSettings settings) async {
    await _settingsBox?.put('settings', settings);
  }

  // Statistics Management
  static int getTotalCompletedSessions() {
    return _statisticsBox?.get('totalCompletedSessions', defaultValue: 0) ?? 0;
  }

  static Future<void> setTotalCompletedSessions(int count) async {
    await _statisticsBox?.put('totalCompletedSessions', count);
  }

  static int getTotalWorkMinutes() {
    return _statisticsBox?.get('totalWorkMinutes', defaultValue: 0) ?? 0;
  }

  static Future<void> setTotalWorkMinutes(int minutes) async {
    await _statisticsBox?.put('totalWorkMinutes', minutes);
  }

  static DateTime? getLastSessionDate() {
    final timestamp = _statisticsBox?.get('lastSessionDate');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  static Future<void> setLastSessionDate(DateTime date) async {
    await _statisticsBox?.put('lastSessionDate', date.millisecondsSinceEpoch);
  }

  // Analytics Methods
  static Map<String, int> getWeeklyStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final sessions = getSessionsForDateRange(
      weekStart,
      weekStart.add(Duration(days: 7)),
    );

    int workSessions = 0;
    int breakSessions = 0;
    int totalMinutes = 0;

    for (var session in sessions) {
      if (session.completed) {
        if (session.sessionType == SessionType.work) {
          workSessions++;
          totalMinutes += session.actualDuration ~/ 60;
        } else {
          breakSessions++;
        }
      }
    }

    return {
      'workSessions': workSessions,
      'breakSessions': breakSessions,
      'totalMinutes': totalMinutes,
    };
  }

  static double getAverageSessionLength() {
    final sessions =
        getAllSessions()
            .where((s) => s.completed && s.sessionType == SessionType.work)
            .toList();

    if (sessions.isEmpty) return 0.0;

    final totalMinutes = sessions
        .map((s) => s.actualDuration ~/ 60)
        .reduce((a, b) => a + b);

    return totalMinutes / sessions.length;
  }

  static int getStreakDays() {
    final sessions =
        getAllSessions()
            .where((s) => s.completed && s.sessionType == SessionType.work)
            .toList();

    if (sessions.isEmpty) return 0;

    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    int streak = 0;
    DateTime? lastDate;

    for (var session in sessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      if (lastDate == null) {
        lastDate = sessionDate;
        streak = 1;
      } else {
        final dayDifference = lastDate.difference(sessionDate).inDays;
        if (dayDifference == 1) {
          streak++;
          lastDate = sessionDate;
        } else if (dayDifference > 1) {
          break;
        }
      }
    }

    return streak;
  }

  // Cleanup
  static Future<void> close() async {
    await _sessionsBox?.close();
    await _settingsBox?.close();
    await _statisticsBox?.close();
  }
}
