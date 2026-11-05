import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/utils/image_helper.dart';
import 'package:shopmate/features/products/data/products_repository.dart';
import 'package:shopmate/features/pos/presentation/widgets/sale_complete_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bug 1: Barcode Queue Item Model Tests', () {
    test('BarcodeQueueItem identifies items without barcodes', () {
      final prod1 = Product(
        id: 1,
        name: 'Sugar 1kg',
        price: 45.0,
        gstRate: 0.0,
        unit: 'kg',
        isFavorite: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final itemWithoutBarcode = BarcodeQueueItem(
        product: prod1,
        variant: null,
        barcodes: const [],
      );

      expect(itemWithoutBarcode.hasBarcode, false);
      expect(itemWithoutBarcode.displayName, 'Sugar 1kg');

      final itemWithBarcode = BarcodeQueueItem(
        product: prod1,
        variant: null,
        barcodes: const ['8901234567890'],
      );

      expect(itemWithBarcode.hasBarcode, true);
      expect(itemWithBarcode.barcodes.first, '8901234567890');
    });

    test('BarcodeQueueItem formats variant labels correctly', () {
      final prod = Product(
        id: 2,
        name: 'Basmati Rice',
        price: 120.0,
        gstRate: 0.0,
        unit: 'kg',
        isFavorite: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final variant = ProductVariant(
        id: 10,
        productId: 2,
        variantName: '5 kg Bag',
        price: 550.0,
        costPrice: 480.0,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item = BarcodeQueueItem(
        product: prod,
        variant: variant,
        barcodes: const [],
      );

      expect(item.hasBarcode, false);
      expect(item.displayName, 'Basmati Rice (5 kg Bag)');
      expect(item.variantLabel, '5 kg Bag');
      expect(item.price, 550.0);
    });
  });

  group('Bug 2: Sale Complete Dialog Tests', () {
    testWidgets('SaleCompleteDialog renders without crashing in ProviderScope', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SaleCompleteDialog(billId: 999),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Sale Complete!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('Bug 3: ImageHelper Thumbnail & Path Tests', () {
    test('ImageHelper creates distinct thumb path', () {
      const path = 'C:/test/products/prod_1_123456.jpg';
      final thumb = ImageHelper.getThumbnailPath(path);
      expect(thumb, contains('prod_1_123456_thumb.jpg'));
      expect(thumb != path, true);
    });
  });
}
