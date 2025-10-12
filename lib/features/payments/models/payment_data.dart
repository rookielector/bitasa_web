// lib/features/payments/models/payment_data.dart

import 'package:bitasa_web/features/currency/currency_data.dart';
import 'package:bitasa_web/features/currency/currency.dart';

class PaymentData {
  // El ID ahora es opcional ('nullable'), porque un objeto PaymentData
  // no tiene ID hasta que se guarda en la base de datos.
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

  PaymentData({
    this.id, // Se hace opcional en el constructor.
    required this.calculationDate,
    required this.sourceAmount,
    required this.sourceCurrencyId,
    required this.targetAmount,
    required this.targetCurrencyId,
    required this.rateDate,
    required this.exchangeRate,
  });

  // Getters para acceder fácilmente a los objetos Currency completos.
  Currency get sourceCurrency => getCurrencyById(sourceCurrencyId);
  Currency get targetCurrency => getCurrencyById(targetCurrencyId);

  // --- Métodos de Conversión para Sembast ---

  // Este 'factory' ahora espera el ID como un parámetro separado,
  // que es como Sembast nos devuelve los datos (clave y valor por separado).
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
    );
  }

  // Al convertir a un mapa para guardar, NO incluimos el ID.
  // Sembast se encarga de gestionar la clave (el ID) por sí mismo.
  Map<String, dynamic> toMap() {
    return {
      'calculationDate': calculationDate.toIso8601String(),
      'sourceAmount': sourceAmount,
      'sourceCurrencyId': sourceCurrencyId,
      'targetAmount': targetAmount,
      'targetCurrencyId': targetCurrencyId,
      'rateDate': rateDate.toIso8601String(),
      'exchangeRate': exchangeRate,
    };
  }

  // Método 'copyWith' para crear copias, útil para Sembast al asignar un ID.
  PaymentData copyWith({int? id}) {
    return PaymentData(
      id: id ?? this.id,
      calculationDate: calculationDate,
      sourceAmount: sourceAmount,
      sourceCurrencyId: sourceCurrencyId,
      targetAmount: targetAmount,
      targetCurrencyId: targetCurrencyId,
      rateDate: rateDate,
      exchangeRate: exchangeRate,
    );
  }
}