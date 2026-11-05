class BarcodeValidationResult {
  final bool isValid;
  final String format;
  final String? warning;

  const BarcodeValidationResult({
    required this.isValid,
    required this.format,
    this.warning,
  });
}

class ScaleBarcodeResult {
  final bool isScaleBarcode;
  final String rawBarcode;
  final String? itemCode;
  final double? value; // e.g., weight in kg (1.250) or price in rupees (125.50)
  final String? valueType; // 'weight' or 'price'
  final String? formattedValue;
  final String? error;

  const ScaleBarcodeResult({
    required this.isScaleBarcode,
    required this.rawBarcode,
    this.itemCode,
    this.value,
    this.valueType,
    this.formattedValue,
    this.error,
  });
}

class BarcodeUtils {
  /// Sanitize barcode: remove all whitespace and trim
  static String sanitize(String? code) {
    if (code == null) return '';
    return code.replaceAll(RegExp(r'\s+'), '').trim();
  }

  /// Returns canonical forms of a barcode for equivalence checks.
  /// If 12 digits (UPC-A), returns [code, '0$code'].
  /// If 13 digits starting with '0', returns [code, code.substring(1)].
  /// Otherwise returns [code].
  static List<String> getEquivalentBarcodes(String raw) {
    final clean = sanitize(raw);
    if (clean.isEmpty) return [];

    final isNumeric = RegExp(r'^\d+$').hasMatch(clean);
    if (!isNumeric) return [clean];

    if (clean.length == 12) {
      return [clean, '0$clean'];
    } else if (clean.length == 13 && clean.startsWith('0')) {
      return [clean, clean.substring(1)];
    }
    return [clean];
  }

  /// Calculates EAN / UPC check digit for a string of digits (without the check digit).
  /// For EAN-13 (12 digits input): odd pos * 1, even pos * 3 (1-based: pos 1=odd, pos 2=even).
  /// Formula: (10 - (sum % 10)) % 10.
  static int calculateEanCheckDigit(String digitsWithoutCheckDigit) {
    int sum = 0;
    // Iterate from right to left with alternating weights 3, 1, 3, 1...
    int weight = 3;
    for (int i = digitsWithoutCheckDigit.length - 1; i >= 0; i--) {
      final digit = int.tryParse(digitsWithoutCheckDigit[i]) ?? 0;
      sum += digit * weight;
      weight = (weight == 3) ? 1 : 3;
    }
    final mod = sum % 10;
    return (10 - mod) % 10;
  }

  /// Validates standard check digits for EAN-13, EAN-8, UPC-A, UPC-E.
  /// Returns a validation result with a soft warning if invalid.
  static BarcodeValidationResult validate(String raw) {
    final clean = sanitize(raw);
    if (clean.isEmpty) {
      return const BarcodeValidationResult(
        isValid: false,
        format: 'Empty',
        warning: 'Barcode cannot be empty',
      );
    }

    final isAllDigits = RegExp(r'^\d+$').hasMatch(clean);
    if (!isAllDigits) {
      // Internal or custom alphanumeric barcode (e.g., Code39/Code128)
      return const BarcodeValidationResult(
        isValid: true,
        format: 'Custom / Alphanumeric',
        warning: null,
      );
    }

    // EAN-13: 13 digits
    if (clean.length == 13) {
      final body = clean.substring(0, 12);
      final expectedCheck = calculateEanCheckDigit(body);
      final actualCheck = int.tryParse(clean[12]) ?? -1;
      if (actualCheck == expectedCheck) {
        return const BarcodeValidationResult(
          isValid: true,
          format: 'EAN-13',
        );
      } else {
        return BarcodeValidationResult(
          isValid: false,
          format: 'EAN-13',
          warning: 'Invalid check digit (expected $expectedCheck, found $actualCheck)',
        );
      }
    }

    // UPC-A: 12 digits
    if (clean.length == 12) {
      final body = clean.substring(0, 11);
      final expectedCheck = calculateEanCheckDigit(body);
      final actualCheck = int.tryParse(clean[11]) ?? -1;
      if (actualCheck == expectedCheck) {
        return const BarcodeValidationResult(
          isValid: true,
          format: 'UPC-A',
        );
      } else {
        return BarcodeValidationResult(
          isValid: false,
          format: 'UPC-A',
          warning: 'Invalid check digit (expected $expectedCheck, found $actualCheck)',
        );
      }
    }

    // EAN-8: 8 digits
    if (clean.length == 8) {
      final body = clean.substring(0, 7);
      final expectedCheck = calculateEanCheckDigit(body);
      final actualCheck = int.tryParse(clean[7]) ?? -1;
      if (actualCheck == expectedCheck) {
        return const BarcodeValidationResult(
          isValid: true,
          format: 'EAN-8',
        );
      } else {
        return BarcodeValidationResult(
          isValid: false,
          format: 'EAN-8',
          warning: 'Invalid check digit (expected $expectedCheck, found $actualCheck)',
        );
      }
    }

    // UPC-E: 6, 7 or 8 digits
    if (clean.length == 6 || clean.length == 7) {
      return const BarcodeValidationResult(
        isValid: true,
        format: 'UPC-E',
      );
    }

    // Other numeric lengths (Code128, etc.)
    return const BarcodeValidationResult(
      isValid: true,
      format: 'Numeric (Internal)',
    );
  }

