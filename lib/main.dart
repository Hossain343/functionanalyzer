import 'package:flutter/material.dart';
import 'screens/wear_home_screen.dart';

void main() {
  runApp(const FunctionAnalyzerApp());
}

class FunctionAnalyzerApp extends StatelessWidget {
  const FunctionAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'math a',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF34D399),
        ),
      ),
      home: const WearHomeScreen(),
    );
  }
}
