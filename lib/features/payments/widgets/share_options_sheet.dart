// lib/features/payments/widgets/share_options_sheet.dart

import 'package:flutter/material.dart';

// Un enum para representar las opciones de forma segura.
enum ShareOption { text, image, qr }

class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Compartir Datos de Pago como:',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Texto Simple'),
              onTap: () {
                // Devolvemos la opción seleccionada al cerrar el sheet.
                Navigator.of(context).pop(ShareOption.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Imagen'),
              onTap: () {
                Navigator.of(context).pop(ShareOption.image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Código QR'),
              onTap: () {
                Navigator.of(context).pop(ShareOption.qr);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}