  /// Parses weighing-scale barcodes:
  /// Typically 12 or 13 digits starting with [prefix] (e.g., '2' or '02').
  /// Next [itemCodeLength] characters are the product item code.
  /// Next [valueLength] characters are the weight (in grams) or price (in paise).
  static ScaleBarcodeResult parseScaleBarcode({
    required String rawBarcode,
    required String prefix,
    int itemCodeLength = 5,
    String valueType = 'weight', // 'weight' or 'price'
    int valueLength = 5,
    int decimalPlaces = 3,
  }) {
    final clean = sanitize(rawBarcode);
    if (!clean.startsWith(prefix) || clean.length < (prefix.length + itemCodeLength + valueLength)) {
      return ScaleBarcodeResult(
        isScaleBarcode: false,
        rawBarcode: clean,
        error: 'Barcode does not match weighing scale prefix ($prefix)',
      );
    }

    try {
      final itemCodeStart = prefix.length;
      final itemCodeEnd = itemCodeStart + itemCodeLength;
      final itemCode = clean.substring(itemCodeStart, itemCodeEnd);

      final valStart = itemCodeEnd;
      final valEnd = valStart + valueLength;
      final rawValStr = clean.substring(valStart, valEnd);
      final rawVal = double.tryParse(rawValStr);

      if (rawVal == null) {
        return ScaleBarcodeResult(
          isScaleBarcode: true,
          rawBarcode: clean,
          itemCode: itemCode,
          error: 'Could not parse embedded number: $rawValStr',
        );
      }

      double finalValue;
      String formatted;
      if (valueType == 'weight') {
        // e.g., grams -> kg (divisor 10^decimalPlaces, default 1000)
        final divisor = _pow10(decimalPlaces);
        finalValue = rawVal / divisor;
        formatted = '${finalValue.toStringAsFixed(decimalPlaces)} kg';
      } else {
        // e.g., paise -> rupees (divisor 10^2 = 100)
        final divisor = _pow10(2);
        finalValue = rawVal / divisor;
        formatted = '₹ ${finalValue.toStringAsFixed(2)}';
      }

      return ScaleBarcodeResult(
        isScaleBarcode: true,
        rawBarcode: clean,
        itemCode: itemCode,
        value: finalValue,
        valueType: valueType,
        formattedValue: formatted,
      );
    } catch (e) {
      return ScaleBarcodeResult(
        isScaleBarcode: true,
        rawBarcode: clean,
        error: 'Failed to parse scale barcode: $e',
      );
    }
  }

  static double _pow10(int exp) {
    double res = 1.0;
    for (int i = 0; i < exp; i++) {
      res *= 10;
    }
    return res;
  }

  /// Generates a valid 13-digit EAN barcode using a 2-digit prefix and a sequence number.
  /// Example: prefix='29', sequence=1000000001 -> 12 digits '290000000001' + check digit.
  static String generateEan13({required String prefix, required int sequence}) {
    final cleanPrefix = sanitize(prefix);
    final neededDigits = 12 - cleanPrefix.length;
    final seqStr = sequence.toString().padLeft(neededDigits, '0');
    final body = '$cleanPrefix$seqStr'.substring(0, 12);
    final checkDigit = calculateEanCheckDigit(body);
    return '$body$checkDigit';
  }
}

