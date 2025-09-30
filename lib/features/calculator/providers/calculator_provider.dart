// lib/features/calculator/providers/calculator_provider.dart

import 'package:bitasa_web/features/currency/currency_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- 1. MODELO DE ESTADO (Sin cambios) ---
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

// --- 2. EL NOTIFIER (Sin cambios) ---
class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(CalculatorState(
    inputAmount: "1",
    sourceCurrencyId: 'USD',
    targetCurrencyId: 'VES',
    selectedDate: DateTime.now(),
  ));

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

  void updateSelectedDate(DateTime newDate) {
    state = state.copyWith(selectedDate: newDate);
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

// --- 3. PROVIDERS (ACTUALIZADOS) ---

final currencyRepositoryProvider = Provider((ref) => CurrencyRepository());

// Provider original que trae las tasas de Firebase.
final ratesProvider = FutureProvider<Map<String, double>>((ref) {
  final selectedDate = ref.watch(calculatorProvider.select((state) => state.selectedDate));
  return ref.watch(currencyRepositoryProvider).getRatesForDate(selectedDate);
});

// Nuevo provider que toma las tasas del 'ratesProvider' y las redondea.
final roundedRatesProvider = Provider<Map<String, double>>((ref) {
  final ratesAsyncValue = ref.watch(ratesProvider);

  return ratesAsyncValue.maybeWhen(
    data: (rates) {
      return rates.map((key, value) {
        final roundedValue = (value * 100).round() / 100;
        return MapEntry(key, roundedValue);
      });
    },
    orElse: () => {},
  );
});

// Provider principal de la calculadora.
final calculatorProvider = StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
});

// Provider del cálculo, actualizado para usar las tasas redondeadas y formatear el resultado.
final convertedAmountProvider = Provider<String>((ref) {
  // Creamos el formateador de números con el patrón para Venezuela.
  final numberFormatter = NumberFormat('#,##0.00', 'es_VE');

  final calculatorState = ref.watch(calculatorProvider);
  // Dependemos del nuevo provider de tasas redondeadas.
  final Map<String, double> rates = ref.watch(roundedRatesProvider);

  if (rates.isEmpty) {
    // Si aún no hay tasas (cargando/error), devolvemos un placeholder.
    // Usamos el formateador para mantener la consistencia visual.
    return numberFormatter.format(0);
  }
  
  final double amount = double.tryParse(calculatorState.inputAmount) ?? 0.0;
  final double sourceRateInVes = rates[calculatorState.sourceCurrencyId] ?? 1.0;
  final double targetRateInVes = rates[calculatorState.targetCurrencyId] ?? 1.0;

  if (targetRateInVes == 0) {
    return numberFormatter.format(0);
  }

  final double result = (amount * sourceRateInVes) / targetRateInVes;
  
  // Devolvemos el resultado como un String ya formateado.
  return numberFormatter.format(result);
});