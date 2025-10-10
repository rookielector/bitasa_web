// lib/features/currency/local_cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const _ratesKey = 'latest_rates';

  // Guarda el mapa de tasas en el almacenamiento local como un string JSON.
  Future<void> saveRates(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = jsonEncode(rates);
    await prefs.setString(_ratesKey, ratesJson);
  }

  // Lee el mapa de tasas desde el almacenamiento local.
  Future<Map<String, double>?> getRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString(_ratesKey);
    if (ratesJson != null) {
      // Decodificamos el JSON y lo convertimos de Map<String, dynamic> a Map<String, double>.
      final decodedMap = jsonDecode(ratesJson) as Map<String, dynamic>;
      return decodedMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }
    return null; // Devuelve nulo si no hay nada guardado.
  }
}