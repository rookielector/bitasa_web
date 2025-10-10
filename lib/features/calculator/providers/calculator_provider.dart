// lib/features/calculator/providers/calculator_provider.dart

import 'package:bitasa_web/features/currency/currency_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- RECUPERAMOS LA LÓGICA DE 'selectedDate' ---
// Ahora que Sembast nos permite consultar por fecha, podemos volver a manejar este estado.

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
    selectedDate: DateTime.now(), // La fecha inicial es hoy por defecto.
  ));

  // --- REINTEGRAMOS EL MÉTODO PARA ACTUALIZAR LA FECHA ---
  void updateSelectedDate(DateTime newDate) {
    state = state.copyWith(selectedDate: newDate);
  }

  // Los otros métodos no cambian.
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

// --- PROVIDERS (ACTUALIZADOS PARA SEMBAST Y FECHAS) ---

final currencyRepositoryProvider = Provider((ref) => CurrencyRepository());

final calculatorProvider = StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
});

// El 'ratesProvider' ahora es un StreamProvider que depende de la fecha seleccionada.
// Si el usuario cambia la fecha en el 'calculatorProvider', Riverpod re-ejecutará
// este provider, pidiendo al repositorio un nuevo stream de datos para la nueva fecha.
final ratesProvider = StreamProvider<Map<String, double>>((ref) {
  final selectedDate = ref.watch(calculatorProvider.select((state) => state.selectedDate));
  return ref.watch(currencyRepositoryProvider).getRatesForDateStream(selectedDate);
});

// El 'roundedRatesProvider' funciona exactamente igual que antes.
// Simplemente consume los datos que le entrega 'ratesProvider', sin importar cómo los obtuvo.
final roundedRatesProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(ratesProvider).maybeWhen(
    data: (rates) => rates.map((key, value) => MapEntry(key, (value * 100).round() / 100)),
    orElse: () => {},
  );
});

// El 'convertedAmountProvider' también funciona exactamente igual que antes.
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