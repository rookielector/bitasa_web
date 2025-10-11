// lib/features/historical/screens/historical_prices_screen.dart

import 'package:bitasa_web/features/currency/currency_data.dart';
import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:bitasa_web/features/historical/providers/historical_provider.dart';
// --- IMPORTAMOS NUESTRA NUEVA VISTA DE GRÁFICOS ---
import 'package:bitasa_web/features/historical/screens/charts_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:table_calendar/table_calendar.dart';

class HistoricalPricesScreen extends ConsumerWidget {
  const HistoricalPricesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsyncValue = ref.watch(historicalRatesStreamProvider);

    // --- CAMBIO: AHORA TENEMOS 2 PESTAÑAS ---
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'Lista'),
              Tab(icon: Icon(Icons.show_chart), text: 'Gráficos'),
            ],
          ),
        ),
        body: ratesAsyncValue.when(
          data: (rates) {
            if (rates.isEmpty) {
              return const Center(child: Text('No hay datos históricos disponibles.'));
            }
            // --- CAMBIO: USAMOS UN TABBARVIEW ---
            return const TabBarView(
              children: [
                HistoricalListView(), // Primera pestaña
                ChartsView(),         // Segunda pestaña
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Ocurrió un error: $error'),
          ),
        ),
      ),
    );
  }
}

// El resto del archivo (HistoricalListView, _CalendarDialog) no necesita cambios.
// Pega aquí el resto del código que ya teníamos para esas clases.

class HistoricalListView extends ConsumerStatefulWidget {
  const HistoricalListView({super.key});

  @override
  ConsumerState<HistoricalListView> createState() => _HistoricalListViewState();
}

class _HistoricalListViewState extends ConsumerState<HistoricalListView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) return 'Hoy';
    if (dateToCompare == yesterday) return 'Ayer';
    return DateFormat.yMMMMEEEEd('es_ES').format(date);
  }

  Future<void> _showDatePickerAndScroll() async {
    final allRates = ref.read(historicalRatesStreamProvider).valueOrNull;
    if (allRates == null || allRates.isEmpty) return;

    final firstDate = allRates.map((r) => r.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastDate = allRates.map((r) => r.date).reduce((a, b) => a.isAfter(b) ? a : b);

    final pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _CalendarDialog(
          firstDate: firstDate,
          lastDate: lastDate,
          initialDate: lastDate,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final groupedRates = ref.read(groupedHistoricalRatesProvider);
      final sortedDates = groupedRates.keys.toList();

      final targetIndex = sortedDates.indexWhere((date) => isSameDay(date, pickedDate));

      if (targetIndex != -1) {
        _itemScrollController.scrollTo(
          index: targetIndex,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOutCubic,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron datos para la fecha seleccionada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedRates = ref.watch(groupedHistoricalRatesProvider);
    final sortedDates = groupedRates.keys.toList();
    final rateFormatter = NumberFormat("#,##0.00", "es_VE");

    const sortOptions = {
      HistoricalSortCriteria.dateDesc: 'Fecha (Reciente)',
      HistoricalSortCriteria.dateAsc: 'Fecha (Antigua)',
      HistoricalSortCriteria.usdDesc: 'USD (Mayor)',
      HistoricalSortCriteria.usdAsc: 'USD (Menor)',
      HistoricalSortCriteria.eurDesc: 'EUR (Mayor)',
      HistoricalSortCriteria.eurAsc: 'EUR (Menor)',
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<HistoricalSortCriteria>(
                      value: ref.watch(historicalSortProvider),
                      isExpanded: true,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          ref.read(historicalSortProvider.notifier).state = newValue;
                        }
                      },
                      hint: Builder(
                        builder: (context) {
                           return Text(
                            'Ordenar por: ${sortOptions[ref.watch(historicalSortProvider)]}',
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      ),
                      items: sortOptions.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showDatePickerAndScroll,
                icon: const Icon(Icons.search, size: 20),
                label: const Text('Buscar Fecha'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final rateData = groupedRates[date]!.first;
              final usdCurrency = getCurrencyById('USD');
              final eurCurrency = getCurrencyById('EUR');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                    child: Text(
                      _formatDateHeader(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(usdCurrency.icon)),
                      title: Text(usdCurrency.nameSingular),
                      trailing: Text(
                        '${rateFormatter.format(rateData.usdRate)} VES',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(eurCurrency.icon)),
                      title: Text(eurCurrency.nameSingular),
                      trailing: Text(
                        '${rateFormatter.format(rateData.eurRate)} VES',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CalendarDialog extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialDate;

  const _CalendarDialog({
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
  });

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Seleccionar Fecha"),
      content: SizedBox(
        width: 350,
        child: TableCalendar(
          locale: 'es_ES',
          firstDay: widget.firstDate,
          lastDay: widget.lastDate,
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancelar"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton(
          child: const Text("Aceptar"),
          onPressed: () {
            Navigator.of(context).pop(_selectedDay);
          },
        ),
      ],
    );
  }
}