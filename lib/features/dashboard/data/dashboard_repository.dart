import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

class DashboardMetrics {
  final double totalSales;
  final int totalBills;
  final double averageBill;
  final double todayUdhaar;
  final double cashCollected;
  final double digitalCollected;
  final double gstCollected;
  final double deltaPercentVsYesterday;

  const DashboardMetrics({
    this.totalSales = 0.0,
    this.totalBills = 0,
    this.averageBill = 0.0,
    this.todayUdhaar = 0.0,
    this.cashCollected = 0.0,
    this.digitalCollected = 0.0,
    this.gstCollected = 0.0,
    this.deltaPercentVsYesterday = 0.0,
  });
}

class HourlySalesPoint {
  final int hour;
  final double amount;
  final String label;

  const HourlySalesPoint({
    required this.hour,
    required this.amount,
    this.label = '',
  });
}

class TopProductSales {
  final String productName;
  final double quantity;
  final double totalAmount;

  const TopProductSales({
    required this.productName,
    required this.quantity,
    required this.totalAmount,
  });
}

class DashboardRepository {
  final AppDatabase _db;

  DashboardRepository(this._db);

  Future<DashboardMetrics> getMetrics({DateTime? startDate, DateTime? endDate}) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, now.day);
    final end = endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    final billsQuery = _db.select(_db.bills)
      ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
      ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end));

    final bills = await billsQuery.get();

    double totalSales = 0.0;
    double todayUdhaar = 0.0;
    double cashCollected = 0.0;
    double digitalCollected = 0.0;
    double gstCollected = 0.0;

    for (final b in bills) {
      totalSales += b.grandTotal;
      gstCollected += (b.cgstTotal + b.sgstTotal + b.igstTotal);
      if (b.paymentMode == 'Credit' && !b.isCreditPaid) {
        todayUdhaar += b.grandTotal;
      }
      cashCollected += b.cashAmount;
      digitalCollected += b.digitalAmount;
    }

    final totalBills = bills.length;
    final averageBill = totalBills > 0 ? (totalSales / totalBills) : 0.0;

    // Calculate yesterday sales to get delta %
    final yestStart = DateTime(now.year, now.month, now.day - 1);
    final yestEnd = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
    final yestBills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(yestStart) & tbl.date.isSmallerOrEqualValue(yestEnd)))
        .get();

    final yestSales = yestBills.fold(0.0, (acc, b) => acc + b.grandTotal);
    double deltaPercent = 0.0;
    if (yestSales > 0) {
      deltaPercent = ((totalSales - yestSales) / yestSales) * 100.0;
    } else if (totalSales > 0) {
      deltaPercent = 100.0;
    }

    return DashboardMetrics(
      totalSales: totalSales,
      totalBills: totalBills,
      averageBill: averageBill,
      todayUdhaar: todayUdhaar,
      cashCollected: cashCollected,
      digitalCollected: digitalCollected,
      gstCollected: gstCollected,
      deltaPercentVsYesterday: deltaPercent,
    );
  }

  Future<List<HourlySalesPoint>> getSalesTrend({String range = 'Today'}) async {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (range == 'This Week') {
      start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (range == 'This Month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      // Today
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    if (range == 'This Week') {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final Map<int, double> weekMap = {for (int d = 1; d <= 7; d++) d: 0.0};
      for (final b in bills) {
        final weekday = b.date.weekday;
        if (weekMap.containsKey(weekday)) {
          weekMap[weekday] = (weekMap[weekday] ?? 0.0) + b.grandTotal;
        }
      }
      return weekMap.entries.map((e) => HourlySalesPoint(
        hour: e.key,
        amount: e.value,
        label: days[e.key - 1],
      )).toList();
    } else if (range == 'This Month') {
      final totalDays = DateTime(now.year, now.month + 1, 0).day;
      final Map<int, double> monthMap = {for (int d = 1; d <= totalDays; d++) d: 0.0};
      for (final b in bills) {
        final day = b.date.day;
        if (monthMap.containsKey(day)) {
          monthMap[day] = (monthMap[day] ?? 0.0) + b.grandTotal;
        }
      }
      return monthMap.entries.map((e) => HourlySalesPoint(
        hour: e.key,
        amount: e.value,
        label: '${e.key}',
      )).toList();
    } else {
      // Today: cover hours 6 AM to 11 PM (or earlier/later if sales occurred)
      int minHour = 6;
      int maxHour = 23;
      for (final b in bills) {
        if (b.date.hour < minHour) minHour = b.date.hour;
        if (b.date.hour > maxHour) maxHour = b.date.hour;
      }
      final Map<int, double> hourlyMap = {for (int h = minHour; h <= maxHour; h++) h: 0.0};
      for (final b in bills) {
        final hour = b.date.hour;
        hourlyMap[hour] = (hourlyMap[hour] ?? 0.0) + b.grandTotal;
      }
      final sortedKeys = hourlyMap.keys.toList()..sort();
      return sortedKeys.map((h) {
        final label = h == 0
            ? '12AM'
            : (h == 12 ? '12PM' : (h > 12 ? '${h - 12}PM' : '${h}AM'));
        return HourlySalesPoint(
          hour: h,
          amount: hourlyMap[h] ?? 0.0,
          label: label,
        );
      }).toList();
    }
  }

  Future<List<HourlySalesPoint>> getHourlySales(DateTime date) async {
    return getSalesTrend(range: 'Today');
  }

  Future<List<TopProductSales>> getTopProducts({DateTime? startDate, DateTime? endDate, int limit = 5}) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    if (bills.isEmpty) return [];

    final billIds = bills.map((b) => b.id).toList();
    final items = await (_db.select(_db.billItems)..where((tbl) => tbl.billId.isIn(billIds))).get();

    final Map<String, ({double qty, double amount})> agg = {};
    for (final it in items) {
      final cur = agg[it.productName] ?? (qty: 0.0, amount: 0.0);
      agg[it.productName] = (qty: cur.qty + it.quantity, amount: cur.amount + it.totalAmount);
    }

    final sorted = agg.entries.toList()
      ..sort((a, b) => b.value.qty.compareTo(a.value.qty));

    return sorted.take(limit).map((e) {
      return TopProductSales(
        productName: e.key,
        quantity: e.value.qty,
        totalAmount: e.value.amount,
      );
    }).toList();
  }

  Future<Map<String, double>> getPaymentBreakdown({DateTime? startDate, DateTime? endDate}) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, now.day);
    final end = endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    final bills = await (_db.select(_db.bills)
          ..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))
          ..where((tbl) => tbl.date.isBiggerOrEqualValue(start) & tbl.date.isSmallerOrEqualValue(end)))
        .get();

    final Map<String, double> map = {
      'Cash': 0.0,
      'UPI': 0.0,
      'Card': 0.0,
      'Credit': 0.0,
    };

    for (final b in bills) {
      if (b.paymentMode == 'Split') {
        map['Cash'] = (map['Cash'] ?? 0.0) + b.cashAmount;
        map['UPI'] = (map['UPI'] ?? 0.0) + b.digitalAmount;
      } else {
        map[b.paymentMode] = (map[b.paymentMode] ?? 0.0) + b.grandTotal;
      }
    }

    return map;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DashboardRepository(db);
});

