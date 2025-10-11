// lib/features/currency/currency_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:bitasa_web/services/database_service.dart';
import 'package:sembast/sembast.dart' as sembast;

class CurrencyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

  // --- MÉTODO PARA LA PANTALLA DE LA CALCULADORA (sin cambios) ---
  Stream<Map<String, double>> getRatesForDateStream(DateTime date) async* {
    final db = await _dbService.database;
    final store = _dbService.ratesStore;

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
      
      await store.record(freshRate.date.toIso8601String()).put(db, freshRate.toMap());

      yield {'USD': freshRate.usdRate, 'EUR': freshRate.eurRate, 'VES': 1.0};
    } catch (e) {
      print("No se pudieron obtener datos de Firebase para la fecha seleccionada: $e");
      if (localRecord == null) {
        throw Exception('Error de red y sin datos en caché para la fecha seleccionada.');
      }
    }
  }

  // --- MÉTODO PARA LA PANTALLA DE HISTÓRICOS (MODIFICADO) ---
  Stream<List<ExchangeRate>> getHistoricalRatesStream() async* {
    final db = await _dbService.database;
    final store = _dbService.ratesStore;

    final finder = sembast.Finder(sortOrders: [sembast.SortOrder('date', false)]);
    final localRecords = await store.find(db, finder: finder);
    
    if (localRecords.isNotEmpty) {
      final rates = localRecords.map((record) => ExchangeRate.fromMap(record.value)).toList();
      yield rates;
    }

    try {
      final query = _db
          .collection('exchange_rates')
          .orderBy('date', descending: true);
          
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final List<ExchangeRate> freshRates = [];
        
        await db.transaction((txn) async {
          // --- LÍNEA CORREGIDA ---
          // Llamamos al método 'delete' sobre el store pasándole la transacción.
          // Sin un 'finder', esto elimina todos los registros del store.
          await store.delete(txn);

          for (final doc in snapshot.docs) {
            final rate = ExchangeRate.fromFirestore(doc);
            freshRates.add(rate);
            await store.record(rate.date.toIso8601String()).put(txn, rate.toMap());
          }
        });

        yield freshRates;
      }
    } catch (e) {
      print("No se pudieron obtener datos históricos de Firebase: $e");
      if (localRecords.isEmpty) {
        throw Exception('Error de red y sin datos históricos en caché.');
      }
    }
  }

  // --- MÉTODO PRIVADO (sin cambios) ---
  Future<ExchangeRate> _fetchRateFromFirestore(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

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