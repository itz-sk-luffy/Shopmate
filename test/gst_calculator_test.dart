import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/core/utils/gst_calculator.dart';

void main() {
  group('GstCalculator Unit Tests', () {
    test('5% exclusive calculation without discount', () {
      final items = [
        const GstLineInput(price: 100.0, quantity: 1.0, gstRate: 5.0),
      ];
      final res = GstCalculator.calculate(items: items, isInclusive: false);

      expect(res.subtotal, 100.0);
      expect(res.taxableValue, 100.0);
      expect(res.totalTax, 5.0);
      expect(res.cgstTotal, 2.5);
      expect(res.sgstTotal, 2.5);
      expect(res.igstTotal, 0.0);
      expect(res.cgstTotal + res.sgstTotal, res.totalTax);
      expect(res.grandTotal, 105.0);
      expect(res.rateBreakups.length, 1);
      expect(res.rateBreakups.first.rate, 5.0);
      expect(res.rateBreakups.first.cgstRate, 2.5);
      expect(res.rateBreakups.first.sgstRate, 2.5);
      expect(res.rateBreakups.first.cgstAmount, 2.5);
      expect(res.rateBreakups.first.sgstAmount, 2.5);
    });

    test('18% inclusive calculation without discount', () {
      final items = [
        const GstLineInput(price: 118.0, quantity: 1.0, gstRate: 18.0),
      ];
      final res = GstCalculator.calculate(items: items, isInclusive: true);

      expect(res.subtotal, 118.0);
      expect(res.taxableValue, 100.0);
      expect(res.totalTax, 18.0);
      expect(res.cgstTotal, 9.0);
      expect(res.sgstTotal, 9.0);
      expect(res.igstTotal, 0.0);
      expect(res.cgstTotal + res.sgstTotal, res.totalTax);
      expect(res.grandTotal, 118.0);
      expect(res.rateBreakups.length, 1);
      expect(res.rateBreakups.first.rate, 18.0);
      expect(res.rateBreakups.first.cgstRate, 9.0);
      expect(res.rateBreakups.first.sgstRate, 9.0);
    });

    test('Rates 0%, 5%, 12%, 18%, 28% in same bill', () {
      final items = [
        const GstLineInput(price: 50.0, quantity: 1.0, gstRate: 0.0),
        const GstLineInput(price: 100.0, quantity: 1.0, gstRate: 5.0),
        const GstLineInput(price: 100.0, quantity: 1.0, gstRate: 12.0),
        const GstLineInput(price: 100.0, quantity: 1.0, gstRate: 18.0),
        const GstLineInput(price: 100.0, quantity: 1.0, gstRate: 28.0),
      ];
      final res = GstCalculator.calculate(items: items, isInclusive: false);

      expect(res.subtotal, 450.0);
      expect(res.taxableValue, 450.0);
      // Tax: 0 + 5 + 12 + 18 + 28 = 63.0
      expect(res.totalTax, 63.0);
      // CGST: 2.5 + 6.0 + 9.0 + 14.0 = 31.5
      expect(res.cgstTotal, 31.5);
      expect(res.sgstTotal, 31.5);
      expect(res.cgstTotal + res.sgstTotal, 63.0);
      expect(res.grandTotal, 513.0);
      expect(res.rateBreakups.length, 4); // rates > 0: 5, 12, 18, 28
    });

    test('Calculation with item discount', () {
      final items = [
        const GstLineInput(price: 100.0, quantity: 1.0, itemDiscount: 20.0, gstRate: 18.0),
      ];
      final res = GstCalculator.calculate(items: items, isInclusive: false);

      expect(res.subtotal, 100.0);
      expect(res.itemDiscountTotal, 20.0);
      expect(res.taxableValue, 80.0);
      // Tax: 80 * 0.18 = 14.40
      expect(res.totalTax, 14.40);
      expect(res.cgstTotal, 7.20);
      expect(res.sgstTotal, 7.20);
      expect(res.unroundedTotal, 94.40);
      // Round off: 94.40 rounds to 94.00, roundOff = -0.40
      expect(res.roundOff, -0.40);
      expect(res.grandTotal, 94.0);
    });

    test('Calculation with bill discount apportioned proportionally', () {
      final items = [
        const GstLineInput(price: 100.0, quantity: 1.0, gstRate: 5.0),
        const GstLineInput(price: 100.0, quantity: 1.0, gstRate: 18.0),
      ];
      // Total base = 200. Bill discount = 50. Proportion = 50% to each line (25 each).
      final res = GstCalculator.calculate(
        items: items,
        billDiscount: 50.0,
        isInclusive: false,
      );

      expect(res.subtotal, 200.0);
      expect(res.billDiscountTotal, 50.0);
      expect(res.taxableValue, 150.0);
      // Line 1: base 75, tax at 5% = 3.75
      // Line 2: base 75, tax at 18% = 13.50
      // Total tax = 17.25
      expect(res.totalTax, 17.25);
      expect(res.cgstTotal + res.sgstTotal, 17.25);
      expect(res.unroundedTotal, 167.25);
    });

    test('Odd-paise rounding splits CGST and SGST without losing a paise', () {
      // 1 item with ₹1 base and 15% rate = 15 paise tax
      final items = [
        const GstLineInput(price: 1.0, quantity: 1.0, gstRate: 15.0),
      ];
      final res = GstCalculator.calculate(items: items, isInclusive: false);

      expect(res.totalTax, 0.15);
      expect(res.cgstTotal, 0.07);
      expect(res.sgstTotal, 0.08);
      expect(double.parse((res.cgstTotal + res.sgstTotal).toStringAsFixed(2)), 0.15);
    });

    test('Inter-state calculation assigns all tax to IGST and 0 to CGST/SGST', () {
      final items = [
        const GstLineInput(price: 200.0, quantity: 1.0, gstRate: 18.0),
      ];
      final res = GstCalculator.calculate(
        items: items,
        isInclusive: false,
        isInterState: true,
      );

      expect(res.taxableValue, 200.0);
      expect(res.totalTax, 36.0);
      expect(res.cgstTotal, 0.0);
      expect(res.sgstTotal, 0.0);
      expect(res.igstTotal, 36.0);
      expect(res.rateBreakups.first.cgstAmount, 0.0);
      expect(res.rateBreakups.first.sgstAmount, 0.0);
      expect(res.rateBreakups.first.igstAmount, 36.0);
    });

    test('deriveStateFromGstin derives state correctly from 2-digit code', () {
      expect(deriveStateFromGstin('27AAAAA0000A1Z5'), 'Maharashtra');
      expect(deriveStateFromGstin('07AAAAA0000A1Z5'), 'Delhi');
      expect(deriveStateFromGstin('29AAAAA0000A1Z5'), 'Karnataka');
      expect(deriveStateFromGstin('33AAAAA0000A1Z5'), 'Tamil Nadu');
      expect(deriveStateFromGstin(''), isNull);
      expect(deriveStateFromGstin(null), isNull);
    });
  });
}
