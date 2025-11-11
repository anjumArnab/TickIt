import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../screens/navigation_wrapper.dart';
import '../services/hive/db_service.dart';
import '../services/hive/db_service_pomodoro.dart';
import '../providers/task_provider.dart';
import '../providers/pomodoro_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive databases
    await DBService.init();
    await DBServicePomodoro.initHive();
    debugPrint('Database initialized successfully');
  } catch (e) {
    debugPrint('Error initializing database: $e');
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
