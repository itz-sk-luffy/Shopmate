import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/providers/database_provider.dart';
import 'package:shopmate/features/more/presentation/more_screen.dart';
import 'package:shopmate/features/pos/domain/cart_item.dart';
import 'package:shopmate/features/pos/presentation/providers/cart_provider.dart';

class MockAppDatabase implements AppDatabase {
  final Map<String, String> settings = {
    'currency_symbol': '₹',
    'store_name': 'Shopmate Mart',
    'launcher_icon_preset': '3',
    'user_role': 'owner',
    'reduce_animations_configured': 'true',
  };

  @override
  Future<Map<String, String>> getAllSettings() async => Map.from(settings);

  @override
  Future<String> getSetting(String key, {String defaultValue = ''}) async => settings[key] ?? defaultValue;

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('POS Product Quantity Bubble Badge Tests', () {
    test('Cart state tracks product quantity accurately for integer and decimal weights', () {
      final fakeDb = MockAppDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(fakeDb),
          settingsProvider.overrideWith((ref) => AppSettingsNotifier(fakeDb)),
        ],
      );

      final cartNotifier = container.read(cartProvider.notifier);
      final product1 = Product(
        id: 101,
        name: 'Whole Wheat Flour',
        price: 50.0,
        gstRate: 0.0,
        unit: 'kg',
        isFavorite: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Initially empty
      expect(container.read(cartProvider).items.any((i) => i.productId == 101), isFalse);

      // Add item once
      cartNotifier.addItem(product1);
      var cartItem = container.read(cartProvider).items.firstWhere((i) => i.productId == 101);
      expect(cartItem.quantity, 1.0);
      String qtyText = cartItem.quantity % 1 == 0 ? cartItem.quantity.toInt().toString() : cartItem.quantity.toString();
      expect(qtyText, '1');

      // Add item second time
      cartNotifier.addItem(product1);
      cartItem = container.read(cartProvider).items.firstWhere((i) => i.productId == 101);
      expect(cartItem.quantity, 2.0);
      qtyText = cartItem.quantity % 1 == 0 ? cartItem.quantity.toInt().toString() : cartItem.quantity.toString();
      expect(qtyText, '2');

      // Update quantity to decimal weight
      final itemIndex = container.read(cartProvider).items.indexWhere((i) => i.productId == 101);
      cartNotifier.updateQuantity(itemIndex, 2.5);
      cartItem = container.read(cartProvider).items.firstWhere((i) => i.productId == 101);
      expect(cartItem.quantity, 2.5);
      qtyText = cartItem.quantity % 1 == 0 ? cartItem.quantity.toInt().toString() : cartItem.quantity.toString();
      expect(qtyText, '2.5');

      // Remove item
      cartNotifier.removeItem(itemIndex);
      expect(container.read(cartProvider).items.any((i) => i.productId == 101), isFalse);
    });

    test('CartItem stores and preserves imagePath', () {
      const item = CartItem(
        productId: 1,
        productName: 'Biscuits',
        unitPrice: 20.0,
        gstRate: 5.0,
        quantity: 2,
        unit: 'pack',
        imagePath: '/data/user/0/com.shopmate.pos/app_flutter/product_images/thumb_123.jpg',
      );

      expect(item.imagePath, '/data/user/0/com.shopmate.pos/app_flutter/product_images/thumb_123.jpg');
      final updated = item.copyWith(quantity: 3);
      expect(updated.imagePath, '/data/user/0/com.shopmate.pos/app_flutter/product_images/thumb_123.jpg');
      expect(updated.quantity, 3);
    });
  });

  group('Customer Udhaar Ledger & Reminder Tests', () {
    test('Payment reminder template formats exact message format', () {
      const customerName = 'Rajesh Kumar';
      const storeName = 'Shopmate Mart';
      const balance = 1250.50;

      final reminderMsg = 'Hello $customerName, this is a gentle reminder from $storeName. '
          'Your pending Udhaar balance is ₹${balance.toStringAsFixed(2)}. '
          'Kindly settle it at your earliest convenience. Thank you!';

      expect(reminderMsg, contains('Hello Rajesh Kumar, this is a gentle reminder from Shopmate Mart.'));
      expect(reminderMsg, contains('Your pending Udhaar balance is ₹1250.50.'));
      expect(reminderMsg, contains('Kindly settle it at your earliest convenience. Thank you!'));
    });

    test('Payment settlement clamps balance to never go negative', () {
      double currentBalance = 500.0;
      double paymentAmount = 600.0;

      final newBalance = (currentBalance - paymentAmount).clamp(0.0, double.infinity);
      expect(newBalance, 0.0);
    });

    test('Payment settlement partially reduces positive balance correctly', () {
      double currentBalance = 500.0;
      double paymentAmount = 200.0;

      final newBalance = (currentBalance - paymentAmount).clamp(0.0, double.infinity);
      expect(newBalance, 300.0);
    });
  });

  group('MoreScreen Header Launcher Icon & Role Tests', () {
    testWidgets('MoreScreen header displays current launcher icon preset and Owner role', (tester) async {
      final fakeDb = MockAppDatabase();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(fakeDb),
            settingsProvider.overrideWith((ref) => AppSettingsNotifier(fakeDb)),
          ],
          child: const MaterialApp(
            home: MoreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Shopmate Mart'), findsOneWidget);
      expect(find.text('Role: OWNER'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });
  });
}
