import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../products/data/products_repository.dart';

class CategorySettingsScreen extends ConsumerStatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  ConsumerState<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends ConsumerState<CategorySettingsScreen> {
  void _openAddCategoryDialog(List<Category> existing) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Category', style: AppTypography.heading3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Category Name *',
                    hintText: 'e.g. Spices, Bakery, Cold Drinks',
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() => errorText = 'Name cannot be empty');
                    return;
                  }
                  if (existing.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
                    setDialogState(() => errorText = 'Category "$name" already exists');
                    return;
                  }

                  final repo = ref.read(productsRepositoryProvider);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await repo.addCategory(name);
                    ref.invalidate(categoriesStreamProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Category "$name" created successfully'),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => errorText = 'Failed to create: $e');
                  }
                },
                child: const Text('Add Category'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openRenameCategoryDialog(Category category, List<Category> existing) {
    final controller = TextEditingController(text: category.name);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Rename "${category.name}"', style: AppTypography.heading3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Category Name *',
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) {
                    setDialogState(() => errorText = 'Name cannot be empty');
                    return;
                  }
                  if (newName.toLowerCase() != category.name.toLowerCase() &&
                      existing.any((c) => c.name.toLowerCase() == newName.toLowerCase())) {
                    setDialogState(() => errorText = 'Category "$newName" already exists');
                    return;
                  }

                  final repo = ref.read(productsRepositoryProvider);
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await repo.updateCategory(category.id, newName);
                  if (ok) {
                    ref.invalidate(categoriesStreamProvider);
                    ref.invalidate(productsListStreamProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Renamed category to "$newName"'),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(Category category, int assignedCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: Text(
          assignedCount > 0
              ? 'This category currently has $assignedCount products assigned. Deleting it will remove the category tag from those products, but the products themselves will NOT be deleted.'
              : 'Are you sure you want to delete the category "${category.name}"?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () async {
              final repo = ref.read(productsRepositoryProvider);
              final messenger = ScaffoldMessenger.of(context);
              await repo.deleteCategory(category.id);
              ref.invalidate(categoriesStreamProvider);
              ref.invalidate(categoryProductCountsStreamProvider);
              ref.invalidate(productsListStreamProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" removed'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete Category'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final countsAsync = ref.watch(categoryProductCountsStreamProvider);
    final counts = countsAsync.value ?? {};
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackRoute: AppRoutes.settings),
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Category',
            onPressed: () {
              final cats = categoriesAsync.value ?? [];
              _openAddCategoryDialog(cats);
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.category_outlined,
                title: 'No Categories Found',
                message: 'Tap the button below to add your first category.',
                actionLabel: 'Add Category',
                onAction: () => _openAddCategoryDialog(categories),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return OutlinedButton.icon(
                  onPressed: () => _openAddCategoryDialog(categories),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add New Category'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                );
              }

              final cat = categories[index];
              final count = counts[cat.id] ?? 0;

              return CustomCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.category_rounded,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.name,
                                style: AppTypography.heading3.copyWith(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count ${count == 1 ? "product" : "products"} assigned',
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Rename Category',
                          onPressed: () => _openRenameCategoryDialog(cat, categories),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.errorRed),
                          tooltip: 'Delete Category',
                          onPressed: () => _confirmDeleteCategory(cat, count),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignCategoryProductsScreen(
                                category: cat,
                                allCategories: categories,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.checklist_rounded, size: 18),
                        label: Text('Assign / Manage Products ($count)'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 38),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class AssignCategoryProductsScreen extends ConsumerStatefulWidget {
  final Category category;
  final List<Category> allCategories;

  const AssignCategoryProductsScreen({
    super.key,
    required this.category,
    required this.allCategories,
  });

  @override
  ConsumerState<AssignCategoryProductsScreen> createState() => _AssignCategoryProductsScreenState();
}

class _AssignCategoryProductsScreenState extends ConsumerState<AssignCategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _initialized = false;
  bool _isSaving = false;
  String _filterType = 'all'; // 'all', 'in_category', 'unassigned'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initSelections(List<Product> products) {
    if (_initialized) return;
    for (final p in products) {
      if (p.categoryId == widget.category.id) {
        _selectedIds.add(p.id);
      }
    }
    _initialized = true;
  }

  Future<void> _saveAssignments() async {
    setState(() => _isSaving = true);
    final repo = ref.read(productsRepositoryProvider);

    try {
      await repo.setProductsForCategory(
        categoryId: widget.category.id,
        selectedProductIds: _selectedIds,
      );

      // Invalidate stream providers so entire app instantly reflects new category products
      ref.invalidate(productsListStreamProvider);
      ref.invalidate(categoryProductCountsStreamProvider);
      ref.invalidate(categoriesStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assigned ${_selectedIds.length} products to "${widget.category.name}"',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save assignments: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final productsAsync = ref.watch(productsListStreamProvider((categoryId: null, search: null)));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final catMap = {for (final c in widget.allCategories) c.id: c.name};

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign: ${widget.category.name}', style: AppTypography.heading3.copyWith(fontSize: 18)),
            Text('${_selectedIds.length} selected', style: AppTypography.caption),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAssignments,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (allProducts) {
          _initSelections(allProducts);

          final query = _searchController.text.trim().toLowerCase();
          final filtered = allProducts.where((p) {
            // Text search
            if (query.isNotEmpty) {
              final nameMatch = p.name.toLowerCase().contains(query);
              final barcodeMatch = p.barcode?.toLowerCase().contains(query) ?? false;
              if (!nameMatch && !barcodeMatch) return false;
            }

            // Filter chips
            if (_filterType == 'in_category') {
              return _selectedIds.contains(p.id) || p.categoryId == widget.category.id;
            } else if (_filterType == 'unassigned') {
              return p.categoryId == null;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products by name or barcode...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() => _searchController.clear());
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: Text('All (${allProducts.length})'),
                                  selected: _filterType == 'all',
                                  onSelected: (_) => setState(() => _filterType = 'all'),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text('Selected (${_selectedIds.length})'),
                                  selected: _filterType == 'in_category',
                                  onSelected: (_) => setState(() => _filterType = 'in_category'),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text('Unassigned (${allProducts.where((p) => p.categoryId == null).length})'),
                                  selected: _filterType == 'unassigned',
                                  onSelected: (_) => setState(() => _filterType = 'unassigned'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              final allFilteredSelected = filtered.every((p) => _selectedIds.contains(p.id));
                              if (allFilteredSelected) {
                                for (final p in filtered) {
                                  _selectedIds.remove(p.id);
                                }
                              } else {
                                for (final p in filtered) {
                                  _selectedIds.add(p.id);
                                }
                              }
                            });
                          },
                          child: Text(
                            filtered.isNotEmpty && filtered.every((p) => _selectedIds.contains(p.id))
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Product list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No products matching filter',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final isSelected = _selectedIds.contains(product.id);
                          final currentCatName = catMap[product.categoryId];

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: theme.colorScheme.primary,
                            title: Text(
                              product.name,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${Formatters.currency(product.price, symbol: settings.currencySymbol)} • '
                              'Unit: ${product.unit} • '
                              '${product.categoryId == widget.category.id ? "In this category" : (currentCatName != null ? "In $currentCatName" : "No category")}',
                              style: AppTypography.caption.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(product.id);
                                } else {
                                  _selectedIds.remove(product.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),

              // Bottom Confirmation Bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(top: BorderSide(color: isDark ? AppColors.darkOutline : AppColors.lightOutline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedIds.length} products assigned',
                          style: AppTypography.section.copyWith(fontSize: 15),
                        ),
                      ),
                      FilledButton(
                        onPressed: _isSaving ? null : _saveAssignments,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Assignments'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
