// lib/features/accounts/screens/financial_accounts_screen.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/accounts/providers/accounts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bitasa_web/features/accounts/screens/financial_account_form.dart';
// import 'package:bitasa_web/shared/widgets/responsive_center.dart'; // -> IMPORTACIÓN ELIMINADA

class FinancialAccountsScreen extends ConsumerWidget {
  const FinancialAccountsScreen({super.key});

  void _showFormBottomSheet(BuildContext context, {FinancialAccount? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FinancialAccountForm(accountToEdit: account);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsyncValue = ref.watch(accountsProvider);

    // --- RESPONSIVECENTER ELIMINADO DE AQUÍ ---
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.phone_android), text: 'Pago Móvil'),
              Tab(icon: Icon(Icons.account_balance), text: 'Transferencias'),
            ],
          ),
        ),
        body: accountsAsyncValue.when(
          data: (accounts) => TabBarView(
            children: [
              _buildAccountList(context, ref, accounts, AccountType.pagoMovil),
              _buildAccountList(context, ref, accounts, AccountType.transferencia),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Ocurrió un error al cargar las cuentas: $error')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showFormBottomSheet(context);
          },
          tooltip: 'Añadir Cuenta',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildAccountList(
    BuildContext context,
    WidgetRef ref,
    List<FinancialAccount> allAccounts,
    AccountType type,
  ) {
    final filteredAccounts = allAccounts.where((acc) => acc.type == type).toList();

    if (filteredAccounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No has añadido datos de\n${type == AccountType.pagoMovil ? "Pago Móvil" : "Transferencia"} todavía.\nUsa el botón (+) para empezar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      // Añadimos padding horizontal aquí para que la lista tenga márgenes en móvil.
      padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 80),
      itemCount: filteredAccounts.length,
      itemBuilder: (context, index) {
        final account = filteredAccounts[index];
        return Card(
          // Quitamos el margen horizontal de la Card, ya que el ListView lo gestiona.
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                account.isDefault ? Icons.star : Icons.star_border,
                color: account.isDefault ? Theme.of(context).colorScheme.secondary : Colors.grey,
              ),
              onPressed: () {
                ref.read(accountsProvider.notifier).setAsDefault(account.id);
              },
              tooltip: 'Marcar como predeterminado',
            ),
            title: Text(account.institutionName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              type == AccountType.pagoMovil 
                ? "Tel: ${account.phoneNumber}\nCI/RIF: ${account.idCard}"
                : "Cta: ${account.accountNumber}\nCI/RIF: ${account.idCard}",
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showFormBottomSheet(context, account: account);
                }
                if (value == 'delete') {
                  ref.read(accountsProvider.notifier).deleteAccount(account.id);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ),
        );
      },
    );
  }
}