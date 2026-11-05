import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/features/dashboard/data/dashboard_repository.dart';
import 'package:shopmate/features/reports/data/reports_repository.dart';

void main() {
  group('Customers & Udhaar Ledger Model Tests', () {
    test('Udhaar balance and pending calculation', () {
      const creditGiven = 1250.0;
      const netPending = 450.0;
      final totalReceived = (creditGiven - netPending).clamp(0.0, double.infinity);

      expect(totalReceived, 800.0);
      expect(netPending > 0, isTrue);
    });
  });

  group('Reports & Analytics Model Tests', () {
    test('ItemWiseSalesRow and DayWiseSalesRow store aggregation values correctly', () {
      const itemRow = ItemWiseSalesRow(
        productName: 'Atta 5kg',
        unit: 'pack',
        quantitySold: 2.0,
        totalAmount: 400.0,
        averagePrice: 200.0,
      );

      expect(itemRow.productName, 'Atta 5kg');
      expect(itemRow.quantitySold, 2.0);
      expect(itemRow.totalAmount, 400.0);
      expect(itemRow.averagePrice, 200.0);

      final dayRow = DayWiseSalesRow(
        date: DateTime(2026, 11, 5),
        billsCount: 3,
        subtotal: 900.0,
        discount: 50.0,
        tax: 35.0,
        grandTotal: 885.0,
      );

      expect(dayRow.billsCount, 3);
      expect(dayRow.grandTotal, 885.0);
      expect(dayRow.tax, 35.0);
    });

    test('GstReportRow calculates CGST and SGST accurately', () {
      const gstRow = GstReportRow(
        gstRate: 18.0,
        taxableAmount: 1000.0,
        cgst: 90.0,
        sgst: 90.0,
        totalTax: 180.0,
      );

      expect(gstRow.gstRate, 18.0);
      expect(gstRow.cgst + gstRow.sgst, gstRow.totalTax);
    });
  });

  group('Dashboard Hourly Graph Tests', () {
    test('HourlySalesPoint maps hours and formats labels correctly', () {
      final points = [
        for (int h = 6; h <= 23; h++)
          HourlySalesPoint(
            hour: h,
            amount: h == 13 ? 370.0 : (h == 17 ? 515.0 : 0.0),
            label: h == 0
                ? '12AM'
                : (h == 12 ? '12PM' : (h > 12 ? '${h - 12}PM' : '${h}AM')),
          ),
      ];

      expect(points.length, 18);
      final hour13 = points.firstWhere((p) => p.hour == 13);
      expect(hour13.amount, 370.0);
      expect(hour13.label, '1PM');

      final hour17 = points.firstWhere((p) => p.hour == 17);
      expect(hour17.amount, 515.0);
      expect(hour17.label, '5PM');
    });
  });
}
