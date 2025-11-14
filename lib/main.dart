import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tick_it/services/notification_service.dart';
import 'screens/navigation_wrapper.dart';
import 'services/hive/db_service.dart';
import 'services/hive/db_service_pomodoro.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive databases
    await DBService.init();
    await DBServicePomodoro.initHive();
    debugPrint('Database initialized successfully');

    // Initialize Task Notification Service
    final taskNotificationService = NotificationService();
    await taskNotificationService.init();
    debugPrint('Task Notification Service initialized successfully');

    // Request notification permissions
    final permissionsGranted = await taskNotificationService.requestPermissions();
    if (permissionsGranted) {
      debugPrint('Notification permissions granted');
    } else {
      debugPrint('Notification permissions denied or not available');
    }

    // Check notification status
    final notificationsEnabled = await taskNotificationService.areNotificationsEnabled();
    debugPrint('Notifications enabled: $notificationsEnabled');

  } catch (e) {
    debugPrint('Error during initialization: $e');
  }

  runApp(const TickIt());
}

class TickIt extends StatelessWidget {
  const TickIt({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
      ],
      child: MaterialApp(
        title: 'Tick It',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const NavigationWrapper(),
      ),
    );
  }
}