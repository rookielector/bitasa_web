// lib/features/currency/currency_repository.dart

import 'package:bitasa_web/features/currency/exchange_rate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter/material.dart'; // Necesario para TimeOfDay

class CurrencyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- MÉTODO ACTUALIZADO ---
  // Ahora acepta una fecha para hacer la consulta.
  Future<Map<String, double>> getRatesForDate(DateTime date) async {
    try {
      // Creamos un rango de búsqueda para el día completo (desde las 00:00 hasta las 23:59).
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _db
          .collection('exchange_rates')
          // Buscamos documentos cuya 'date' esté dentro del rango del día seleccionado.
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        // Si no hay tasa para ese día, buscamos la más reciente anterior a esa fecha.
        return getLatestRateBefore(date);
      }

      final rateDoc = snapshot.docs.first;
      final ExchangeRate rate = ExchangeRate.fromFirestore(rateDoc);

      return {
        'USD': rate.usdRate,
        'EUR': rate.eurRate,
        'VES': 1.0,
      };

    } catch (e) {
      throw Exception('Error al obtener la tasa para la fecha: $e');
    }
  }

  // --- MÉTODO AUXILIAR AÑADIDO ---
  // Busca la tasa más reciente disponible antes de una fecha dada.
  Future<Map<String, double>> getLatestRateBefore(DateTime date) async {
     final snapshot = await _db
          .collection('exchange_rates')
          .where('date', isLessThan: date)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        throw Exception('No se encontraron tasas para la fecha seleccionada ni anteriores.');
      }
      
      final rateDoc = snapshot.docs.first;
      final ExchangeRate rate = ExchangeRate.fromFirestore(rateDoc);

      return {
        'USD': rate.usdRate,
        'EUR': rate.eurRate,
        'VES': 1.0,
      };
  }
}