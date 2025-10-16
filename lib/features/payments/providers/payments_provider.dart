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
    // Ejecutamos la acción de guardado.
    await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).savePayment(payment);
    });
    // Invalidamos el provider para forzar una recarga de la lista y mostrar el nuevo ítem.
    ref.invalidateSelf();
  }

  Future<void> deletePayment(int id) async {
    await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).deletePayment(id);
    });
    ref.invalidateSelf();
  }

  // --- NUEVO MÉTODO PARA ACTUALIZAR EL MOTIVO ---
  Future<void> updatePaymentSubject(int id, String newSubject) async {
    await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).updatePaymentSubject(id, newSubject);
    });
    // Forzamos la recarga de la lista para que la UI refleje el cambio inmediatamente.
    ref.invalidateSelf();
  }
}

// --- PROVIDER PRINCIPAL DE PAGOS GUARDADOS ---
final savedPaymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<PaymentData>>(() {
  return PaymentsNotifier();
});