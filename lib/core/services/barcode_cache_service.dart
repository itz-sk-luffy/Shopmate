import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../utils/barcode_utils.dart';

class BarcodeProductMatch {
  final Product product;
  final ProductVariant? variant;
  final String barcode;

  const BarcodeProductMatch({
    required this.product,
    this.variant,
    required this.barcode,
  });

  String get displayName {
    if (variant != null && variant!.variantName.isNotEmpty && variant!.variantName != 'Standard') {
      return '${product.name} (${variant!.variantName})';
    }
    return product.name;
  }

  double get price => variant?.price ?? product.price;
  String get unit => product.unit;
  double get gstRate => product.gstRate;
}

class BarcodeCacheService {
  final AppDatabase _db;
  final Map<String, BarcodeProductMatch> _cache = {};
  bool _isInitialized = false;

  BarcodeCacheService(this._db);

  bool get isInitialized => _isInitialized;

  /// Lazy-loaded warm up of active products and their barcodes
  Future<void> warmUp() async {
    try {
      _cache.clear();

      // Query products that are not deleted
      final activeProducts = await (_db.select(_db.products)
            ..where((tbl) => tbl.isDeleted.equals(false)))
          .get();
      final prodMap = {for (var p in activeProducts) p.id: p};

      // Query all variants
      final variants = await _db.select(_db.productVariants).get();
      final varMap = {for (var v in variants) v.id: v};

      // Query all barcodes
      final barcodes = await _db.select(_db.productBarcodes).get();
      for (final b in barcodes) {
        final prod = prodMap[b.productId];
        if (prod != null) {
          final variant = b.variantId != null ? varMap[b.variantId] : null;
          final match = BarcodeProductMatch(
            product: prod,
            variant: variant,
            barcode: b.barcode,
          );
          _indexBarcode(b.barcode, match);
        }
      }

      // Also index legacy products.barcode if not already present
      for (final p in activeProducts) {
        if (p.barcode != null && p.barcode!.trim().isNotEmpty) {
          final clean = BarcodeUtils.sanitize(p.barcode!);
          if (!_cache.containsKey(clean)) {
            final match = BarcodeProductMatch(
              product: p,
              variant: null,
              barcode: clean,
            );
            _indexBarcode(clean, match);
          }
        }
      }

      _isInitialized = true;
    } catch (_) {
      // In-memory cache failure should not crash app, will fall back to DB
    }
  }

  void _indexBarcode(String barcode, BarcodeProductMatch match) {
    final clean = BarcodeUtils.sanitize(barcode);
    if (clean.isEmpty) return;

    final equivalents = BarcodeUtils.getEquivalentBarcodes(clean);
    for (final eq in equivalents) {
      _cache[eq] = match;
    }
  }

  /// Instant lookup: Map check first (< 1 ms), falls back to DB indexed query on miss
  Future<BarcodeProductMatch?> findByBarcode(String rawBarcode) async {
    final clean = BarcodeUtils.sanitize(rawBarcode);
    if (clean.isEmpty) return null;

    if (!_isInitialized) {
      await warmUp();
    }

    // 1. Direct in-memory cache lookup
    if (_cache.containsKey(clean)) {
      return _cache[clean];
    }

    // 2. Equivalent barcode check in cache (UPC-A <-> EAN-13)
    final equivalents = BarcodeUtils.getEquivalentBarcodes(clean);
    for (final eq in equivalents) {
      if (_cache.containsKey(eq)) {
        return _cache[eq];
      }
    }

    // 3. Fallback to indexed DB query
    for (final code in equivalents) {
      final barcodeRecord = await (_db.select(_db.productBarcodes)
            ..where((tbl) => tbl.barcode.equals(code)))
          .getSingleOrNull();

      if (barcodeRecord != null) {
        final product = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(barcodeRecord.productId) & tbl.isDeleted.equals(false)))
            .getSingleOrNull();

        if (product != null) {
          ProductVariant? variant;
          if (barcodeRecord.variantId != null) {
            variant = await (_db.select(_db.productVariants)
                  ..where((tbl) => tbl.id.equals(barcodeRecord.variantId!)))
                .getSingleOrNull();
          }

          final match = BarcodeProductMatch(
            product: product,
            variant: variant,
            barcode: barcodeRecord.barcode,
          );
          _indexBarcode(code, match);
          return match;
        }
      }

      // Check legacy products table
      final legacyProduct = await (_db.select(_db.products)
            ..where((tbl) => tbl.barcode.equals(code) & tbl.isDeleted.equals(false)))
          .getSingleOrNull();

      if (legacyProduct != null) {
        final match = BarcodeProductMatch(
          product: legacyProduct,
          variant: null,
          barcode: code,
        );
        _indexBarcode(code, match);
        return match;
      }
    }

    return null;
  }

  /// Check if a barcode is already used by another product/variant
  Future<BarcodeProductMatch?> checkDuplicate(String rawBarcode, {int? excludeProductId, int? excludeVariantId}) async {
    final match = await findByBarcode(rawBarcode);
    if (match == null) return null;

    if (excludeProductId != null && match.product.id == excludeProductId) {
      if (excludeVariantId == null || match.variant?.id == excludeVariantId) {
        return null;
      }
    }
    return match;
  }

  /// Log an unmatched barcode scan with 30-day auto cleanup
  Future<void> logUnmatchedScan(String rawBarcode) async {
    final clean = BarcodeUtils.sanitize(rawBarcode);
    if (clean.isEmpty) return;

    try {
      // 1. Auto cleanup: delete entries older than 30 days
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      await (_db.delete(_db.unmatchedScans)..where((tbl) => tbl.lastScannedAt.isSmallerOrEqualValue(cutoff))).go();

      // 2. Check if barcode is already logged
      final existing = await (_db.select(_db.unmatchedScans)
            ..where((tbl) => tbl.barcode.equals(clean)))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.update(_db.unmatchedScans)..where((tbl) => tbl.id.equals(existing.id))).write(
          UnmatchedScansCompanion(
            scanCount: Value(existing.scanCount + 1),
            lastScannedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await _db.into(_db.unmatchedScans).insert(
          UnmatchedScansCompanion.insert(
            barcode: clean,
            scanCount: const Value(1),
            lastScannedAt: Value(DateTime.now()),
            createdAt: Value(DateTime.now()),
          ),
        );
      }
    } catch (_) {}
  }

  /// Invalidate cache when products/variants change
  void invalidate() {
    _isInitialized = false;
    _cache.clear();
  }
}

final barcodeCacheServiceProvider = Provider<BarcodeCacheService>((ref) {
  final db = ref.watch(databaseProvider);
  return BarcodeCacheService(db);
});

