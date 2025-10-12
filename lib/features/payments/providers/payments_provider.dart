// lib/features/payments/providers/payments_provider.dart

import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:bitasa_web/features/payments/repositories/payments_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del Repositorio.
final paymentsRepositoryProvider = Provider((ref) => PaymentsRepository());

// --- NOTIFIER PARA EL HISTORIAL DE PAGOS ---
class PaymentsNotifier extends AsyncNotifier<List<PaymentData>> {
  
  @override
  Future<List<PaymentData>> build() async {
    // Carga la lista inicial de pagos guardados.
    return ref.read(paymentsRepositoryProvider).getSavedPayments();
  }

  // --- MÉTODOS DE ACCIÓN ---

  Future<void> savePayment(PaymentData payment) async {
    // No ponemos el estado en carga aquí para que la UI no parpadee.
    // Simplemente ejecutamos la acción y refrescamos la lista.
    await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).savePayment(payment);
    });
    // Invalidamos el provider para forzar una recarga de la lista.
    ref.invalidateSelf();
  }

  Future<void> deletePayment(int id) async {
    await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).deletePayment(id);
    });
    ref.invalidateSelf();
  }
}

// --- PROVIDER PRINCIPAL DE PAGOS GUARDADOS ---
final savedPaymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<PaymentData>>(() {
  return PaymentsNotifier();
});