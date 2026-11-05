import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class CustomersRepository {
  final AppDatabase _db;

  CustomersRepository(this._db);

  Stream<List<Customer>> watchCustomers({String? search}) {
    final query = _db.select(_db.customers);
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      query.where((tbl) => tbl.name.like(s) | tbl.phone.like(s));
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
    ]);
    return query.watch();
  }

  Future<List<Customer>> searchCustomers(String query) {
    final q = _db.select(_db.customers);
    if (query.trim().isNotEmpty) {
      final s = '%${query.trim()}%';
      q.where((tbl) => tbl.name.like(s) | tbl.phone.like(s));
    }
    q.orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]);
    return q.get();
  }

  Future<Customer?> getCustomerById(int id) {
    return (_db.select(_db.customers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<Customer?> getCustomerByPhone(String phone) {
    if (phone.trim().isEmpty) return Future.value(null);
    return (_db.select(_db.customers)..where((tbl) => tbl.phone.equals(phone.trim()))).getSingleOrNull();
  }

  Future<int> addCustomer(CustomersCompanion customer) {
    return _db.into(_db.customers).insert(customer);
  }

  Future<bool> updateCustomer(Customer customer) {
    return _db.update(_db.customers).replace(customer);
  }

  Future<void> updateCustomerBalance(int customerId, double deltaAmount) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return;
    final newBalance = customer.balance + deltaAmount;
    await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(customerId))).write(
      CustomersCompanion(
        balance: Value(newBalance),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteCustomer(int id) async {
    return await _db.transaction(() async {
      // 1. Unlink bills referencing this customer so Foreign Key constraints are satisfied
      // while preserving historical sales reports and customer name/phone strings
      await (_db.update(_db.bills)..where((tbl) => tbl.customerId.equals(id))).write(
        const BillsCompanion(customerId: Value(null)),
      );
      // 2. Delete the customer record
      return await (_db.delete(_db.customers)..where((tbl) => tbl.id.equals(id))).go();
    });
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomersRepository(db);
});

final customersStreamProvider = StreamProvider.autoDispose<List<Customer>>((ref) {
  final repo = ref.watch(customersRepositoryProvider);
  return repo.watchCustomers();
});
