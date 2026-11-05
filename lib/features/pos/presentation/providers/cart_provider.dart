import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../domain/cart_item.dart';
import '../../domain/cart_state.dart';

class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;

  CartNotifier(this._ref) : super(const CartState()) {
    _syncSettings(_ref.read(settingsProvider));
    _ref.listen<AppSettingsState>(settingsProvider, (previous, next) {
      _syncSettings(next);
    });
  }

  void _syncSettings(AppSettingsState settings) {
    final newGstType = settings.gstEnabled ? settings.taxType : 'none';

    final updatedItems = state.items.map((item) {
      if (item.hasCustomGstRate) return item;
      final effectiveRate = !settings.gstEnabled
          ? 0.0
          : (item.originalProductGstRate > 0
              ? item.originalProductGstRate
              : settings.taxRateDefault);
      return item.copyWith(gstRate: effectiveRate);
    }).toList();

    state = state.copyWith(
      items: updatedItems,
      gstType: newGstType,
      storeState: settings.storeState,
    );
  }

  void addItem(Product product, {double quantity = 1.0}) {
    final existingIndex =
        state.items.indexWhere((item) => item.productId == product.id);

    final settings = _ref.read(settingsProvider);
    final effectiveGstRate = !settings.gstEnabled
        ? 0.0
        : (product.gstRate > 0 ? product.gstRate : settings.taxRateDefault);

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      updateQuantity(existingIndex, newQuantity);
    } else {
      final newItem = CartItem(
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        isDecimalAllowed: product.unit == 'kg' ||
            product.unit == 'ltr' ||
            product.unit == 'gm' ||
            product.unit == 'ml',
        quantity: quantity,
        unitPrice: product.price,
        gstRate: effectiveGstRate,
        hasCustomGstRate: false,
        originalProductGstRate: product.gstRate,
        imagePath: product.imagePath,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void addCustomItem({
    required String name,
    required double price,
    required double quantity,
    required String unit,
    required double gstRate,
    bool isDecimalAllowed = false,
  }) {
    final settings = _ref.read(settingsProvider);
    final effectiveRate = !settings.gstEnabled
        ? 0.0
        : (gstRate > 0 ? gstRate : settings.taxRateDefault);

    final newItem = CartItem(
      productId: null,
      productName: name,
      unit: unit,
      isDecimalAllowed: isDecimalAllowed,
      quantity: quantity,
      unitPrice: price,
      gstRate: effectiveRate,
      hasCustomGstRate: gstRate > 0,
      originalProductGstRate: gstRate,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateQuantity(int index, double newQuantity) {
    if (index < 0 || index >= state.items.length) return;
    if (newQuantity <= 0.0001) {
      removeItem(index);
      return;
    }
    final updatedList = List<CartItem>.from(state.items);
    updatedList[index] = updatedList[index].copyWith(quantity: newQuantity);
    state = state.copyWith(items: updatedList);
  }

  void updateCartItem(
    int index, {
    double? quantity,
    double? unitPrice,
    double? discountAmount,
    double? gstRate,
  }) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    final newQty = quantity ?? item.quantity;
    if (newQty <= 0.0001) {
      removeItem(index);
      return;
    }
    final updatedList = List<CartItem>.from(state.items);
    updatedList[index] = item.copyWith(
      quantity: newQty,
      unitPrice: unitPrice ?? item.unitPrice,
      discountAmount: discountAmount != null
          ? (discountAmount < 0 ? 0.0 : discountAmount)
          : item.discountAmount,
      gstRate: gstRate ?? item.gstRate,
      hasCustomGstRate: gstRate != null ? true : item.hasCustomGstRate,
    );
    state = state.copyWith(items: updatedList);
  }

  void incrementQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    final delta = item.isDecimalAllowed ? 0.25 : 1.0;
    updateQuantity(index, item.quantity + delta);
  }

  void decrementQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    final delta = item.isDecimalAllowed ? 0.25 : 1.0;
    updateQuantity(index, item.quantity - delta);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updatedList = List<CartItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: updatedList);
  }

  void setItemDiscount(int index, double discountAmount) {
    if (index < 0 || index >= state.items.length) return;
    final updatedList = List<CartItem>.from(state.items);
    updatedList[index] = updatedList[index].copyWith(
      discountAmount: discountAmount < 0 ? 0.0 : discountAmount,
    );
    state = state.copyWith(items: updatedList);
  }

  void setCustomer(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(selectedCustomer: customer);
    }
  }

  void setPaymentMode(String mode) {
    state = state.copyWith(paymentMode: mode);
  }

  void setCashTendered(double amount) {
    state = state.copyWith(cashTendered: amount < 0 ? 0.0 : amount);
  }

  void setDigitalAmount(double amount) {
    state = state.copyWith(digitalAmount: amount < 0 ? 0.0 : amount);
  }

  void setBillDiscountPercent(double percent) {
    state = state.copyWith(
      billDiscountPercent: percent.clamp(0.0, 100.0),
      isBillDiscountPercent: true,
      billDiscountAmount: 0.0,
    );
  }

  void setBillDiscountAmount(double amount) {
    state = state.copyWith(
      billDiscountAmount: amount < 0 ? 0.0 : amount,
      isBillDiscountPercent: false,
      billDiscountPercent: 0.0,
    );
  }

  void clearBillDiscount() {
    state = state.copyWith(
      billDiscountAmount: 0.0,
      billDiscountPercent: 0.0,
      isBillDiscountPercent: false,
    );
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void clearCart() {
    final settings = _ref.read(settingsProvider);
    state = CartState(
      gstType: settings.gstEnabled ? settings.taxType : 'none',
      storeState: settings.storeState,
    );
  }

  void loadFromHeldBill({
    required List<CartItem> items,
    Customer? customer,
    required int heldBillId,
    String? notes,
    double billDiscountPercent = 0.0,
    double billDiscountAmount = 0.0,
    bool isBillDiscountPercent = false,
  }) {
    final settings = _ref.read(settingsProvider);
    state = CartState(
      items: items,
      selectedCustomer: customer,
      heldBillId: heldBillId,
      notes: notes,
      billDiscountPercent: billDiscountPercent,
      billDiscountAmount: billDiscountAmount,
      isBillDiscountPercent: isBillDiscountPercent,
      gstType: settings.gstEnabled ? settings.taxType : 'none',
      storeState: settings.storeState,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
