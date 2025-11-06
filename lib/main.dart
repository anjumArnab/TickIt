import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hive/db_service.dart';
import '../screens/homepage.dart';
import 'services/hive/db_service_pomodoro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DBService.init();
    await DBServicePomodoro.initHive();
    debugPrint('Database initialized successfully');
  } catch (e) {
    debugPrint('Error initializing database: $e');
  }

  runApp(TickIt());
}

class TickIt extends StatelessWidget {
  const TickIt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tick It',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Homepage(),
    );
  }
}
