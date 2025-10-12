// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark); // --- CAMBIO 1: Iniciar en modo oscuro por defecto ---

  // --- NUEVO GETTER ---
  // Este 'getter' nos dirá si debemos usar el tema oscuro.
  // Lo usaremos en la UI para decidir el icono.
  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.system) {
      // Si el tema es el del sistema, preguntamos al brillo del contexto.
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    } else {
      // Si no, simplemente comprobamos si el estado es 'dark'.
      return state == ThemeMode.dark;
    }
  }

  // --- MÉTODO TOGGLE MEJORADO ---
  void toggleTheme(BuildContext context) {
    // Leemos el brillo actual para tomar una decisión más inteligente.
    final isCurrentlyDark = isDarkMode(context);

    // Si actualmente está oscuro, lo cambiamos a claro.
    // Si actualmente está claro, lo cambiamos a oscuro.
    // Esto elimina la dependencia del estado 'system'.
    state = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});