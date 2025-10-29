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
  final double exchangeRate; // Campo legado, se mantiene por compatibilidad
  final String? subject; 

  // --- NUEVOS CAMPOS PARA LA TASA DE REFERENCIA ---
  // Guardan la tasa base (ej: 1 USD = 219.87 VES) sin importar la dirección del cálculo.
  final double? referenceRateValue;
  final String? referenceRateCurrencyId;

  PaymentData({
    this.id,
    required this.calculationDate,
    required this.sourceAmount,
    required this.sourceCurrencyId,
    required this.targetAmount,
    required this.targetCurrencyId,
    required this.rateDate,
    required this.exchangeRate,
    this.subject,
    // Añadimos los nuevos campos al constructor
    this.referenceRateValue,
    this.referenceRateCurrencyId,
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
      subject: map['subject'] as String?,
      // Leemos los nuevos campos (pueden ser nulos en datos antiguos)
      referenceRateValue: (map['referenceRateValue'] as num?)?.toDouble(),
      referenceRateCurrencyId: map['referenceRateCurrencyId'] as String?,
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
      'subject': subject,
      // Guardamos los nuevos campos
      'referenceRateValue': referenceRateValue,
      'referenceRateCurrencyId': referenceRateCurrencyId,
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
      subject: subject ?? this.subject,
      // Los añadimos al copyWith
      referenceRateValue: referenceRateValue,
      referenceRateCurrencyId: referenceRateCurrencyId,
    );
  }
}