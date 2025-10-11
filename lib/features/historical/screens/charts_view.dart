// lib/features/historical/screens/charts_view.dart

import 'package:bitasa_web/features/historical/providers/historical_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ChartsView extends ConsumerWidget {
  const ChartsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdSpots = ref.watch(usdChartSpotsProvider);
    final eurSpots = ref.watch(eurChartSpotsProvider);
    final selectedDays = ref.watch(chartDaysProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text("Comportamiento de Tasas", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          
          ToggleButtons(
            isSelected: [
              selectedDays == 7,
              selectedDays == 30,
              selectedDays == 90,
            ],
            onPressed: (index) {
              int days = 90;
              if (index == 0) days = 7;
              if (index == 1) days = 30;
              ref.read(chartDaysProvider.notifier).state = days;
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: Theme.of(context).colorScheme.secondary,
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('7 Días')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('30 Días')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('90 Días')),
            ],
          ),
          const SizedBox(height: 24),

          _buildSingleChart(
            context: context,
            title: "Tasa Histórica USD / VES",
            spots: usdSpots,
            color: Colors.green,
            selectedDays: selectedDays,
          ),
          const SizedBox(height: 32),

          _buildSingleChart(
            context: context,
            title: "Tasa Histórica EUR / VES",
            spots: eurSpots,
            color: Colors.blue,
            selectedDays: selectedDays,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChart({
    required BuildContext context,
    required String title,
    required List<FlSpot> spots,
    required Color color,
    required int selectedDays,
  }) {
    if (spots.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text("No hay datos suficientes para el gráfico en este rango.", textAlign: TextAlign.center)),
      );
    }
    
    final tooltipRateFormatter = NumberFormat("#,##0.00", "es_VE");

    double getInterval() {
      if (selectedDays <= 7) return const Duration(days: 2).inMilliseconds.toDouble();
      if (selectedDays <= 30) return const Duration(days: 7).inMilliseconds.toDouble();
      return const Duration(days: 30).inMilliseconds.toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: getInterval(),
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(DateFormat('dd MMM', 'es_ES').format(date), style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              // --- SECCIÓN CORREGIDA Y SIMPLIFICADA ---
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  // Eliminamos cualquier referencia a 'tooltipBgColor' o 'tooltipConfiguration'.
                  // Usaremos el estilo por defecto del paquete.
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                      return LineTooltipItem(
                        '${DateFormat('dd/MM/yy').format(date)}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: '${tooltipRateFormatter.format(spot.y)} VES',
                            style: TextStyle(color: color, fontWeight: FontWeight.w900),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}