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

  // Crea un objeto ExchangeRate desde un DocumentSnapshot de Firestore
  factory ExchangeRate.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ExchangeRate(
      // Convertimos el Timestamp de Firestore a DateTime de Dart
      date: (data['date'] as Timestamp).toDate(),
      usdRate: (data['usd_rate'] as num).toDouble(),
      eurRate: (data['eur_rate'] as num).toDouble(),
    );
  }
}