// lib/features/accounts/providers/accounts_provider.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/accounts/repositories/accounts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider del Repositorio (instancia única).
final accountsRepositoryProvider = Provider((ref) => AccountsRepository());

// --- NOTIFIER PARA LA GESTIÓN DE CUENTAS ---
// Usamos un AsyncNotifier para manejar estados de carga, error y datos de forma automática.
class AccountsNotifier extends AsyncNotifier<List<FinancialAccount>> {
  
  // Método build: Se ejecuta al iniciar el provider. Carga la lista inicial.
  @override
  Future<List<FinancialAccount>> build() async {
    return ref.read(accountsRepositoryProvider).getAccounts();
  }

  // --- MÉTODOS DE ACCIÓN (Mutaciones) ---
  // Cada método llama al repositorio y luego refresca el estado del provider.

  Future<void> addAccount(FinancialAccount account) async {
    // Ponemos el estado en carga.
    state = const AsyncValue.loading();
    // Ejecutamos la acción asíncrona y capturamos errores.
    state = await AsyncValue.guard(() async {
      await ref.read(accountsRepositoryProvider).addAccount(account);
      // Volvemos a cargar la lista para tener los datos frescos.
      return ref.read(accountsRepositoryProvider).getAccounts();
    });
  }

  Future<void> updateAccount(FinancialAccount account) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountsRepositoryProvider).updateAccount(account);
      return ref.read(accountsRepositoryProvider).getAccounts();
    });
  }

  Future<void> deleteAccount(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountsRepositoryProvider).deleteAccount(id);
      return ref.read(accountsRepositoryProvider).getAccounts();
    });
  }

  Future<void> setAsDefault(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountsRepositoryProvider).setAsDefault(id);
      return ref.read(accountsRepositoryProvider).getAccounts();
    });
  }
}

// --- PROVIDER PRINCIPAL DE CUENTAS ---
// La UI observará este provider para obtener la lista y llamar a sus métodos.
final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<FinancialAccount>>(() {
  return AccountsNotifier();
});

// --- PROVIDER DERIVADO: CUENTA POR DEFECTO ---
// Un provider simple que busca en la lista del accountsProvider y devuelve la cuenta por defecto.
final defaultAccountProvider = Provider<FinancialAccount?>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.valueOrNull?.where((acc) => acc.isDefault).firstOrNull;
});

// --- NUEVO PROVIDER PARA LA LISTA DE BANCOS ---
// Un FutureProvider que llama al repositorio para obtener la lista de bancos.
// La UI observará este provider para mostrar el estado de carga y la lista.
final bankListProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(accountsRepositoryProvider).getBankList();
});