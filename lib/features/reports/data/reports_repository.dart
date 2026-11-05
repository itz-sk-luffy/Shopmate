import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/formatters.dart';

class DayWiseSalesRow {
  final DateTime date;
  final int billsCount;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;

  const DayWiseSalesRow({
    required this.date,
    required this.billsCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
  });
}

class GstReportRow {
  final double gstRate;
  final double taxableAmount;
  final double cgst;
  final double sgst;
  final double totalTax;

  const GstReportRow({
    required this.gstRate,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.totalTax,
  });
}

class ItemWiseSalesRow {
  final String productName;
  final String unit;
  final double quantitySold;
  final double totalAmount;
  final double averagePrice;

  const ItemWiseSalesRow({
    required this.productName,
    required this.unit,
    required this.quantitySold,
    required this.totalAmount,
    required this.averagePrice,
  });
}

class ReportsRepository {
  final AppDatabase _db;

  ReportsRepository(this._db);

  Future<List<DayWiseSalesRow>> getDayWiseSummary(DateTime start, DateTime end) async {
    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();

    final Map<String, ({DateTime date, int count, double sub, double disc, double tax, double total})> map = {};

    for (final b in bills) {
      final key = '${b.date.year}-${b.date.month.toString().padLeft(2, '0')}-${b.date.day.toString().padLeft(2, '0')}';
      final cur = map[key] ?? (
        date: DateTime(b.date.year, b.date.month, b.date.day),
        count: 0,
        sub: 0.0,
        disc: 0.0,
        tax: 0.0,
        total: 0.0,
      );

      map[key] = (
        date: cur.date,
        count: cur.count + 1,
        sub: cur.sub + b.subtotal,
        disc: cur.disc + b.itemDiscountTotal + b.billDiscountAmount,
        tax: cur.tax + b.cgstTotal + b.sgstTotal + b.igstTotal,
        total: cur.total + b.grandTotal,
      );
    }

    return map.values.map((v) {
      return DayWiseSalesRow(
        date: v.date,
        billsCount: v.count,
        subtotal: v.sub,
        discount: v.disc,
        tax: v.tax,
        grandTotal: v.total,
      );
    }).toList();
  }

  Future<List<GstReportRow>> getGstBreakdown(DateTime start, DateTime end) async {
    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    if (bills.isEmpty) return [];

    final billIds = bills.map((b) => b.id).toList();
    final items = await (_db.select(_db.billItems)..where((tbl) => tbl.billId.isIn(billIds))).get();

    final Map<double, ({double base, double cgst, double sgst, double igst, double totalTax})> map = {
      0.0: (base: 0.0, cgst: 0.0, sgst: 0.0, igst: 0.0, totalTax: 0.0),
      5.0: (base: 0.0, cgst: 0.0, sgst: 0.0, igst: 0.0, totalTax: 0.0),
      12.0: (base: 0.0, cgst: 0.0, sgst: 0.0, igst: 0.0, totalTax: 0.0),
      18.0: (base: 0.0, cgst: 0.0, sgst: 0.0, igst: 0.0, totalTax: 0.0),
      28.0: (base: 0.0, cgst: 0.0, sgst: 0.0, igst: 0.0, totalTax: 0.0),
    };

    for (final it in items) {
      final rate = it.gstRate;
      final cur = map[rate] ?? (base: 0.0, cgst: 0.0, sgst: 0.0, igst: 0.0, totalTax: 0.0);
      final taxBase = it.taxableValue > 0 ? it.taxableValue : (it.totalAmount - it.gstAmount);
      final cgstAmt = it.cgstAmount > 0 ? it.cgstAmount : (it.gstAmount / 2.0);
      final sgstAmt = it.sgstAmount > 0 ? it.sgstAmount : (it.gstAmount - cgstAmt);
      map[rate] = (
        base: cur.base + taxBase,
        cgst: cur.cgst + cgstAmt,
        sgst: cur.sgst + sgstAmt,
        igst: cur.igst + it.igstAmount,
        totalTax: cur.totalTax + it.gstAmount,
      );
    }

    final allRows = map.entries.map((e) {
      return GstReportRow(
        gstRate: e.key,
        taxableAmount: e.value.base,
        cgst: e.value.cgst,
        sgst: e.value.sgst,
        totalTax: e.value.totalTax,
      );
    }).toList();

    final nonZero = allRows.where((r) => r.taxableAmount > 0 || r.totalTax > 0).toList();
    return nonZero.isNotEmpty ? nonZero : allRows;
  }

  Future<List<ItemWiseSalesRow>> getItemWiseSummary(DateTime start, DateTime end) async {
    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    if (bills.isEmpty) return [];

    final billIds = bills.map((b) => b.id).toList();
    final items = await (_db.select(_db.billItems)..where((tbl) => tbl.billId.isIn(billIds))).get();

    final Map<String, ({String unit, double qty, double amount})> map = {};
    for (final it in items) {
      final cur = map[it.productName] ?? (unit: it.unit, qty: 0.0, amount: 0.0);
      map[it.productName] = (
        unit: it.unit,
        qty: cur.qty + it.quantity,
        amount: cur.amount + it.totalAmount,
      );
    }

    final list = map.entries.map((e) {
      final avg = e.value.qty > 0 ? (e.value.amount / e.value.qty) : 0.0;
      return ItemWiseSalesRow(
        productName: e.key,
        unit: e.value.unit,
        quantitySold: e.value.qty,
        totalAmount: e.value.amount,
        averagePrice: avg,
      );
    }).toList();

    list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return list;
  }

  Future<void> shareDayWiseCsv(List<DayWiseSalesRow> rows) async {
    final buffer = StringBuffer();
    buffer.writeln('Date,Bills Count,Subtotal,Discount,Tax,Grand Total');
    for (final r in rows) {
      buffer.writeln('${Formatters.date(r.date)},${r.billsCount},${r.subtotal.toStringAsFixed(2)},${r.discount.toStringAsFixed(2)},${r.tax.toStringAsFixed(2)},${r.grandTotal.toStringAsFixed(2)}');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Daywise_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Day-wise Sales Report');
  }

  Future<void> shareItemWiseCsv(List<ItemWiseSalesRow> rows) async {
    final buffer = StringBuffer();
    buffer.writeln('Product Name,Unit,Quantity Sold,Average Price,Total Amount');
    for (final r in rows) {
      buffer.writeln('"${r.productName.replaceAll('"', '""')}",${r.unit},${r.quantitySold},${r.averagePrice.toStringAsFixed(2)},${r.totalAmount.toStringAsFixed(2)}');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Item_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Item Sales Report');
  }

  Future<void> shareGstCsv(List<GstReportRow> rows) async {
    final buffer = StringBuffer();
    buffer.writeln('GST Rate,Taxable Amount,CGST,SGST,Total Tax');
    for (final r in rows) {
      buffer.writeln('${r.gstRate.toInt()}%,${r.taxableAmount.toStringAsFixed(2)},${r.cgst.toStringAsFixed(2)},${r.sgst.toStringAsFixed(2)},${r.totalTax.toStringAsFixed(2)}');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/GST_Tax_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'GST Tax Summary Report');
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ReportsRepository(db);
});
