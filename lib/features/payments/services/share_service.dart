// lib/features/payments/services/share_service.dart

import 'dart:typed_data';
import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:bitasa_web/features/payments/widgets/payment_data_image_widget.dart';
import 'package:bitasa_web/features/payments/widgets/simple_calc_image_widget.dart';
import 'package:bitasa_web/services/widget_capture_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final WidgetCaptureService _captureService = WidgetCaptureService();

  // --- MÉTODOS DE "COMPARTIR COMO TEXTO" ---
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

  // --- NUEVOS MÉTODOS DE "COMPARTIR COMO IMAGEN" ---

  Future<void> shareSimpleCalculationAsImage(BuildContext context, PaymentData paymentData) async {
    await _showPreviewAndShare(
      context: context,
      title: 'Previsualización de Cálculo',
      child: SimpleCalcImageWidget(paymentData: paymentData),
      fileName: 'bitasa_calculo_${paymentData.id ?? DateTime.now().millisecondsSinceEpoch}.png',
    );
  }

  Future<void> sharePaymentDataAsImage(BuildContext context, PaymentData paymentData, FinancialAccount account) async {
    await _showPreviewAndShare(
      context: context,
      title: 'Previsualización de Datos de Pago',
      child: PaymentDataImageWidget(paymentData: paymentData, account: account),
      fileName: 'bitasa_pago_${paymentData.id ?? DateTime.now().millisecondsSinceEpoch}.png',
    );
  }

  // --- MÉTODO PRIVADO GENÉRICO PARA PREVISUALIZAR Y CAPTURAR ---
  Future<void> _showPreviewAndShare({
    required BuildContext context,
    required String title,
    required Widget child,
    required String fileName,
  }) async {
    final GlobalKey captureKey = GlobalKey();

    // Usamos 'context.mounted' para evitar errores si el widget se desmonta.
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: RepaintBoundary(
              key: captureKey,
              child: child,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final Uint8List? imageBytes = await _captureService.captureWidget(captureKey);
                
                if (ctx.mounted) Navigator.of(ctx).pop();

                if (imageBytes != null) {
                  final file = XFile.fromData(
                    imageBytes,
                    name: fileName,
                    mimeType: 'image/png',
                  );
                  await Share.shareXFiles([file], text: 'Datos de pago de Bitasa');
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al generar la imagen.')),
                    );
                  }
                }
              },
              child: const Text('Compartir Imagen'),
            ),
          ],
        );
      },
    );
  }
  
  // --- MÉTODO PRIVADO AUXILIAR PARA COMPARTIR TEXTO ---
  Future<void> _shareText(String content) async {
    const String footer = '''

----------------------------------
Calcula y gestiona tus pagos con Bitasa Web.
¡Pruébala aquí!
https://rookielector.github.io/bitasa_web/
''';
    final String fullContent = content.trim() + footer;
    try {
      await Share.share(fullContent);
    } catch (e) {
      if (kDebugMode) {
        print("Error al compartir texto: $e");
      }
    }
  }
}