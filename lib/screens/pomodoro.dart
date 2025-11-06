// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '/models/hive/pomodoro_session.dart';
import '/services/hive/db_service_pomodoro.dart';



class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  Timer? _timer;
  int _seconds = 25 * 60;
  bool _isRunning = false;
  bool _isWorkSession = true;
  int _completedSessions = 0;

  // Current session tracking
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

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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

    // Save incomplete session if it was started
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

    // Save completed session to database
    await _saveCompletedSession();

    setState(() {
      _isRunning = false;

      if (_isWorkSession) {
        _completedSessions++;
        // Update total completed sessions in database
        DBServicePomodoro.setTotalCompletedSessions(_completedSessions);

        // Update total work minutes
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

    // Update last session date
    await DBServicePomodoro.setLastSessionDate(DateTime.now());

    _showSessionCompleteDialog();

    // Auto-start next session if enabled
    if ((_isWorkSession && _settings.autoStartWorkSessions) ||
        (!_isWorkSession && _settings.autoStartBreaks)) {
      Future.delayed(Duration(seconds: 2), () {
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
      actualDuration: plannedDuration, // Full duration since it completed
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
    // Long break every N work sessions (configurable)
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
              SizedBox(height: 10),
              Text(
                'Sessions completed today: ${_getTodayCompletedSessions()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('View Stats'),
              onPressed: () {
                Navigator.of(context).pop();
                showStatsDialog();
              },
            ),
            TextButton(
              child: Text('OK'),
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

  // Made public so it can be called from homepage
  void showStatsDialog() {
    final weeklyStats = DBServicePomodoro.getWeeklyStats();
    final streakDays = DBServicePomodoro.getStreakDays();
    final avgSessionLength = DBServicePomodoro.getAverageSessionLength();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This Week:'),
              Text('• Work sessions: ${weeklyStats['workSessions']}'),
              Text('• Total minutes: ${weeklyStats['totalMinutes']}'),
              Text('• Break sessions: ${weeklyStats['breakSessions']}'),
              SizedBox(height: 10),
              Text('Overall:'),
              Text('• Total completed: $_completedSessions'),
              Text('• Current streak: $streakDays days'),
              Text('• Avg session: ${avgSessionLength.toStringAsFixed(1)} min'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Made public so it can be called from homepage
  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Work Duration'),
                    subtitle: Text('${_settings.workDuration ~/ 60} minutes'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setDialogState(() {
                              if (_settings.workDuration > 60) {
                                _settings.workDuration -= 60;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
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
                    title: Text('Auto-start breaks'),
                    value: _settings.autoStartBreaks,
                    onChanged: (value) {
                      setDialogState(() {
                        _settings.autoStartBreaks = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text('Auto-start work sessions'),
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
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Save'),
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
    // Save incomplete session if timer was running
    if (_isRunning && _currentSessionStart != null) {
      _saveIncompleteSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Session type indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

            SizedBox(height: 40),

            // Timer display
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
                    offset: Offset(0, 5),
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

            SizedBox(height: 10),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Start/Pause button
                ElevatedButton(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTimerColor(),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _isRunning ? 'PAUSE' : 'START',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                SizedBox(width: 20),

                // Reset button
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'RESET',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),

            // Session counter and today's progress
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
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
                  SizedBox(height: 5),
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
