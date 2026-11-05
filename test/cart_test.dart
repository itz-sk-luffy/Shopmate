import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/features/pos/domain/cart_item.dart';
import 'package:shopmate/features/pos/domain/cart_state.dart';

void main() {
  group('Cart Calculations Test', () {
    test('Calculates loose item weight total accurately', () {
      const item = CartItem(
        productId: 1,
        productName: 'Basmati Rice',
        unit: 'kg',
        isDecimalAllowed: true,
        quantity: 0.350,
        unitPrice: 120.0,
      );

      expect(item.subtotal, 42.0);
      expect(item.discountedSubtotal, 42.0);
    });

    test('Exclusive GST calculation', () {
      const item = CartItem(
        productId: 2,
        productName: 'Soap',
        unit: 'pcs',
        quantity: 2.0,
        unitPrice: 50.0,
        gstRate: 18.0,
      );

      const state = CartState(
        items: [item],
        gstType: 'exclusive',
      );

      expect(state.rawSubtotal, 100.0);
      expect(state.taxableAmount, 100.0);
      expect(state.totalGst, 18.0);
      expect(state.cgstTotal, 9.0);
      expect(state.sgstTotal, 9.0);
      expect(state.grandTotal, 118.0);
    });

    test('Inclusive GST calculation', () {
      const item = CartItem(
        productId: 3,
        productName: 'Biscuit',
        unit: 'pcs',
        quantity: 1.0,
        unitPrice: 118.0,
        gstRate: 18.0,
      );

      const state = CartState(
        items: [item],
        gstType: 'inclusive',
      );

      expect(state.rawSubtotal, 118.0);
      expect(state.grandTotal, 118.0);
      // 118 - (118 / 1.18) = 18.0
      expect((state.totalGst - 18.0).abs() < 0.001, isTrue);
      expect((state.cgstTotal - 9.0).abs() < 0.001, isTrue);
    });

    test('Bill discount and Round-off calculation', () {
      const item = CartItem(
        productId: 4,
        productName: 'Cooking Oil',
        unit: 'ltr',
        quantity: 1.0,
        unitPrice: 195.40,
        gstRate: 0.0,
      );

      const state = CartState(
        items: [item],
        billDiscountAmount: 10.0,
        gstType: 'none',
      );

      expect(state.rawSubtotal, 195.40);
      expect(state.billDiscountTotal, 10.0);
      expect((state.unroundedTotal - 185.40).abs() < 0.001, isTrue);
      // 185.40 rounds to 185.00 -> roundOff = -0.40
      expect((state.roundOff - (-0.40)).abs() < 0.001, isTrue);
      expect(state.grandTotal, 185.0);
    });

    test('Cash tendered and Change Due calculation', () {
      const item = CartItem(
        productId: 5,
        productName: 'Tea Pack',
        unit: 'pcs',
        quantity: 1.0,
        unitPrice: 240.0,
      );

      const state = CartState(
        items: [item],
        paymentMode: 'Cash',
        cashTendered: 500.0,
        gstType: 'none',
      );

      expect(state.grandTotal, 240.0);
      expect(state.changeDue, 260.0);
    });
  });
}
