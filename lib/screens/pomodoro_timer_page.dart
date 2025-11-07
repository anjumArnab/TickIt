import 'dart:async';

import 'package:flutter/material.dart';
import '../models/hive/pomodoro_session.dart';
import '../services/hive/db_service_pomodoro.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  Timer? _timer;
  int _seconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkSession = true;
  int _completedSessions = 0;

  DateTime? _currentSessionStart;
  PomodoroSettings _settings = PomodoroSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStatistics();
  }

  Future<void> _loadSettings() async {
    final settings = DBServicePomodoro.getSettings();
    setState(() {
      _settings = settings;
      _seconds = _isWorkSession ? _settings.workDuration : _getBreakDuration();
    });
  }

  Future<void> _loadStatistics() async {
    final totalSessions = DBServicePomodoro.getTotalCompletedSessions();
    setState(() {
      _completedSessions = totalSessions;
    });
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _currentSessionStart = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _completeSession();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    _timer?.cancel();

    if (_currentSessionStart != null) {
      _saveIncompleteSession();
    }

    setState(() {
      _isRunning = false;
      _currentSessionStart = null;
      _seconds = _isWorkSession ? _settings.workDuration : _getBreakDuration();
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();

    await _saveCompletedSession();

    setState(() {
      _isRunning = false;

      if (_isWorkSession) {
        _completedSessions++;
        DBServicePomodoro.setTotalCompletedSessions(_completedSessions);

        final currentTotal = DBServicePomodoro.getTotalWorkMinutes();
        DBServicePomodoro.setTotalWorkMinutes(
          currentTotal + (_settings.workDuration ~/ 60),
        );

        _isWorkSession = false;
        _seconds = _getBreakDuration();
      } else {
        _isWorkSession = true;
        _seconds = _settings.workDuration;
      }

      _currentSessionStart = null;
    });

    await DBServicePomodoro.setLastSessionDate(DateTime.now());

    _showSessionCompleteDialog();

    if ((_isWorkSession && _settings.autoStartWorkSessions) ||
        (!_isWorkSession && _settings.autoStartBreaks)) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _startTimer();
      });
    }
  }

  Future<void> _saveCompletedSession() async {
    if (_currentSessionStart == null) return;

    final sessionType =
        _isWorkSession
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

  Future<void> _saveIncompleteSession() async {
    if (_currentSessionStart == null) return;

    final sessionType =
        _isWorkSession
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

  int _getBreakDuration() {
    return (_completedSessions % _settings.sessionsUntilLongBreak == 0 &&
            _completedSessions > 0)
        ? _settings.longBreakDuration
        : _settings.shortBreakDuration;
  }

  void _showSessionCompleteDialog() {
    String title =
        _isWorkSession ? "Break Complete!" : "Work Session Complete!";
    String message =
        _isWorkSession
            ? "Ready for another work session?"
            : "Time for a ${_getBreakDuration() == _settings.longBreakDuration ? 'long' : 'short'} break!";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 10),
              Text(
                'Sessions completed today: ${_getTodayCompletedSessions()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('View Stats'),
              onPressed: () {
                Navigator.of(context).pop();
                _showStatsDialog();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int _getTodayCompletedSessions() {
    final todaySessions = DBServicePomodoro.getSessionsForDate(DateTime.now());
    return todaySessions
        .where((s) => s.completed && s.sessionType == SessionType.work)
        .length;
  }

  void _showStatsDialog() {
    final weeklyStats = DBServicePomodoro.getWeeklyStats();
    final streakDays = DBServicePomodoro.getStreakDays();
    final avgSessionLength = DBServicePomodoro.getAverageSessionLength();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This Week:'),
              Text('• Work sessions: ${weeklyStats['workSessions']}'),
              Text('• Total minutes: ${weeklyStats['totalMinutes']}'),
              Text('• Break sessions: ${weeklyStats['breakSessions']}'),
              const SizedBox(height: 10),
              const Text('Overall:'),
              Text('• Total completed: $_completedSessions'),
              Text('• Current streak: $streakDays days'),
              Text('• Avg session: ${avgSessionLength.toStringAsFixed(1)} min'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Work Duration'),
                    subtitle: Text('${_settings.workDuration ~/ 60} minutes'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setDialogState(() {
                              if (_settings.workDuration > 60) {
                                _settings.workDuration -= 60;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setDialogState(() {
                              _settings.workDuration += 60;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Auto-start breaks'),
                    value: _settings.autoStartBreaks,
                    onChanged: (value) {
                      setDialogState(() {
                        _settings.autoStartBreaks = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-start work sessions'),
                    value: _settings.autoStartWorkSessions,
                    onChanged: (value) {
                      setDialogState(() {
                        _settings.autoStartWorkSessions = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                await DBServicePomodoro.saveSettings(_settings);
                setState(() {
                  _seconds =
                      _isWorkSession
                          ? _settings.workDuration
                          : _getBreakDuration();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_isWorkSession) {
      return Colors.red;
    } else {
      return _getBreakDuration() == _settings.longBreakDuration
          ? Colors.blue
          : Colors.green;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRunning && _currentSessionStart != null) {
      _saveIncompleteSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pomodoro Timer',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.black),
            onPressed: _showStatsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _getTimerColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isWorkSession
                    ? 'WORK SESSION'
                    : (_getBreakDuration() == _settings.longBreakDuration
                        ? 'LONG BREAK'
                        : 'SHORT BREAK'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getTimerColor(),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _formatTime(_seconds),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getTimerColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTimerColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _isRunning ? 'PAUSE' : 'START',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'RESET',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Completed: $_completedSessions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Today: ${_getTodayCompletedSessions()} sessions',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}