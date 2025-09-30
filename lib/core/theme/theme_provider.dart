// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Creamos un Notifier que contendrá el estado (ThemeMode)
class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Le damos un estado inicial (ej: el tema del sistema)
  ThemeNotifier() : super(ThemeMode.system);

  // Método para cambiar el tema
  void toggleTheme() {
    // Si el estado actual es oscuro, lo cambiamos a claro, y viceversa.
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

// 2. Creamos el Provider global
// Este es el objeto que usaremos en la UI para leer y modificar el estado.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});