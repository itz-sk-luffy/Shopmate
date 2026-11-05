import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/barcode_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/products_repository.dart';
import 'product_edit_screen.dart';

class UnmatchedScansScreen extends ConsumerStatefulWidget {
  const UnmatchedScansScreen({super.key});

  @override
  ConsumerState<UnmatchedScansScreen> createState() => _UnmatchedScansScreenState();
}

class _UnmatchedScansScreenState extends ConsumerState<UnmatchedScansScreen> {
  @override
  void initState() {
    super.initState();
    _purgeOldScans();
  }

  Future<void> _purgeOldScans() async {
    final db = ref.read(databaseProvider);
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    await (db.delete(db.unmatchedScans)..where((tbl) => tbl.lastScannedAt.isSmallerOrEqualValue(cutoff))).go();
  }

  void _onTapScan(UnmatchedScan item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_rounded, color: AppColors.primaryTeal),
              title: Text('Barcode: ${item.barcode}', style: AppTypography.heading3),
              subtitle: Text('Scanned ${item.scanCount} times • Last: ${DateFormat.yMMMd().add_jm().format(item.lastScannedAt)}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_box_rounded),
              title: const Text('Create New Product with this barcode'),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductEditScreen(),
                  ),
                );
                if (res != null) {
                  _deleteScan(item.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Attach to Existing Product'),
              onTap: () {
                Navigator.pop(ctx);
                _openAttachDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
              title: const Text('Delete Entry', style: TextStyle(color: AppColors.errorRed)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteScan(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteScan(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.unmatchedScans)..where((tbl) => tbl.id.equals(id))).go();
    setState(() {});
  }

  void _openAttachDialog(UnmatchedScan scan) async {
    final repo = ref.read(productsRepositoryProvider);
    final products = await repo.getAllActiveProducts();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = products.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();

            return AlertDialog(
              title: Text('Attach ${scan.barcode} to Product', style: AppTypography.heading3),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search Product',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) => setDialogState(() => query = val),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final prod = filtered[idx];
                          return ListTile(
                            title: Text(prod.name, style: AppTypography.bodyMedium),
                            subtitle: Text('Price: ${prod.price} • Current: ${prod.barcode ?? "No barcode"}'),
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await repo.assignBarcodeToProduct(productId: prod.id, barcode: scan.barcode);
                              ref.read(barcodeCacheServiceProvider).invalidate();
                              await _deleteScan(scan.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Attached ${scan.barcode} to ${prod.name}'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unmatched Scans Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear All Logged Scans',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All Scans?'),
                  content: const Text('Are you sure you want to clear the entire unmatched scans log?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear All')),
                  ],
                ),
              );
              if (ok == true) {
                await db.delete(db.unmatchedScans).go();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<UnmatchedScan>>(
        stream: (db.select(db.unmatchedScans)..orderBy([(t) => drift.OrderingTerm.desc(t.lastScannedAt)])).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final scans = snapshot.data!;
          if (scans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.barcode_reader, size: 64, color: AppColors.lightOutlineVariant),
                  SizedBox(height: 16),
                  Text('No unmatched scans found', style: AppTypography.heading3),
                  SizedBox(height: 6),
                  Text('Barcodes scanned that are not in catalog will appear here.', style: AppTypography.caption),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: scans.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = scans[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryTeal),
                ),
                title: Text(item.barcode, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Last scanned: ${DateFormat.yMMMd().add_jm().format(item.lastScannedAt)}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryTeal),
                  ),
                  child: Text('${item.scanCount}x', style: AppTypography.captionBold.copyWith(color: AppColors.primaryTeal)),
                ),
                onTap: () => _onTapScan(item),
              );
            },
          );
        },
      ),
    );
  }
}
