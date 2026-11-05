class CartItem {
  final int? productId;
  final String productName;
  final String unit;
  final bool isDecimalAllowed;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double gstRate;
  final bool hasCustomGstRate;
  final double originalProductGstRate;
  final String? imagePath;

  const CartItem({
    this.productId,
    required this.productName,
    this.unit = 'pcs',
    this.isDecimalAllowed = false,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0.0,
    this.gstRate = 0.0,
    this.hasCustomGstRate = false,
    this.originalProductGstRate = 0.0,
    this.imagePath,
  });

  double get subtotal => quantity * unitPrice;

  double get discountedSubtotal {
    final net = subtotal - discountAmount;
    return net > 0 ? net : 0.0;
  }

  double gstAmount(String gstType) {
    if (gstRate <= 0 || gstType == 'none') return 0.0;
    if (gstType == 'exclusive') {
      return discountedSubtotal * (gstRate / 100.0);
    } else if (gstType == 'inclusive') {
      return discountedSubtotal - (discountedSubtotal / (1.0 + (gstRate / 100.0)));
    }
    return 0.0;
  }

  double totalAmount(String gstType) {
    if (gstType == 'exclusive') {
      return discountedSubtotal + gstAmount(gstType);
    }
    return discountedSubtotal;
  }

  CartItem copyWith({
    int? productId,
    String? productName,
    String? unit,
    bool? isDecimalAllowed,
    double? quantity,
    double? unitPrice,
    double? discountAmount,
    double? gstRate,
    bool? hasCustomGstRate,
    double? originalProductGstRate,
    String? imagePath,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      isDecimalAllowed: isDecimalAllowed ?? this.isDecimalAllowed,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      gstRate: gstRate ?? this.gstRate,
      hasCustomGstRate: hasCustomGstRate ?? this.hasCustomGstRate,
      originalProductGstRate: originalProductGstRate ?? this.originalProductGstRate,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
