import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Day-End Closing & Register Reconciliation Math Test', () {
    test('Calculates expected cash correctly from formula', () {
      const double openingCash = 1000.0;
      const double cashSales = 4500.0;
      const double returnsAmount = 0.0;
      const double cashExpenses = 350.0;

      // Expected Cash = Opening Cash + Cash Sales - Returns - Cash Expenses
      const double expectedCash = openingCash + cashSales - returnsAmount - cashExpenses;

      expect(expectedCash, 5150.0);

      // Balanced Register
      const double countedCashBalanced = 5150.0;
      const double diffBalanced = countedCashBalanced - expectedCash;
      expect(diffBalanced, 0.0);

      // Shortage (Counted < Expected)
      const double countedCashShortage = 5000.0;
      const double diffShortage = countedCashShortage - expectedCash;
      expect(diffShortage, -150.0);

      // Surplus (Counted > Expected)
      const double countedCashSurplus = 5200.0;
      const double diffSurplus = countedCashSurplus - expectedCash;
      expect(diffSurplus, 50.0);
    });

    test('30-Day auto purge cutoff calculation', () {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 30));

      final oldItemDate = now.subtract(const Duration(days: 35));
      final recentItemDate = now.subtract(const Duration(days: 10));

      expect(oldItemDate.isBefore(cutoff), isTrue);
      expect(recentItemDate.isBefore(cutoff), isFalse);

      final daysRemainingForRecent = recentItemDate.add(const Duration(days: 30)).difference(now).inDays;
      expect(daysRemainingForRecent, 20);
    });
  });
}
