// lib/features/payments/services/share_service.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ShareService {

  // El método para compartir el cálculo simple no cambia.
  Future<void> shareSimpleCalculationAsText(PaymentData paymentData) async {
    final numberFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');
    final formattedCalcDate = DateFormat('dd/MM/yyyy HH:mm').format(paymentData.calculationDate);
    final formattedRateDate = DateFormat('dd/MM/yyyy').format(paymentData.rateDate);
    
    final String shareTextContent = '''
*Bitasa - Cálculo de Conversión*
${numberFormatter.format(paymentData.sourceAmount)} ${paymentData.sourceCurrencyId} = *${numberFormatter.format(paymentData.targetAmount)} ${paymentData.targetCurrencyId}*
----------------------------------
*Tasa Aplicada:* 1 ${paymentData.sourceCurrencyId} = ${rateFormatter.format(paymentData.exchangeRate)} ${paymentData.targetCurrencyId}
*Fecha de la Tasa:* $formattedRateDate
*Fecha del Cálculo:* $formattedCalcDate
''';
    
    await _shareText(shareTextContent);
  }

  // --- MÉTODO ACTUALIZADO CON EL NUEVO FORMATO ---
  Future<void> sharePaymentDataAsText(PaymentData paymentData, FinancialAccount account) async {
    final resultFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');
    final formattedCalcDate = DateFormat('dd/MM/yyyy HH:mm').format(paymentData.calculationDate);
    final formattedRateDate = DateFormat('dd/MM/yyyy').format(paymentData.rateDate);

    final String shareTextContent = '''
*Bitasa - Datos para el Pago*
*Entidad:* ${account.institutionName}
*${account.type == AccountType.pagoMovil ? 'Teléfono' : 'Nro. Cuenta'}:* ${account.type == AccountType.pagoMovil ? account.phoneNumber : account.accountNumber}
*Cédula/RIF:* ${account.idCard}
*Monto a Pagar:* *${resultFormatter.format(paymentData.targetAmount)} ${paymentData.targetCurrencyId}*
----------------------------------
*Tasa Aplicada:* 1 ${paymentData.sourceCurrencyId} = ${rateFormatter.format(paymentData.exchangeRate)} ${paymentData.targetCurrencyId}
*Fecha de la Tasa:* $formattedRateDate
*Fecha del Cálculo:* $formattedCalcDate
''';

    await _shareText(shareTextContent);
  }

  // El método _shareText no necesita cambios.
  Future<void> _shareText(String content) async {
    const String footer = '''

----------------------------------
Calcula y gestiona tus pagos con Bitasa Web.
¡Pruébala aquí!
https://rookielector.github.io/bitasa_web/
''';
    try {
      await Share.share(content.trim() + footer);
    } catch (e) {
      if (kDebugMode) {
        print("Error al compartir: $e");
      }
    }
  }
}