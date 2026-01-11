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
      title: 'Home Pulse',
      debugShowCheckedModeBanner: false,
      
      // 1. Motyw Jasny (Domyślny)
      theme: AppTheme.lightTheme,
      
      // 2. Motyw Ciemny (TO JEST KLUCZOWE - bez tego ani rusz)
      darkTheme: AppTheme.darkTheme,
      
      // 3. Tryb automatyczny (Reaguje na ustawienia telefonu)
      themeMode: ThemeMode.system, 
      
      home: const StartsScreen(),
    );
  }
}