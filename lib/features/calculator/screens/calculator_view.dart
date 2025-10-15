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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  void _saveCurrentCalculation() {
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
    );

    ref.read(savedPaymentsProvider.notifier).savePayment(newPayment);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cálculo guardado'), duration: Duration(seconds: 2)),
    );
  }

  void _sharePaymentData({PaymentData? paymentFromList}) async {
    final bool isFromSavedList = paymentFromList != null;
    final shareService = ref.read(shareServiceProvider);

    // --- FLUJO UNIFICADO ---

    // 1. Crear/Obtener el PaymentData
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
    
    // 2. Mostrar opciones de formato (Texto, Imagen, QR)
    final selectedOption = await showModalBottomSheet<ShareOption>(
      context: context,
      builder: (ctx) => const ShareOptionsSheet(),
    );

    if (selectedOption == null) return; // El usuario cerró el sheet sin elegir.

    // 3. Aplicar la lógica dual (simple vs. datos de pago)
    if (isFromSavedList) {
      // Flujo "Datos de Pago"
      final accounts = ref.read(accountsProvider).valueOrNull ?? [];
      if (accounts.isEmpty) {
        if (mounted) {
          showDialog(
            context: context, // <-- AÑADIMOS EL CONTEXTO AQUÍ
            builder: (ctx) => AlertDialog( /* ... */ ),
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
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compartir como QR (en desarrollo)')));
          break;
      }
    } else {
      // Flujo "Cálculo Simple"
      switch (selectedOption) {
        case ShareOption.text:
          await shareService.shareSimpleCalculationAsText(paymentData);
          break;
        case ShareOption.image:
          await shareService.shareSimpleCalculationAsImage(context, paymentData);
          break;
        case ShareOption.qr:
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compartir como QR (en desarrollo)')));
          break;
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    ref.listen<CalculatorState>(calculatorProvider, (previous, next) {
      if (next.inputAmount != _amountController.text && next.inputAmount != "0") {
        _amountController.text = next.inputAmount;
      } else if (next.inputAmount == "0" && _amountController.text.isNotEmpty) {
        _amountController.clear();
      }
    });

    final rateInfoAsyncValue = ref.watch(rateInfoProvider);

    return rateInfoAsyncValue.when(
      data: (rateInfo) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildCalculatorView()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Cálculos para Gestión de Pagos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          _buildSavedPaymentsList(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  Widget _buildCalculatorView() {
    final calculatorState = ref.watch(calculatorProvider);
    final convertedAmount = ref.watch(convertedAmountProvider);
    final num inputAmount = num.tryParse(calculatorState.inputAmount) ?? 0;
    final num outputAmount = num.tryParse(convertedAmount.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final rates = ref.watch(roundedRatesProvider);
    final double sourceRate = rates[calculatorState.sourceCurrencyId] ?? 0.0;
    final double targetRate = rates[calculatorState.targetCurrencyId] ?? 0.0;
    final double displayRate = (targetRate > 0) ? sourceRate / targetRate : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildConversionCard(
            title: 'Tú envías',
            currencyCode: calculatorState.sourceCurrencyId,
            currencyName: getCurrencyName(calculatorState.sourceCurrencyId, inputAmount),
            amountController: _amountController,
            isInput: true,
            onTapSelector: () => _showCurrencyPicker(context, isSource: true),
          ),
          const SizedBox(height: 16),
          Tooltip(
            message: 'Intercambiar monedas',
            child: GestureDetector(
              onTap: () => ref.read(calculatorProvider.notifier).swapCurrencies(),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                child: Icon(
                  Icons.swap_vert,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 28,
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
                child: OutlinedButton.icon(
                  onPressed: _saveCurrentCalculation,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Guardar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sharePaymentData,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRateInfoSection(
            currentDate: calculatorState.selectedDate,
            displayRate: displayRate,
            sourceCurrency: calculatorState.sourceCurrencyId,
            targetCurrency: calculatorState.targetCurrencyId,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentsList() {
    final savedPaymentsAsync = ref.watch(savedPaymentsProvider);
    final numberFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat("#,##0.00", "es_VE");

    return savedPaymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                child: Text(
                  'Los cálculos que guardes aparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return SliverList.builder(
          itemCount: payments.length > 5 ? 5 : payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
              child: ListTile(
                title: Text(
                  '${numberFormatter.format(payment.sourceAmount)} ${payment.sourceCurrencyId} ➔ ${numberFormatter.format(payment.targetAmount)} ${payment.targetCurrencyId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  'Tasa: 1 ${payment.sourceCurrencyId} = ${rateFormatter.format(payment.exchangeRate)} ${payment.targetCurrencyId}\n'
                  'Guardado: ${DateFormat('dd/MM/yy HH:mm').format(payment.calculationDate)}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.share_outlined, color: Theme.of(context).colorScheme.secondary),
                      tooltip: 'Compartir cálculo',
                      onPressed: () => _sharePaymentData(paymentFromList: payment),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      tooltip: 'Eliminar cálculo',
                      onPressed: () {
                        ref.read(savedPaymentsProvider.notifier).deletePayment(payment.id!);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
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
      height: 130,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                child: isInput
                    ? TextField(
                        controller: amountController,
                        focusNode: _amountFocusNode,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0,00',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        ),
                        onChanged: (value) {
                          ref.read(calculatorProvider.notifier).updateAmount(value.replaceAll(',', '.'));
                        },
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          amount ?? '0,00',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                currencyName,
                style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}