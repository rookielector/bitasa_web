// lib/features/currency/currency_data.dart

import 'package:flutter/material.dart';
import 'currency.dart';

// Lista global y constante de todas las monedas soportadas por la aplicación.
final List<Currency> allCurrencies = [
  const Currency(
    id: 'USD',
    nameSingular: 'Dólar',
    namePlural: 'Dólares',
    icon: Icons.attach_money,
  ),
  const Currency(
    id: 'EUR',
    nameSingular: 'Euro',
    namePlural: 'Euros',
    icon: Icons.euro,
  ),
  const Currency(
    id: 'VES',
    nameSingular: 'Bolívar',
    namePlural: 'Bolívares',
    icon: Icons.account_balance,
  ),
  // Aquí podremos añadir más monedas fácilmente en el futuro (BTC, COP, etc.)
  // siempre y cuando tengamos sus tasas en Firebase.
];

// Función auxiliar para encontrar una moneda por su ID rápidamente.
Currency getCurrencyById(String id) {
  return allCurrencies.firstWhere(
    (currency) => currency.id == id,
    // Si por alguna razón no se encuentra (no debería pasar), devolvemos USD como fallback.
    orElse: () => allCurrencies.first, 
  );
}