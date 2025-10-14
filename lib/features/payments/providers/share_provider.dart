// lib/features/payments/providers/share_provider.dart

import 'package:bitasa_web/features/payments/services/share_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Un Provider simple que crea y expone una única instancia de nuestro ShareService.
final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});