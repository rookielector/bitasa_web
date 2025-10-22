// lib/features/calculator/screens/calculator_view.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/accounts/providers/accounts_provider.dart';
import 'package:bitasa_web/features/accounts/widgets/account_selection_sheet.dart';
import 'package:bitasa_web/features/calculator/providers/calculator_provider.dart';
import 'package:bitasa_web/features/currency/currency_data.dart';
import 'package:bitasa_web/features/currency/widgets/currency_selection_sheet.dart';
import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:bitasa_web/features/payments/providers/payments_provider.dart';
import 'package:bitasa_web/features/payments/providers/share_provider.dart';
import 'package:bitasa_web/features/payments/widgets/share_options_sheet.dart';
import 'package:bitasa_web/features/tutorial/providers/tutorial_provider.dart';
import 'package:bitasa_web/screens/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';

class CalculatorView extends ConsumerStatefulWidget {
  const CalculatorView({super.key});

  @override
  ConsumerState<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends ConsumerState<CalculatorView> {
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  
  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: ref.read(calculatorProvider).inputAmount,
    );
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        _amountController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _amountController.text.length,
        );
      }
    });

    // La lógica de inicio del tour se ha movido al 'build' a través de un 'ref.listen'.
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }
  
  String getCurrencyName(String code, num amount) {
    final currency = getCurrencyById(code);
    if (amount.abs() == 1) {
      return currency.nameSingular;
    }
    return currency.namePlural;
  }

  Future<void> _showCurrencyPicker(BuildContext context, {required bool isSource}) async {
    final selectedCurrencyId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CurrencySelectionSheet(),
    );

    if (selectedCurrencyId != null) {
      if (isSource) {
        ref.read(calculatorProvider.notifier).setSourceCurrency(selectedCurrencyId);
      } else {
        ref.read(calculatorProvider.notifier).setTargetCurrency(selectedCurrencyId);
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: ref.read(calculatorProvider).selectedDate,
      firstDate: DateTime(2022),
      lastDate: now.add(const Duration(days: 5)),
      locale: const Locale('es', 'ES'),
    );

    if (newDate != null) {
      ref.read(calculatorProvider.notifier).updateSelectedDate(newDate);
    }
  }

  void _saveCurrentCalculation({String? subject}) {
    final calcState = ref.read(calculatorProvider);
    final rates = ref.read(roundedRatesProvider);
    final displayRate = (rates[calcState.targetCurrencyId] ?? 0.0) > 0
        ? (rates[calcState.sourceCurrencyId] ?? 0.0) / (rates[calcState.targetCurrencyId] ?? 1.0)
        : 0.0;
    
    final convertedAmountString = ref.read(convertedAmountProvider)
      .replaceAll('.', '')
      .replaceAll(',', '.');
        
    final newPayment = PaymentData(
      calculationDate: DateTime.now(),
      sourceAmount: double.tryParse(calcState.inputAmount) ?? 0.0,
      sourceCurrencyId: calcState.sourceCurrencyId,
      targetAmount: double.tryParse(convertedAmountString) ?? 0.0,
      targetCurrencyId: calcState.targetCurrencyId,
      rateDate: calcState.selectedDate,
      exchangeRate: displayRate,
      subject: subject,
    );

    ref.read(savedPaymentsProvider.notifier).savePayment(newPayment);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cálculo guardado'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _showSaveDialog() async {
    final subjectController = TextEditingController();
    
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar Cálculo'),
        content: TextField(
          controller: subjectController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivo del Pago (Opcional)',
            hintText: 'Ej: Factura #123, Alquiler...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Guardar')),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      _saveCurrentCalculation(subject: subjectController.text.trim());
    }
  }

  Future<void> _showEditSubjectDialog(PaymentData payment) async {
    final subjectController = TextEditingController(text: payment.subject ?? '');

    final String? newSubject = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Motivo'),
        content: TextField(
          controller: subjectController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Motivo del Pago (Opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(subjectController.text.trim()), child: const Text('Actualizar')),
        ],
      ),
    );

    if (newSubject != null && payment.id != null) {
      ref.read(savedPaymentsProvider.notifier).updatePaymentSubject(payment.id!, newSubject);
    }
  }

  void _sharePaymentData({PaymentData? paymentFromList}) async {
    final bool isFromSavedList = paymentFromList != null;
    final shareService = ref.read(shareServiceProvider);

    final PaymentData paymentData;
    if (isFromSavedList) {
      paymentData = paymentFromList;
    } else {
      final calcState = ref.read(calculatorProvider);
      final rates = ref.read(roundedRatesProvider);
      final displayRate = (rates[calcState.targetCurrencyId] ?? 0.0) > 0
          ? (rates[calcState.sourceCurrencyId] ?? 0.0) / (rates[calcState.targetCurrencyId] ?? 1.0)
          : 0.0;
      final convertedAmountString = ref.read(convertedAmountProvider).replaceAll('.', '').replaceAll(',', '.');
          
      paymentData = PaymentData(
        calculationDate: DateTime.now(),
        sourceAmount: double.tryParse(calcState.inputAmount) ?? 0.0,
        sourceCurrencyId: calcState.sourceCurrencyId,
        targetAmount: double.tryParse(convertedAmountString) ?? 0.0,
        targetCurrencyId: calcState.targetCurrencyId,
        rateDate: calcState.selectedDate,
        exchangeRate: displayRate,
      );
    }
    
    final selectedOption = await showModalBottomSheet<ShareOption>(
      context: context,
      builder: (ctx) => const ShareOptionsSheet(),
    );

    if (selectedOption == null) return;

    if (isFromSavedList) {
      final accounts = ref.read(accountsProvider).valueOrNull ?? [];
      if (accounts.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Configuración Requerida'),
              content: const Text('Para compartir tus datos de pago, primero necesitas añadir una cuenta en la pestaña "Cuentas".'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Más Tarde')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    homeShellKey.currentState?.onItemTapped(1);
                  },
                  child: const Text('Ir a Cuentas'),
                ),
              ],
            ),
          );
        }
        return;
      }

      FinancialAccount? accountToUse;
      if (accounts.length == 1) {
        accountToUse = accounts.first;
      } else {
        accountToUse = await showModalBottomSheet<FinancialAccount>(
          context: context,
          builder: (ctx) => AccountSelectionSheet(accounts: accounts),
        );
      }
      
      if (accountToUse == null) return;
      
      switch (selectedOption) {
        case ShareOption.text:
          await shareService.sharePaymentDataAsText(paymentData, accountToUse);
          break;
        case ShareOption.image:
          await shareService.sharePaymentDataAsImage(context, paymentData, accountToUse);
          break;
        case ShareOption.qr:
          await shareService.sharePaymentDataAsQr(context, paymentData, accountToUse);
          break;
      }
    } else {
      switch (selectedOption) {
        case ShareOption.text:
          await shareService.shareSimpleCalculationAsText(paymentData);
          break;
        case ShareOption.image:
          await shareService.shareSimpleCalculationAsImage(context, paymentData);
          break;
        case ShareOption.qr:
          await shareService.shareSimpleCalculationAsQr(context, paymentData);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha la bandera del tutorial.
    ref.listen<bool>(startTutorialProvider, (previous, shouldStart) {
      if (shouldStart) {
        final keys = ref.read(tutorialKeysProvider);
        final tutorialService = ref.read(tutorialServiceProvider);
        
        ShowCaseWidget.of(context).startShowCase(keys.keys);
        
        tutorialService.markTutorialAsSeen();
        // Resetea la bandera para que no se vuelva a lanzar en esta sesión.
        ref.read(startTutorialProvider.notifier).state = false;
      }
    });
    
    ref.listen<CalculatorState>(calculatorProvider, (previous, next) {
      if (next.inputAmount != _amountController.text && next.inputAmount != "0") {
        _amountController.text = next.inputAmount;
      } else if (next.inputAmount == "0" && _amountController.text.isNotEmpty) {
        _amountController.clear();
      }
    });

    final rateInfoAsyncValue = ref.watch(rateInfoProvider);

    return rateInfoAsyncValue.when(
      data: (rateInfo) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildCalculatorContent(),
          const SizedBox(height: 24),
          const Text('Cálculos para Gestión de Pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildSavedPaymentsList(),
          const SizedBox(height: 24),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Error al cargar las tasas.\n$error", textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () { ref.invalidate(rateInfoProvider); },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalculatorContent() {
    final tutorialKeys = ref.watch(tutorialKeysProvider);
    final calculatorState = ref.watch(calculatorProvider);
    final convertedAmount = ref.watch(convertedAmountProvider);
    final num inputAmount = num.tryParse(calculatorState.inputAmount) ?? 0;
    final num outputAmount = num.tryParse(convertedAmount.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final rates = ref.watch(roundedRatesProvider);
    final double sourceRate = rates[calculatorState.sourceCurrencyId] ?? 0.0;
    final double targetRate = rates[calculatorState.targetCurrencyId] ?? 0.0;
    final double displayRate = (targetRate > 0) ? sourceRate / targetRate : 0.0;
    
    return Column(
      children: [
        const SizedBox(height: 24),
        Showcase(
          key: tutorialKeys.sourceCurrency,
          title: 'Moneda de Origen',
          description: 'Toca aquí para seleccionar la moneda que quieres convertir.',
          child: _buildConversionCard(
            title: 'Tú envías',
            currencyCode: calculatorState.sourceCurrencyId,
            currencyName: getCurrencyName(calculatorState.sourceCurrencyId, inputAmount),
            amountController: _amountController,
            isInput: true,
            onTapSelector: () => _showCurrencyPicker(context, isSource: true),
          ),
        ),
        const SizedBox(height: 16),
        Showcase(
          key: tutorialKeys.swapButton,
          title: 'Intercambiar Monedas',
          description: 'Usa este botón para invertir rápidamente las monedas de origen y destino.',
          child: Tooltip(
            message: 'Intercambiar monedas',
            child: GestureDetector(
              onTap: () => ref.read(calculatorProvider.notifier).swapCurrencies(),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                child: Icon(Icons.swap_vert, color: Theme.of(context).colorScheme.secondary, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildConversionCard(
          title: 'Recibes',
          currencyCode: calculatorState.targetCurrencyId,
          currencyName: getCurrencyName(calculatorState.targetCurrencyId, outputAmount),
          amount: convertedAmount,
          isInput: false,
          onTapSelector: () => _showCurrencyPicker(context, isSource: false),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Showcase(
                key: tutorialKeys.saveButton,
                title: 'Guardar Cálculo',
                description: 'Guarda este cálculo para añadirle un motivo y compartirlo como un "Dato de Pago" completo más tarde.',
                child: OutlinedButton.icon(
                  onPressed: _showSaveDialog,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Guardar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Showcase(
                key: tutorialKeys.shareButton,
                title: 'Compartir Cálculo',
                description: 'Comparte rápidamente este cálculo como texto, imagen o QR, con o sin tus datos bancarios.',
                child: ElevatedButton.icon(
                  onPressed: () => _sharePaymentData(),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Showcase(
          key: tutorialKeys.rateDate,
          title: 'Fecha de la Tasa',
          description: 'Toca aquí para usar una tasa de una fecha anterior o para usar la tasa del día siguiente cuando esté disponible.',
          child: _buildRateInfoSection(
            currentDate: calculatorState.selectedDate,
            displayRate: displayRate,
            sourceCurrency: calculatorState.sourceCurrencyId,
            targetCurrency: calculatorState.targetCurrencyId,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPaymentsList() {
    final savedPaymentsAsync = ref.watch(savedPaymentsProvider);
    final numberFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat("#,##0.00", "es_VE");

    return savedPaymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
              child: Text(
                'Los cálculos que guardes aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        
        return Column(
          children: List.generate(payments.length > 5 ? 5 : payments.length, (index) {
            final payment = payments[index];
            final formattedRateDate = DateFormat('dd/MM/yyyy').format(payment.rateDate);

            return Card(
              margin: const EdgeInsets.fromLTRB(0, 8.0, 0, 0),
              child: ListTile(
                title: Text(
                  '${numberFormatter.format(payment.sourceAmount)} ${payment.sourceCurrencyId} ➔ ${numberFormatter.format(payment.targetAmount)} ${payment.targetCurrencyId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (payment.subject != null && payment.subject!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          payment.subject!,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      'Tasa: 1 ${payment.sourceCurrencyId} = ${rateFormatter.format(payment.exchangeRate)} ${payment.targetCurrencyId} (Tasa del $formattedRateDate)',
                    ),
                    Text(
                      'Guardado: ${DateFormat('dd/MM/yy HH:mm').format(payment.calculationDate)}',
                    ),
                  ],
                ),
                isThreeLine: (payment.subject != null && payment.subject!.isNotEmpty),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditSubjectDialog(payment);
                    } else if (value == 'share') {
                      _sharePaymentData(paymentFromList: payment);
                    } else if (value == 'delete') {
                      ref.read(savedPaymentsProvider.notifier).deletePayment(payment.id!);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar Motivo'))),
                    PopupMenuItem<String>(value: 'share', child: ListTile(leading: Icon(Icons.share_outlined), title: Text('Compartir'))),
                    PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Eliminar'))),
                  ],
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Más opciones',
                ),
              ),
            );
          }),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildRateInfoSection({
    required DateTime currentDate,
    required double displayRate,
    required String sourceCurrency,
    required String targetCurrency,
  }) {
    final defaultRate = ref.watch(defaultRateProvider);
    final futureRate = ref.watch(futureRateProvider);
    
    final isUsingFutureRate = futureRate != null &&
        DateUtils.isSameDay(futureRate.date, currentDate);

    final formattedDate = DateFormat.yMMMMEEEEd('es_ES').format(currentDate);
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Text(
            '1 $sourceCurrency = ${rateFormatter.format(displayRate)} $targetCurrency',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Tasa del: $formattedDate',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (futureRate != null && defaultRate != null)
            ElevatedButton(
              onPressed: () {
                final targetDate = isUsingFutureRate ? defaultRate.date : futureRate.date;
                ref.read(calculatorProvider.notifier).updateSelectedDate(targetDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isUsingFutureRate
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.secondary,
                foregroundColor: isUsingFutureRate
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Theme.of(context).colorScheme.onSecondary,
                side: isUsingFutureRate ? BorderSide(color: Theme.of(context).dividerColor) : null,
                elevation: isUsingFutureRate ? 0 : 2,
              ),
              child: Text(
                isUsingFutureRate
                    ? 'Volver a tasa de ${DateFormat.EEEE('es_ES').format(defaultRate.date)}'
                    : 'Usar tasa del ${DateFormat.EEEE('es_ES').format(futureRate.date)}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversionCard({
    required String title,
    required String currencyCode,
    required String currencyName,
    String? amount,
    TextEditingController? amountController,
    required bool isInput,
    required VoidCallback onTapSelector,
  }) {
    final theme = Theme.of(context);
    final currency = getCurrencyById(currencyCode);

    return Container(
      padding: const EdgeInsets.all(20.0),
      constraints: const BoxConstraints(minHeight: 130),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 16)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onTapSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white24,
                            child: Icon(currency.icon, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(currencyCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: constraints.maxWidth * 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isInput)
                      TextField(
                        controller: amountController,
                        focusNode: _amountFocusNode,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0,00',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        ),
                        onChanged: (value) {
                          ref.read(calculatorProvider.notifier).updateAmount(value.replaceAll(',', '.'));
                        },
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          amount ?? '0,00',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      currencyName,
                      style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}