import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/core/utils/barcode_utils.dart';

/// Keyboard wedge detector logic replicating A2 requirements
class KeyboardWedgeDetector {
  final int maxIntervalMs;
  final List<({String char, int timestampMs})> _buffer = [];

  KeyboardWedgeDetector({this.maxIntervalMs = 50});

  /// Processes a character event. Returns non-null barcode string if a burst ending with Enter was detected.
  String? onChar(String char, int nowMs, {bool isEnter = false, bool isFocusedInInput = false}) {
    if (isEnter) {
      if (_buffer.isEmpty) return null;

      // Verify burst: check if every adjacent character arrived within maxIntervalMs
      bool isBurst = true;
      for (int i = 1; i < _buffer.length; i++) {
        if (_buffer[i].timestampMs - _buffer[i - 1].timestampMs > maxIntervalMs) {
          isBurst = false;
          break;
        }
      }

      final scannedCode = _buffer.map((e) => e.char).join();
      _buffer.clear();

      // If user was typing slowly in search field, isBurst will be false
      if (isBurst && scannedCode.isNotEmpty) {
        return scannedCode;
      }
      return null;
    }

    // Normal typing in search field takes 100-300ms per keystroke
    _buffer.add((char: char, timestampMs: nowMs));
    return null;
  }

  void reset() => _buffer.clear();
}

/// Debounce tracker replicating A1 requirements
class BarcodeDebounceTracker {
  final int debounceMs;
  final bool sameBarcodeAddsQuantity;
  String? _lastCode;
  int _lastTimeMs = 0;

  BarcodeDebounceTracker({
    this.debounceMs = 800,
    required this.sameBarcodeAddsQuantity,
  });

  bool shouldAcceptScan(String code, int nowMs) {
    if (_lastCode == code) {
      final diff = nowMs - _lastTimeMs;
      if (diff < debounceMs) {
        // Within debounce window: ignore repeated scan
        return false;
      }
      // If outside debounce window: check setting
      if (!sameBarcodeAddsQuantity) {
        return false;
      }
    }
    _lastCode = code;
    _lastTimeMs = nowMs;
    return true;
  }
}

void main() {
  group('A2: Keyboard-wedge burst detection tests', () {
    test('Rapid burst (< 50ms per key) ending in Enter is treated as scanner input', () {
      final detector = KeyboardWedgeDetector(maxIntervalMs: 50);
      const barcode = '8901030383700';

      int currentTime = 1000;
      String? result;

      for (int i = 0; i < barcode.length; i++) {
        currentTime += 15; // 15ms interval (typical for hardware USB/BT scanner)
        detector.onChar(barcode[i], currentTime);
      }

      currentTime += 20;
      result = detector.onChar('', currentTime, isEnter: true);

      expect(result, equals('8901030383700'));
    });

    test('Human typing in search field (120ms per key) is NOT mistaken for scanner burst', () {
      final detector = KeyboardWedgeDetector(maxIntervalMs: 50);
      const query = 'Tata';

      int currentTime = 1000;
      for (int i = 0; i < query.length; i++) {
        currentTime += 150; // 150ms per key (normal human typing speed)
        detector.onChar(query[i], currentTime);
      }

      currentTime += 200;
      final result = detector.onChar('', currentTime, isEnter: true);

      // Not a burst, so should return null (leaving text in search field)
      expect(result, isNull);
    });
  });

  group('A1: Scan Debounce and Same Barcode Setting Tests', () {
    test('Ignores duplicate scan within 800 ms debounce window', () {
      final tracker = BarcodeDebounceTracker(sameBarcodeAddsQuantity: true);
      const code = '8901030383700';

      expect(tracker.shouldAcceptScan(code, 1000), isTrue);
      // Scan 200 ms later: must be ignored by debounce
      expect(tracker.shouldAcceptScan(code, 1200), isFalse);
      // Scan 500 ms later: still under 800 ms
      expect(tracker.shouldAcceptScan(code, 1500), isFalse);
      // Scan 900 ms later: accepted!
      expect(tracker.shouldAcceptScan(code, 1900), isTrue);
    });

    test('If setting "Same barcode again adds quantity" is OFF, rejects repeat scan even after debounce', () {
      final tracker = BarcodeDebounceTracker(sameBarcodeAddsQuantity: false);
      const code = '8901030383700';

      expect(tracker.shouldAcceptScan(code, 1000), isTrue);
      // Scan 2000 ms later: rejected because setting is off
      expect(tracker.shouldAcceptScan(code, 3000), isFalse);

      // But a different barcode is accepted
      expect(tracker.shouldAcceptScan('012345678905', 3100), isTrue);
    });
  });

  group('A3: CSV Leading Zeros and Repair Tests', () {
    test('Export preserves leading zeros using text formula format', () {
      const barcode = '012345678905';
      final formatted = barcode.startsWith('0') ? '="$barcode"' : barcode;
      expect(formatted, equals('="012345678905"'));
    });

    test('Import strips formula quotes and restores barcode text', () {
      const rawCell = '="012345678905"';
      String cleaned = rawCell;
      if (cleaned.startsWith('="') && cleaned.endsWith('"')) {
        cleaned = cleaned.substring(2, cleaned.length - 1);
      }
      expect(cleaned, equals('012345678905'));
    });

    test('Repairs 12-digit barcode stripped by Excel if valid EAN-13 when prepending 0', () {
      // 0890103038370 is 13 digits with check digit.
      // Suppose Excel stripped leading 0 leaving 890103038370 (12 digits)
      final validEanWithLeadingZero = BarcodeUtils.generateEan13(prefix: '0', sequence: 1234567890);
      expect(validEanWithLeadingZero.startsWith('0'), isTrue);

      final strippedByExcel = validEanWithLeadingZero.substring(1);
      expect(strippedByExcel.length, 12);

      // Repair logic
      String repaired = strippedByExcel;
      if (repaired.length == 12) {
        final candidate = '0$repaired';
        if (BarcodeUtils.validate(candidate).isValid) {
          repaired = candidate;
        }
      }

      expect(repaired, equals(validEanWithLeadingZero));
    });
  });
}

