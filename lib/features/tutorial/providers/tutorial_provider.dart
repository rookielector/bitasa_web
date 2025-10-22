// lib/features/tutorial/providers/tutorial_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Esta clase contendrá todas las GlobalKeys para el tour.
class TutorialKeys {
  final GlobalKey sourceCurrency = GlobalKey();
  final GlobalKey swapButton = GlobalKey();
  final GlobalKey shareButton = GlobalKey();
  final GlobalKey saveButton = GlobalKey();
  final GlobalKey rateDate = GlobalKey(); // Nueva clave para la fecha

  List<GlobalKey> get keys => [sourceCurrency, swapButton, shareButton, saveButton, rateDate];
}

// Un Provider simple que nos da una única instancia de TutorialKeys.
final tutorialKeysProvider = Provider((ref) => TutorialKeys());


// Un FutureProvider para gestionar el estado de "ya ha visto el tutorial".
final tutorialSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenTutorial') ?? false;
});

// Provider para el servicio que maneja la lógica (marcar como visto).
final tutorialServiceProvider = Provider((ref) => TutorialService());

class TutorialService {
  Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
  }
}