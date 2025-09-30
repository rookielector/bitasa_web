// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // --- TEMA CLARO ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
    ).copyWith(
      secondary: Colors.blueAccent,
      // Color de fondo para las tarjetas
      surface: Colors.white, 
      // Color del texto sobre las tarjetas
      onSurface: Colors.black87, 
    ),
    fontFamily: 'Roboto',
  );

  // --- TEMA OSCURO ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
    ).copyWith(
      secondary: Colors.blueAccent,
      // Color de fondo para las tarjetas
      surface: const Color(0xFF2C2C54),
      // Color del texto sobre las tarjetas
      onSurface: Colors.white,
    ),
    fontFamily: 'Roboto',
  );
}