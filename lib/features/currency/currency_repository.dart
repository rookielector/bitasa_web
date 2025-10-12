// lib/features/currency/currency_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:bitasa_web/features/currency/rate_info.dart'; // Importamos nuestro nuevo modelo
import 'package:bitasa_web/services/database_service.dart';
import 'package:sembast/sembast.dart' as sembast;

class CurrencyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();

    // --- NUEVO MÉTODO INTELIGENTE ---
  // Este método se convertirá en el punto de entrada principal para la calculadora.
  Stream<RateInfo> getDefaultRateInfoStream() async* {
    final db = await _dbService.database;
    final store = _dbService.ratesStore;
    final now = DateTime.now();

    // --- LÓGICA OFFLINE-FIRST ---

    // 1. BUSCAR EN LA CACHÉ LOCAL (SEMBAST) PRIMERO
    final defaultRateLocal = await _findDefaultRateInCache(now);
    ExchangeRate? futureRateLocal;
    if (defaultRateLocal != null) {
      futureRateLocal = await _findFutureRateInCache(defaultRateLocal.date);
      // Emitimos lo que encontramos en la caché inmediatamente.
      yield RateInfo(defaultRate: defaultRateLocal, futureRate: futureRateLocal);
    }

    // 2. BUSCAR EN LA RED (FIREBASE) PARA ACTUALIZAR
    try {
      final freshRates = await _fetchAllRecentRatesFromFirestore();
      if (freshRates.isNotEmpty) {
        // Guardamos todas las tasas nuevas en Sembast.
        await db.transaction((txn) async {
          for (final rate in freshRates) {
            await store.record(rate.date.toIso8601String()).put(txn, rate.toMap());
          }
        });

        // Ahora, con los datos actualizados, volvemos a buscar la tasa por defecto y futura.
        final defaultRateFresh = _findDefaultRateInList(now, freshRates);
        ExchangeRate? futureRateFresh;
        if (defaultRateFresh != null) {
          futureRateFresh = _findFutureRateInList(defaultRateFresh.date, freshRates);
          // Emitimos el RateInfo actualizado con los datos de la red.
          yield RateInfo(defaultRate: defaultRateFresh, futureRate: futureRateFresh);
        }
      }
    } catch (e) {
      print("No se pudieron obtener datos frescos de Firebase: $e");
      if (defaultRateLocal == null) {
        throw Exception('Error de red y sin datos en caché.');
      }
    }
  }

  // --- MÉTODOS AUXILIARES PARA LA NUEVA LÓGICA ---

  Future<ExchangeRate?> _findDefaultRateInCache(DateTime fromDate) async {
    final db = await _dbService.database;
    final store = _dbService.ratesStore;
    final finder = sembast.Finder(
      filter: sembast.Filter.lessThanOrEquals('date', fromDate.toIso8601String()),
      sortOrders: [sembast.SortOrder('date', false)],
      limit: 1,
    );
    final record = await store.findFirst(db, finder: finder);
    return record != null ? ExchangeRate.fromMap(record.value) : null;
  }

  Future<ExchangeRate?> _findFutureRateInCache(DateTime afterDate) async {
    final db = await _dbService.database;
    final store = _dbService.ratesStore;
    final finder = sembast.Finder(
      filter: sembast.Filter.greaterThan('date', afterDate.toIso8601String()),
      sortOrders: [sembast.SortOrder('date', true)], // true = ascendente
      limit: 1,
    );
    final record = await store.findFirst(db, finder: finder);
    return record != null ? ExchangeRate.fromMap(record.value) : null;
  }

  Future<List<ExchangeRate>> _fetchAllRecentRatesFromFirestore() async {
    final startDate = DateTime.now().subtract(const Duration(days: 7)); // Buscamos en la última semana
    final query = _db
        .collection('exchange_rates')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('date', descending: true);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ExchangeRate.fromFirestore(doc)).toList();
  }

  ExchangeRate? _findDefaultRateInList(DateTime fromDate, List<ExchangeRate> rates) {
    // Ordenamos por si acaso
    rates.sort((a, b) => b.date.compareTo(a.date));
    return rates.firstWhere((rate) => !rate.date.isAfter(fromDate), orElse: () => rates.last);
  }

  ExchangeRate? _findFutureRateInList(DateTime afterDate, List<ExchangeRate> rates) {
    rates.sort((a, b) => a.date.compareTo(b.date));
    try {
      return rates.firstWhere((rate) => rate.date.isAfter(afterDate));
    } catch (e) {
      return null;
    }
  }

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