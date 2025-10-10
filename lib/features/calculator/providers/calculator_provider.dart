// lib/features/calculator/providers/calculator_provider.dart

import 'package:bitasa_web/features/currency/currency_repository.dart';
import 'package:bitasa_web/features/currency/data_wrapper.dart'; // Importamos el DataWrapper
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// --- CalculatorState y CalculatorNotifier no cambian en esta actualización ---
// Siguen siendo responsables del estado de la UI (monto y monedas seleccionadas).

class CalculatorState {
  final String inputAmount;
  final String sourceCurrencyId;
  final String targetCurrencyId;

  CalculatorState({
    required this.inputAmount,
    required this.sourceCurrencyId,
    required this.targetCurrencyId,
  });

  CalculatorState copyWith({
    String? inputAmount,
    String? sourceCurrencyId,
    String? targetCurrencyId,
  }) {
    return CalculatorState(
      inputAmount: inputAmount ?? this.inputAmount,
      sourceCurrencyId: sourceCurrencyId ?? this.sourceCurrencyId,
      targetCurrencyId: targetCurrencyId ?? this.targetCurrencyId,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(CalculatorState(
    inputAmount: "1",
    sourceCurrencyId: 'USD',
    targetCurrencyId: 'VES',
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

// --- PROVIDERS (ACTUALIZADOS PARA MANEJAR EL DATASOURCE) ---

final currencyRepositoryProvider = Provider((ref) => CurrencyRepository());

// El StreamProvider ahora sabe que emitirá nuestro objeto DataWrapper.
// La UI que observe este provider será notificada de cada nueva emisión.
final ratesProvider = StreamProvider<DataWrapper<Map<String, double>>>((ref) {
  return ref.watch(currencyRepositoryProvider).getRatesStream();
});

// El roundedRatesProvider se actualiza para "desenvolver" los datos.
// Su única responsabilidad es tomar las tasas del DataWrapper y redondearlas.
final roundedRatesProvider = Provider<Map<String, double>>((ref) {
  // Observamos el estado completo del StreamProvider (el AsyncValue que contiene el DataWrapper).
  final ratesAsyncValue = ref.watch(ratesProvider);

  // Usamos .maybeWhen para manejar el caso de éxito de forma segura.
  return ratesAsyncValue.maybeWhen(
    // Cuando hay datos (data), recibimos nuestro objeto 'wrapper'.
    data: (wrapper) {
      // Extraemos el mapa de tasas del wrapper.
      final rates = wrapper.data;
      // Aplicamos la lógica de redondeo y devolvemos el resultado.
      return rates.map((key, value) => MapEntry(key, (value * 100).round() / 100));
    },
    // En cualquier otro caso (cargando, error), devolvemos un mapa vacío.
    orElse: () => {},
  );
});

final calculatorProvider = StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
});

// Este provider no necesita cambios, ya que depende de 'roundedRatesProvider',
// que ya le entrega los datos en el formato que espera (un simple Map).
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