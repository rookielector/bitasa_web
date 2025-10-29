// lib/features/calculator/providers/calculator_provider.dart

import 'package:bitasa_web/features/currency/currency_repository.dart';
import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:bitasa_web/features/currency/rate_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart'; 

// --- CalculatorState y CalculatorNotifier (SIN CAMBIOS) ---
class CalculatorState {
  final String inputAmount;
  final String sourceCurrencyId;
  final String targetCurrencyId;
  final DateTime selectedDate;

  CalculatorState({
    required this.inputAmount,
    required this.sourceCurrencyId,
    required this.targetCurrencyId,
    required this.selectedDate,
  });

  CalculatorState copyWith({
    String? inputAmount,
    String? sourceCurrencyId,
    String? targetCurrencyId,
    DateTime? selectedDate,
  }) {
    return CalculatorState(
      inputAmount: inputAmount ?? this.inputAmount,
      sourceCurrencyId: sourceCurrencyId ?? this.sourceCurrencyId,
      targetCurrencyId: targetCurrencyId ?? this.targetCurrencyId,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(CalculatorState(
    inputAmount: "1",
    sourceCurrencyId: 'USD',
    targetCurrencyId: 'VES',
    selectedDate: DateTime.now(), 
  ));

  void updateSelectedDate(DateTime newDate) {
    state = state.copyWith(selectedDate: newDate);
  }

  void updateAmount(String newAmount) {
    state = state.copyWith(inputAmount: newAmount.isEmpty ? "0" : newAmount);
  }

  void swapCurrencies() {
    final originalSource = state.sourceCurrencyId;
    final originalTarget = state.targetCurrencyId;
    state = state.copyWith(
      sourceCurrencyId: originalTarget,
      targetCurrencyId: originalSource,
    );
  }

  void setSourceCurrency(String newCurrencyId) {
    if (newCurrencyId == state.targetCurrencyId) {
      swapCurrencies();
    } else {
      state = state.copyWith(sourceCurrencyId: newCurrencyId);
    }
  }

  void setTargetCurrency(String newCurrencyId) {
    if (newCurrencyId == state.sourceCurrencyId) {
      swapCurrencies();
    } else {
      state = state.copyWith(targetCurrencyId: newCurrencyId);
    }
  }
}

// --- PROVIDERS PRINCIPALES (SIN CAMBIOS) ---

final currencyRepositoryProvider = Provider((ref) => CurrencyRepository());

final rateInfoProvider = StreamProvider<RateInfo>((ref) {
  return ref.watch(currencyRepositoryProvider).getDefaultRateInfoStream();
});

final calculatorProvider = StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  final notifier = CalculatorNotifier();
  ref.listen<AsyncValue<RateInfo>>(rateInfoProvider, (previous, next) {
    next.whenData((rateInfo) {
      final currentState = notifier.state;
      final isViewingDefault = DateUtils.isSameDay(currentState.selectedDate, rateInfo.defaultRate.date);
      final isViewingFuture = rateInfo.futureRate != null && DateUtils.isSameDay(currentState.selectedDate, rateInfo.futureRate!.date);
      if (!isViewingDefault && !isViewingFuture) {
        return;
      }
      notifier.updateSelectedDate(rateInfo.defaultRate.date);
    });
  });
  return notifier;
});

final ratesProvider = StreamProvider<Map<String, double>>((ref) async* {
  final selectedDate = ref.watch(calculatorProvider.select((state) => state.selectedDate));
  final rateInfoAsync = ref.watch(rateInfoProvider);

  final rateInfo = rateInfoAsync.valueOrNull;

  if (rateInfo == null) {
    yield {};
    return;
  }
  
  final isDefaultDate = DateUtils.isSameDay(selectedDate, rateInfo.defaultRate.date);
  final isFutureDate = rateInfo.futureRate != null && DateUtils.isSameDay(selectedDate, rateInfo.futureRate!.date);

  if (isDefaultDate || isFutureDate) {
    final rate = isFutureDate ? rateInfo.futureRate! : rateInfo.defaultRate;
    yield {'USD': rate.usdRate, 'EUR': rate.eurRate, 'VES': 1.0};
  } else {
    yield* ref.watch(currencyRepositoryProvider).getRatesForDateStream(selectedDate);
  }
});

// --- PROVIDERS DE AYUDA (SIN CAMBIOS) ---
final defaultRateProvider = Provider<ExchangeRate?>((ref) {
  return ref.watch(rateInfoProvider).valueOrNull?.defaultRate;
});

final futureRateProvider = Provider<ExchangeRate?>((ref) {
  return ref.watch(rateInfoProvider).valueOrNull?.futureRate;
});

// --- PROVIDERS DERIVADOS ---
final roundedRatesProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(ratesProvider).maybeWhen(
    data: (rates) => rates.map((key, value) => MapEntry(key, (value * 100).round() / 100)),
    orElse: () => {},
  );
});

final referenceRatesProvider = Provider<List<String>>((ref) {
  final rates = ref.watch(roundedRatesProvider);
  if (rates.isEmpty) {
    return [];
  }

  final rateFormatter = NumberFormat('#,##0.00', 'es_VE');
  final List<String> referenceStrings = [];

  rates.entries.forEach((entry) {
    if (entry.key != 'VES') {
      final currencyCode = entry.key;
      final rateValue = entry.value;
      referenceStrings.add('1 $currencyCode = ${rateFormatter.format(rateValue)} VES');
    }
  });

  referenceStrings.sort();
  return referenceStrings;
});

// NUEVO: Provider que filtra y devuelve solo la tasa de referencia activa.
final activeReferenceRateProvider = Provider<String>((ref) {
  final calculatorState = ref.watch(calculatorProvider);
  final allReferenceRates = ref.watch(referenceRatesProvider);

  if (allReferenceRates.isEmpty) {
    return '';
  }

  // Identificar la moneda extranjera en el par de cálculo.
  String foreignCurrencyId;
  if (calculatorState.sourceCurrencyId == 'VES') {
    foreignCurrencyId = calculatorState.targetCurrencyId;
  } else {
    // Si la moneda origen no es VES (puede ser USD o EUR), esa es la referencia.
    // Esto cubre los casos USD -> VES, EUR -> VES, y también USD -> EUR.
    foreignCurrencyId = calculatorState.sourceCurrencyId;
  }

  // Si por alguna razón la moneda extranjera también es VES (ej. en un par VES-VES), no mostrar nada.
  if (foreignCurrencyId == 'VES') {
    return '';
  }
  
  // Buscar la cadena de texto de la tasa que corresponde a esa moneda.
  return allReferenceRates.firstWhere(
    (rateString) => rateString.startsWith('1 $foreignCurrencyId'),
    orElse: () => '', // Devolver vacío si no se encuentra para evitar errores.
  );
});

final convertedAmountProvider = Provider<String>((ref) {
  final numberFormatter = NumberFormat('#,##0.00', 'es_VE');
  final calculatorState = ref.watch(calculatorProvider);
  final Map<String, double> rates = ref.watch(roundedRatesProvider);

  if (rates.isEmpty) {
    return numberFormatter.format(0);
  }
  
  final double amount = double.tryParse(calculatorState.inputAmount) ?? 0.0;
  final double sourceRateInVes = rates[calculatorState.sourceCurrencyId] ?? 1.0;
  final double targetRateInVes = rates[calculatorState.targetCurrencyId] ?? 1.0;

  if (targetRateInVes == 0) {
    return numberFormatter.format(0);
  }

  final double result = (amount * sourceRateInVes) / targetRateInVes;
  
  return numberFormatter.format(result);
});