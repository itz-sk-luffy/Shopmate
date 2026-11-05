import 'dart:math';
import '../../../core/database/app_database.dart';
import '../../../core/utils/gst_calculator.dart';
import 'cart_item.dart';

class CartState {
  final List<CartItem> items;
  final Customer? selectedCustomer;
  final String paymentMode; // 'Cash', 'UPI', 'Card', 'Credit', 'Split'
  final double cashTendered;
  final double digitalAmount;
  final double billDiscountPercent;
  final double billDiscountAmount;
  final bool isBillDiscountPercent;
  final String gstType; // 'exclusive', 'inclusive', 'none'
  final bool isInterState;
  final String? storeState;
  final String? customerState;
  final String? notes;
  final int? heldBillId;
  final int? editingBillId;

  const CartState({
    this.items = const [],
    this.selectedCustomer,
    this.paymentMode = 'Cash',
    this.cashTendered = 0.0,
    this.digitalAmount = 0.0,
    this.billDiscountPercent = 0.0,
    this.billDiscountAmount = 0.0,
    this.isBillDiscountPercent = false,
    this.gstType = 'exclusive',
    this.isInterState = false,
    this.storeState,
    this.customerState,
    this.notes,
    this.heldBillId,
    this.editingBillId,
  });

  int get itemCount => items.length;

  double get totalUnits => items.fold(0.0, (acc, item) => acc + item.quantity);

  GstCalculationResult get gstResult {
    final lineInputs = items.map((i) => GstLineInput(
      price: i.unitPrice,
      quantity: i.quantity,
      itemDiscount: i.discountAmount,
      gstRate: gstType == 'none' ? 0.0 : i.gstRate,
      productName: i.productName,
      productId: i.productId,
    )).toList();

    final rawSub = items.fold(0.0, (acc, item) => acc + item.subtotal);
    final itemDisc = items.fold(0.0, (acc, item) => acc + item.discountAmount);
    final netBeforeBill = max(0.0, rawSub - itemDisc);

    final billDisc = isBillDiscountPercent
        ? netBeforeBill * (billDiscountPercent / 100.0)
        : billDiscountAmount;

    return GstCalculator.calculate(
      items: lineInputs,
      billDiscount: billDisc,
      isInclusive: gstType == 'inclusive',
      isInterState: isInterState,
      applyRoundOff: true,
    );
  }

  double get rawSubtotal => gstResult.subtotal;

  double get itemsDiscountTotal => gstResult.itemDiscountTotal;

  double get netBeforeBillDiscount =>
      max(0.0, rawSubtotal - itemsDiscountTotal);

  double get billDiscountTotal => gstResult.billDiscountTotal;

  double get taxableAmount => gstResult.taxableValue;

  double get totalGst => gstResult.totalTax;

  double get cgstTotal => gstResult.cgstTotal;

  double get sgstTotal => gstResult.sgstTotal;

  double get igstTotal => gstResult.igstTotal;

  List<GstRateBreakup> get rateBreakups => gstResult.rateBreakups;

  double get unroundedTotal => gstResult.unroundedTotal;

  double get roundOff => gstResult.roundOff;

  double get grandTotal => gstResult.grandTotal;

  double get changeDue {
    if (paymentMode == 'Cash') {
      return max(0.0, cashTendered - grandTotal);
    }
    return 0.0;
  }

  double get balanceDue {
    if (paymentMode == 'Split') {
      return max(0.0, grandTotal - (cashTendered + digitalAmount));
    } else if (paymentMode == 'Cash') {
      return max(0.0, grandTotal - cashTendered);
    }
    return 0.0;
  }

  CartState copyWith({
    List<CartItem>? items,
    Customer? selectedCustomer,
    bool clearCustomer = false,
    String? paymentMode,
    double? cashTendered,
    double? digitalAmount,
    double? billDiscountPercent,
    double? billDiscountAmount,
    bool? isBillDiscountPercent,
    String? gstType,
    bool? isInterState,
    String? storeState,
    String? customerState,
    String? notes,
    int? heldBillId,
    bool clearHeldBillId = false,
    int? editingBillId,
    bool clearEditingBillId = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedCustomer:
          clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      paymentMode: paymentMode ?? this.paymentMode,
      cashTendered: cashTendered ?? this.cashTendered,
      digitalAmount: digitalAmount ?? this.digitalAmount,
      billDiscountPercent: billDiscountPercent ?? this.billDiscountPercent,
      billDiscountAmount: billDiscountAmount ?? this.billDiscountAmount,
      isBillDiscountPercent:
          isBillDiscountPercent ?? this.isBillDiscountPercent,
      gstType: gstType ?? this.gstType,
      isInterState: isInterState ?? this.isInterState,
      storeState: storeState ?? this.storeState,
      customerState: customerState ?? this.customerState,
      notes: notes ?? this.notes,
      heldBillId:
          clearHeldBillId ? null : (heldBillId ?? this.heldBillId),
      editingBillId:
          clearEditingBillId ? null : (editingBillId ?? this.editingBillId),
    );
  }
}
