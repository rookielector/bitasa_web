// lib/features/currency/currency_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:bitasa_web/services/database_service.dart';

// --- CAMBIO 1: AÑADIMOS 'as sembast' AL IMPORT ---
// Ahora, para usar cualquier clase de Sembast, debemos prefijarla con 'sembast.'.
import 'package:sembast/sembast.dart' as sembast;

class CurrencyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  Stream<Map<String, double>> getRatesForDateStream(DateTime date) async* {
    final db = await _dbService.database;
    final store = _dbService.ratesStore;

    // --- CAMBIO 2: USAMOS EL PREFIJO 'sembast.' ---
    // Le decimos a Dart que use el 'Finder' y 'Filter' de la librería Sembast.
    final finder = sembast.Finder(
      filter: sembast.Filter.lessThanOrEquals('date', date.toIso8601String()),
      sortOrders: [sembast.SortOrder('date', false)],
      limit: 1,
    );
    final localRecord = await store.findFirst(db, finder: finder);
    
    if (localRecord != null) {
      final rate = ExchangeRate.fromMap(localRecord.value);
      yield {'USD': rate.usdRate, 'EUR': rate.eurRate, 'VES': 1.0};
    }

    try {
      final freshRate = await _fetchRateFromFirestore(date);
      
      // La clave del registro es un String, así que no necesita prefijo.
      await store.record(freshRate.date.toIso8601String()).put(db, freshRate.toMap());

      yield {'USD': freshRate.usdRate, 'EUR': freshRate.eurRate, 'VES': 1.0};
    } catch (e) {
      print("No se pudieron obtener datos de Firebase: $e");
      if (localRecord == null) {
        throw Exception('Error de red y sin datos en caché.');
      }
    }
  }

  Future<ExchangeRate> _fetchRateFromFirestore(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Aquí no hay ambigüedad, 'Filter' no se usa.
    var query = _db
        .collection('exchange_rates')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThanOrEqualTo: endOfDay)
        .limit(1);

    var snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      query = _db
          .collection('exchange_rates')
          .where('date', isLessThan: startOfDay)
          .orderBy('date', descending: true)
          .limit(1);
      snapshot = await query.get();
    }
    
    if (snapshot.docs.isEmpty) {
      throw Exception('No se encontraron tasas para la fecha solicitada ni anteriores.');
    }
    
    return ExchangeRate.fromFirestore(snapshot.docs.first);
  }
}