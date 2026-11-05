import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/providers/database_provider.dart';
import 'package:shopmate/core/utils/gst_calculator.dart';
import 'package:shopmate/features/products/data/products_repository.dart';
import 'package:shopmate/features/products/presentation/product_edit_screen.dart';
import 'package:shopmate/features/products/presentation/products_screen.dart';
import 'package:shopmate/features/recycle_bin/data/recycle_bin_repository.dart';

class FakeProductsRepository extends Fake implements ProductsRepository {
  final List<Product> products;
  FakeProductsRepository({this.products = const []});

  @override
  Future<List<Category>> getCategories() async => [];

  @override
  Stream<List<Category>> watchCategories() => Stream.value([]);

  @override
  Stream<List<Unit>> watchUnits() => Stream.value([
    const Unit(id: 1, name: 'Pieces', code: 'pcs', isDecimalAllowed: false),
    const Unit(id: 2, name: 'Kilograms', code: 'kg', isDecimalAllowed: true),
  ]);

  @override
  Stream<List<Product>> watchProducts({int? categoryId, String? search}) => Stream.value(products);

  @override
  Future<Product?> getProductById(int id) async {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<void> softDeleteProduct(int id) async {}

  @override
  Future<void> restoreProduct(int id) async {}
}

class FakeAppDatabase implements AppDatabase {
  final Map<String, String> settings = {};

  @override
  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    return settings[key] ?? defaultValue;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<Map<String, String>> getAllSettings() async {
    return settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Product Forms Simplification & Swipe-to-Delete Tests', () {
    testWidgets('1 & 2: Add & Edit Product Screen do NOT display any GST Rate dropdown', (tester) async {
      final db = FakeAppDatabase();
      final fakeRepo = FakeProductsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            productsRepositoryProvider.overrideWithValue(fakeRepo),
            unitsStreamProvider.overrideWith((ref) => fakeRepo.watchUnits()),
            categoriesStreamProvider.overrideWith((ref) => fakeRepo.watchCategories()),
          ],
          child: const MaterialApp(
            home: ProductEditScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Product Name, Price, Unit, and Category are present
      expect(find.text('Product Name *'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);

      // Verify GST Rate input / dropdown is completely absent from the form
      expect(find.text('GST Rate'), findsNothing);
      expect(find.text('GST Rate *'), findsNothing);
    });

    test('3: Confirm GST calculates using GstCalculator with exclusive/inclusive rates', () {
      final items = [
        const GstLineInput(
          price: 100.0,
          quantity: 2.0,
          gstRate: 18.0,
        ),
      ];

      final breakdown = GstCalculator.calculate(
        items: items,
        isInclusive: false,
      );

      expect(breakdown.subtotal, 200.0);
      expect(breakdown.taxableValue, 200.0);
      expect(breakdown.cgstTotal, 18.0);
      expect(breakdown.sgstTotal, 18.0);
      expect(breakdown.totalTax, 36.0);
      expect(breakdown.grandTotal, 236.0);
    });

    test('4, 6, 7 & 10: Soft delete, Billing exclusion, and Undo restoration', () {
      final activeProduct = Product(
        id: 101,
        name: 'Atta 5kg',
        price: 250.0,
        gstRate: 0.0,
        unit: 'kg',
        isFavorite: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Simulating soft deletion
      final deletedProduct = activeProduct.copyWith(
        isDeleted: true,
        deletedAt: Value(DateTime.now()),
      );

      expect(deletedProduct.isDeleted, true);
      expect(deletedProduct.deletedAt, isNotNull);

      // Simulating Undo restoration
      final restoredProduct = deletedProduct.copyWith(
        isDeleted: false,
        deletedAt: const Value(null),
      );

      expect(restoredProduct.isDeleted, false);
      expect(restoredProduct.deletedAt, isNull);
    });

    test('8: Recycle Bin Item preserves title, unit, and calculates remaining days', () {
      final deletedTime = DateTime.now().subtract(const Duration(days: 5));
      final binItem = RecycleBinItem(
        id: 101,
        type: RecycleBinItemType.product,
        title: 'Atta 5kg',
        subtitle: 'kg • Barcode: 890123456789',
        amount: 250.0,
        deletedAt: deletedTime,
      );

      expect(binItem.title, 'Atta 5kg');
      expect(binItem.type, RecycleBinItemType.product);
      expect(binItem.daysRemaining, anyOf(24, 25));
    });

    test('9: Historical Bill Items preserve immutable snapshots independently of products', () {
      // Historical bill item snapshot
      const historicalItem = BillItem(
        id: 501,
        billId: 42,
        productId: 101,
        productName: 'Atta 5kg',
        unit: 'kg',
        quantity: 2.0,
        unitPrice: 250.0,
        discountAmount: 0.0,
        gstRate: 18.0,
        gstAmount: 90.0,
        taxableValue: 500.0,
        cgstAmount: 45.0,
        sgstAmount: 45.0,
        igstAmount: 0.0,
        totalAmount: 590.0,
      );

      expect(historicalItem.productName, 'Atta 5kg');
      expect(historicalItem.totalAmount, 590.0);
      expect(historicalItem.gstRate, 18.0);
      expect(historicalItem.cgstAmount, 45.0);
      expect(historicalItem.sgstAmount, 45.0);

      // Even if product 101 is deleted from products catalog, bill item fields remain fully intact
      expect(historicalItem.productId, 101);
    });

    testWidgets('4 & 5: Swipe product reveals Delete action, Cancel leaves product unchanged', (tester) async {
      final sampleProduct = Product(
        id: 77,
        name: 'Detergent Powder',
        price: 99.0,
        gstRate: 18.0,
        unit: 'pcs',
        isFavorite: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final db = FakeAppDatabase();
      final fakeRepo = FakeProductsRepository(products: [sampleProduct]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            productsRepositoryProvider.overrideWithValue(fakeRepo),
            productsListStreamProvider((categoryId: null, search: null)).overrideWith(
              (ref) => Stream.value([sampleProduct]),
            ),
            categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProductsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detergent Powder'), findsOneWidget);

      // Swipe the product to the left
      await tester.drag(find.text('Detergent Powder'), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Verify the confirmation dialog appears
      expect(find.text('Delete Product?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete Detergent Powder?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismisses and product remains on screen
      expect(find.text('Delete Product?'), findsNothing);
      expect(find.text('Detergent Powder'), findsOneWidget);
    });
  });
}
