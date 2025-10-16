// lib/features/payments/widgets/payment_data_image_widget.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDataImageWidget extends StatelessWidget {
  final PaymentData paymentData;
  final FinancialAccount account;

  const PaymentDataImageWidget({
    super.key,
    required this.paymentData,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final resultFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');
    final formattedCalcDate = DateFormat('dd/MM/yyyy HH:mm').format(paymentData.calculationDate);
    final formattedRateDate = DateFormat('dd/MM/yyyy').format(paymentData.rateDate);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset('assets/images/logo.webp', height: 60),
          const SizedBox(height: 16),
          const Text(
            'DATOS PARA EL PAGO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black26),
          const SizedBox(height: 16),
          
          if (paymentData.subject != null && paymentData.subject!.isNotEmpty) ...[
            _buildInfoRow('Motivo:', paymentData.subject!),
            const SizedBox(height: 12),
          ],
          
          _buildInfoRow('Entidad:', account.institutionName),
          _buildInfoRow(
            account.type == AccountType.pagoMovil ? 'Teléfono:' : 'Nro. Cuenta:',
            account.type == AccountType.pagoMovil ? account.phoneNumber! : account.accountNumber!,
          ),
          _buildInfoRow('Cédula/RIF:', account.idCard),
          
          const SizedBox(height: 12),
          const Divider(color: Colors.black26),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            'Tasa Aplicada:', 
            '1 ${paymentData.sourceCurrencyId} = ${rateFormatter.format(paymentData.exchangeRate)} ${paymentData.targetCurrencyId}',
          ),
          _buildInfoRow('Fecha de la Tasa:', formattedRateDate),
          _buildInfoRow('Fecha del Cálculo:', formattedCalcDate),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONTO A PAGAR:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${resultFormatter.format(paymentData.targetAmount)} ${paymentData.targetCurrencyId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF11A820),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Divider(color: Colors.black26),
          const SizedBox(height: 12),
          const Text(
            'Calcula y gestiona tus pagos con Bitasa Web',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 4),
          const Text(
            'https://rookielector.github.io/bitasa_web/',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}