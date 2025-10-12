// lib/services/database_service.dart

import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFactory = databaseFactoryWeb;
    const dbPath = 'bitasa_sembast.db';
    final db = await dbFactory.openDatabase(dbPath);
    return db;
  }

  // --- AÑADIMOS LOS NUEVOS STORES ---

  // Store para las tasas de cambio (ya existía).
  final ratesStore = stringMapStoreFactory.store('exchange_rates');

  // Store para los cálculos guardados (Datos de Pago).
  // Usará un 'int' como clave autoincremental.
  final paymentsStore = intMapStoreFactory.store('saved_payments');

  // Store para las cuentas financieras del usuario.
  final accountsStore = intMapStoreFactory.store('financial_accounts');
}