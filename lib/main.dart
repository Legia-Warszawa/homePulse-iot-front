import 'package:flutter/material.dart';
import 'package:homepulse/screns/starts_screen.dart';
import 'package:homepulse/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
       debugShowCheckedModeBanner: false, // Dodaj tę linię
      theme: AppTheme.lightTheme,
      home: const StartsScreen(),
    );
  }
}
