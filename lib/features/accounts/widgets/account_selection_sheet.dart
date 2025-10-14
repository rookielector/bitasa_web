// lib/features/accounts/widgets/account_selection_sheet.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:flutter/material.dart';

class AccountSelectionSheet extends StatelessWidget {
  final List<FinancialAccount> accounts;

  const AccountSelectionSheet({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    // --- NUEVA LÓGICA DE ORDENAMIENTO ---
    final sortedAccounts = List<FinancialAccount>.from(accounts);
    
    // El método 'sort' modifica la lista in-situ.
    sortedAccounts.sort((a, b) {
      // 1. Si 'a' es el predeterminado, siempre debe ir primero (-1).
      if (a.isDefault) return -1;
      // 2. Si 'b' es el predeterminado, siempre debe ir primero, así que 'a' va después (1).
      if (b.isDefault) return 1;
      // 3. Si ninguno es predeterminado, los ordenamos alfabéticamente por nombre de institución.
      return a.institutionName.toLowerCase().compareTo(b.institutionName.toLowerCase());
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Selecciona la cuenta para compartir',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                shrinkWrap: true,
                // Usamos la nueva lista ordenada.
                itemCount: sortedAccounts.length,
                itemBuilder: (context, index) {
                  final account = sortedAccounts[index];
                  return ListTile(
                    leading: Icon(
                      account.type == AccountType.pagoMovil 
                          ? Icons.phone_android 
                          : Icons.account_balance,
                    ),
                    title: Text(account.institutionName),
                    subtitle: Text(
                      account.type == AccountType.pagoMovil
                          ? account.phoneNumber!
                          : account.accountNumber!,
                    ),
                    // La estrella sigue indicando cuál es la predeterminada.
                    trailing: account.isDefault 
                        ? const Icon(Icons.star, color: Colors.amber, size: 20) 
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(account);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}