import 'dart:async';
import 'package:flutter/material.dart';
import '../models/hive/pomodoro_session.dart';
import '../services/hive/db_service_pomodoro.dart';

class PomodoroProvider extends ChangeNotifier {
  // Timer state
  Timer? _timer;
  int _seconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkSession = true;
  int _completedSessions = 0;
  DateTime? _currentSessionStart;

  // Settings
  PomodoroSettings _settings = PomodoroSettings();

  // Callback for session completion (to show dialog in UI)
  Function()? onSessionComplete;

  // Getters
  int get seconds => _seconds;
  bool get isRunning => _isRunning;
  bool get isWorkSession => _isWorkSession;
  int get completedSessions => _completedSessions;
  PomodoroSettings get settings => _settings;
  DateTime? get currentSessionStart => _currentSessionStart;

  // Initialize provider - load settings and statistics
  Future<void> initialize() async {
    await loadSettings();
    await loadStatistics();
  }

  // Load settings from database
  Future<void> loadSettings() async {
    try {
      _settings = DBServicePomodoro.getSettings();
      _seconds = _isWorkSession ? _settings.workDuration : _getBreakDuration();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      rethrow;
    }
  }

  // Save settings to database
  Future<void> saveSettings(PomodoroSettings newSettings) async {
    try {
      await DBServicePomodoro.saveSettings(newSettings);
      _settings = newSettings;
      _seconds = _isWorkSession ? _settings.workDuration : _getBreakDuration();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }

  // Load statistics from database
  Future<void> loadStatistics() async {
    try {
      _completedSessions = DBServicePomodoro.getTotalCompletedSessions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      rethrow;
    }
  }

  // Start timer
  void startTimer() {
    _isRunning = true;
    _currentSessionStart = DateTime.now();
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        _seconds--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });
  }

  // Pause timer
  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  // Reset timer
  Future<void> resetTimer() async {
    _timer?.cancel();

    // Save incomplete session if timer was running
    if (_currentSessionStart != null) {
      await _saveIncompleteSession();
    }

    _isRunning = false;
    _currentSessionStart = null;
    _seconds = _isWorkSession ? _settings.workDuration : _getBreakDuration();
    notifyListeners();
  }

  // Complete session - called when timer reaches 0
  Future<void> _completeSession() async {
    // Cancel the timer
    _timer?.cancel();

    // Save the completed session to database
    await _saveCompletedSession();

    // Update state based on session type
    if (_isWorkSession) {
      // Increment completed sessions count
      _completedSessions++;
      await DBServicePomodoro.setTotalCompletedSessions(_completedSessions);

      // Update total work minutes
      final currentTotal = DBServicePomodoro.getTotalWorkMinutes();
      await DBServicePomodoro.setTotalWorkMinutes(
        currentTotal + (_settings.workDuration ~/ 60),
      );

      // Switch to break session
      _isWorkSession = false;
      _seconds = _getBreakDuration();
    } else {
      // Break completed, switch back to work session
      _isWorkSession = true;
      _seconds = _settings.workDuration;
    }

    // Reset running state and session start time
    _isRunning = false;
    _currentSessionStart = null;

    // Update last session date
    await DBServicePomodoro.setLastSessionDate(DateTime.now());

    // Notify listeners to update UI
    notifyListeners();

    // Trigger callback to show completion dialog in UI
    // This will call _showSessionCompleteDialog in PomodoroTimerPage
    if (onSessionComplete != null) {
      onSessionComplete!();
    }

    // Auto-start next session if enabled in settings
    if ((_isWorkSession && _settings.autoStartWorkSessions) ||
        (!_isWorkSession && _settings.autoStartBreaks)) {
      // Wait 2 seconds before auto-starting
      await Future.delayed(const Duration(seconds: 2));
      startTimer();
    }
  }

  // Save completed session to database
  Future<void> _saveCompletedSession() async {
    if (_currentSessionStart == null) return;

    final sessionType = _isWorkSession
        ? SessionType.work
        : (_getBreakDuration() == _settings.longBreakDuration
            ? SessionType.longBreak
            : SessionType.shortBreak);

    final plannedDuration =
        _isWorkSession ? _settings.workDuration : _getBreakDuration();

    final session = PomodoroSession(
      startTime: _currentSessionStart!,
      endTime: DateTime.now(),
      sessionType: sessionType,
      plannedDuration: plannedDuration,
      actualDuration: plannedDuration,
      completed: true,
    );

    await DBServicePomodoro.saveSession(session);
  }

  // Save incomplete session to database (when user resets before completion)
  Future<void> _saveIncompleteSession() async {
    if (_currentSessionStart == null) return;

    final sessionType = _isWorkSession
        ? SessionType.work
        : (_getBreakDuration() == _settings.longBreakDuration
            ? SessionType.longBreak
            : SessionType.shortBreak);

    final plannedDuration =
        _isWorkSession ? _settings.workDuration : _getBreakDuration();
    final actualDuration = plannedDuration - _seconds;

    final session = PomodoroSession(
      startTime: _currentSessionStart!,
      endTime: DateTime.now(),
      sessionType: sessionType,
      plannedDuration: plannedDuration,
      actualDuration: actualDuration,
      completed: false,
    );

    await DBServicePomodoro.saveSession(session);
  }

  // Get break duration based on session count
  int _getBreakDuration() {
    return (_completedSessions % _settings.sessionsUntilLongBreak == 0 &&
            _completedSessions > 0)
        ? _settings.longBreakDuration
        : _settings.shortBreakDuration;
  }

  // Get today's completed sessions
  int getTodayCompletedSessions() {
    final todaySessions = DBServicePomodoro.getSessionsForDate(DateTime.now());
    return todaySessions
        .where((s) => s.completed && s.sessionType == SessionType.work)
        .length;
  }

  // Get weekly statistics
  Map<String, int> getWeeklyStats() {
    return DBServicePomodoro.getWeeklyStats();
  }

  // Get streak days
  int getStreakDays() {
    return DBServicePomodoro.getStreakDays();
  }

  // Get average session length
  double getAverageSessionLength() {
    return DBServicePomodoro.getAverageSessionLength();
  }

  // Format time for display (MM:SS)
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Get timer color based on session type
  Color getTimerColor() {
    if (_isWorkSession) {
      return Colors.red;
    } else {
      return _getBreakDuration() == _settings.longBreakDuration
          ? Colors.blue
          : Colors.green;
    }
  }

  // Get session type text for display
  String getSessionTypeText() {
    if (_isWorkSession) {
      return 'WORK SESSION';
    } else {
      return _getBreakDuration() == _settings.longBreakDuration
          ? 'LONG BREAK'
          : 'SHORT BREAK';
    }
  }

  // Dispose timer when provider is disposed
  @override
  void dispose() {
    _timer?.cancel();
    // Save incomplete session if timer was running
    if (_isRunning && _currentSessionStart != null) {
      _saveIncompleteSession();
    }
    super.dispose();
  }
}