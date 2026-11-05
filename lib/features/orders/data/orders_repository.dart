import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../pos/domain/cart_state.dart';

class OrdersRepository {
  final AppDatabase _db;

  OrdersRepository(this._db);

  Stream<List<Bill>> watchBills({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMode,
    bool? onlyCreditUnpaid,
  }) {
    final query = _db.select(_db.bills)
      ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false));

    if (startDate != null) {
      query.where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.date.isSmallerOrEqualValue(endDate));
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      query.where((tbl) => tbl.billNumber.like(s) | tbl.customerName.like(s) | tbl.customerPhone.like(s));
    }
    if (paymentMode != null && paymentMode != 'All') {
      query.where((tbl) => tbl.paymentMode.equals(paymentMode));
    }
    if (onlyCreditUnpaid == true) {
      query.where((tbl) => tbl.paymentMode.equals('Credit') & tbl.isCreditPaid.equals(false));
    }

    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);

    return query.watch();
  }

  Future<Bill?> getBillById(int billId) {
    return (_db.select(_db.bills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
  }

  Future<Bill?> getBillByNumber(String billNumber) {
    final clean = billNumber.trim();
    return (_db.select(_db.bills)
          ..where((tbl) => tbl.billNumber.equals(clean) & tbl.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<List<BillItem>> getBillItems(int billId) {
    return (_db.select(_db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
  }

  Future<List<BillEdit>> getBillEdits(int billId) {
    return (_db.select(_db.billEdits)
          ..where((tbl) => tbl.billId.equals(billId))
          ..orderBy([(t) => OrderingTerm(expression: t.editedAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<Bill> updatePastBill({
    required int billId,
    required CartState newCart,
    String? editReason,
  }) async {
    return _db.transaction(() async {
      final oldBill = await (_db.select(_db.bills)..where((tbl) => tbl.id.equals(billId))).getSingle();
      final oldItems = await (_db.select(_db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();

      // 1. Record snapshot in BillEdits
      final oldSnapshot = {
        'billNumber': oldBill.billNumber,
        'grandTotal': oldBill.grandTotal,
        'items': oldItems.map((i) => {
          'name': i.productName,
          'qty': i.quantity,
          'price': i.unitPrice,
          'total': i.totalAmount,
        }).toList(),
      };

      await _db.into(_db.billEdits).insert(BillEditsCompanion.insert(
        billId: billId,
        editedAt: Value(DateTime.now()),
        previousTotal: oldBill.grandTotal,
        newTotal: newCart.grandTotal,
        reasonNotes: Value(editReason),
        changesJson: jsonEncode(oldSnapshot),
      ));

      // 2. Adjust customer balance if Udhaar was affected
      if (oldBill.paymentMode == 'Credit' && oldBill.customerId != null && !oldBill.isCreditPaid) {
        // Revert old Udhaar
        final cust = await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(oldBill.customerId!))).getSingleOrNull();
        if (cust != null) {
          await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(cust.id))).write(
            CustomersCompanion(balance: Value(cust.balance - oldBill.grandTotal)),
          );
        }
      }

      // 3. Update Bills record
      await (_db.update(_db.bills)..where((tbl) => tbl.id.equals(billId))).write(
        BillsCompanion(
          customerId: Value(newCart.selectedCustomer?.id),
          customerName: Value(newCart.selectedCustomer?.name),
          customerPhone: Value(newCart.selectedCustomer?.phone),
          paymentMode: Value(newCart.paymentMode),
          cashAmount: Value(newCart.paymentMode == 'Cash'
              ? newCart.cashTendered - newCart.changeDue
              : (newCart.paymentMode == 'Split' ? newCart.cashTendered : 0.0)),
          digitalAmount: Value(newCart.paymentMode == 'Split'
              ? newCart.digitalAmount
              : (newCart.paymentMode != 'Cash' && newCart.paymentMode != 'Credit'
                  ? newCart.grandTotal
                  : 0.0)),
          changeTendered: Value(newCart.changeDue),
          subtotal: Value(newCart.rawSubtotal),
          itemDiscountTotal: Value(newCart.itemsDiscountTotal),
          billDiscountPercent: Value(newCart.isBillDiscountPercent ? newCart.billDiscountPercent : 0.0),
          billDiscountAmount: Value(newCart.billDiscountTotal),
          gstType: Value(newCart.gstType),
          cgstTotal: Value(newCart.cgstTotal),
          sgstTotal: Value(newCart.sgstTotal),
          igstTotal: Value(newCart.igstTotal),
          roundOff: Value(newCart.roundOff),
          grandTotal: Value(newCart.grandTotal),
          notes: Value(newCart.notes),
          isEdited: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 4. Delete old items and insert updated items
      await (_db.delete(_db.billItems)..where((tbl) => tbl.billId.equals(billId))).go();

      final gstRes = newCart.gstResult;
      for (int i = 0; i < newCart.items.length; i++) {
        final item = newCart.items[i];
        final lineRes = i < gstRes.lineResults.length ? gstRes.lineResults[i] : null;
        await _db.into(_db.billItems).insert(BillItemsCompanion.insert(
          billId: billId,
          productId: Value(item.productId),
          productName: item.productName,
          unit: Value(item.unit),
          quantity: Value(item.quantity),
          unitPrice: item.unitPrice,
          discountAmount: Value(item.discountAmount),
          gstRate: Value(lineRes?.gstRate ?? item.gstRate),
          gstAmount: Value(lineRes?.gstAmount ?? item.gstAmount(newCart.gstType)),
          taxableValue: Value(lineRes?.taxableValue ?? 0.0),
          cgstAmount: Value(lineRes?.cgstAmount ?? 0.0),
          sgstAmount: Value(lineRes?.sgstAmount ?? 0.0),
          igstAmount: Value(lineRes?.igstAmount ?? 0.0),
          totalAmount: lineRes?.lineTotal ?? item.totalAmount(newCart.gstType),
        ));
      }

      // 5. Apply new Udhaar if new bill is Credit
      if (newCart.paymentMode == 'Credit' && newCart.selectedCustomer != null) {
        final cust = await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(newCart.selectedCustomer!.id))).getSingleOrNull();
        if (cust != null) {
          await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(cust.id))).write(
            CustomersCompanion(balance: Value(cust.balance + newCart.grandTotal)),
          );
        }
      }

      return (_db.select(_db.bills)..where((tbl) => tbl.id.equals(billId))).getSingle();
    });
  }

  Future<void> markCreditAsPaid(int billId, {required String paymentMode}) async {
    await _db.transaction(() async {
      final bill = await (_db.select(_db.bills)..where((tbl) => tbl.id.equals(billId))).getSingle();
      if (bill.isCreditPaid) return;

      // Mark bill as credit paid
      await (_db.update(_db.bills)..where((tbl) => tbl.id.equals(billId))).write(
        BillsCompanion(
          isCreditPaid: const Value(true),
          notes: Value('${bill.notes ?? ''} [Paid via $paymentMode on ${DateTime.now().toString().split('.').first}]'.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Deduct customer Udhaar balance
      if (bill.customerId != null) {
        final cust = await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(bill.customerId!))).getSingleOrNull();
        if (cust != null) {
          await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(cust.id))).write(
            CustomersCompanion(
              balance: Value(cust.balance - bill.grandTotal),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    });
  }

  Future<void> softDeleteBill(int billId) async {
    await _db.transaction(() async {
      final bill = await (_db.select(_db.bills)..where((tbl) => tbl.id.equals(billId))).getSingle();

      // If credit bill wasn't paid yet, adjust customer balance
      if (bill.paymentMode == 'Credit' && !bill.isCreditPaid && bill.customerId != null) {
        final cust = await (_db.select(_db.customers)..where((tbl) => tbl.id.equals(bill.customerId!))).getSingleOrNull();
        if (cust != null) {
          await (_db.update(_db.customers)..where((tbl) => tbl.id.equals(cust.id))).write(
            CustomersCompanion(
              balance: Value(cust.balance - bill.grandTotal),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      // Soft delete bill
      await (_db.update(_db.bills)..where((tbl) => tbl.id.equals(billId))).write(
        BillsCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return OrdersRepository(db);
});

final ordersFilterProvider = StateProvider<({
  DateTime? startDate,
  DateTime? endDate,
  String? search,
  String? paymentMode,
  bool? onlyCreditUnpaid,
})>((ref) {
  return (
    startDate: null,
    endDate: null,
    search: null,
    paymentMode: null,
    onlyCreditUnpaid: false,
  );
});

final billsStreamProvider = StreamProvider.autoDispose<List<Bill>>((ref) {
  final repo = ref.watch(ordersRepositoryProvider);
  final filter = ref.watch(ordersFilterProvider);
  return repo.watchBills(
    startDate: filter.startDate,
    endDate: filter.endDate,
    search: filter.search,
    paymentMode: filter.paymentMode,
    onlyCreditUnpaid: filter.onlyCreditUnpaid,
  );
});
