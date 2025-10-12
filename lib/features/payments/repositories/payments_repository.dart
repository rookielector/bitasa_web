// lib/features/payments/repositories/payments_repository.dart

import 'package:bitasa_web/features/payments/models/payment_data.dart';
import 'package:bitasa_web/services/database_service.dart';
import 'package:sembast/sembast.dart';

class PaymentsRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<StoreRef<int, Map<String, dynamic>>> get _store async {
    final db = await _dbService.database;
    return _dbService.paymentsStore;
  }

  Future<void> savePayment(PaymentData payment) async {
    final store = await _store;
    final db = await _dbService.database;
    await store.add(db, payment.toMap());
  }

  Future<List<PaymentData>> getSavedPayments() async {
    final store = await _store;
    final db = await _dbService.database;

    final finder = Finder(sortOrders: [SortOrder('calculationDate', false)]);
    final records = await store.find(db, finder: finder);

    return records.map((snapshot) {
      // --- CAMBIO: Pasamos el ID al factory ---
      return PaymentData.fromMap(snapshot.value, snapshot.key);
    }).toList();
  }
  
  Future<void> deletePayment(int id) async {
    final store = await _store;
    final db = await _dbService.database;
    await store.record(id).delete(db);
  }
}