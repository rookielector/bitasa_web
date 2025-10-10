// lib/features/currency/currency_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bitasa_web/features/currency/local_cache_service.dart';
import 'package:bitasa_web/features/currency/data_wrapper.dart'; // Importamos nuestra nueva clase wrapper

class CurrencyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalCacheService _cache = LocalCacheService();

  // El Stream ahora emite nuestro objeto DataWrapper, que contiene tanto
  // los datos como la información sobre su origen (caché o red).
  Stream<DataWrapper<Map<String, double>>> getRatesStream() async* {
    
    // --- PASO 1: EMITIR DATOS DE LA CACHÉ ---
    // Intentamos leer los datos guardados localmente.
    final cachedRates = await _cache.getRates();
    
    // Si existen datos en la caché, los emitimos inmediatamente,
    // envolviéndolos en un DataWrapper y etiquetándolos con 'DataSource.cache'.
    if (cachedRates != null) {
      yield DataWrapper(data: cachedRates, source: DataSource.cache);
    }

    // --- PASO 2: INTENTAR OBTENER DATOS FRESCOS DE LA RED ---
    try {
      // Llamamos a Firebase para obtener las tasas más recientes.
      final freshRates = await _fetchRatesFromFirestore();
      
      // Guardamos estas nuevas tasas en la caché para futuras sesiones offline.
      await _cache.saveRates(freshRates);
      
      // Emitimos los nuevos datos, esta vez etiquetándolos con 'DataSource.network'.
      // La UI recibirá esta nueva emisión y podrá reaccionar (ej. ocultando el banner de "offline").
      yield DataWrapper(data: freshRates, source: DataSource.network);

    } catch (e) {
      // Si la llamada a Firebase falla (sin conexión, error de servidor, etc.),
      // el 'catch' se activa y simplemente no hacemos nada.
      print("Failed to fetch fresh rates: $e");
      
      // La única vez que propagamos el error es si la app se abre por primera vez
      // sin conexión y sin nada en la caché.
      if (cachedRates == null) {
        throw Exception('No se pudieron obtener las tasas y no hay datos locales guardados.');
      }
    }
  }

  // Este método privado se encarga únicamente de la lógica de Firebase.
  // No ha cambiado internamente.
  Future<Map<String, double>> _fetchRatesFromFirestore() async {
    final snapshot = await _db
        .collection('exchange_rates')
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      throw Exception('No se encontraron tasas en Firestore.');
    }

    final data = snapshot.docs.first.data();
    
    return {
      'USD': (data['usd_rate'] as num).toDouble(),
      'EUR': (data['eur_rate'] as num).toDouble(),
      'VES': 1.0,
    };
  }
}