import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Products,
  Categories,
  Units,
  Customers,
  Bills,
  BillItems,
  BillEdits,
  Expenses,
  DayClosings,
  StoreSettings,
  ProductVariants,
  ProductBarcodes,
  UnmatchedScans,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create performance indexes
        await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_product_barcodes_barcode ON product_barcodes(barcode);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_products_is_deleted ON products(is_deleted);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_bills_date ON bills(date);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_bills_number ON bills(bill_number);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_bills_is_deleted ON bills(is_deleted);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON bill_items(bill_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_bill_edits_bill_id ON bill_edits(bill_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_day_closings_date ON day_closings(date);');

        // Seed default units
        await into(units).insert(UnitsCompanion.insert(code: 'pcs', name: 'Pieces', isDecimalAllowed: const Value(false)));
        await into(units).insert(UnitsCompanion.insert(code: 'kg', name: 'Kilograms', isDecimalAllowed: const Value(true)));
        await into(units).insert(UnitsCompanion.insert(code: 'ltr', name: 'Litres', isDecimalAllowed: const Value(true)));
        await into(units).insert(UnitsCompanion.insert(code: 'gm', name: 'Grams', isDecimalAllowed: const Value(true)));
        await into(units).insert(UnitsCompanion.insert(code: 'ml', name: 'Millilitres', isDecimalAllowed: const Value(true)));
        await into(units).insert(UnitsCompanion.insert(code: 'pkt', name: 'Packets', isDecimalAllowed: const Value(false)));

        // Seed default categories
        await into(categories).insert(CategoriesCompanion.insert(name: 'Groceries', colorHex: const Value('#0F766E'), iconName: const Value('shopping_basket')));
        await into(categories).insert(CategoriesCompanion.insert(name: 'Beverages', colorHex: const Value('#0284C7'), iconName: const Value('local_drink')));
        await into(categories).insert(CategoriesCompanion.insert(name: 'Dairy', colorHex: const Value('#F59E0B'), iconName: const Value('egg')));
        await into(categories).insert(CategoriesCompanion.insert(name: 'Snacks', colorHex: const Value('#D97706'), iconName: const Value('cookie')));
        await into(categories).insert(CategoriesCompanion.insert(name: 'Personal Care', colorHex: const Value('#7C3AED'), iconName: const Value('clean_hands')));
        await into(categories).insert(CategoriesCompanion.insert(name: 'Household', colorHex: const Value('#059669'), iconName: const Value('home')));
        await into(categories).insert(CategoriesCompanion.insert(name: 'General', colorHex: const Value('#64748B'), iconName: const Value('category')));

        // Seed default store settings
        final defaultSettings = {
          'store_name': 'Shopmate Store',
          'store_address': 'Main Market',
          'store_phone': '',
          'store_email': '',
          'store_gstin': '',
          'store_state': 'State',
          'store_license': '',
          'store_footer': 'Thank you for shopping with us! Visit again.',
          'bill_prefix': 'INV-',
          'bill_next_number': '1001',
          'currency_symbol': '₹',
          'date_format': 'dd/MM/yyyy',
          'language': 'en',
          'theme_mode': 'system',
          'accent_color': '0xFF0F766E',
          'tax_rate_default': '0',
          'tax_type': 'exclusive',
          'gst_enabled': 'true',
          'reduce_animations': 'false',
          'receipt_show_gst': 'true',
          'receipt_show_customer': 'true',
          'receipt_show_footer': 'true',
          'print_cut_feed': '3',
          'print_font_size': 'normal',
          'auto_backup_enabled': 'true',
          'auto_backup_interval': 'daily',
          'has_completed_onboarding': 'false',
          'app_lock_enabled': 'false',
          'app_lock_pin': '',
          'app_lock_biometric': 'false',
          'user_role': 'owner',
          'search_engine': 'google',
          'same_barcode_adds_quantity': 'true',
          'scale_prefix': '2',
          'scale_item_code_length': '5',
          'scale_value_type': 'weight',
          'scale_value_length': '5',
          'scale_decimal_places': '3',
          'internal_barcode_prefix': '29',
          'internal_barcode_seq': '100000',
          'barcode_autofill_online': 'false',
          'print_bill_barcode': 'false',
          'dev_mode_enabled': 'false',
          'show_performance_overlay': 'false',
        };

        for (final entry in defaultSettings.entries) {
          await into(storeSettings).insert(StoreSettingsCompanion.insert(
            key: entry.key,
            value: entry.value,
          ));
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(billItems, billItems.taxableValue);
          await m.addColumn(billItems, billItems.cgstAmount);
          await m.addColumn(billItems, billItems.sgstAmount);
          await m.addColumn(billItems, billItems.igstAmount);
        }
        if (from < 3) {
          await m.createTable(productVariants);
          await m.createTable(productBarcodes);
          await m.createTable(unmatchedScans);
          await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_product_barcodes_barcode ON product_barcodes(barcode);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);');

          final existingProducts = await select(products).get();
          for (final p in existingProducts) {
            final variantId = await into(productVariants).insert(
              ProductVariantsCompanion.insert(
                productId: p.id,
                variantName: const Value('Standard'),
                price: p.price,
                isDefault: const Value(true),
              ),
            );
            if (p.barcode != null && p.barcode!.trim().isNotEmpty) {
              final clean = p.barcode!.trim().replaceAll(' ', '');
              await into(productBarcodes).insertOnConflictUpdate(
                ProductBarcodesCompanion.insert(
                  variantId: Value(variantId),
                  productId: p.id,
                  barcode: clean,
                  isPrimary: const Value(true),
                ),
              );
            }
          }
        }
      },
    );
  }

  // Settings helper methods
  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final query = select(storeSettings)..where((tbl) => tbl.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value ?? defaultValue;
  }

  Future<void> setSetting(String key, String value) async {
    await into(storeSettings).insertOnConflictUpdate(StoreSettingsCompanion(
      key: Value(key),
      value: Value(value),
    ));
  }

  Future<Map<String, String>> getAllSettings() async {
    final list = await select(storeSettings).get();
    return {for (var item in list) item.key: item.value};
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'shopmate.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA journal_mode = WAL;');
        rawDb.execute('PRAGMA synchronous = NORMAL;');
        rawDb.execute('PRAGMA temp_store = MEMORY;');
        rawDb.execute('PRAGMA cache_size = -3000;');
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}
