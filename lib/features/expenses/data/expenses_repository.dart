import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class ExpensesRepository {
  final AppDatabase _db;

  ExpensesRepository(this._db);

  Stream<List<Expense>> watchExpenses({DateTime? startDate, DateTime? endDate, String? category}) {
    final query = _db.select(_db.expenses)..where((tbl) => tbl.isDeleted.equals(false));

    if (startDate != null) {
      query.where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.date.isSmallerOrEqualValue(endDate));
    }
    if (category != null && category != 'All') {
      query.where((tbl) => tbl.category.equals(category));
    }

    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);

    return query.watch();
  }

  Future<int> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
  }) {
    return _db.into(_db.expenses).insert(
      ExpensesCompanion.insert(
        title: title,
        amount: amount,
        category: Value(category),
        date: date,
        notes: Value(notes),
        isDeleted: const Value(false),
      ),
    );
  }

  Future<void> softDeleteExpense(int id) async {
    await (_db.update(_db.expenses)..where((tbl) => tbl.id.equals(id))).write(
      const ExpensesCompanion(isDeleted: Value(true)),
    );
  }

  Future<double> getTodayExpensesTotal() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final expenses = await (_db.select(_db.expenses)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    return expenses.fold<double>(0.0, (acc, e) => acc + e.amount);
  }
}

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpensesRepository(db);
});

final expensesFilterProvider = StateProvider<({String category, String dateFilter})>((ref) {
  return (category: 'All', dateFilter: 'This Month');
});

final expensesStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final repo = ref.watch(expensesRepositoryProvider);
  final filter = ref.watch(expensesFilterProvider);

  final now = DateTime.now();
  DateTime? start;
  DateTime? end;

  if (filter.dateFilter == 'Today') {
    start = DateTime(now.year, now.month, now.day);
    end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  } else if (filter.dateFilter == 'This Month') {
    start = DateTime(now.year, now.month, 1);
    end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  return repo.watchExpenses(
    startDate: start,
    endDate: end,
    category: filter.category,
  );
});
