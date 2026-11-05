import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../data/products_repository.dart';

class ProductMergeScreen extends ConsumerStatefulWidget {
  const ProductMergeScreen({super.key});

  @override
  ConsumerState<ProductMergeScreen> createState() => _ProductMergeScreenState();
}

class _ProductMergeScreenState extends ConsumerState<ProductMergeScreen> {
  bool _isLoading = true;
  Map<String, List<Product>> _duplicateGroups = {};

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  @override
  void dispose() {
    ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }

  Future<void> _findDuplicates() async {
    final repo = ref.read(productsRepositoryProvider);
    final allProducts = await repo.getAllActiveProducts();

    final Map<String, List<Product>> map = {};
    for (final p in allProducts) {
      final key = p.name.trim().toLowerCase();
      map.putIfAbsent(key, () => []).add(p);
    }

    final duplicates = <String, List<Product>>{};
    for (final entry in map.entries) {
      if (entry.value.length > 1) {
        duplicates[entry.key] = entry.value;
      }
    }

    if (mounted) {
      setState(() {
        _duplicateGroups = duplicates;
        _isLoading = false;
      });
    }
  }

  void _confirmMerge({required Product target, required List<Product> sources}) async {
    final sourceIds = sources.map((s) => s.id).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Product Merge', style: AppTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merge ${sources.length} products into:', style: AppTypography.body),
            const SizedBox(height: 6),
            Text(
              '${target.name} (ID: ${target.id})',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'All barcodes, variants, and order history will be reassigned to this product. The secondary items will be moved to the Recycle Bin (you can undo anytime).',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm Merge')),
        ],
      ),
    );

    if (ok == true && mounted) {
      final repo = ref.read(productsRepositoryProvider);
      await repo.mergeProducts(targetProductId: target.id, sourceProductIds: sourceIds);
      ref.read(barcodeCacheServiceProvider).invalidate();

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text('Merged products into ${target.name}'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.warningAmber,
              onPressed: () async {
                final repo = ref.read(productsRepositoryProvider);
                for (final id in sourceIds) {
                  await repo.restoreProduct(id);
                }
                _findDuplicates();
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        // Force dismiss after timeout so accessibility mode does not lock it on screen
        Future.delayed(const Duration(seconds: 4), () {
          controller.close();
        });
        _findDuplicates();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge Duplicate Products'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _duplicateGroups.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.successGreen),
                      SizedBox(height: 16),
                      Text('No duplicate product names found', style: AppTypography.heading3),
                      SizedBox(height: 6),
                      Text('All active catalog products have distinct names.', style: AppTypography.caption),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _duplicateGroups.length,
                  itemBuilder: (context, idx) {
                    final groupName = _duplicateGroups.keys.elementAt(idx);
                    final prods = _duplicateGroups[groupName]!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    prods.first.name,
                                    style: AppTypography.heading3,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${prods.length} duplicates',
                                    style: AppTypography.captionBold.copyWith(color: AppColors.accentAmber),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            ...prods.map((p) {
                              final otherSources = prods.where((it) => it.id != p.id).toList();

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primaryTeal),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'ID #${p.id} • ${Formatters.currency(p.price, symbol: settings.currencySymbol)}',
                                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Barcode: ${p.barcode ?? "None"} • Unit: ${p.unit}',
                                            style: AppTypography.caption,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: const Size(80, 36),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _confirmMerge(target: p, sources: otherSources),
                                      child: const Text('Keep this', style: TextStyle(fontSize: 12), maxLines: 1),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
