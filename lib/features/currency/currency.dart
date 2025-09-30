// lib/features/currency/currency.dart

import 'package:flutter/material.dart';

class Currency {
  final String id; // El código único, ej: 'USD', 'VES'
  final String nameSingular; // Ej: 'Dólar'
  final String namePlural; // Ej: 'Dólares'
  final IconData icon; // El icono asociado

  const Currency({
    required this.id,
    required this.nameSingular,
    required this.namePlural,
    required this.icon,
  });
}