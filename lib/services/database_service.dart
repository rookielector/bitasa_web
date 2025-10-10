// lib/services/database_service.dart

import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

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
    // Como nuestra PWA es solo para la web, usamos directamente el 'databaseFactoryWeb'.
    // No necesitamos la lógica para comprobar si es móvil o no.
    final dbFactory = databaseFactoryWeb;
            
    const dbPath = 'bitasa_sembast.db';
    
    // Abrimos la base de datos usando el factory de la web (que usa IndexedDB).
    final db = await dbFactory.openDatabase(dbPath);
    
    return db;
  }

  final ratesStore = stringMapStoreFactory.store('exchange_rates');
}