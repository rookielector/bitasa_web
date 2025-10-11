// lib/features/historical/providers/historical_provider.dart

// --- IMPORT CORREGIDO ---
// Importamos el archivo que define TODOS nuestros providers de datos,
// incluyendo el 'currencyRepositoryProvider'.
import 'package:bitasa_web/features/calculator/providers/calculator_provider.dart';

import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

// Enumeración para los criterios de ordenamiento.
enum HistoricalSortCriteria { dateDesc, dateAsc, usdAsc, usdDesc, eurAsc, eurDesc }

// Provider para el Criterio de Ordenamiento seleccionado.
final historicalSortProvider = StateProvider<HistoricalSortCriteria>((ref) => HistoricalSortCriteria.dateDesc);

// Provider para obtener los datos crudos del Repositorio.
final historicalRatesStreamProvider = StreamProvider<List<ExchangeRate>>((ref) {
  // Ahora sí, 'currencyRepositoryProvider' se encuentra sin problemas
  // porque está definido en el archivo que acabamos de importar.
  return ref.watch(currencyRepositoryProvider).getHistoricalRatesStream();
});

// Provider para los Datos Procesados y Agrupados para la UI.
final groupedHistoricalRatesProvider = Provider<Map<DateTime, List<ExchangeRate>>>((ref) {
  final ratesAsyncValue = ref.watch(historicalRatesStreamProvider);
  final sortCriteria = ref.watch(historicalSortProvider);

  return ratesAsyncValue.when(
    data: (rates) {
      // --- LÓGICA DE ORDENAMIENTO ---
      // Creamos una copia mutable para poder ordenarla.
      final sortedRates = List<ExchangeRate>.from(rates);
      sortedRates.sort((a, b) {
        switch (sortCriteria) {
          case HistoricalSortCriteria.dateAsc:
            return a.date.compareTo(b.date);
          case HistoricalSortCriteria.usdAsc:
            return a.usdRate.compareTo(b.usdRate);
          case HistoricalSortCriteria.usdDesc:
            return b.usdRate.compareTo(a.usdRate);
          case HistoricalSortCriteria.eurAsc:
            return a.eurRate.compareTo(b.eurRate);
          case HistoricalSortCriteria.eurDesc:
            return b.eurRate.compareTo(a.eurRate);
          case HistoricalSortCriteria.dateDesc:
          default:
            return b.date.compareTo(a.date);
        }
      });

      // --- LÓGICA DE AGRUPACIÓN ---
      final groupedData = groupBy<ExchangeRate, DateTime>(
        sortedRates, 
        (rate) => DateTime(rate.date.year, rate.date.month, rate.date.day)
      );
      
      return groupedData;
    },
    loading: () => {},
    error: (e, s) => {},
  );
});