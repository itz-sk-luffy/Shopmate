import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/cart_state.dart';

class HeldBillEntry {
  final Bill bill;
  final int itemCount;

  const HeldBillEntry({
    required this.bill,
    required this.itemCount,
  });
}

class BillingRepository {
  final AppDatabase _db;
  final Ref? _ref;

  BillingRepository(this._db, [this._ref]);

  /// Computes the next sequential numeric suffix for a given prefix.
  /// next = max(numeric suffix of every bill_number with the current prefix across ALL rows
  /// including deleted, held, and edited bills) + 1, and never lower than startNum from Settings.
  Future<int> computeNextBillNumericSuffix(String prefix, int startNum) async {
    final rows = await _db.customSelect(
      'SELECT bill_number FROM bills WHERE bill_number LIKE ?',
      variables: [Variable.withString('$prefix%')],
      readsFrom: {_db.bills},
    ).get();

    int maxSuffix = startNum - 1;
    for (final row in rows) {
      final bn = row.read<String>('bill_number');
      if (bn.startsWith(prefix)) {
        final suffixStr = bn.substring(prefix.length);
        final suffixVal = int.tryParse(suffixStr);
        if (suffixVal != null && suffixVal > maxSuffix) {
          maxSuffix = suffixVal;
        }
      }
    }
    return maxSuffix + 1;
  }

  Future<Bill> createBill(CartState cart) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        return await _db.transaction(() async {
          // 1. Fetch & compute next sequential bill number inside this transaction
          final prefix = await _db.getSetting('bill_prefix', defaultValue: 'INV-');
          final nextNumStr = await _db.getSetting('bill_next_number', defaultValue: '1001');
          final startNum = int.tryParse(nextNumStr) ?? 1001;

          final nextNum = await computeNextBillNumericSuffix(prefix, startNum);
          final billNumber = '$prefix$nextNum';

          // Update next bill number setting in DB
          await _db.setSetting('bill_next_number', '${nextNum + 1}');
          _ref?.read(settingsProvider.notifier).loadSettings();

          // 2. Insert into Bills
          final billCompanion = BillsCompanion.insert(
            billNumber: billNumber,
            date: DateTime.now(),
            customerId: Value(cart.selectedCustomer?.id),
            customerName: Value(cart.selectedCustomer?.name),
            customerPhone: Value(cart.selectedCustomer?.phone),
            paymentMode: Value(cart.paymentMode),
            cashAmount: Value(cart.paymentMode == 'Cash'
                ? cart.cashTendered - cart.changeDue
                : (cart.paymentMode == 'Split' ? cart.cashTendered : 0.0)),
            digitalAmount: Value(cart.paymentMode == 'Split'
                ? cart.digitalAmount
                : (cart.paymentMode != 'Cash' && cart.paymentMode != 'Credit'
                    ? cart.grandTotal
                    : 0.0)),
            changeTendered: Value(cart.changeDue),
            subtotal: Value(cart.rawSubtotal),
            itemDiscountTotal: Value(cart.itemsDiscountTotal),
            billDiscountPercent: Value(cart.isBillDiscountPercent ? cart.billDiscountPercent : 0.0),
            billDiscountAmount: Value(cart.billDiscountTotal),
            gstType: Value(cart.gstType),
            cgstTotal: Value(cart.cgstTotal),
            sgstTotal: Value(cart.sgstTotal),
            igstTotal: Value(cart.igstTotal),
            roundOff: Value(cart.roundOff),
            grandTotal: Value(cart.grandTotal),
            notes: Value(cart.notes),
            isHeld: const Value(false),
            isCreditPaid: const Value(false),
            isEdited: const Value(false),
            isDeleted: const Value(false),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          );

          final billId = await _db.into(_db.bills).insert(billCompanion);

          // 3. Insert into BillItems
          final gstRes = cart.gstResult;
          for (int i = 0; i < cart.items.length; i++) {
            final item = cart.items[i];
            final lineRes = i < gstRes.lineResults.length ? gstRes.lineResults[i] : null;
            final itemCompanion = BillItemsCompanion.insert(
              billId: billId,
              productId: Value(item.productId),
              productName: item.productName,
              unit: Value(item.unit),
              quantity: Value(item.quantity),
              unitPrice: item.unitPrice,
              discountAmount: Value(item.discountAmount),
              gstRate: Value(lineRes?.gstRate ?? item.gstRate),
              gstAmount: Value(lineRes?.gstAmount ?? item.gstAmount(cart.gstType)),
              taxableValue: Value(lineRes?.taxableValue ?? 0.0),
              cgstAmount: Value(lineRes?.cgstAmount ?? 0.0),
              sgstAmount: Value(lineRes?.sgstAmount ?? 0.0),
              igstAmount: Value(lineRes?.igstAmount ?? 0.0),
              totalAmount: lineRes?.lineTotal ?? item.totalAmount(cart.gstType),
            );
            await _db.into(_db.billItems).insert(itemCompanion);
          }

          // 4. Update Customer Udhaar balance if Credit sale
          if (cart.paymentMode == 'Credit' && cart.selectedCustomer != null) {
            final custId = cart.selectedCustomer!.id;
            final currentCustomer = await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(custId))).getSingleOrNull();
            if (currentCustomer != null) {
              final newBal = currentCustomer.balance + cart.grandTotal;
              await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(custId))).write(
                CustomersCompanion(
                  balance: Value(newBal),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            }
          }

