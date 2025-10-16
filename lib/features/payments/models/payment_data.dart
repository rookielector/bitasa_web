// lib/features/payments/models/payment_data.dart

import 'package:bitasa_web/features/currency/currency_data.dart';
import 'package:bitasa_web/features/currency/currency.dart';

class PaymentData {
  final int? id;
  
  // Datos del cálculo
  final DateTime calculationDate;
  final double sourceAmount;
  final String sourceCurrencyId;
  final double targetAmount;
  final String targetCurrencyId;

  // Datos de la tasa usada
  final DateTime rateDate;
  final double exchangeRate;

  // --- NUEVO CAMPO AÑADIDO ---
  final String? subject; // Motivo del pago, es opcional.

  PaymentData({
    this.id,
    required this.calculationDate,
    required this.sourceAmount,
    required this.sourceCurrencyId,
    required this.targetAmount,
    required this.targetCurrencyId,
    required this.rateDate,
    required this.exchangeRate,
    this.subject, // Lo añadimos al constructor.
  });

  Currency get sourceCurrency => getCurrencyById(sourceCurrencyId);
  Currency get targetCurrency => getCurrencyById(targetCurrencyId);

  factory PaymentData.fromMap(Map<String, dynamic> map, int id) {
    return PaymentData(
      id: id,
      calculationDate: DateTime.parse(map['calculationDate'] as String),
      sourceAmount: (map['sourceAmount'] as num).toDouble(),
      sourceCurrencyId: map['sourceCurrencyId'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      targetCurrencyId: map['targetCurrencyId'] as String,
      rateDate: DateTime.parse(map['rateDate'] as String),
      exchangeRate: (map['exchangeRate'] as num).toDouble(),
      subject: map['subject'] as String?, // Leemos el nuevo campo.
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calculationDate': calculationDate.toIso8601String(),
      'sourceAmount': sourceAmount,
      'sourceCurrencyId': sourceCurrencyId,
      'targetAmount': targetAmount,
      'targetCurrencyId': targetCurrencyId,
      'rateDate': rateDate.toIso8601String(),
      'exchangeRate': exchangeRate,
      'subject': subject, // Guardamos el nuevo campo.
    };
  }

  PaymentData copyWith({int? id, String? subject}) {
    return PaymentData(
      id: id ?? this.id,
      calculationDate: calculationDate,
      sourceAmount: sourceAmount,
      sourceCurrencyId: sourceCurrencyId,
      targetAmount: targetAmount,
      targetCurrencyId: targetCurrencyId,
      rateDate: rateDate,
      exchangeRate: exchangeRate,
      subject: subject ?? this.subject, // Lo añadimos al copyWith.
    );
  }
}