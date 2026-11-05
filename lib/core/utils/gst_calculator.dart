import 'dart:math';

/// Indian 2-digit GSTIN prefix mapping to state / UT name.
const Map<String, String> indianGstinStateMap = {
  '01': 'Jammu and Kashmir',
  '02': 'Himachal Pradesh',
  '03': 'Punjab',
  '04': 'Chandigarh',
  '05': 'Uttarakhand',
  '06': 'Haryana',
  '07': 'Delhi',
  '08': 'Rajasthan',
  '09': 'Uttar Pradesh',
  '10': 'Bihar',
  '11': 'Sikkim',
  '12': 'Arunachal Pradesh',
  '13': 'Nagaland',
  '14': 'Manipur',
  '15': 'Mizoram',
  '16': 'Tripura',
  '17': 'Meghalaya',
  '18': 'Assam',
  '19': 'West Bengal',
  '20': 'Jharkhand',
  '21': 'Odisha',
  '22': 'Chhattisgarh',
  '23': 'Madhya Pradesh',
  '24': 'Gujarat',
  '26': 'Dadra and Nagar Haveli and Daman and Diu',
  '27': 'Maharashtra',
  '28': 'Andhra Pradesh',
  '29': 'Karnataka',
  '30': 'Goa',
  '31': 'Lakshadweep',
  '32': 'Kerala',
  '33': 'Tamil Nadu',
  '34': 'Puducherry',
  '35': 'Andaman and Nicobar Islands',
  '36': 'Telangana',
  '37': 'Andhra Pradesh (New)',
  '38': 'Ladakh',
  '97': 'Other Territory',
  '99': 'Centre Jurisdiction',
};

/// Derive the Indian state from a GSTIN's first two digits.
String? deriveStateFromGstin(String? gstin) {
  if (gstin == null) return null;
  final trimmed = gstin.trim();
  if (trimmed.length < 2) return null;
  final prefix = trimmed.substring(0, 2);
  return indianGstinStateMap[prefix];
}

/// Represents an item input for GST calculation.
class GstLineInput {
  final double price; // unit price
  final double quantity; // qty
  final double itemDiscount; // per-line discount in ₹
  final double gstRate; // rate percentage e.g. 0, 5, 12, 18, 28
  final String? productName;
  final int? productId;

  const GstLineInput({
    required this.price,
    this.quantity = 1.0,
    this.itemDiscount = 0.0,
    this.gstRate = 0.0,
    this.productName,
    this.productId,
  });
}

/// Result of calculating GST for an individual line item.
class GstLineResult {
  final GstLineInput input;
  final double baseAmount; // price * qty - item discount
  final double billDiscountApportioned;
  final double taxableValue;
  final double gstRate;
  final double gstAmount; // total tax for this line
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double lineTotal;

  // Exact integer paise for zero-loss arithmetic
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int taxPaise;
  final int lineTotalPaise;

  const GstLineResult({
    required this.input,
    required this.baseAmount,
    required this.billDiscountApportioned,
    required this.taxableValue,
    required this.gstRate,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.lineTotal,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.taxPaise,
    required this.lineTotalPaise,
  });
}

/// Rate-wise GST breakup (e.g. for 5%, 12%, 18%).
class GstRateBreakup {
  final double rate; // overall rate, e.g. 5.0
  final double taxableValue;
  final double cgstRate; // rate / 2 e.g. 2.5
  final double sgstRate; // rate / 2 e.g. 2.5
  final double igstRate; // rate e.g. 5.0
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;

  const GstRateBreakup({
    required this.rate,
    required this.taxableValue,
    required this.cgstRate,
    required this.sgstRate,
    required this.igstRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
  });
}

/// Complete result of GST calculation across a bill or cart.
class GstCalculationResult {
  final List<GstLineResult> lineResults;
  final List<GstRateBreakup> rateBreakups;
  final double subtotal; // sum of (price * qty)
  final double itemDiscountTotal;
  final double billDiscountTotal;
  final double totalDiscount;
  final double taxableValue;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double totalTax;
  final double unroundedTotal;
  final double roundOff;
  final double grandTotal;
  final bool isInclusive;
  final bool isInterState;

