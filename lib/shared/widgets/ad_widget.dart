// lib/shared/widgets/ad_widget.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdWidget extends StatelessWidget {
  // Guardamos tu Direct Link como una constante.
  static const String _adUrl = 'https://otieu.com/4/10074400';

  const AdWidget({super.key});

  // Método para lanzar la URL.
  Future<void> _launchAdUrl() async {
    final uri = Uri.parse(_adUrl);
    if (await canLaunchUrl(uri)) {
      // 'launchUrl' se encargará de abrir el enlace en una nueva pestaña.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // En el improbable caso de que no se pueda lanzar, lo imprimimos en la consola.
      print('No se pudo lanzar la URL: $_adUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchAdUrl,
      child: Container(
        height: 50, // Altura estándar para un banner
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PUBLICIDAD',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}