// lib/features/payments/services/share_service.dart

import 'dart:typed_data';
import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:bitasa_web/features/payments/widgets/payment_data_image_widget.dart';
import 'package:bitasa_web/features/payments/widgets/simple_calc_image_widget.dart';
import 'package:bitasa_web/features/payments/widgets/qr_code_view_widget.dart';
import 'package:bitasa_web/services/widget_capture_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final WidgetCaptureService _captureService = WidgetCaptureService();

  // --- MÉTODOS PÚBLICOS PRINCIPALES ---

  // TEXTO
  Future<void> shareSimpleCalculationAsText(PaymentData paymentData) async {
    final textContent = _generateSimpleText(paymentData);
    await _shareText(textContent);
  }

  Future<void> sharePaymentDataAsText(PaymentData paymentData, FinancialAccount account) async {
    final textContent = _generatePaymentDataText(paymentData, account);
    await _shareText(textContent);
  }

  // IMAGEN
  Future<void> shareSimpleCalculationAsImage(BuildContext context, PaymentData paymentData) async {
    await _showPreviewAndShare(
      context: context,
      title: 'Previsualización de Cálculo',
      child: SimpleCalcImageWidget(paymentData: paymentData),
      fileName: 'bitasa_calculo.png',
    );
  }

  Future<void> sharePaymentDataAsImage(BuildContext context, PaymentData paymentData, FinancialAccount account) async {
    await _showPreviewAndShare(
      context: context,
      title: 'Previsualización de Datos de Pago',
      child: PaymentDataImageWidget(paymentData: paymentData, account: account),
      fileName: 'bitasa_pago.png',
    );
  }

  // CÓDIGO QR
  Future<void> shareSimpleCalculationAsQr(BuildContext context, PaymentData paymentData) async {
    final textContent = _generateSimpleText(paymentData) + _getFooter();
    await _showPreviewAndShare(
      context: context,
      title: 'Código QR del Cálculo',
      child: QrCodeViewWidget(data: textContent.trim()),
      fileName: 'bitasa_qr_calculo.png',
    );
  }

  Future<void> sharePaymentDataAsQr(BuildContext context, PaymentData paymentData, FinancialAccount account) async {
    final textContent = _generatePaymentDataText(paymentData, account) + _getFooter();
    await _showPreviewAndShare(
      context: context,
      title: 'Código QR de Datos de Pago',
      child: QrCodeViewWidget(data: textContent.trim()),
      fileName: 'bitasa_qr_pago.png',
    );
  }


  // --- MÉTODOS PRIVADOS AUXILIARES ---

  String _generateSimpleText(PaymentData paymentData) {
    final numberFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');
    final formattedCalcDate = DateFormat('dd/MM/yyyy HH:mm').format(paymentData.calculationDate);
    final formattedRateDate = DateFormat('dd/MM/yyyy').format(paymentData.rateDate);
    
    return '''
*Bitasa - Cálculo de Conversión*
${numberFormatter.format(paymentData.sourceAmount)} ${paymentData.sourceCurrencyId} = *${numberFormatter.format(paymentData.targetAmount)} ${paymentData.targetCurrencyId}*
----------------------------------
*Tasa Aplicada:* 1 ${paymentData.sourceCurrencyId} = ${rateFormatter.format(paymentData.exchangeRate)} ${paymentData.targetCurrencyId}
*Fecha de la Tasa:* $formattedRateDate
*Fecha del Cálculo:* $formattedCalcDate
''';
  }

  String _generatePaymentDataText(PaymentData paymentData, FinancialAccount account) {
    final resultFormatter = NumberFormat('#,##0.00', 'es_VE');
    final rateFormatter = NumberFormat('#,##0.00', 'es_VE');
    final formattedCalcDate = DateFormat('dd/MM/yyyy HH:mm').format(paymentData.calculationDate);
    final formattedRateDate = DateFormat('dd/MM/yyyy').format(paymentData.rateDate);

    return '''
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
  }
  
  String _getFooter() {
    return '''

----------------------------------
Calcula y gestiona tus pagos con Bitasa Web.
¡Pruébala aquí!
https://rookielector.github.io/bitasa_web/
''';
  }

  Future<void> _shareText(String content) async {
    final String fullContent = content.trim() + _getFooter();
    try {
      await Share.share(fullContent);
    } catch (e) {
      if (kDebugMode) {
        print("Error al compartir texto: $e");
      }
    }
  }

  Future<void> _showPreviewAndShare({
    required BuildContext context,
    required String title,
    required Widget child,
    required String fileName,
  }) async {
    final GlobalKey captureKey = GlobalKey();
    if (!context.mounted) return;

    // La lógica de 'share' ahora vivirá dentro del callback del botón.
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
                // --- NUEVA LÓGICA DE CAPTURA Y COMPARTIR ---
                
                // 1. Capturamos el widget.
                final Uint8List? imageBytes = await _captureService.captureWidget(captureKey);
                
                // 2. Si la captura falla, mostramos un error y nos quedamos en el diálogo.
                if (imageBytes == null) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Error al generar la imagen. Intenta de nuevo.')),
                    );
                  }
                  return;
                }
                
                // 3. Si la captura tiene éxito, cerramos el diálogo.
                if (ctx.mounted) Navigator.of(ctx).pop();

                // 4. Creamos el XFile.
                final file = XFile.fromData(
                  imageBytes,
                  name: fileName,
                  mimeType: 'image/png',
                );

                // 5. Intentamos compartir el archivo.
                try {
                  await Share.shareXFiles([file], text: 'Datos de pago de Bitasa');
                } catch (e) {
                  // Si la API de compartir falla, mostramos un error.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo abrir el diálogo de compartir: $e')),
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
}