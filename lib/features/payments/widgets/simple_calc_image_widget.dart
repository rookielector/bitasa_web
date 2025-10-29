// lib/features/payments/widgets/simple_calc_image_widget.dart

import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SimpleCalcImageWidget extends StatelessWidget {
  final PaymentData paymentData;
  final String? referenceRate;

  const SimpleCalcImageWidget({
    super.key, 
    required this.paymentData,
    this.referenceRate,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormatter = NumberFormat('#,##0.00', 'es_VE');
    final resultFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');
    final formattedCalcDate = DateFormat('dd/MM/yyyy HH:mm').format(paymentData.calculationDate);
    final formattedRateDate = DateFormat('dd/MM/yyyy').format(paymentData.rateDate);

    // Lógica para determinar qué tasa mostrar
    final rateLine = (referenceRate != null && referenceRate!.isNotEmpty)
        ? referenceRate!
        : '1 ${paymentData.sourceCurrencyId} = ${rateFormatter.format(paymentData.exchangeRate)} ${paymentData.targetCurrencyId}';

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      width: 400, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.webp', height: 60),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.black26),
          const SizedBox(height: 16),

          Text(
            '${numberFormatter.format(paymentData.sourceAmount)} ${paymentData.sourceCurrencyId}',
            style: const TextStyle(fontSize: 20, color: Colors.black54),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Icon(Icons.arrow_downward, color: Colors.black54),
          ),
          Text(
            '${resultFormatter.format(paymentData.targetAmount)} ${paymentData.targetCurrencyId}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Color(0xFF11A820),
            ),
          ),
          const SizedBox(height: 24),
          
          Column(
            children: [
              _buildInfoRow(
                'Tasa Aplicada:',
                rateLine, // Usamos la variable con la lógica
              ),
              _buildInfoRow('Fecha de la Tasa:', formattedRateDate),
              _buildInfoRow('Fecha del Cálculo:', formattedCalcDate),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.black26),
          const SizedBox(height: 12),
          const Text(
            'Calcula y gestiona tus pagos con Bitasa Web',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 4),
          const Text(
            'https://bitasa-v1.web.app/',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}