import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/routing/app_routes.dart';

class FakeCategoryManager {
  final List<Category> _categories = [];
  final List<Product> _products = [];
  int _nextCatId = 1;
  int _nextProdId = 1;

  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);

  int addCategory(String name) {
    final cat = Category(
      id: _nextCatId++,
      name: name.trim(),
    );
    _categories.add(cat);
    return cat.id;
  }

  bool updateCategory(int id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return false;
    _categories[idx] = Category(id: id, name: trimmed);
    return true;
  }

  void deleteCategory(int id) {
    // 1. Unassign all products from this category
    for (int i = 0; i < _products.length; i++) {
      if (_products[i].categoryId == id) {
        _products[i] = _products[i].copyWith(categoryId: const drift.Value(null));
      }
    }
    // 2. Delete the category
    _categories.removeWhere((c) => c.id == id);
  }

  int addProduct(String name, double price, {int? categoryId}) {
    final now = DateTime.now();
    final p = Product(
      id: _nextProdId++,
      name: name,
      price: price,
      gstRate: 0.0,
      unit: 'pcs',
      categoryId: categoryId,
      isFavorite: false,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
    _products.add(p);
    return p.id;
  }

  void setProductsForCategory({required int categoryId, required Set<int> selectedProductIds}) {
    // 1. Unassign products currently in this category that were deselected
    for (int i = 0; i < _products.length; i++) {
      if (_products[i].categoryId == categoryId && !selectedProductIds.contains(_products[i].id)) {
        _products[i] = _products[i].copyWith(categoryId: const drift.Value(null));
      }
    }

    // 2. Assign newly selected products to this category
    for (int i = 0; i < _products.length; i++) {
      if (selectedProductIds.contains(_products[i].id)) {
        _products[i] = _products[i].copyWith(categoryId: drift.Value(categoryId));
      }
    }
  }

  Map<int, int> getCategoryProductCounts() {
    final map = <int, int>{};
    for (final p in _products) {
      if (!p.isDeleted && p.categoryId != null) {
        map[p.categoryId!] = (map[p.categoryId!] ?? 0) + 1;
      }
    }
    return map;
  }
}

void main() {
  late FakeCategoryManager manager;

  setUp(() {
    manager = FakeCategoryManager();
    manager.addCategory('Groceries');
    manager.addCategory('Beverages');
    manager.addCategory('Dairy');
  });

  group('Category Management & Product Assignment Tests', () {
    test('AppRoutes.categories is correctly defined and registered', () {
      expect(AppRoutes.categories, '/settings/categories');
      expect(AppRoutes.allRoutes.contains(AppRoutes.categories), isTrue);
    });

    test('Add, update, and get categories', () {
      final initial = manager.categories;
      expect(initial.map((c) => c.name), containsAll(['Beverages', 'Dairy', 'Groceries']));

      // Add a new category
      final newId = manager.addCategory('Bakery & Snacks');
      expect(newId, isPositive);
      expect(manager.categories.any((c) => c.name == 'Bakery & Snacks'), isTrue);

      // Rename category
      final renamed = manager.updateCategory(newId, 'Bakery');
      expect(renamed, isTrue);
      expect(manager.categories.any((c) => c.name == 'Bakery'), isTrue);
      expect(manager.categories.any((c) => c.name == 'Bakery & Snacks'), isFalse);
    });

    test('Bulk assign and unassign multiple products to a category', () {
      final groceries = manager.categories.firstWhere((c) => c.name == 'Groceries');

      final p1 = manager.addProduct('A1 Chips', 50.0);
      final p2 = manager.addProduct('Basmati Rice', 120.0);
      final p3 = manager.addProduct('Orange Juice', 90.0);

      // Initially no category
      expect(manager.products.firstWhere((p) => p.id == p1).categoryId, isNull);

      // Bulk assign p1 and p2 to Groceries
      manager.setProductsForCategory(
        categoryId: groceries.id,
        selectedProductIds: {p1, p2},
      );

      expect(manager.products.firstWhere((p) => p.id == p1).categoryId, equals(groceries.id));
      expect(manager.products.firstWhere((p) => p.id == p2).categoryId, equals(groceries.id));
      expect(manager.products.firstWhere((p) => p.id == p3).categoryId, isNull);

      // Now update Groceries to only have p2 and p3 (unassigning p1)
      manager.setProductsForCategory(
        categoryId: groceries.id,
        selectedProductIds: {p2, p3},
      );

      expect(manager.products.firstWhere((p) => p.id == p1).categoryId, isNull,
          reason: 'p1 was deselected so categoryId must become null');
      expect(manager.products.firstWhere((p) => p.id == p2).categoryId, equals(groceries.id));
      expect(manager.products.firstWhere((p) => p.id == p3).categoryId, equals(groceries.id));
    });

    test('Delete category safely unassigns products without deleting them', () {
      final dairy = manager.categories.firstWhere((c) => c.name == 'Dairy');

      final p1 = manager.addProduct('Milk 500ml', 30.0, categoryId: dairy.id);
      final p2 = manager.addProduct('Paneer 200g', 80.0, categoryId: dairy.id);

      // Verify products are in Dairy
      expect(manager.products.firstWhere((p) => p.id == p1).categoryId, equals(dairy.id));

      // Delete Dairy category
      manager.deleteCategory(dairy.id);

      // Verify category was deleted
      expect(manager.categories.any((c) => c.id == dairy.id), isFalse);

      // Verify products still exist and are active, with categoryId set to null
      final prod1 = manager.products.firstWhere((p) => p.id == p1);
      final prod2 = manager.products.firstWhere((p) => p.id == p2);

      expect(prod1.isDeleted, isFalse);
      expect(prod1.categoryId, isNull);

      expect(prod2.isDeleted, isFalse);
      expect(prod2.categoryId, isNull);
    });

    test('getCategoryProductCounts correctly aggregates assigned product count', () {
      final beverages = manager.categories.firstWhere((c) => c.name == 'Beverages');

      var counts = manager.getCategoryProductCounts();
      expect(counts[beverages.id] ?? 0, equals(0));

      // Add 2 products to Beverages
      manager.addProduct('Cola Can', 40.0, categoryId: beverages.id);
      manager.addProduct('Lemon Soda', 20.0, categoryId: beverages.id);

      counts = manager.getCategoryProductCounts();
      expect(counts[beverages.id], equals(2));
    });
  });
}
