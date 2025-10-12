// lib/features/currency/rate_info.dart

import 'package:bitasa_web/features/currency/exchange_rate.dart';

// Esta clase "envuelve" toda la información de tasas que la aplicación necesita
// para una sesión de usuario.
class RateInfo {
  // La tasa que se debe usar por defecto al abrir la app.
  // Será la de hoy, o la del viernes si es fin de semana, etc.
  final ExchangeRate defaultRate;

  // La tasa "del día siguiente" o futura, si está disponible.
  // Es opcional (puede ser nulo).
  final ExchangeRate? futureRate;

  RateInfo({
    required this.defaultRate,
    this.futureRate,
  });
}