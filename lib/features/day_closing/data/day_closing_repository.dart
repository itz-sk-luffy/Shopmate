import 'package:drift/drift.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../printer/services/thermal_printer_service.dart';

class DaySummaryData {
  final double openingCash;
  final double cashSales;
  final double cashExpenses;
  final double expectedCash;

  const DaySummaryData({
    required this.openingCash,
    required this.cashSales,
    required this.cashExpenses,
    required this.expectedCash,
  });
}

class DayClosingRepository {
  final AppDatabase _db;
  final Ref _ref;

  DayClosingRepository(this._db, this._ref);

  Future<DaySummaryData> getTodaySummary() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 1. Opening Cash from setting
    final openingStr = await _db.getSetting('register_opening_cash', defaultValue: '0');
    final openingCash = double.tryParse(openingStr) ?? 0.0;

    // 2. Today's Cash Sales
    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    double cashSales = 0.0;
    for (final b in bills) {
      if (b.paymentMode == 'Cash' || b.paymentMode == 'Split') {
        cashSales += b.cashAmount;
      }
    }

    // 3. Today's Cash Expenses
    final expenses = await (_db.select(_db.expenses)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    final cashExpenses = expenses.fold(0.0, (acc, e) => acc + e.amount);

    final expected = openingCash + cashSales - cashExpenses;

    return DaySummaryData(
      openingCash: openingCash,
      cashSales: cashSales,
      cashExpenses: cashExpenses,
      expectedCash: expected,
    );
  }

  Future<DayClosing> saveDayClosing({
    required double openingCash,
    required double cashSales,
    required double cashExpenses,
    required double expectedCash,
    required double countedCash,
    required double difference,
    String? notes,
  }) async {
    final companion = DayClosingsCompanion.insert(
      date: DateTime.now(),
      openingCash: Value(openingCash),
      cashSales: Value(cashSales),
      cashExpenses: Value(cashExpenses),
      expectedCash: Value(expectedCash),
      countedCash: Value(countedCash),
      difference: Value(difference),
      notes: Value(notes),
      closedAt: Value(DateTime.now()),
    );

    final id = await _db.into(_db.dayClosings).insert(companion);
    return (_db.select(_db.dayClosings)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Stream<List<DayClosing>> watchPastClosings() {
    return (_db.select(_db.dayClosings)
          ..orderBy([(t) => OrderingTerm(expression: t.closedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<bool> printDayEndReceipt(DayClosing closing) async {
    final printer = _ref.read(thermalPrinterServiceProvider);
    final isConn = await printer.isConnected();
    if (!isConn) return false;

    final settings = _ref.read(settingsProvider);
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      settings.storeName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.text('DAY END CLOSING SUMMARY', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Date: ${Formatters.dateTime(closing.closedAt)}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '-');

    bytes += generator.row([
      PosColumn(text: 'Opening Cash:', width: 7),
      PosColumn(text: Formatters.currency(closing.openingCash, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: '+ Cash Sales:', width: 7),
      PosColumn(text: Formatters.currency(closing.cashSales, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: '- Expenses:', width: 7),
      PosColumn(text: Formatters.currency(closing.cashExpenses, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    bytes += generator.row([
      PosColumn(text: 'Expected Cash:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: Formatters.currency(closing.expectedCash, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Counted Cash:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: Formatters.currency(closing.countedCash, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Difference:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: Formatters.currency(closing.difference, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    if (closing.notes != null && closing.notes!.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text('Notes: ${closing.notes}');
    }

    bytes += generator.feed(settings.printCutFeed);
    bytes += generator.cut();

    return await PrintBluetoothThermal.writeBytes(bytes);
  }
}

final dayClosingRepositoryProvider = Provider<DayClosingRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DayClosingRepository(db, ref);
});

final todaySummaryProvider = FutureProvider.autoDispose<DaySummaryData>((ref) {
  final repo = ref.watch(dayClosingRepositoryProvider);
  return repo.getTodaySummary();
});

final pastClosingsStreamProvider = StreamProvider.autoDispose<List<DayClosing>>((ref) {
  final repo = ref.watch(dayClosingRepositoryProvider);
  return repo.watchPastClosings();
});
