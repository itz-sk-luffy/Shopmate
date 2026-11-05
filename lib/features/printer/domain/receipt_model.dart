import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/formatters.dart';

class ReceiptTaxLine {
  final String label;
  final double amount;

  const ReceiptTaxLine({
    required this.label,
    required this.amount,
  });
}

class ReceiptItemModel {
  final String productName;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double totalAmount;
  final double gstRate;

  const ReceiptItemModel({
    required this.productName,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.totalAmount,
    this.gstRate = 0.0,
  });
}

class ReceiptModel {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeGstin;
  final String storeFooter;
  final String billNumber;
  final DateTime date;
  final String dateFormatted;
  final String timeFormatted;
  final String paymentMode;
  final String? customerName;
  final String? customerPhone;
  final List<ReceiptItemModel> items;
  final double subtotal;
  final double itemDiscountTotal;
  final double billDiscountAmount;
  final List<ReceiptTaxLine> taxLines;
  final double roundOff;
  final double grandTotal;
  final double cashAmount;
  final double changeTendered;
  final String currencySymbol;
  final int printCutFeed;
  final bool printBillBarcode;

  const ReceiptModel({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.storeGstin,
    required this.storeFooter,
    required this.billNumber,
    required this.date,
    required this.dateFormatted,
    required this.timeFormatted,
    required this.paymentMode,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.billDiscountAmount,
    required this.taxLines,
    required this.roundOff,
    required this.grandTotal,
    required this.cashAmount,
    required this.changeTendered,
    required this.currencySymbol,
    required this.printCutFeed,
    this.printBillBarcode = false,
  });

  factory ReceiptModel.fromBill({
    required Bill bill,
    required List<BillItem> items,
    required AppSettingsState settings,
  }) {
    final taxLines = <ReceiptTaxLine>[];
    if (settings.gstEnabled && settings.receiptShowGst && bill.gstType != 'none' && (bill.cgstTotal > 0 || bill.sgstTotal > 0 || bill.igstTotal > 0)) {
      if (bill.igstTotal > 0) {
        final rateMap = <double, double>{};
        for (final item in items) {
          if (item.gstRate > 0) {
            rateMap[item.gstRate] = (rateMap[item.gstRate] ?? 0.0) + item.igstAmount;
          }
        }
        if (rateMap.isEmpty) {
          taxLines.add(ReceiptTaxLine(label: 'IGST', amount: bill.igstTotal));
        } else {
          for (final r in (rateMap.keys.toList()..sort())) {
            final rateStr = r.toStringAsFixed(r.truncateToDouble() == r ? 0 : 1);
            taxLines.add(ReceiptTaxLine(label: 'IGST $rateStr%', amount: rateMap[r]!));
          }
        }
      } else {
        final cgstMap = <double, double>{};
        final sgstMap = <double, double>{};
        for (final item in items) {
          if (item.gstRate > 0) {
            cgstMap[item.gstRate] = (cgstMap[item.gstRate] ?? 0.0) + item.cgstAmount;
            sgstMap[item.gstRate] = (sgstMap[item.gstRate] ?? 0.0) + item.sgstAmount;
          }
        }
        if (cgstMap.isEmpty) {
          taxLines.add(ReceiptTaxLine(label: 'CGST', amount: bill.cgstTotal));
          taxLines.add(ReceiptTaxLine(label: 'SGST', amount: bill.sgstTotal));
        } else {
          for (final r in (cgstMap.keys.toList()..sort())) {
            final half = r / 2.0;
            final rateStr = half.toStringAsFixed(half.truncateToDouble() == half ? 0 : 1);
            final cgstVal = cgstMap[r] ?? 0.0;
            final sgstVal = sgstMap[r] ?? 0.0;
            taxLines.add(ReceiptTaxLine(
              label: 'CGST $rateStr%',
              amount: cgstVal > 0 ? cgstVal : bill.cgstTotal / cgstMap.length,
            ));
            taxLines.add(ReceiptTaxLine(
              label: 'SGST $rateStr%',
              amount: sgstVal > 0 ? sgstVal : bill.sgstTotal / sgstMap.length,
            ));
          }
        }
      }
    }

    final itemModels = items.map((i) => ReceiptItemModel(
      productName: i.productName,
      quantity: i.quantity,
      unit: i.unit,
      unitPrice: i.unitPrice,
      totalAmount: i.totalAmount,
      gstRate: i.gstRate,
    )).toList();

    return ReceiptModel(
      storeName: settings.storeName,
      storeAddress: settings.storeAddress,
      storePhone: settings.storePhone,
      storeGstin: (settings.receiptShowGst && settings.storeGstin.isNotEmpty) ? settings.storeGstin : '',
      storeFooter: (settings.receiptShowFooter && settings.storeFooter.isNotEmpty) ? settings.storeFooter : '',
      billNumber: bill.billNumber,
      date: bill.date,
      dateFormatted: Formatters.date(bill.date),
      timeFormatted: Formatters.time(bill.date),
      paymentMode: bill.paymentMode,
      customerName: (settings.receiptShowCustomer && bill.customerName != null && bill.customerName!.isNotEmpty)
          ? bill.customerName
          : null,
      customerPhone: (settings.receiptShowCustomer && bill.customerPhone != null && bill.customerPhone!.isNotEmpty)
          ? bill.customerPhone
          : null,
      items: itemModels,
      subtotal: bill.subtotal,
      itemDiscountTotal: bill.itemDiscountTotal,
      billDiscountAmount: bill.billDiscountAmount,
      taxLines: taxLines,
      roundOff: bill.roundOff,
      grandTotal: bill.grandTotal,
      cashAmount: bill.cashAmount,
      changeTendered: bill.changeTendered,
      currencySymbol: settings.receiptCurrencySymbol,
      printCutFeed: settings.printCutFeed,
      printBillBarcode: settings.printBillBarcode,
    );
  }
}

