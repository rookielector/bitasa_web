// lib/features/accounts/screens/financial_account_form.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/accounts/providers/accounts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialAccountForm extends ConsumerStatefulWidget {
  final FinancialAccount? accountToEdit;
  const FinancialAccountForm({super.key, this.accountToEdit});

  @override
  ConsumerState<FinancialAccountForm> createState() => _FinancialAccountFormState();
}

class _FinancialAccountFormState extends ConsumerState<FinancialAccountForm> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _idCardController;
  late TextEditingController _phoneController;
  late TextEditingController _accountNumberController;
  late TextEditingController _otherBankController;

  String? _selectedBank;
  bool _showOtherBankField = false;
  final String _otherOption = 'Otro...';
  
  AccountType _selectedType = AccountType.pagoMovil;
  bool _isDefault = true;

  @override
  void initState() {
    super.initState();
    final account = widget.accountToEdit;
    
    _idCardController = TextEditingController(text: account?.idCard ?? '');
    _phoneController = TextEditingController(text: account?.phoneNumber ?? '');
    _accountNumberController = TextEditingController(text: account?.accountNumber ?? '');
    _otherBankController = TextEditingController();

    _selectedType = account?.type ?? AccountType.pagoMovil;
    _isDefault = account?.isDefault ?? true;

    if (account != null) {
      // Guardamos el nombre del banco para la selección inicial.
      // La lógica de si es 'Otro...' se manejará en el método 'build'.
      _selectedBank = account.institutionName;
    }
  }
  
  @override
  void dispose() {
    _idCardController.dispose();
    _phoneController.dispose();
    _accountNumberController.dispose();
    _otherBankController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final String institutionName = (_showOtherBankField ? _otherBankController.text.trim() : _selectedBank) ?? '';
      
      if (institutionName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona o introduce un banco.'), backgroundColor: Colors.red),
        );
        return;
      }

      final newAccountData = FinancialAccount(
        id: widget.accountToEdit?.id ?? 0,
        type: _selectedType,
        institutionName: institutionName,
        idCard: _idCardController.text.trim(),
        phoneNumber: _selectedType == AccountType.pagoMovil ? _phoneController.text.trim() : null,
        accountNumber: _selectedType == AccountType.transferencia ? _accountNumberController.text.trim() : null,
        isDefault: _isDefault,
      );

      if (widget.accountToEdit == null) {
        ref.read(accountsProvider.notifier).addAccount(newAccountData);
      } else {
        ref.read(accountsProvider.notifier).updateAccount(newAccountData);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankListAsync = ref.watch(bankListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.accountToEdit == null ? 'Añadir Nueva Cuenta' : 'Editar Cuenta',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (widget.accountToEdit == null) ...[
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: AccountType.pagoMovil, child: Text('Pago Móvil')),
                  DropdownMenuItem(value: AccountType.transferencia, child: Text('Transferencia')),
                ],
                onChanged: (value) {
                  if(value != null) setState(() => _selectedType = value);
                },
                decoration: const InputDecoration(labelText: 'Tipo de Cuenta', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
            ],

            bankListAsync.when(
              data: (banks) {
                final fullBankList = [...banks, _otherOption];
                
                // Si el banco guardado no está en la lista, lo tratamos como "Otro".
                if (widget.accountToEdit != null && !fullBankList.contains(_selectedBank)) {
                  _showOtherBankField = true;
                  _otherBankController.text = _selectedBank ?? '';
                  _selectedBank = _otherOption;
                }

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      hint: const Text('Selecciona un banco'),
                      isExpanded: true,
                      items: fullBankList.map((String bank) {
                        return DropdownMenuItem<String>(
                          value: bank,
                          child: Text(bank, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBank = value;
                          _showOtherBankField = (value == _otherOption);
                        });
                      },
                      validator: (value) => value == null ? 'Selecciona un banco' : null,
                      decoration: const InputDecoration(labelText: 'Banco', border: OutlineInputBorder()),
                    ),
                    if (_showOtherBankField)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: TextFormField(
                          controller: _otherBankController,
                          decoration: const InputDecoration(labelText: 'Nombre del Banco', border: OutlineInputBorder()),
                          validator: (value) {
                            if (_showOtherBankField && (value == null || value.isEmpty)) {
                              return 'Campo requerido';
                            }
                            return null;
                          },
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Text('Error al cargar bancos: $e'),
            ),

            const SizedBox(height: 12),
            if (_selectedType == AccountType.pagoMovil)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Número de Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
            if (_selectedType == AccountType.transferencia)
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(labelText: 'Número de Cuenta', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _idCardController,
              decoration: const InputDecoration(labelText: 'Cédula / RIF', border: OutlineInputBorder()),
              keyboardType: TextInputType.text,
              validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
            ),
            CheckboxListTile(
              title: const Text('Marcar como predeterminado'),
              value: _isDefault,
              onChanged: (value) {
                if (value != null) setState(() => _isDefault = value);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _onSave, child: const Text('Guardar')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}