          // 5. If this bill was resumed from a held bill, delete the old held bill
          if (cart.heldBillId != null) {
            await (_db.delete(_db.bills)..where((tbl) => tbl.id.equals(cart.heldBillId!))).go();
          }

          return (_db.select(_db.bills)..where((tbl) => tbl.id.equals(billId))).getSingle();
        });
      } catch (e) {
        final err = e.toString();
        final isUniqueConflict = err.contains('2067') ||
            err.contains('UNIQUE constraint failed: bills.bill_number');
        if (isUniqueConflict && attempts < 3) {
          continue; // Retry with recomputed number
        }
        rethrow;
      }
    }
  }

  Future<Bill> holdBill(CartState cart) async {
    return _db.transaction(() async {
      final holdId = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final billNumber = 'HOLD-$holdId';

      final billCompanion = BillsCompanion.insert(
        billNumber: billNumber,
        date: DateTime.now(),
        customerId: Value(cart.selectedCustomer?.id),
        customerName: Value(cart.selectedCustomer?.name),
        customerPhone: Value(cart.selectedCustomer?.phone),
        paymentMode: Value(cart.paymentMode),
        subtotal: Value(cart.rawSubtotal),
        itemDiscountTotal: Value(cart.itemsDiscountTotal),
        billDiscountPercent: Value(cart.isBillDiscountPercent ? cart.billDiscountPercent : 0.0),
        billDiscountAmount: Value(cart.billDiscountTotal),
        gstType: Value(cart.gstType),
        cgstTotal: Value(cart.cgstTotal),
        sgstTotal: Value(cart.sgstTotal),
        igstTotal: Value(cart.igstTotal),
        roundOff: Value(cart.roundOff),
        grandTotal: Value(cart.grandTotal),
        notes: Value(cart.notes),
        isHeld: const Value(true),
        isCreditPaid: const Value(false),
        isEdited: const Value(false),
        isDeleted: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      final billId = await _db.into(_db.bills).insert(billCompanion);

      final gstRes = cart.gstResult;
      for (int i = 0; i < cart.items.length; i++) {
        final item = cart.items[i];
        final lineRes = i < gstRes.lineResults.length ? gstRes.lineResults[i] : null;
        final itemCompanion = BillItemsCompanion.insert(
          billId: billId,
          productId: Value(item.productId),
          productName: item.productName,
          unit: Value(item.unit),
          quantity: Value(item.quantity),
          unitPrice: item.unitPrice,
          discountAmount: Value(item.discountAmount),
          gstRate: Value(lineRes?.gstRate ?? item.gstRate),
          gstAmount: Value(lineRes?.gstAmount ?? item.gstAmount(cart.gstType)),
          taxableValue: Value(lineRes?.taxableValue ?? 0.0),
          cgstAmount: Value(lineRes?.cgstAmount ?? 0.0),
          sgstAmount: Value(lineRes?.sgstAmount ?? 0.0),
          igstAmount: Value(lineRes?.igstAmount ?? 0.0),
          totalAmount: lineRes?.lineTotal ?? item.totalAmount(cart.gstType),
        );
        await _db.into(_db.billItems).insert(itemCompanion);
      }

      return (_db.select(_db.bills)..where((tbl) => tbl.id.equals(billId))).getSingle();
    });
  }

  Stream<List<HeldBillEntry>> watchHeldBills() {
    final countCol = _db.billItems.id.count();
    final query = _db.select(_db.bills).join([
      leftOuterJoin(_db.billItems, _db.billItems.billId.equalsExp(_db.bills.id)),
    ])
      ..where(_db.bills.isHeld.equals(true) & _db.bills.isDeleted.equals(false))
      ..groupBy([_db.bills.id])
      ..orderBy([OrderingTerm(expression: _db.bills.date, mode: OrderingMode.desc)])
      ..addColumns([countCol]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return HeldBillEntry(
          bill: row.readTable(_db.bills),
          itemCount: row.read(countCol) ?? 0,
        );
      }).toList();
    });
  }

  Future<List<BillItem>> getBillItems(int billId) {
    return (_db.select(_db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
  }

  Future<void> deleteHeldBill(int billId) async {
    await (_db.delete(_db.bills)..where((tbl) => tbl.id.equals(billId))).go();
  }
}

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BillingRepository(db, ref);
});

final heldBillsStreamProvider = StreamProvider.autoDispose<List<HeldBillEntry>>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.watchHeldBills();
});
