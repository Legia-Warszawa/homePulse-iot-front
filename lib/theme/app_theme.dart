import 'package:flutter/material.dart';

class AppTheme {
  // --- Definicje Kolorów ---
  
  // LIGHT MODE
  static const Color _lightPrimary = Color(0xFFFF5722);
  static const Color _lightOnPrimary = Colors.white;
  static const Color _lightBackground = Color(0xFFF2F4F7);
  static const Color _lightSurface = Colors.white;
  static const Color _lightOnSurface = Color(0xFF1A1C1E);

  // DARK MODE (Deep Tech)
  static const Color _darkPrimary = Color(0xFFFF8A65); // Neon Orange
  static const Color _darkOnPrimary = Color(0xFF3E1C00);
  static const Color _darkBackground = Color(0xFF121212); // Czysta czerń lub bardzo ciemny szary
  static const Color _darkSurface = Color(0xFF1E1E24); // Grafit kart
  static const Color _darkOnSurface = Color(0xFFE2E2E6);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      secondary: Color(0xFF039BE5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: _lightOnSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData( // Używamy CardThemeData
      color: _lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      surface: _darkSurface, // To sprawia, że karty są grafitowe, a nie białe
      onSurface: _darkOnSurface,
      secondary: Color(0xFF4FC3F7),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: _darkOnSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData( // Używamy CardThemeData
      color: _darkSurface, // Grafitowe tło karty
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    iconTheme: const IconThemeData(
      color: _darkPrimary,
    ),
  );
}