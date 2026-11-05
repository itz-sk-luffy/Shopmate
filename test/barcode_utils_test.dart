import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/core/utils/barcode_utils.dart';

void main() {
  group('BarcodeUtils Check Digit & Validation Tests', () {
    test('Calculates and validates EAN-13 correctly', () {
      // Known valid EAN-13: 8901030383700
      final res = BarcodeUtils.validate('8901030383700');
      expect(res.isValid, isTrue);
      expect(res.format, 'EAN-13');
      expect(res.warning, isNull);

      // Invalid check digit: change 0 to 1
      final badRes = BarcodeUtils.validate('8901030383701');
      expect(badRes.isValid, isFalse);
      expect(badRes.warning, contains('Invalid check digit'));
    });

    test('Calculates and validates UPC-A correctly', () {
      // Known valid UPC-A: 012345678905
      final res = BarcodeUtils.validate('012345678905');
      expect(res.isValid, isTrue);
      expect(res.format, 'UPC-A');

      // Invalid UPC-A check digit
      final bad = BarcodeUtils.validate('012345678904');
      expect(bad.isValid, isFalse);
    });

    test('Validates EAN-8 correctly', () {
      // Known valid EAN-8: 96385074
      final res = BarcodeUtils.validate('96385074');
      expect(res.isValid, isTrue);
      expect(res.format, 'EAN-8');
    });

    test('Treats UPC-A and its EAN-13 form with leading 0 as equivalent', () {
      const upcA = '012345678905';
      final equiv = BarcodeUtils.getEquivalentBarcodes(upcA);
      expect(equiv, contains('012345678905'));
      expect(equiv, contains('0012345678905'));

      const ean13 = '0012345678905';
      final equiv2 = BarcodeUtils.getEquivalentBarcodes(ean13);
      expect(equiv2, contains('0012345678905'));
      expect(equiv2, contains('012345678905'));
    });

    test('Sanitizes whitespace and trims', () {
      expect(BarcodeUtils.sanitize('  890 1030 383701  '), '8901030383701');
    });
  });

  group('Weighing Scale Barcode Parser Tests', () {
    test('Parses weight-embedded barcode (e.g. prefix 2, 5 digit item code, 5 digit weight in grams)', () {
      // 2 + 00123 (item 123) + 01500 (1500g = 1.500kg) + 4 (check digit)
      const raw = '200123015004';
      final parsed = BarcodeUtils.parseScaleBarcode(
        rawBarcode: raw,
        prefix: '2',
        itemCodeLength: 5,
        valueType: 'weight',
        valueLength: 5,
        decimalPlaces: 3,
      );

      expect(parsed.isScaleBarcode, isTrue);
      expect(parsed.itemCode, '00123');
      expect(parsed.value, 1.500);
      expect(parsed.formattedValue, '1.500 kg');
    });

    test('Parses price-embedded barcode (e.g. prefix 2, 5 digit item code, 5 digit price in paise)', () {
      // 2 + 00456 (item 456) + 09950 (9950 paise = ₹ 99.50) + 1
      const raw = '200456099501';
      final parsed = BarcodeUtils.parseScaleBarcode(
        rawBarcode: raw,
        prefix: '2',
        itemCodeLength: 5,
        valueType: 'price',
        valueLength: 5,
      );

      expect(parsed.isScaleBarcode, isTrue);
      expect(parsed.itemCode, '00456');
      expect(parsed.value, 99.50);
      expect(parsed.formattedValue, '₹ 99.50');
    });

    test('Ignores barcode if prefix does not match', () {
      const raw = '8901030383701';
      final parsed = BarcodeUtils.parseScaleBarcode(
        rawBarcode: raw,
        prefix: '2',
      );
      expect(parsed.isScaleBarcode, isFalse);
    });
  });

  group('Sequential Internal Barcode Generation', () {
    test('Generates valid 13-digit EAN barcode with prefix and check digit', () {
      final code = BarcodeUtils.generateEan13(prefix: '29', sequence: 1001);
      expect(code.length, 13);
      expect(code.startsWith('29'), isTrue);

      final val = BarcodeUtils.validate(code);
      expect(val.isValid, isTrue);
      expect(val.format, 'EAN-13');
    });

    test('Sequential codes are distinct and valid', () {
      final code1 = BarcodeUtils.generateEan13(prefix: '29', sequence: 1001);
      final code2 = BarcodeUtils.generateEan13(prefix: '29', sequence: 1002);
      expect(code1, isNot(equals(code2)));
      expect(BarcodeUtils.validate(code1).isValid, isTrue);
      expect(BarcodeUtils.validate(code2).isValid, isTrue);
    });
  });
}
