import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../customers/data/customers_repository.dart';
import '../../data/billing_repository.dart';
import '../../domain/cart_item.dart';
import '../providers/cart_provider.dart';

class HeldBillsSheet extends ConsumerWidget {
  final String currencySymbol;

  const HeldBillsSheet({super.key, required this.currencySymbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final heldBillsAsync = ref.watch(heldBillsStreamProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Held Bills', style: AppTypography.heading3.copyWith(fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: heldBillsAsync.when(
              data: (bills) {
                if (bills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 10),
                        const Text('No held bills', style: AppTypography.captionBold),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = bills[index];
                    final bill = entry.bill;
                    final itemCount = entry.itemCount;

                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            // Customer name + caption
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (bill.customerName != null && bill.customerName!.trim().isNotEmpty)
                                        ? bill.customerName!.trim()
                                        : 'Walk-in Customer',
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${Formatters.formatTime(bill.date)} • $itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Total on the right (bold)
                            Flexible(
                              child: Text(
                                Formatters.currency(bill.grandTotal, symbol: currencySymbol),
                                style: AppTypography.priceBold.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Resume button
                            FilledButton.tonal(
                              onPressed: () async {
                                final billingRepo = ref.read(billingRepositoryProvider);
                                final items = await billingRepo.getBillItems(bill.id);
                                Customer? customer;
                                if (bill.customerId != null) {
                                  final custRepo = ref.read(customersRepositoryProvider);
                                  customer = await custRepo.getCustomerById(bill.customerId!);
                                }

                                final cartItems = items.map((it) {
                                  return CartItem(
                                    productId: it.productId,
                                    productName: it.productName,
                                    unit: it.unit,
                                    isDecimalAllowed: it.unit == 'kg' ||
                                        it.unit == 'ltr' ||
                                        it.unit == 'gm' ||
                                        it.unit == 'ml',
                                    quantity: it.quantity,
                                    unitPrice: it.unitPrice,
                                    discountAmount: it.discountAmount,
                                    gstRate: it.gstRate,
                                  );
                                }).toList();

                                ref.read(cartProvider.notifier).loadFromHeldBill(
                                  items: cartItems,
                                  customer: customer,
                                  heldBillId: bill.id,
                                  notes: bill.notes,
                                  billDiscountPercent: bill.billDiscountPercent,
                                  billDiscountAmount: bill.billDiscountAmount,
                                  isBillDiscountPercent: bill.billDiscountPercent > 0,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Resumed held bill ${bill.billNumber}')),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Resume', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 2),
                            // Delete icon
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Held Bill?'),
                                    content: Text('Are you sure you want to delete ${bill.billNumber}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await ref.read(billingRepositoryProvider).deleteHeldBill(bill.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
