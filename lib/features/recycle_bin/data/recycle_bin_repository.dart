import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

enum RecycleBinItemType {
  product,
  bill,
  expense,
}

class RecycleBinItem {
  final int id;
  final RecycleBinItemType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime deletedAt;
  final String? imagePath;

  RecycleBinItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.deletedAt,
    this.imagePath,
  });

  int get daysRemaining {
    final expiryDate = deletedAt.add(const Duration(days: 30));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }
}

class RecycleBinRepository {
  final AppDatabase _db;

  RecycleBinRepository(this._db);

  /// Automatically purges any items soft-deleted more than 30 days ago
  Future<int> autoPurgeExpiredItems() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    int purgedCount = 0;

    // 1. Purge expired products
    final expiredProducts = await (_db.select(_db.products)
          ..where((tbl) => tbl.isDeleted.equals(true) & tbl.deletedAt.isSmallerOrEqualValue(cutoff)))
        .get();

    for (final prod in expiredProducts) {
      if (prod.imagePath != null) {
        try {
          final file = File(prod.imagePath!);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
      await (_db.delete(_db.products)..where((tbl) => tbl.id.equals(prod.id))).go();
      purgedCount++;
    }

    // 2. Purge expired bills
    final expiredBills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(true) & tbl.deletedAt.isSmallerOrEqualValue(cutoff)))
        .get();

    for (final bill in expiredBills) {
      await (_db.delete(_db.bills)..where((tbl) => tbl.id.equals(bill.id))).go();
      purgedCount++;
    }

    // 3. Purge expired expenses
    final expiredExpenses = await (_db.select(_db.expenses)
          ..where((tbl) => tbl.isDeleted.equals(true) & tbl.date.isSmallerOrEqualValue(cutoff)))
        .get();

    for (final exp in expiredExpenses) {
      await (_db.delete(_db.expenses)..where((tbl) => tbl.id.equals(exp.id))).go();
      purgedCount++;
    }

    return purgedCount;
  }

  /// Fetches all soft-deleted items across products, bills, and expenses
  Future<List<RecycleBinItem>> getAllDeletedItems() async {
    // Run auto-purge first
    await autoPurgeExpiredItems();

    final List<RecycleBinItem> items = [];

    // Deleted Products
    final products = await (_db.select(_db.products)
          ..where((tbl) => tbl.isDeleted.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]))
        .get();

    for (final p in products) {
      items.add(RecycleBinItem(
        id: p.id,
        type: RecycleBinItemType.product,
        title: p.name,
        subtitle: '${p.unit} • Barcode: ${p.barcode ?? "None"}',
        amount: p.price,
        deletedAt: p.deletedAt ?? p.updatedAt,
        imagePath: p.imagePath,
      ));
    }

    // Deleted Bills
    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]))
        .get();

    for (final b in bills) {
      items.add(RecycleBinItem(
        id: b.id,
        type: RecycleBinItemType.bill,
        title: 'Bill #${b.billNumber}',
        subtitle: '${b.customerName ?? "Walk-in"} • ${b.paymentMode}',
        amount: b.grandTotal,
        deletedAt: b.deletedAt ?? b.updatedAt,
      ));
    }

    // Deleted Expenses
    final expenses = await (_db.select(_db.expenses)
          ..where((tbl) => tbl.isDeleted.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();

    for (final e in expenses) {
      items.add(RecycleBinItem(
        id: e.id,
        type: RecycleBinItemType.expense,
        title: e.title,
        subtitle: 'Category: ${e.category}',
        amount: e.amount,
        deletedAt: e.date,
      ));
    }

    // Sort combined by deletedAt descending
    items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return items;
  }

  /// Restores a soft-deleted item
  Future<void> restoreItem(RecycleBinItem item) async {
    switch (item.type) {
      case RecycleBinItemType.product:
        await (_db.update(_db.products)..where((tbl) => tbl.id.equals(item.id))).write(
          const ProductsCompanion(
            isDeleted: Value(false),
            deletedAt: Value(null),
          ),
        );
        break;

      case RecycleBinItemType.bill:
        await _db.transaction(() async {
          final bill = await (_db.select(_db.bills)..where((tbl) => tbl.id.equals(item.id))).getSingle();
          // If credit bill was unpaid and has customer, add back to customer balance
          if (bill.paymentMode == 'Credit' && !bill.isCreditPaid && bill.customerId != null) {
            final cust = await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(bill.customerId!))).getSingleOrNull();
            if (cust != null) {
              await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(cust.id))).write(
                CustomersCompanion(
                  balance: Value(cust.balance + bill.grandTotal),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            }
          }
          await (_db.update(_db.bills)..where((tbl) => tbl.id.equals(item.id))).write(
            const BillsCompanion(
              isDeleted: Value(false),
              deletedAt: Value(null),
            ),
          );
        });
        break;

      case RecycleBinItemType.expense:
        await (_db.update(_db.expenses)..where((tbl) => tbl.id.equals(item.id))).write(
          const ExpensesCompanion(isDeleted: Value(false)),
        );
        break;
    }
  }

  /// Permanently hard-deletes an item
  Future<void> permanentDeleteItem(RecycleBinItem item) async {
    switch (item.type) {
      case RecycleBinItemType.product:
        if (item.imagePath != null) {
          try {
            final file = File(item.imagePath!);
            if (file.existsSync()) file.deleteSync();
          } catch (_) {}
        }
        await (_db.delete(_db.productBarcodes)..where((tbl) => tbl.productId.equals(item.id))).go();
        await (_db.delete(_db.productVariants)..where((tbl) => tbl.productId.equals(item.id))).go();
        await (_db.delete(_db.products)..where((tbl) => tbl.id.equals(item.id))).go();
        break;

      case RecycleBinItemType.bill:
        await (_db.delete(_db.bills)..where((tbl) => tbl.id.equals(item.id))).go();
        break;

      case RecycleBinItemType.expense:
        await (_db.delete(_db.expenses)..where((tbl) => tbl.id.equals(item.id))).go();
        break;
    }
  }

  /// Empties entire recycle bin
  Future<void> emptyRecycleBin() async {
    // 1. Delete all soft-deleted products
    final prods = await (_db.select(_db.products)..where((tbl) => tbl.isDeleted.equals(true))).get();
    for (final p in prods) {
      if (p.imagePath != null) {
        try {
          final file = File(p.imagePath!);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
      await (_db.delete(_db.productBarcodes)..where((tbl) => tbl.productId.equals(p.id))).go();
      await (_db.delete(_db.productVariants)..where((tbl) => tbl.productId.equals(p.id))).go();
    }
    await (_db.delete(_db.products)..where((tbl) => tbl.isDeleted.equals(true))).go();

    // 2. Delete all soft-deleted bills
    await (_db.delete(_db.bills)..where((tbl) => tbl.isDeleted.equals(true))).go();

    // 3. Delete all soft-deleted expenses
    await (_db.delete(_db.expenses)..where((tbl) => tbl.isDeleted.equals(true))).go();
  }
}

final recycleBinRepositoryProvider = Provider<RecycleBinRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RecycleBinRepository(db);
});

final recycleBinItemsProvider = FutureProvider.autoDispose<List<RecycleBinItem>>((ref) async {
  final repo = ref.watch(recycleBinRepositoryProvider);
  return repo.getAllDeletedItems();
});
