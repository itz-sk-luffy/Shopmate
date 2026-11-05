import 'dart:isolate';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/barcode_utils.dart';

class BarcodeQueueItem {
  final Product product;
  final ProductVariant? variant;
  final List<String> barcodes;

  const BarcodeQueueItem({
    required this.product,
    this.variant,
    this.barcodes = const [],
  });

  String get displayName => variant != null && variant!.variantName != 'Standard'
      ? '${product.name} (${variant!.variantName})'
      : product.name;

  String get variantLabel => variant != null ? variant!.variantName : 'Standard';

  double get price => variant != null ? variant!.price : product.price;

  int? get variantId => variant?.id;
  int get productId => product.id;

  bool get hasBarcode => barcodes.isNotEmpty;
}

class ProductsRepository {
  final AppDatabase _db;

  ProductsRepository(this._db);

  // Watch non-deleted products with optional category and search filtering
  Stream<List<Product>> watchProducts({int? categoryId, String? search}) {
    final query = _db.select(_db.products)
      ..where((tbl) => tbl.isDeleted.equals(false));

    if (categoryId != null && categoryId > 0) {
      query.where((tbl) => tbl.categoryId.equals(categoryId));
    }

    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      query.where((tbl) => tbl.name.like(s) | tbl.barcode.like(s));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.isFavorite, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
    ]);

    return query.watch();
  }

  Future<List<Product>> getAllActiveProducts() async {
    return (_db.select(_db.products)..where((tbl) => tbl.isDeleted.equals(false))).get();
  }

  Future<Product?> getProductById(int id) {
    return (_db.select(_db.products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final clean = BarcodeUtils.sanitize(barcode);
    if (clean.isEmpty) return null;

    final equivalents = BarcodeUtils.getEquivalentBarcodes(clean);
    for (final code in equivalents) {
      // Check product_barcodes table first
      final bc = await (_db.select(_db.productBarcodes)..where((tbl) => tbl.barcode.equals(code))).getSingleOrNull();
      if (bc != null) {
        final prod = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(bc.productId) & tbl.isDeleted.equals(false)))
            .getSingleOrNull();
        if (prod != null) return prod;
      }

      // Check legacy products.barcode
      final legacy = await (_db.select(_db.products)
            ..where((tbl) => tbl.barcode.equals(code) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();
      if (legacy != null) return legacy;
    }
    return null;
  }

  Future<bool> isBarcodeDuplicate(String barcode, {int? excludeId}) async {
    final clean = BarcodeUtils.sanitize(barcode);
    if (clean.isEmpty) return false;

    final owner = await getBarcodeOwner(clean, excludeProductId: excludeId);
    return owner != null;
  }

  /// Returns owner product and optional variant if barcode is already assigned
  Future<({Product product, ProductVariant? variant})?> getBarcodeOwner(String barcode, {int? excludeProductId}) async {
    final clean = BarcodeUtils.sanitize(barcode);
    if (clean.isEmpty) return null;

    final equivalents = BarcodeUtils.getEquivalentBarcodes(clean);
    for (final code in equivalents) {
      final bc = await (_db.select(_db.productBarcodes)..where((tbl) => tbl.barcode.equals(code))).getSingleOrNull();
      if (bc != null) {
        if (excludeProductId != null && bc.productId == excludeProductId) continue;
        final prod = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(bc.productId) & tbl.isDeleted.equals(false)))
            .getSingleOrNull();
        if (prod != null) {
          ProductVariant? variant;
          if (bc.variantId != null) {
            variant = await (_db.select(_db.productVariants)..where((tbl) => tbl.id.equals(bc.variantId!))).getSingleOrNull();
          }
          return (product: prod, variant: variant);
        }
      }

      // Check legacy products table
      final leg = await (_db.select(_db.products)
            ..where((tbl) => tbl.barcode.equals(code) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();
      if (leg != null) {
        if (excludeProductId != null && leg.id == excludeProductId) continue;
        return (product: leg, variant: null);
      }
    }
    return null;
  }

  /// Generates a unique sequential internal barcode inside a drift transaction
  Future<String> generateInternalBarcode() async {
    return _db.transaction(() async {
      final prefix = await _db.getSetting('internal_barcode_prefix', defaultValue: '29');
      final seqStr = await _db.getSetting('internal_barcode_seq', defaultValue: '100000');
      int currentSeq = int.tryParse(seqStr) ?? 100000;

      while (true) {
        currentSeq++;
        final candidate = BarcodeUtils.generateEan13(prefix: prefix, sequence: currentSeq);

        final existing = await (_db.select(_db.productBarcodes)..where((tbl) => tbl.barcode.equals(candidate))).getSingleOrNull();
        if (existing == null) {
          await _db.setSetting('internal_barcode_seq', currentSeq.toString());
          return candidate;
        }
      }
    });
  }

  /// Watch queue items (product + variant + assigned barcodes) reactively
  Stream<List<BarcodeQueueItem>> watchBarcodeQueueItems() {
    final query = _db.customSelect(
      'SELECT 1',
      readsFrom: {_db.products, _db.productVariants, _db.productBarcodes},
    );

    return query.watch().asyncMap((_) async {
      final products = await (_db.select(_db.products)
            ..where((tbl) => tbl.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc)]))
          .get();

      final variants = await (_db.select(_db.productVariants)
            ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc)]))
          .get();

      final barcodes = await _db.select(_db.productBarcodes).get();

      final Map<int, List<ProductBarcode>> barcodesByProduct = {};
      for (final b in barcodes) {
        barcodesByProduct.putIfAbsent(b.productId, () => []).add(b);
      }

      final Map<int, List<ProductVariant>> variantsByProduct = {};
      for (final v in variants) {
        variantsByProduct.putIfAbsent(v.productId, () => []).add(v);
      }

      final List<BarcodeQueueItem> items = [];

      for (final prod in products) {
        final prodVariants = variantsByProduct[prod.id] ?? [];
        final prodBarcodes = barcodesByProduct[prod.id] ?? [];

        if (prodVariants.isEmpty) {
          final bcs = prodBarcodes.map((b) => b.barcode).toList();
          items.add(BarcodeQueueItem(
            product: prod,
            variant: null,
            barcodes: bcs,
          ));
        } else {
          for (final variant in prodVariants) {
            final vBarcodes = prodBarcodes
                .where((b) => b.variantId == variant.id || (variant.isDefault && b.variantId == null))
                .map((b) => b.barcode)
                .toList();
            items.add(BarcodeQueueItem(
              product: prod,
              variant: variant,
              barcodes: vBarcodes,
            ));
          }
        }
      }

      return items;
    });
  }

  /// Get products that have no barcode assigned (for bulk assign mode)
  Future<List<Product>> getProductsWithoutBarcodes() async {
    final allProducts = await getAllActiveProducts();
    final allBarcodes = await _db.select(_db.productBarcodes).get();
    final productIdsWithBarcodes = allBarcodes.map((b) => b.productId).toSet();

    return allProducts.where((p) {
      if (productIdsWithBarcodes.contains(p.id)) return false;
      return p.barcode == null || p.barcode!.trim().isEmpty;
    }).toList();
  }

  /// Assign barcode to product and its default variant
  Future<void> assignBarcodeToProduct({required int productId, required String barcode, int? variantId}) async {
    final clean = BarcodeUtils.sanitize(barcode);
    if (clean.isEmpty) return;

    await _db.transaction(() async {
      int? vId = variantId;
      if (vId == null) {
        final defVariant = await (_db.select(_db.productVariants)
              ..where((tbl) => tbl.productId.equals(productId) & tbl.isDefault.equals(true)))
            .getSingleOrNull();
        vId = defVariant?.id;
        if (vId == null) {
          final prod = await getProductById(productId);
          if (prod != null) {
            vId = await _db.into(_db.productVariants).insert(
              ProductVariantsCompanion.insert(
                productId: productId,
                variantName: const Value('Standard'),
                price: prod.price,
                isDefault: const Value(true),
              ),
            );
          }
        }
      }

      await _db.into(_db.productBarcodes).insertOnConflictUpdate(
        ProductBarcodesCompanion.insert(
          productId: productId,
          variantId: Value(vId),
          barcode: clean,
          isPrimary: const Value(true),
        ),
      );

      await (_db.update(_db.products)..where((tbl) => tbl.id.equals(productId))).write(
        ProductsCompanion(
          barcode: Value(clean),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Merge multiple products into one target product with recycle bin undo support
  Future<void> mergeProducts({required int targetProductId, required List<int> sourceProductIds}) async {
    await _db.transaction(() async {
      for (final srcId in sourceProductIds) {
        if (srcId == targetProductId) continue;

        // Reassign variants
        await (_db.update(_db.productVariants)..where((tbl) => tbl.productId.equals(srcId))).write(
          ProductVariantsCompanion(productId: Value(targetProductId)),
        );

        // Reassign barcodes
        await (_db.update(_db.productBarcodes)..where((tbl) => tbl.productId.equals(srcId))).write(
          ProductBarcodesCompanion(productId: Value(targetProductId)),
        );

        // Reassign bill items
        await (_db.update(_db.billItems)..where((tbl) => tbl.productId.equals(srcId))).write(
          BillItemsCompanion(productId: Value(targetProductId)),
        );

        // Soft delete source product for undo through recycle bin
        await (_db.update(_db.products)..where((tbl) => tbl.id.equals(srcId))).write(
          ProductsCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<int> addProduct(ProductsCompanion product) async {
    return _db.transaction(() async {
      final cleanBarcode = product.barcode.present && product.barcode.value != null
          ? BarcodeUtils.sanitize(product.barcode.value!)
          : null;

      final updatedProduct = cleanBarcode != null
          ? product.copyWith(barcode: Value(cleanBarcode))
          : product;

      final id = await _db.into(_db.products).insert(updatedProduct);

      // Create default variant
      final variantId = await _db.into(_db.productVariants).insert(
        ProductVariantsCompanion.insert(
          productId: id,
          variantName: const Value('Standard'),
          price: product.price.value,
          isDefault: const Value(true),
        ),
      );

      // Insert into product_barcodes if barcode provided
      if (cleanBarcode != null && cleanBarcode.isNotEmpty) {
        await _db.into(_db.productBarcodes).insertOnConflictUpdate(
          ProductBarcodesCompanion.insert(
            productId: id,
            variantId: Value(variantId),
            barcode: cleanBarcode,
            isPrimary: const Value(true),
          ),
        );
      }

      return id;
    });
  }

  Future<bool> updateProduct(ProductsCompanion product) async {
    return _db.transaction(() async {
      final cleanBarcode = product.barcode.present && product.barcode.value != null
          ? BarcodeUtils.sanitize(product.barcode.value!)
          : null;

      final updatedProduct = cleanBarcode != null
          ? product.copyWith(barcode: Value(cleanBarcode))
          : product;

      final ok = await _db.update(_db.products).replace(updatedProduct);

      final pId = product.id.value;
      if (cleanBarcode != null && cleanBarcode.isNotEmpty) {
        final defVariant = await (_db.select(_db.productVariants)
              ..where((tbl) => tbl.productId.equals(pId) & tbl.isDefault.equals(true)))
            .getSingleOrNull();

        await _db.into(_db.productBarcodes).insertOnConflictUpdate(
          ProductBarcodesCompanion.insert(
            productId: pId,
            variantId: Value(defVariant?.id),
            barcode: cleanBarcode,
            isPrimary: const Value(true),
          ),
        );
      }

      return ok;
    });
  }

  Future<void> softDeleteProduct(int id) async {
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(id))).write(
      ProductsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restoreProduct(int id) async {
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(id))).write(
      const ProductsCompanion(
        isDeleted: Value(false),
        deletedAt: Value(null),
      ),
    );
  }

  Future<void> toggleFavorite(int id, bool currentStatus) async {
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(id))).write(
      ProductsCompanion(
        isFavorite: Value(!currentStatus),
      ),
    );
  }

  // Bulk price update by percentage per category
  Future<int> bulkUpdatePrices({required int categoryId, required double percentage}) async {
    final products = await (_db.select(_db.products)
          ..where((tbl) => tbl.categoryId.equals(categoryId) & tbl.isDeleted.equals(false)))
        .get();

    int count = 0;
    final factor = 1.0 + (percentage / 100.0);

    for (final p in products) {
      final newPrice = (p.price * factor).roundToDouble();
      await (_db.update(_db.products)..where((tbl) => tbl.id.equals(p.id))).write(
        ProductsCompanion(
          price: Value(newPrice),
          updatedAt: Value(DateTime.now()),
        ),
      );
      count++;
    }
    return count;
  }

  // Categories & Units
  Stream<List<Category>> watchCategories() {
    return (_db.select(_db.categories)..orderBy([(tbl) => OrderingTerm(expression: tbl.name)])).watch();
  }

  Future<List<Category>> getCategories() {
    return (_db.select(_db.categories)..orderBy([(tbl) => OrderingTerm(expression: tbl.name)])).get();
  }

  Future<int> addCategory(String name) {
    return _db.into(_db.categories).insert(CategoriesCompanion.insert(name: name.trim()));
  }

  Future<bool> updateCategory(int id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    final count = await (_db.update(_db.categories)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(name: Value(trimmed)),
    );
    return count > 0;
  }

  Future<void> deleteCategory(int id) async {
    await _db.transaction(() async {
      // 1. Unassign all products from this category so they are preserved
      await (_db.update(_db.products)..where((tbl) => tbl.categoryId.equals(id))).write(
        const ProductsCompanion(categoryId: Value(null)),
      );
      // 2. Delete the category
      await (_db.delete(_db.categories)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  Stream<Map<int, int>> watchCategoryProductCounts() {
    return (_db.select(_db.products)..where((tbl) => tbl.isDeleted.equals(false)))
        .watch()
        .map((products) {
      final map = <int, int>{};
      for (final p in products) {
        if (p.categoryId != null) {
          map[p.categoryId!] = (map[p.categoryId!] ?? 0) + 1;
        }
      }
      return map;
    });
  }

  Future<void> setProductsForCategory({
    required int categoryId,
    required Set<int> selectedProductIds,
  }) async {
    await _db.transaction(() async {
      // 1. Unassign products currently in this category that were deselected
      final currentlyInCat = await (_db.select(_db.products)
            ..where((tbl) => tbl.categoryId.equals(categoryId) & tbl.isDeleted.equals(false)))
          .get();

      for (final p in currentlyInCat) {
        if (!selectedProductIds.contains(p.id)) {
          await (_db.update(_db.products)..where((tbl) => tbl.id.equals(p.id))).write(
            const ProductsCompanion(categoryId: Value(null)),
          );
        }
      }

      // 2. Assign newly selected products to this category
      for (final pid in selectedProductIds) {
        await (_db.update(_db.products)..where((tbl) => tbl.id.equals(pid))).write(
          ProductsCompanion(categoryId: Value(categoryId)),
        );
      }
    });
  }

  Stream<List<Unit>> watchUnits() {
    return _db.select(_db.units).watch();
  }

  Future<List<Unit>> getUnits() {
    return _db.select(_db.units).get();
  }

  // CSV Export
  Future<String> exportCsv() async {
    final products = await getAllActiveProducts();
    final categories = await getCategories();
    final catMap = {for (var c in categories) c.id: c.name};

    final buffer = StringBuffer();
    buffer.writeln('Name,Price,GST_Percent,Unit,Category,Barcode');

    for (final p in products) {
      final catName = catMap[p.categoryId] ?? 'General';
      final cleanName = p.name.replaceAll('"', '""');
      final rawBarcode = p.barcode ?? '';
      // Preserve leading zeros for Excel / Sheets using the text formula ="0123..."
      final formattedBarcode = rawBarcode.isNotEmpty
          ? (rawBarcode.startsWith('0') ? '="$rawBarcode"' : rawBarcode)
          : '';
      buffer.writeln('"$cleanName",${p.price},${p.gstRate},${p.unit},"$catName",$formattedBarcode');
    }

    return buffer.toString();
  }

  // CSV Import
  Future<int> importCsv(String csvContent) async {
    final parsedRows = await Isolate.run(() => _parseAllCsvRows(csvContent));
    if (parsedRows.isEmpty) return 0;

    final categories = await getCategories();
    final catMap = {for (var c in categories) c.name.toLowerCase(): c.id};

    int importedCount = 0;

    for (final parts in parsedRows) {
      if (parts.length >= 4) {
        final name = parts[0].trim();
        final price = double.tryParse(parts[1].trim()) ?? 0.0;
        final gstRate = double.tryParse(parts[2].trim()) ?? 0.0;
        final unit = parts[3].trim().isEmpty ? 'pcs' : parts[3].trim();
        final catName = parts.length > 4 ? parts[4].trim() : 'General';
        String? barcode = parts.length > 5 && parts[5].trim().isNotEmpty ? parts[5].trim() : null;

        if (barcode != null) {
          // Strip Excel formula format ="..." if present
          if (barcode.startsWith('="') && barcode.endsWith('"')) {
            barcode = barcode.substring(2, barcode.length - 1);
          } else if (barcode.startsWith('"') && barcode.endsWith('"')) {
            barcode = barcode.substring(1, barcode.length - 1);
          }
          barcode = BarcodeUtils.sanitize(barcode);

          // Auto-repair if Excel stripped leading zero from a 13-digit EAN-13
          if (barcode.length == 12 && RegExp(r'^\d+$').hasMatch(barcode)) {
            final candidateEan = '0$barcode';
            final val = BarcodeUtils.validate(candidateEan);
            if (val.isValid) {
              barcode = candidateEan;
            }
          }

          // Duplicate protection: if already used by another product/variant, do not duplicate
          final isDupe = await isBarcodeDuplicate(barcode);
          if (isDupe) {
            barcode = null; // import product without conflicting barcode
          }
        }

        int? catId = catMap[catName.toLowerCase()];
        if (catId == null && catName.isNotEmpty) {
          catId = await addCategory(catName);
          catMap[catName.toLowerCase()] = catId;
        }

        await addProduct(ProductsCompanion.insert(
          name: name,
          price: price,
          gstRate: Value(gstRate),
          unit: Value(unit),
          categoryId: Value(catId),
          barcode: Value(barcode),
        ));
        importedCount++;
      }
    }

    return importedCount;
  }

  static List<List<String>> _parseAllCsvRows(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final List<List<String>> rows = [];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      rows.add(_parseCsvLineStatic(line));
    }
    return rows;
  }

  static List<String> _parseCsvLineStatic(String line) {
    final List<String> result = [];
    bool insideQuotes = false;
    final StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductsRepository(db);
});

final productsListStreamProvider = StreamProvider.autoDispose.family<List<Product>, ({int? categoryId, String? search})>((ref, arg) {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.watchProducts(categoryId: arg.categoryId, search: arg.search);
});

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.watchCategories();
});

final categoryProductCountsStreamProvider = StreamProvider.autoDispose<Map<int, int>>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.watchCategoryProductCounts();
});

final unitsStreamProvider = StreamProvider.autoDispose<List<Unit>>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.watchUnits();
});

final barcodeQueueStreamProvider = StreamProvider.autoDispose<List<BarcodeQueueItem>>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.watchBarcodeQueueItems();
});
