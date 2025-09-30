// lib/main.dart

import 'package:bitasa_web/core/theme/app_theme.dart';
import 'package:bitasa_web/core/theme/theme_provider.dart';
import 'package:bitasa_web/firebase_options.dart';
import 'package:bitasa_web/screens/calculator_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- PASO 1: AÑADIR IMPORTS DE LOCALIZACIÓN ---
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('es_ES', null);
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Bitasa Web',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const CalculatorScreen(),
      
      // --- PASO 2: CONFIGURAR LOS DELEGADOS Y LOCALES SOPORTADOS ---
      // Esta sección le dice a Flutter cómo manejar la localización.
      
      // Los 'localizationsDelegates' son las "fábricas" que proveen las traducciones.
      localizationsDelegates: const [
        // Provee las traducciones para los widgets básicos de Material (ej. Tooltips, TextFields).
        GlobalMaterialLocalizations.delegate,
        // Provee las traducciones para la dirección del texto y otras configuraciones de widgets.
        GlobalWidgetsLocalizations.delegate,
        // Provee las traducciones para los widgets de Cupertino (estilo iOS).
        GlobalCupertinoLocalizations.delegate,
      ],

      // 'supportedLocales' es la lista de idiomas que tu aplicación soportará.
      supportedLocales: const [
        Locale('es', 'ES'), // Español de España
        Locale('en', 'US'), // Inglés de Estados Unidos (es bueno tenerlo como fallback)
        // Puedes añadir más idiomas aquí si lo deseas en el futuro.
      ],

      // Opcional: define el idioma por defecto de la aplicación.
      locale: const Locale('es', 'ES'),
    );
  }
}