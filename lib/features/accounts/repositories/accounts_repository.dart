// lib/features/accounts/repositories/accounts_repository.dart

import 'package:bitasa_web/features/accounts/models/financial_account.dart';
import 'package:bitasa_web/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- CAMBIO 1: AÑADIMOS 'as sembast' AL IMPORT ---
import 'package:sembast/sembast.dart' as sembast;

class AccountsRepository {
  final DatabaseService _dbService = DatabaseService();
  // --- CAMBIO 2: DECLARAMOS LA VARIABLE _firestore ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<sembast.StoreRef<int, Map<String, dynamic>>> get _store async {
    final db = await _dbService.database;
    return _dbService.accountsStore;
  }
  
  Future<List<String>> getBankList() async {
    try {
      final snapshot = await _firestore
          .collection('financial_institutions')
          .orderBy('name')
          .get();
      if (snapshot.docs.isEmpty) return [];
      
      final bankNames = snapshot.docs.map((doc) {
        final data = doc.data();
        final code = data['bank_code'] ?? 'S/C';
        final name = data['name'] ?? 'Nombre no disponible';
        return '$code - $name';
      }).toList();
      
      return bankNames;
    } catch (e) {
      print('Error al obtener bancos de Firebase: $e');
      throw Exception('No se pudo cargar la lista de bancos.');
    }
  }

  Future<void> addAccount(FinancialAccount account) async {
    final store = await _store;
    final db = await _dbService.database;

    // --- CAMBIO 3: USAMOS EL PREFIJO 'sembast.' PARA LA TRANSACCIÓN ---
    await db.transaction((sembast.Transaction txn) async {
      if (account.isDefault) {
        await _clearDefaultFlag(txn);
      }
      await store.add(txn, account.toMap());
    });
  }
  
  Future<void> updateAccount(FinancialAccount account) async {
    final store = await _store;
    final db = await _dbService.database;
    
    await db.transaction((sembast.Transaction txn) async {
      if (account.isDefault) {
        await _clearDefaultFlag(txn);
      }
      await store.record(account.id).update(txn, account.toMap());
    });
  }

  Future<void> deleteAccount(int id) async {
    final store = await _store;
    final db = await _dbService.database;
    await store.record(id).delete(db);
  }

  Future<void> setAsDefault(int id) async {
    final store = await _store;
    final db = await _dbService.database;

    await db.transaction((sembast.Transaction txn) async {
      await _clearDefaultFlag(txn);
      await store.record(id).update(txn, {'isDefault': true});
    });
  }

  Future<List<FinancialAccount>> getAccounts() async {
    final store = await _store;
    final db = await _dbService.database;
    final records = await store.find(db);

    return records.map((snapshot) {
      return FinancialAccount.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }

  Future<FinancialAccount?> getDefaultAccount() async {
    final store = await _store;
    final db = await _dbService.database;

    // --- CAMBIO 4: USAMOS EL PREFIJO 'sembast.' PARA FILTER Y FINDER ---
    final finder = sembast.Finder(filter: sembast.Filter.equals('isDefault', true), limit: 1);
    final record = await store.findFirst(db, finder: finder);
    
    if (record != null) {
      return FinancialAccount.fromMap(record.value, record.key);
    }
    return null;
  }
  
  Future<void> _clearDefaultFlag(sembast.Transaction txn) async {
    final store = _dbService.accountsStore;
    final finder = sembast.Finder(filter: sembast.Filter.equals('isDefault', true));
    final records = await store.find(txn, finder: finder);
    for (var record in records) {
      await store.record(record.key).update(txn, {'isDefault': false});
    }
  }
}