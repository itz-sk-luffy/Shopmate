import 'package:flutter_test/flutter_test.dart';

/// Pure helper replicating the generator logic in BillingRepository
int calculateNextBillNumericSuffix({
  required List<String> existingBillNumbers,
  required String prefix,
  required int startNum,
}) {
  int maxSuffix = startNum - 1;
  for (final bn in existingBillNumbers) {
    if (bn.startsWith(prefix)) {
      final suffixStr = bn.substring(prefix.length);
      final suffixVal = int.tryParse(suffixStr);
      if (suffixVal != null && suffixVal > maxSuffix) {
        maxSuffix = suffixVal;
      }
    }
  }
  return maxSuffix + 1;
}

void main() {
  group('Bill Number Generator Logic Tests', () {
    test('Sequential generation starting from settings start number', () {
      final existing = <String>[];
      const prefix = 'INV-';
      const startNum = 1001;

      final next1 = calculateNextBillNumericSuffix(
        existingBillNumbers: existing,
        prefix: prefix,
        startNum: startNum,
      );
      expect(next1, 1001);
      existing.add('$prefix$next1');

      final next2 = calculateNextBillNumericSuffix(
        existingBillNumbers: existing,
        prefix: prefix,
        startNum: startNum,
      );
      expect(next2, 1002);
      existing.add('$prefix$next2');

      final next3 = calculateNextBillNumericSuffix(
        existingBillNumbers: existing,
        prefix: prefix,
        startNum: startNum,
      );
      expect(next3, 1003);
    });

    test('Deleted and edited bills prevent number reuse (never duplicate numbers)', () {
      // Existing rows include deleted and edited bills
      final allRows = ['INV-1001', 'INV-1002', 'INV-1003', 'INV-1004'];
      const prefix = 'INV-';
      const startNum = 1001;

      // Even if INV-1004 was deleted or edited, next must be 1005
      final next = calculateNextBillNumericSuffix(
        existingBillNumbers: allRows,
        prefix: prefix,
        startNum: startNum,
      );
      expect(next, 1005);
    });

    test('Held bills (HOLD-xxx) do not pollute or bump regular invoice sequence', () {
      final existing = ['INV-1001', 'INV-1002', 'HOLD-981244', 'HOLD-123456'];
      const prefix = 'INV-';
      const startNum = 1001;

      final next = calculateNextBillNumericSuffix(
        existingBillNumbers: existing,
        prefix: prefix,
        startNum: startNum,
      );
      expect(next, 1003);
    });

    test('Restored backup with higher bill numbers than stale settings counter never collides', () {
      // Stale settings counter might be 1002, but restored database has bills up to INV-1004
      final restoredBills = ['INV-1001', 'INV-1002', 'INV-1003', 'INV-1004'];
      const prefix = 'INV-';
      const staleStartNum = 1002;

      // Must inspect all rows and produce 1005, preventing UNIQUE constraint failed (code 2067)
      final next = calculateNextBillNumericSuffix(
        existingBillNumbers: restoredBills,
        prefix: prefix,
        startNum: staleStartNum,
      );
      expect(next, 1005);
    });

    test('Honors higher start number in settings if greater than existing maximum', () {
      final existing = ['INV-1001', 'INV-1002'];
      const prefix = 'INV-';
      const higherStartNum = 5000;

      final next = calculateNextBillNumericSuffix(
        existingBillNumbers: existing,
        prefix: prefix,
        startNum: higherStartNum,
      );
      expect(next, 5000);
    });
  });
}
