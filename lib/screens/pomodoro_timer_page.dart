import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hive/pomodoro_session.dart';
import '../providers/pomodoro_provider.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = context.read<PomodoroProvider>();
    provider.initialize();
    
    // Set the callback to show dialog when session completes
    provider.onSessionComplete = () {
      if (mounted) {
        _showSessionCompleteDialog(provider);
      }
    };
  });
}

  void _showSessionCompleteDialog(PomodoroProvider provider) {
    String title =
        provider.isWorkSession ? "Break Complete!" : "Work Session Complete!";
    String message =
        provider.isWorkSession
            ? "Ready for another work session?"
            : "Time for a ${provider.settings.longBreakDuration == provider.seconds ? 'long' : 'short'} break!";

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
                'Sessions completed today: ${provider.getTodayCompletedSessions()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('View Stats'),
              onPressed: () {
                Navigator.of(context).pop();
                _showStatsDialog(provider);
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

  void _showStatsDialog(PomodoroProvider provider) {
    final weeklyStats = provider.getWeeklyStats();
    final streakDays = provider.getStreakDays();
    final avgSessionLength = provider.getAverageSessionLength();

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
              Text('• Total completed: ${provider.completedSessions}'),
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

  void _showSettingsDialog(PomodoroProvider provider) {
    PomodoroSettings tempSettings = PomodoroSettings(
      workDuration: provider.settings.workDuration,
      shortBreakDuration: provider.settings.shortBreakDuration,
      longBreakDuration: provider.settings.longBreakDuration,
      sessionsUntilLongBreak: provider.settings.sessionsUntilLongBreak,
      autoStartBreaks: provider.settings.autoStartBreaks,
      autoStartWorkSessions: provider.settings.autoStartWorkSessions,
    );

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
                    subtitle: Text(
                      '${tempSettings.workDuration ~/ 60} minutes',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setDialogState(() {
                              if (tempSettings.workDuration > 60) {
                                tempSettings.workDuration -= 60;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setDialogState(() {
                              tempSettings.workDuration += 60;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Auto-start breaks'),
                    value: tempSettings.autoStartBreaks,
                    onChanged: (value) {
                      setDialogState(() {
                        tempSettings.autoStartBreaks = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Auto-start work sessions'),
                    value: tempSettings.autoStartWorkSessions,
                    onChanged: (value) {
                      setDialogState(() {
                        tempSettings.autoStartWorkSessions = value;
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
                await provider.saveSettings(tempSettings);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, pomodoroProvider, child) {
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
                onPressed: () => _showStatsDialog(pomodoroProvider),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                onPressed: () => _showSettingsDialog(pomodoroProvider),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: pomodoroProvider.getTimerColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pomodoroProvider.getSessionTypeText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: pomodoroProvider.getTimerColor(),
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
                      pomodoroProvider.formatTime(pomodoroProvider.seconds),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: pomodoroProvider.getTimerColor(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed:
                          pomodoroProvider.isRunning
                              ? () => pomodoroProvider.pauseTimer()
                              : () => pomodoroProvider.startTimer(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pomodoroProvider.getTimerColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        pomodoroProvider.isRunning ? 'PAUSE' : 'START',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => pomodoroProvider.resetTimer(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'RESET',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                        'Total Completed: ${pomodoroProvider.completedSessions}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Today: ${pomodoroProvider.getTodayCompletedSessions()} sessions',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
