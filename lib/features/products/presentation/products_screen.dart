import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/products_repository.dart';
import 'barcode_label_dialog.dart';
import 'bulk_label_print_screen.dart';
import 'bulk_assign_barcode_screen.dart';
import 'unmatched_scans_screen.dart';
import 'product_merge_screen.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBulkPriceUpdateDialog() {
    final categoriesAsync = ref.read(categoriesStreamProvider);
    final categories = categoriesAsync.value ?? [];
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No categories available for bulk update')),
      );
      return;
    }

    int chosenCatId = categories.first.id;
    final percentController = TextEditingController(text: '10');
    bool isIncrease = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bulk Price Update by %', style: AppTypography.section),
                  const SizedBox(height: 6),
                  const Text('Update prices for all products in a chosen category.', style: AppTypography.caption),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: chosenCatId,
                    decoration: const InputDecoration(labelText: 'Select Category'),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => chosenCatId = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('+ Increase (%)')),
                      ButtonSegment(value: false, label: Text('- Decrease (%)')),
                    ],
                    selected: {isIncrease},
                    onSelectionChanged: (set) => setModalState(() => isIncrease = set.first),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: percentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Percentage Value (%)',
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () async {
                      final pct = double.tryParse(percentController.text.trim()) ?? 0.0;
                      if (pct <= 0) return;
                      final finalPct = isIncrease ? pct : -pct;
                      final repo = ref.read(productsRepositoryProvider);
                      final updatedCount = await repo.bulkUpdatePrices(
                        categoryId: chosenCatId,
                        percentage: finalPct,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated $updatedCount product prices by ${finalPct.toStringAsFixed(1)}%'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: const Text('Apply Price Changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    final repo = ref.read(productsRepositoryProvider);
    final csvData = await repo.exportCsv();
    await Share.share(csvData, subject: 'Shopmate_Products_Catalog.csv');
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final repo = ref.read(productsRepositoryProvider);
        final count = await repo.importCsv(content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $count products from CSV'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import CSV: $e')),
        );
      }
    }
  }

  void _showBarcodeLabel(Product product) {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (_) => BarcodeLabelDialog(
        product: product,
        currencySymbol: settings.currencySymbol,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final productsAsync = ref.watch(
      productsListStreamProvider((
        categoryId: _selectedCategoryId,
        search: _searchController.text.trim(),
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.percent_rounded),
            tooltip: 'Bulk Price Update',
            onPressed: _showBulkPriceUpdateDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              ScaffoldMessenger.of(context).clearSnackBars();
              if (val == 'bulk_labels') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkLabelPrintScreen()));
              } else if (val == 'bulk_assign') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkAssignBarcodeScreen()));
              } else if (val == 'unmatched_scans') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UnmatchedScansScreen()));
              } else if (val == 'merge_tool') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductMergeScreen()));
              } else if (val == 'export') {
                _exportCsv();
              } else if (val == 'import') {
                _importCsv();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'bulk_labels',
                child: Row(
                  children: [
                    Icon(Icons.print_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Print Barcode Labels (58mm)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_assign',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Bulk Assign Barcodes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unmatched_scans',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Unmatched Scans Log'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'merge_tool',
                child: Row(
                  children: [
                    Icon(Icons.merge_type_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Merge Duplicate Products'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_upload_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 10),
                    Text('Import CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name or barcode...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Categories Filter Chips
          categoriesAsync.when(
            data: (categories) {
              if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedCategoryId = null);
                });
              }
              return SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ChoiceChip(
                      label: const Text('All Items'),
                      selected: _selectedCategoryId == null,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategoryId = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((c) {
                      final isSel = _selectedCategoryId == c.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: isSel,
                          onSelected: (val) {
                            setState(() => _selectedCategoryId = val ? c.id : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 42),
            error: (_, __) => const SizedBox(height: 42),
          ),
          const SizedBox(height: 6),
          const Divider(),

          // Products List/Grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Products Found',
                    message: _searchController.text.isNotEmpty
                        ? 'Try searching with a different product name or barcode.'
                        : 'Tap "+" to add items to your store catalog.',
                    actionLabel: 'Add Product',
                    onAction: () => context.push(AppRoutes.productAdd),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    cacheExtent: 200.0,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildGridCard(product, settings.currencySymbol, isDark);
                    },
                  );
                }

                return ListView.builder(
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  cacheExtent: 200.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildListItem(product, settings.currencySymbol, isDark);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.productAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    );
  }

  Future<bool> _confirmDeleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteProduct(Product product) async {
    final repo = ref.read(productsRepositoryProvider);
    await repo.softDeleteProduct(product.id);

    // Invalidate product & barcode providers so Billing, Search, and Barcode lists immediately update
    ref.invalidate(productsListStreamProvider);
    ref.invalidate(barcodeQueueStreamProvider);
    ref.read(barcodeCacheServiceProvider).invalidate();

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Product deleted successfully.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accentAmber,
          onPressed: () async {
            await repo.restoreProduct(product.id);
            ref.invalidate(productsListStreamProvider);
            ref.invalidate(barcodeQueueStreamProvider);
            ref.read(barcodeCacheServiceProvider).invalidate();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
    // Explicit timer to force auto-dismiss after timeout
    Future.delayed(const Duration(seconds: 4), () {
      controller.close();
    });
  }

  Widget _buildSwipeBackground({required bool isGrid}) {
    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 8.0),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: isGrid ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.errorRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
          SizedBox(height: 2),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Product product, String currency, bool isDark) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey('product_list_${product.id}'),
        direction: DismissDirection.endToStart,
        background: _buildSwipeBackground(isGrid: false),
        confirmDismiss: (direction) => _confirmDeleteProduct(product),
        onDismissed: (_) => _deleteProduct(product),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CustomCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: () => context.push(AppRoutes.productEditPath(product.id)),
            child: Row(
              children: [
                // Product thumbnail (cacheWidth: 150 for 60fps Poco C51 performance)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    child: product.imagePath != null && File(product.imagePath!).existsSync()
                        ? Image.file(
                            File(product.imagePath!),
                            fit: BoxFit.cover,
                            cacheWidth: 150,
                            cacheHeight: 150,
                            filterQuality: FilterQuality.low,
                          )
                        : Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 26),
                  ),
                ),
              const SizedBox(width: 12),
              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.section.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Unit: ${product.unit}',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (settings.gstEnabled && product.gstRate > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GST ${product.gstRate.toInt()}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(product.price, symbol: currency),
                    style: AppTypography.priceMedium.copyWith(fontSize: 15),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                        tooltip: 'Barcode Label',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showBarcodeLabel(product),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          product.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 20,
                          color: product.isFavorite ? AppColors.accentAmber : null,
                        ),
                        tooltip: 'Favorite',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref.read(productsRepositoryProvider).toggleFavorite(product.id, product.isFavorite);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildGridCard(Product product, String currency, bool isDark) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey('product_grid_${product.id}'),
        direction: DismissDirection.endToStart,
        background: _buildSwipeBackground(isGrid: true),
        confirmDismiss: (direction) => _confirmDeleteProduct(product),
        onDismissed: (_) => _deleteProduct(product),
        child: CustomCard(
          padding: const EdgeInsets.all(10),
          onTap: () => context.push(AppRoutes.productEditPath(product.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        child: product.imagePath != null && File(product.imagePath!).existsSync()
                            ? Image.file(
                                File(product.imagePath!),
                                fit: BoxFit.cover,
                                cacheWidth: 150,
                                cacheHeight: 150,
                                filterQuality: FilterQuality.low,
                              )
                            : Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 36),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () {
                        ref.read(productsRepositoryProvider).toggleFavorite(product.id, product.isFavorite);
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        child: Icon(
                          product.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 16,
                          color: product.isFavorite ? AppColors.accentAmber : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.section.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.currency(product.price, symbol: currency),
                  style: AppTypography.priceMedium.copyWith(fontSize: 14),
                ),
                Text(
                  '/${product.unit}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}
