// lib/shared/widgets/affiliate_banner_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AffiliateBannerWidget extends StatefulWidget {
  const AffiliateBannerWidget({Key? key}) : super(key: key);

  @override
  State<AffiliateBannerWidget> createState() => _AffiliateBannerWidgetState();
}

class _AffiliateBannerWidgetState extends State<AffiliateBannerWidget> {
  late Timer _timer;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _bannerItems = [
    {
      'type': 'monetag',
      'title': 'PUBLICIDAD',
      'subtitle': 'Anuncio patrocinado',
      'url': 'https://otieu.com/4/10074400',
      'color': Colors.transparent,
    },
    {
      'type': 'affiliate',
      'name': 'Binance',
      'promo': 'Únete a la principal plataforma de trading de criptomonedas',
      'url': 'https://account.binance.com/register?ref=20959762&?registerChannel=user_center',
      'badgeColor': const Color(0xFFF0B90B),
    },
    {
      'type': 'affiliate',
      'name': 'OKX',
      'promo': 'Regístrate y gana criptomonedas, aprovecha la nueva tarjeta VISA',
      'url': 'https://okx.com/join/19610346',
      'badgeColor': const Color(0xFFFFFFFF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _bannerItems.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _bannerItems[_currentIndex];
    final bool isMonetag = currentItem['type'] == 'monetag';

    return GestureDetector(
      onTap: () {
        _launchURL(currentItem['url']!);
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1A29),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMonetag) ...[
              const Text(
                "PUBLICIDAD",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (currentItem['badgeColor'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: currentItem['badgeColor'] as Color, width: 0.8),
                ),
                child: Text(
                  currentItem['name']!,
                  style: TextStyle(
                    color: currentItem['badgeColor'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentItem['promo']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.white38,
              ),
            ],
          ],
        ),
      ),
    );
  }
}