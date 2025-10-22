import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF5722),     // #FF5722 - Pomarańczowy (poprawione)
      secondary: Color(0xFF03A9F4),   // #03A9F4 - Niebieski (poprawione)
      surface: Color(0xFFE1E2F5),     // #F5F5F5 - Jasny szary (poprawione)
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      background: Color(0xFFFAFAFA),  // Tło aplikacji
      onBackground: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF5722),  // Użyj primary color
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFFF5F5F5),  // Poprawione surface color
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF5722),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    useMaterial3: true,
  );
}