  const GstCalculationResult({
    required this.lineResults,
    required this.rateBreakups,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.billDiscountTotal,
    required this.totalDiscount,
    required this.taxableValue,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.igstTotal,
    required this.totalTax,
    required this.unroundedTotal,
    required this.roundOff,
    required this.grandTotal,
    required this.isInclusive,
    required this.isInterState,
  });
}

double _paiseToRupees(int paise) {
  return double.parse((paise / 100.0).toStringAsFixed(2));
}

/// Pure GstCalculator providing exact integer-paise calculations.
class GstCalculator {
  /// Pure calculation method
  static GstCalculationResult calculate({
    required List<GstLineInput> items,
    double billDiscount = 0.0,
    bool isInclusive = false,
    bool isInterState = false,
    bool applyRoundOff = true,
  }) {
    // 1. Calculate raw base per line in integer paise
    // base = price * qty - item discount
    int subtotalPaise = 0;
    int itemDiscountPaise = 0;
    final lineBasePaiseList = <int>[];

    for (final item in items) {
      final lineRawPaise = (item.price * item.quantity * 100).round();
      final lineDiscPaise = (item.itemDiscount * 100).round().clamp(0, lineRawPaise);
      final lineBasePaise = lineRawPaise - lineDiscPaise;

      subtotalPaise += lineRawPaise;
      itemDiscountPaise += lineDiscPaise;
      lineBasePaiseList.add(lineBasePaise);
    }

    final totalBasePaise = lineBasePaiseList.fold(0, (a, b) => a + b);
    final requestedBillDiscountPaise = (billDiscount * 100).round();
    final actualBillDiscountPaise = requestedBillDiscountPaise.clamp(0, totalBasePaise);

    // 2. Apportion bill discount across lines proportionally BEFORE tax
    final billDiscountPerLinePaise = List<int>.filled(items.length, 0);
    if (totalBasePaise > 0 && actualBillDiscountPaise > 0) {
      int distributed = 0;
      for (int i = 0; i < items.length; i++) {
        final share = (actualBillDiscountPaise * lineBasePaiseList[i] / totalBasePaise).floor();
        billDiscountPerLinePaise[i] = share;
        distributed += share;
      }
      // Distribute any remainder (due to floor) 1 paise at a time to lines with largest base
      int remainder = actualBillDiscountPaise - distributed;
      int i = 0;
      while (remainder > 0 && i < items.length) {
        billDiscountPerLinePaise[i] += 1;
        remainder--;
        i++;
      }
    }

    // 3. Compute per-line taxable value and taxes
    final lineResults = <GstLineResult>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final basePaise = lineBasePaiseList[i];
      final apportionedDiscPaise = billDiscountPerLinePaise[i];
      final effectiveBasePaise = max(0, basePaise - apportionedDiscPaise);

      int taxablePaise;
      int taxPaise;

      if (item.gstRate <= 0.0) {
        taxablePaise = effectiveBasePaise;
        taxPaise = 0;
      } else if (isInclusive) {
        // Inclusive: taxable = base / (1 + rate/100), tax = base - taxable
        taxablePaise = (effectiveBasePaise / (1.0 + (item.gstRate / 100.0))).round();
        taxPaise = effectiveBasePaise - taxablePaise;
      } else {
        // Exclusive: taxable = base, tax = taxable * rate / 100
        taxablePaise = effectiveBasePaise;
        taxPaise = (taxablePaise * (item.gstRate / 100.0)).round();
      }

      int cgstPaise;
      int sgstPaise;
      int igstPaise;

      if (isInterState) {
        cgstPaise = 0;
        sgstPaise = 0;
        igstPaise = taxPaise;
      } else {
        // Intra-state: CGST = tax/2 and SGST = tax - CGST
        // Rounded in integer paise so CGST + SGST == taxPaise exactly
        cgstPaise = taxPaise ~/ 2;
        sgstPaise = taxPaise - cgstPaise;
        igstPaise = 0;
      }

      final lineTotalPaise = isInclusive
          ? effectiveBasePaise
          : (taxablePaise + taxPaise);

      lineResults.add(GstLineResult(
        input: item,
        baseAmount: _paiseToRupees(basePaise),
        billDiscountApportioned: _paiseToRupees(apportionedDiscPaise),
        taxableValue: _paiseToRupees(taxablePaise),
        gstRate: item.gstRate,
        gstAmount: _paiseToRupees(taxPaise),
        cgstAmount: _paiseToRupees(cgstPaise),
        sgstAmount: _paiseToRupees(sgstPaise),
        igstAmount: _paiseToRupees(igstPaise),
        lineTotal: _paiseToRupees(lineTotalPaise),
        taxablePaise: taxablePaise,
        cgstPaise: cgstPaise,
        sgstPaise: sgstPaise,
        igstPaise: igstPaise,
        taxPaise: taxPaise,
        lineTotalPaise: lineTotalPaise,
      ));
    }

