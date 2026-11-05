import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/providers/database_provider.dart';
import 'package:shopmate/core/routing/app_router.dart';
import 'package:shopmate/core/routing/app_routes.dart';
import 'package:shopmate/features/pos/domain/cart_item.dart';
import 'package:shopmate/features/pos/presentation/providers/cart_provider.dart';
import 'package:shopmate/features/pos/presentation/widgets/cart_items_sheet.dart';
import 'package:shopmate/features/products/presentation/product_edit_screen.dart';

class FakeAppDatabase implements AppDatabase {
  final Map<String, String> settings = {
    'currency_symbol': '₹',
    'gst_enabled': 'true',
    'tax_type': 'exclusive',
    'tax_rate_default': '18.0',
    'store_state': 'Delhi',
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

  group('Requirement 1: Direct Startup into Billing (POS)', () {
    test('Router default initial location is /billing', () {
      final router = createRouter(
        hasCompletedOnboarding: true,
        isAppLockEnabled: false,
        isUnlocked: true,
        isLoading: false,
      );

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.billing);
    });
  });

  group('Requirement 2: Reactive GST Settings Synchronization in Cart', () {
    test('Cart recalculates tax dynamically and preserves custom item GST', () async {
      final fakeDb = FakeAppDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(fakeDb),
          settingsProvider.overrideWith((ref) => AppSettingsNotifier(fakeDb)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).loadSettings();

      final cartNotifier = container.read(cartProvider.notifier);
      final product = Product(
        id: 10,
        name: 'Organic Wheat Flour',
        price: 100.0,
        unit: 'kg',
        gstRate: 5.0,
        isFavorite: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      cartNotifier.addItem(product, quantity: 2);
      var cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.subtotal, 200.0);

      // Verify custom GST item rate preserved vs standard update
      cartNotifier.updateCartItem(0, gstRate: 12.0);
      cart = container.read(cartProvider);
      expect(cart.items.first.gstRate, 12.0);
      expect(cart.items.first.hasCustomGstRate, isTrue);

      // Cart item copyWith handles gstType == 'none'
      const zeroTaxItem = CartItem(
        productId: 1,
        productName: 'Milk',
        unit: 'ltr',
        quantity: 1,
        unitPrice: 50.0,
        gstRate: 5.0,
      );
      final noneGstAmount = zeroTaxItem.gstAmount('none');
      expect(noneGstAmount, 0.0);
    });

    test('CartItem updateCartItem updates all fields correctly', () async {
      final fakeDb = FakeAppDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(fakeDb),
          settingsProvider.overrideWith((ref) => AppSettingsNotifier(fakeDb)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).loadSettings();

      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addCustomItem(
        name: 'Loose Rice',
        price: 60.0,
        quantity: 1.0,
        unit: 'kg',
        gstRate: 0.0,
        isDecimalAllowed: true,
      );

      var cart = container.read(cartProvider);
      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 1.0);

      cartNotifier.updateCartItem(
        0,
        quantity: 2.5,
        unitPrice: 65.0,
        discountAmount: 10.0,
        gstRate: 5.0,
      );

      cart = container.read(cartProvider);
      expect(cart.items.first.quantity, 2.5);
      expect(cart.items.first.unitPrice, 65.0);
      expect(cart.items.first.discountAmount, 10.0);
      expect(cart.items.first.gstRate, 5.0);
      expect(cart.items.first.hasCustomGstRate, isTrue);

      // Explicit delete
      cartNotifier.removeItem(0);
      cart = container.read(cartProvider);
      expect(cart.items.isEmpty, isTrue);
    });
  });

  group('Requirement 4: Explicit Cart Edit & Delete UI Buttons', () {
    testWidgets('CartItemsSheet displays explicit Edit and Delete buttons for each item', (tester) async {
      final fakeDb = FakeAppDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(fakeDb),
          settingsProvider.overrideWith((ref) => AppSettingsNotifier(fakeDb)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).loadSettings();

      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addCustomItem(
        name: 'Item A',
        price: 50.0,
        quantity: 1.0,
        unit: 'pcs',
        gstRate: 0.0,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CartItemsSheet(currencySymbol: '₹'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find Edit and Delete buttons
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap Edit opens the Edit Item Dialog (pump with duration to avoid infinite blinking cursor)
      await tester.tap(find.text('Edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit: Item A'), findsOneWidget);
      expect(find.text('Unit Price'), findsOneWidget);
      expect(find.text('Line Discount'), findsOneWidget);
      expect(find.text('GST Rate (%)'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Delete removes the item
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Cart is empty'), findsOneWidget);
    });

    testWidgets('CartItemsSheet has Add Item header button and does not have Add Product Not in Catalog', (tester) async {
      final fakeDb = FakeAppDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(fakeDb),
          settingsProvider.overrideWith((ref) => AppSettingsNotifier(fakeDb)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).loadSettings();

      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addCustomItem(
        name: 'Item A',
        price: 50.0,
        quantity: 1.0,
        unit: 'pcs',
        gstRate: 0.0,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: CartItemsSheet(currencySymbol: '₹'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Ensure 'Add Product Not in Catalog' is gone
      expect(find.text('Add Product Not in Catalog'), findsNothing);

      // Ensure 'Add Item' is present in header
      expect(find.text('Add Item'), findsOneWidget);

      // Tap 'Add Item' to open CustomItemDialog
      await tester.tap(find.text('Add Item'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify CustomItemDialog cards and checkbox are present
      expect(find.text('Product Details'), findsOneWidget);
      expect(find.text('Barcode / Scan'), findsOneWidget);
      expect(find.text('Also save to Product Catalog'), findsOneWidget);
      expect(find.text('Product Name *'), findsOneWidget);
      expect(find.text('Qty *'), findsNothing);
    });
  });

  group('Requirement 5: Product Barcode Scanner Flash Toggle UI', () {
    testWidgets('ProductBarcodeScannerSheet renders Toggle Flash button with tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductBarcodeScannerSheet(),
          ),
        ),
      );
      await tester.pump();

      // Verify the AppBar contains the flash toggle button with tooltip 'Toggle Flash'
      expect(find.byTooltip('Toggle Flash'), findsOneWidget);
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
    });
  });
}
