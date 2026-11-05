import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../products/data/products_repository.dart';
import '../data/recycle_bin_repository.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  String _selectedFilter = 'All';

  Future<void> _handleRestore(RecycleBinItem item) async {
    final repo = ref.read(recycleBinRepositoryProvider);
    await repo.restoreItem(item);

    if (!mounted) return;
    ref.invalidate(recycleBinItemsProvider);
    ref.invalidate(productsListStreamProvider);
    ref.invalidate(barcodeQueueStreamProvider);
    ref.read(barcodeCacheServiceProvider).invalidate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored "${item.title}" successfully'),
        backgroundColor: AppColors.primaryTeal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePermanentDelete(RecycleBinItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Item?'),
        content: Text(
          'Are you sure you want to delete "${item.title}" permanently? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(recycleBinRepositoryProvider);
      await repo.permanentDeleteItem(item);

      if (!mounted) return;
      ref.invalidate(recycleBinItemsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted permanently'),
          backgroundColor: AppColors.errorRed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleEmptyBin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Entire Recycle Bin?'),
        content: const Text(
          'This will permanently delete ALL items in the Recycle Bin. This action is irreversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Empty Recycle Bin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(recycleBinRepositoryProvider);
      await repo.emptyRecycleBin();

      if (!mounted) return;
      ref.invalidate(recycleBinItemsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recycle Bin emptied completely'),
          backgroundColor: AppColors.errorRed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Color _typeColor(RecycleBinItemType type) {
    switch (type) {
      case RecycleBinItemType.product:
        return AppColors.primaryTeal;
      case RecycleBinItemType.bill:
        return const Color(0xFF0284C7);
      case RecycleBinItemType.expense:
        return AppColors.warningAmber;
    }
  }

  IconData _typeIcon(RecycleBinItemType type) {
    switch (type) {
      case RecycleBinItemType.product:
        return Icons.inventory_2_outlined;
      case RecycleBinItemType.bill:
        return Icons.receipt_long_outlined;
      case RecycleBinItemType.expense:
        return Icons.money_off_csred_outlined;
    }
  }

  String _typeLabel(RecycleBinItemType type) {
    switch (type) {
      case RecycleBinItemType.product:
        return 'Product';
      case RecycleBinItemType.bill:
        return 'Bill';
      case RecycleBinItemType.expense:
        return 'Expense';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final itemsAsync = ref.watch(recycleBinItemsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Recycle Bin (30 Days)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Empty Recycle Bin',
            onPressed: () => _handleEmptyBin(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 30-Day Auto Purge Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.warningAmber.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.auto_delete_outlined, color: AppColors.warningAmber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Items here are auto-purged after 30 days. You can restore them or delete them permanently anytime.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Products', 'Bills', 'Expenses'].map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Items List
          Expanded(
            child: itemsAsync.when(
              data: (allItems) {
                final filtered = allItems.where((item) {
                  if (_selectedFilter == 'Products') return item.type == RecycleBinItemType.product;
                  if (_selectedFilter == 'Bills') return item.type == RecycleBinItemType.bill;
                  if (_selectedFilter == 'Expenses') return item.type == RecycleBinItemType.expense;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'All'
                              ? 'Recycle Bin is completely empty'
                              : 'No $_selectedFilter in Recycle Bin',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final color = _typeColor(item.type);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Type avatar / Image
                            if (item.imagePath != null && File(item.imagePath!).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(item.imagePath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  cacheWidth: 100,
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_typeIcon(item.type), color: color, size: 24),
                              ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _typeLabel(item.type),
                                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        Formatters.currency(item.amount, symbol: settings.currencySymbol),
                                        style: AppTypography.priceBold.copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Deleted ${Formatters.timeAgo(item.deletedAt)} • ${item.daysRemaining} days left',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Actions
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore_rounded, color: AppColors.primaryTeal),
                                  tooltip: 'Restore item',
                                  onPressed: () => _handleRestore(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed),
                                  tooltip: 'Delete permanently',
                                  onPressed: () => _handlePermanentDelete(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading recycle bin: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