    // 4. Rate-wise breakup groupings
    final rateMap = <double, List<GstLineResult>>{};
    for (final res in lineResults) {
      if (res.gstRate > 0) {
        rateMap.putIfAbsent(res.gstRate, () => []).add(res);
      }
    }

    final rateBreakups = <GstRateBreakup>[];
    final sortedRates = rateMap.keys.toList()..sort();
    for (final rate in sortedRates) {
      final list = rateMap[rate]!;
      int rTaxablePaise = 0;
      int rCgstPaise = 0;
      int rSgstPaise = 0;
      int rIgstPaise = 0;

      for (final r in list) {
        rTaxablePaise += r.taxablePaise;
        rCgstPaise += r.cgstPaise;
        rSgstPaise += r.sgstPaise;
        rIgstPaise += r.igstPaise;
      }

      rateBreakups.add(GstRateBreakup(
        rate: rate,
        taxableValue: _paiseToRupees(rTaxablePaise),
        cgstRate: rate / 2.0,
        sgstRate: rate / 2.0,
        igstRate: rate,
        cgstAmount: _paiseToRupees(rCgstPaise),
        sgstAmount: _paiseToRupees(rSgstPaise),
        igstAmount: _paiseToRupees(rIgstPaise),
        totalTax: _paiseToRupees(rCgstPaise + rSgstPaise + rIgstPaise),
      ));
    }

    // 5. Aggregate totals
    final totalTaxablePaise = lineResults.fold(0, (acc, l) => acc + l.taxablePaise);
    final totalCgstPaise = lineResults.fold(0, (acc, l) => acc + l.cgstPaise);
    final totalSgstPaise = lineResults.fold(0, (acc, l) => acc + l.sgstPaise);
    final totalIgstPaise = lineResults.fold(0, (acc, l) => acc + l.igstPaise);
    final totalTaxPaise = totalCgstPaise + totalSgstPaise + totalIgstPaise;

    int unroundedTotalPaise;
    if (isInclusive) {
      unroundedTotalPaise = totalBasePaise - actualBillDiscountPaise;
    } else {
      unroundedTotalPaise = totalTaxablePaise + totalTaxPaise;
    }

    int grandTotalPaise;
    int roundOffPaise;

    if (applyRoundOff) {
      grandTotalPaise = ((unroundedTotalPaise / 100.0).round()) * 100;
      roundOffPaise = grandTotalPaise - unroundedTotalPaise;
    } else {
      grandTotalPaise = unroundedTotalPaise;
      roundOffPaise = 0;
    }

    return GstCalculationResult(
      lineResults: lineResults,
      rateBreakups: rateBreakups,
      subtotal: _paiseToRupees(subtotalPaise),
      itemDiscountTotal: _paiseToRupees(itemDiscountPaise),
      billDiscountTotal: _paiseToRupees(actualBillDiscountPaise),
      totalDiscount: _paiseToRupees(itemDiscountPaise + actualBillDiscountPaise),
      taxableValue: _paiseToRupees(totalTaxablePaise),
      cgstTotal: _paiseToRupees(totalCgstPaise),
      sgstTotal: _paiseToRupees(totalSgstPaise),
      igstTotal: _paiseToRupees(totalIgstPaise),
      totalTax: _paiseToRupees(totalTaxPaise),
      unroundedTotal: _paiseToRupees(unroundedTotalPaise),
      roundOff: _paiseToRupees(roundOffPaise),
      grandTotal: _paiseToRupees(grandTotalPaise),
      isInclusive: isInclusive,
      isInterState: isInterState,
    );
  }
}
