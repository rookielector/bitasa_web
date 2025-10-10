// lib/screens/calculator_screen.dart

import 'package:bitasa_web/core/theme/theme_provider.dart';
import 'package:bitasa_web/features/calculator/providers/calculator_provider.dart';
import 'package:bitasa_web/features/currency/currency_data.dart';
import 'package:bitasa_web/features/currency/widgets/currency_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
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

  // --- REINTEGRAMOS EL MÉTODO PARA MOSTRAR EL SELECTOR DE FECHA ---
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: ref.read(calculatorProvider).selectedDate,
      firstDate: DateTime(2022),
      lastDate: now,
      locale: const Locale('es', 'ES'),
    );

    if (newDate != null) {
      ref.read(calculatorProvider.notifier).updateSelectedDate(newDate);
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

    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
    final ratesAsyncValue = ref.watch(ratesProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, 
        title: Image.asset('assets/images/logo.webp', height: 65),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Cambiar Tema',
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: ratesAsyncValue.when(
          data: (rates) => _buildCalculatorView(),
          loading: () {
            if (ratesAsyncValue.hasValue) {
              return _buildCalculatorView();
            }
            return const Center(child: CircularProgressIndicator());
          },
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
                      onPressed: () { ref.invalidate(ratesProvider); },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
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
          const Spacer(),
          _buildRateInfoSection(calculatorState.selectedDate, displayRate, calculatorState.sourceCurrencyId, calculatorState.targetCurrencyId),
        ],
      ),
    );
  }

  Widget _buildRateInfoSection(DateTime date, double rate, String source, String target) {
    final formattedDate = DateFormat.yMMMMd('es_ES').format(date);
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Text(
            '1 $source = ${rateFormatter.format(rate)} $target',
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