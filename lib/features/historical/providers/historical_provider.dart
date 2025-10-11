// lib/features/historical/providers/historical_provider.dart

import 'package:bitasa_web/features/calculator/providers/calculator_provider.dart';
import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';

// --- PROVIDERS DE LA VISTA DE LISTA ---
enum HistoricalSortCriteria { dateDesc, dateAsc, usdAsc, usdDesc, eurAsc, eurDesc }
final historicalSortProvider = StateProvider<HistoricalSortCriteria>((ref) => HistoricalSortCriteria.dateDesc);
final historicalRatesStreamProvider = StreamProvider<List<ExchangeRate>>((ref) {
  return ref.watch(currencyRepositoryProvider).getHistoricalRatesStream();
});

// --- PROVIDER 'groupedHistoricalRatesProvider' CORREGIDO ---
final groupedHistoricalRatesProvider = Provider<Map<DateTime, List<ExchangeRate>>>((ref) {
  final ratesAsyncValue = ref.watch(historicalRatesStreamProvider);
  final sortCriteria = ref.watch(historicalSortProvider);

  // Usamos 'maybeWhen' con 'orElse' para garantizar que siempre se devuelva un valor.
  return ratesAsyncValue.maybeWhen(
    data: (rates) {
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

      final groupedData = groupBy<ExchangeRate, DateTime>(
        sortedRates, 
        (rate) => DateTime(rate.date.year, rate.date.month, rate.date.day)
      );
      
      return groupedData;
    },
    // 'orElse' se ejecuta para los casos de 'loading', 'error' o cualquier otro.
    // Devolvemos un mapa vacío, cumpliendo así con el tipo de retorno no nulo.
    orElse: () => {},
  );
});


// --- PROVIDERS PARA LA VISTA DE GRÁFICOS ---
final chartDaysProvider = StateProvider<int>((ref) => 30);

final filteredChartRatesProvider = Provider<List<ExchangeRate>>((ref) {
  final days = ref.watch(chartDaysProvider);
  final allRatesAsync = ref.watch(historicalRatesStreamProvider);

  return allRatesAsync.maybeWhen(
    data: (rates) {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final filtered = rates.where((rate) {
        return rate.date.isAfter(startDate) && rate.date.isBefore(endDate);
      }).toList();

      filtered.sort((a, b) => a.date.compareTo(b.date));
      return filtered;
    },
    orElse: () => [], // Hacemos lo mismo aquí por seguridad
  );
});

final usdChartSpotsProvider = Provider<List<FlSpot>>((ref) {
  final rates = ref.watch(filteredChartRatesProvider);
  return rates.map((rate) {
    return FlSpot(
      rate.date.millisecondsSinceEpoch.toDouble(),
      rate.usdRate,
    );
  }).toList();
});

final eurChartSpotsProvider = Provider<List<FlSpot>>((ref) {
  final rates = ref.watch(filteredChartRatesProvider);
  return rates.map((rate) {
    return FlSpot(
      rate.date.millisecondsSinceEpoch.toDouble(),
      rate.eurRate,
    );
  }).toList();
});