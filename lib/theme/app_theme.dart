import 'package:flutter/material.dart';

class AppTheme {
  // --- Definicje Kolorów (ZIELONE) ---
  
  // LIGHT MODE
  static const Color _lightPrimary = Color(0xFF2E7D32); // Ciemna, elegancka zieleń (Forest Green)
  static const Color _lightOnPrimary = Colors.white;
  static const Color _lightBackground = Color(0xFFF1F8E9); // Bardzo jasna mięta/biel
  static const Color _lightSurface = Colors.white;
  static const Color _lightOnSurface = Color(0xFF1B5E20); // Bardzo ciemna zieleń dla tekstu

  // DARK MODE
  static const Color _darkPrimary = Color(0xFF4CAF50); // Jaśniejsza, żywa zieleń
  static const Color _darkOnPrimary = Colors.white;
  static const Color _darkBackground = Color(0xFF121212); // Czysta czerń
  static const Color _darkSurface = Color(0xFF1E1E24); // Grafit kart
  static const Color _darkOnSurface = Color(0xFFE8F5E9); // Jasny miętowy biały dla tekstu

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      secondary: Color(0xFF66BB6A), // Akcentowa zieleń
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
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
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      secondary: Color(0xFF81C784),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkPrimary, // Zielony AppBar w trybie ciemnym
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData( 
      color: _darkSurface,
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white, // Białe ikony w ciemnym motywie
    ),
  );
}