final dashboardRangeProvider = StateProvider<String>((ref) => 'Today');

/// Stream watching non-deleted, non-held bills so all dashboard metrics & trend charts
/// automatically refresh in real-time when bills are created or modified.
final dashboardBillsChangeStreamProvider = StreamProvider.autoDispose<List<Bill>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.bills)..where((tbl) => tbl.isDeleted.equals(false) & tbl.isHeld.equals(false))).watch();
});

final FutureProviderFamily<DashboardMetrics, String> dashboardMetricsFamilyProvider =
    FutureProvider.family<DashboardMetrics, String>((ref, range) async {
  // Watch bill changes for automatic live update
  ref.watch(dashboardBillsChangeStreamProvider);
  final repo = ref.watch(dashboardRepositoryProvider);

  final now = DateTime.now();
  DateTime? start;
  DateTime? end;

  if (range == 'Today') {
    start = DateTime(now.year, now.month, now.day);
    end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Prefetch 'This Week' and 'This Month' so switching between ranges is instant
    Future.microtask(() {
      ref.read(dashboardMetricsFamilyProvider('This Week').future);
      ref.read(dashboardMetricsFamilyProvider('This Month').future);
    });
  } else if (range == 'This Week') {
    start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  } else if (range == 'This Month') {
    start = DateTime(now.year, now.month, 1);
    end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  return repo.getMetrics(startDate: start, endDate: end);
});

final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final range = ref.watch(dashboardRangeProvider);
  return ref.watch(dashboardMetricsFamilyProvider(range));
});

final hourlySalesProvider = FutureProvider.autoDispose<List<HourlySalesPoint>>((ref) async {
  // Watch bill updates & range selection for live reactive chart rendering
  ref.watch(dashboardBillsChangeStreamProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  final range = ref.watch(dashboardRangeProvider);
  return repo.getSalesTrend(range: range);
});

final topProductsProvider = FutureProvider.autoDispose<List<TopProductSales>>((ref) async {
  ref.watch(dashboardBillsChangeStreamProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  final range = ref.watch(dashboardRangeProvider);

  final now = DateTime.now();
  DateTime? start;
  DateTime? end = DateTime(now.year, now.month, now.day, 23, 59, 59);

  if (range == 'Today') {
    start = DateTime(now.year, now.month, now.day);
  } else if (range == 'This Week') {
    start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  } else if (range == 'This Month') {
    start = DateTime(now.year, now.month, 1);
  }

  return repo.getTopProducts(startDate: start, endDate: end);
});

final paymentBreakdownProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  ref.watch(dashboardBillsChangeStreamProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  final range = ref.watch(dashboardRangeProvider);

  final now = DateTime.now();
  DateTime? start;
  DateTime? end = DateTime(now.year, now.month, now.day, 23, 59, 59);

  if (range == 'Today') {
    start = DateTime(now.year, now.month, now.day);
  } else if (range == 'This Week') {
    start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  } else if (range == 'This Month') {
    start = DateTime(now.year, now.month, 1);
  }

  return repo.getPaymentBreakdown(startDate: start, endDate: end);
});
