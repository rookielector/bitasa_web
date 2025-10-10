// lib/features/currency/exchange_rate.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeRate {
  final DateTime date;
  final double usdRate;
  final double eurRate;

  ExchangeRate({
    required this.date,
    required this.usdRate,
    required this.eurRate,
  });

  // --- Métodos de Conversión ---

  // Convierte un objeto ExchangeRate a un Map (formato JSON) para guardarlo en Sembast.
  Map<String, dynamic> toMap() {
    return {
      // Guardamos la fecha como un String en formato ISO 8601, que es estándar y ordenable.
      'date': date.toIso8601String(),
      'usdRate': usdRate,
      'eurRate': eurRate,
    };
  }

  // Crea un objeto ExchangeRate desde un Map (leído de Sembast).
  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    return ExchangeRate(
      // Convertimos el String de nuevo a un objeto DateTime.
      date: DateTime.parse(map['date'] as String),
      usdRate: (map['usdRate'] as num).toDouble(),
      eurRate: (map['eurRate'] as num).toDouble(),
    );
  }
  
  // Mantenemos nuestro factory para crear desde Firestore, pero lo adaptamos.
  factory ExchangeRate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExchangeRate(
      date: (data['date'] as Timestamp).toDate(),
      usdRate: (data['usd_rate'] as num).toDouble(),
      eurRate: (data['eur_rate'] as num).toDouble(),
    );
  }
}