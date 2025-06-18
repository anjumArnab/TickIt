import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/homepage.dart';

void main() {
  runApp(TickIt());
}

class TickIt extends StatelessWidget {
  const TickIt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TickIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Homepage(),
    );
  }
}
