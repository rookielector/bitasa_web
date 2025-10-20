// lib/features/payments/widgets/qr_code_view_widget.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeViewWidget extends StatelessWidget {
  final String data;

  const QrCodeViewWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280, 
      height: 340, // Aumentamos un poco más la altura para dar aire
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bitasa - Datos de Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 8),
            
            // --- CAMBIO CLAVE: USAMOS UN LAYOUTBUILDER ---
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Obtenemos el tamaño del espacio disponible (que será un cuadrado
                  // gracias al 'AspectRatio' que podríamos añadir o al 'Expanded' en una columna).
                  final qrSize = constraints.maxHeight;
                  
                  return QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    // Forzamos el tamaño del QR a ser el máximo posible en el espacio dado.
                    size: qrSize,
                    gapless: false,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            const Text(
              'Escanea este código para ver los detalles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            
            const SizedBox(height: 8),
            const Divider(color: Colors.black26),
            const SizedBox(height: 8),
            const Text(
              'Calcula y gestiona tus pagos con Bitasa Web',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.black45),
            ),
            const SizedBox(height: 2),
            const Text(
              'https://bitasa-v1.web.app/',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}