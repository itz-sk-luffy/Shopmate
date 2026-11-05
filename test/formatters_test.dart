import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/core/utils/formatters.dart';

void main() {
  group('Formatters & Indian Currency Words Test', () {
    test('Converts numbers to Indian Rupees in words accurately', () {
      expect(
        Formatters.numberToWordsIndian(0),
        'Zero Rupees Only',
      );

      expect(
        Formatters.numberToWordsIndian(50),
        'Fifty Rupees Only',
      );

      expect(
        Formatters.numberToWordsIndian(345),
        'Three Hundred Forty Five Rupees Only',
      );

      expect(
        Formatters.numberToWordsIndian(1450),
        'One Thousand Four Hundred Fifty Rupees Only',
      );

      expect(
        Formatters.numberToWordsIndian(25000),
        'Twenty Five Thousand Rupees Only',
      );

      expect(
        Formatters.numberToWordsIndian(125000),
        'One Lakh Twenty Five Thousand Rupees Only',
      );
    });

    test('Currency formatting with ₹ symbol and decimals', () {
      final formatted = Formatters.currency(150.50, symbol: '₹');
      expect(formatted.contains('150.50'), isTrue);
      expect(formatted.contains('₹'), isTrue);
    });

    test('Quantity formatting for integer and decimal units', () {
      expect(Formatters.formatQuantity(2.0, 'pcs'), '2 pcs');
      expect(Formatters.formatQuantity(0.250, 'kg'), '0.25 kg');
      expect(Formatters.formatQuantity(1.500, 'ltr'), '1.5 ltr');
    });

    test('timeAgo calculates appropriate relative time strings', () {
      final now = DateTime.now();
      expect(Formatters.timeAgo(now.subtract(const Duration(seconds: 30))), 'Just now');
      expect(Formatters.timeAgo(now.subtract(const Duration(minutes: 5))), '5m ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(hours: 3))), '3h ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(days: 4))), '4d ago');
    });
  });
}
