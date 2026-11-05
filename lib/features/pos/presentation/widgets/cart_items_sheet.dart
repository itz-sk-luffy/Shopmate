import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/barcode_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_helper.dart';
import '../../../products/data/products_repository.dart';
import '../../domain/cart_item.dart';
import '../providers/cart_provider.dart';
import 'checkout_sheet.dart';
import 'custom_item_dialog.dart';

class CartItemsSheet extends ConsumerWidget {
  final String currencySymbol;

  const CartItemsSheet({super.key, required this.currencySymbol});

  void _openCustomItemDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    showDialog(
      context: context,
      builder: (ctx) => CustomItemDialog(
        defaultGstRate: settings.gstEnabled ? settings.taxRateDefault : 0.0,
        isGstEnabled: settings.gstEnabled,
        onAdd: ({
          required String name,
          required double price,
          required double quantity,
          required String unit,
          required double gstRate,
          required bool isDecimalAllowed,
          int? categoryId,
          String? barcode,
          bool saveToCatalog = false,
        }) async {
          if (saveToCatalog) {
            try {
              final repo = ref.read(productsRepositoryProvider);
              final newId = await repo.addProduct(
                ProductsCompanion.insert(
                  name: name,
                  price: price,
                  gstRate: drift.Value(gstRate),
                  unit: drift.Value(unit),
                  categoryId: drift.Value(categoryId),
                  barcode: drift.Value(barcode),
                ),
              );
              ref.invalidate(productsListStreamProvider);
              ref.invalidate(categoryProductCountsStreamProvider);
              ref.read(barcodeCacheServiceProvider).invalidate();
              final newProd = await repo.getProductById(newId);
              if (newProd != null) {
                ref.read(cartProvider.notifier).addItem(newProd, quantity: quantity);
                return;
              }
            } catch (e) {
              debugPrint('Error saving custom item to catalog: $e');
            }
          }

          ref.read(cartProvider.notifier).addCustomItem(
            name: name,
            price: price,
            quantity: quantity,
            unit: unit,
            gstRate: gstRate,
            isDecimalAllowed: isDecimalAllowed,
          );
        },
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    WidgetRef ref,
    int index,
    CartItem item,
  ) {
    final qtyCtrl = TextEditingController(
      text: item.isDecimalAllowed
          ? item.quantity.toStringAsFixed(3)
          : item.quantity.toInt().toString(),
    );
    final priceCtrl = TextEditingController(
      text: item.unitPrice.toStringAsFixed(
        item.unitPrice.truncateToDouble() == item.unitPrice ? 0 : 2,
      ),
    );
    final discountCtrl = TextEditingController(
      text: item.discountAmount > 0
          ? item.discountAmount.toStringAsFixed(
              item.discountAmount.truncateToDouble() == item.discountAmount
                  ? 0
                  : 2,
            )
          : '',
    );
    final gstCtrl = TextEditingController(
      text: item.gstRate.toStringAsFixed(
        item.gstRate.truncateToDouble() == item.gstRate ? 0 : 1,
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit: ${item.productName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Quantity (${item.unit})',
                  helperText: item.isDecimalAllowed
                      ? 'Decimal weights allowed'
                      : 'Piece count (integers)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Unit Price',
                  prefixText: '$currencySymbol ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Line Discount',
                  prefixText: '$currencySymbol ',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gstCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'GST Rate (%)',
                  suffixText: '%',
                  hintText: '0, 5, 12, 18, 28',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newQty =
                  double.tryParse(qtyCtrl.text.trim()) ?? item.quantity;
              final newPrice =
                  double.tryParse(priceCtrl.text.trim()) ?? item.unitPrice;
              final newDisc =
                  double.tryParse(discountCtrl.text.trim()) ?? 0.0;
              final newGst = double.tryParse(gstCtrl.text.trim());

              ref.read(cartProvider.notifier).updateCartItem(
                    index,
                    quantity: newQty,
                    unitPrice: newPrice,
                    discountAmount: newDisc,
                    gstRate: newGst,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to POS Catalog',
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Text('Current Cart', style: AppTypography.heading3.copyWith(fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cart.itemCount} items',
                          style: AppTypography.captionBold.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openCustomItemDialog(context, ref),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton.icon(
                  onPressed: cart.items.isEmpty
                      ? null
                      : () {
                          ref.read(cartProvider.notifier).clearCart();
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close Cart',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 10),
                        const Text('Cart is empty', style: AppTypography.captionBold),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => _openCustomItemDialog(context, ref),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Item'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      return Dismissible(
                        key: ValueKey('${item.productName}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(cartProvider.notifier).removeItem(index);
                        },
                        child: Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                              width: 0.8,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product thumbnail preview
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: item.imagePath != null &&
                                                item.imagePath!.isNotEmpty &&
                                                File(item.imagePath!).existsSync()
                                            ? Builder(builder: (_) {
                                                final thumb = ImageHelper.getThumbnailPath(item.imagePath!);
                                                final imgFile = File(thumb).existsSync() ? File(thumb) : File(item.imagePath!);
                                                return Image.file(
                                                  imgFile,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 100,
                                                  cacheHeight: 100,
                                                  filterQuality: FilterQuality.low,
                                                  errorBuilder: (_, __, ___) => Icon(
                                                    Icons.inventory_2_outlined,
                                                    size: 22,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                );
                                              })
                                            : Icon(
                                                Icons.inventory_2_outlined,
                                                size: 22,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 2,
                                            children: [
                                              Text(
                                                '${Formatters.currency(item.unitPrice, symbol: currencySymbol)} / ${item.unit}',
                                                style: AppTypography.caption,
                                              ),
                                              if (cart.gstType != 'none')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'GST ${item.gstRate.toStringAsFixed(item.gstRate.truncateToDouble() == item.gstRate ? 0 : 1)}%',
                                                    style: AppTypography.captionBold.copyWith(
                                                      fontSize: 10,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              if (item.discountAmount > 0)
                                                Text(
                                                  'Disc: -${Formatters.currency(item.discountAmount, symbol: currencySymbol)}',
                                                  style: AppTypography.captionBold.copyWith(
                                                    color: AppColors.successGreen,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      Formatters.currency(item.discountedSubtotal, symbol: currencySymbol),
                                      style: AppTypography.priceBold.copyWith(
                                        fontSize: 15,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  height: 1,
                                  thickness: 0.6,
                                  color: (isDark ? AppColors.darkOutline : AppColors.lightOutline).withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Stepper (- qty +)
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 16),
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.all(6),
                                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                              onPressed: () => ref.read(cartProvider.notifier).decrementQuantity(index),
                                            ),
                                            InkWell(
                                              onTap: () => _showEditItemDialog(context, ref, index, item),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Text(
                                                  item.isDecimalAllowed
                                                      ? item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 3)
                                                      : item.quantity.toInt().toString(),
                                                  style: AppTypography.priceBold.copyWith(fontSize: 14),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 16),
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.all(6),
                                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                              onPressed: () => ref.read(cartProvider.notifier).incrementQuantity(index),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Action buttons: Edit & Delete
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _showEditItemDialog(context, ref, index, item),
                                            icon: const Icon(Icons.edit_outlined, size: 14),
                                            label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              minimumSize: const Size(60, 36),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton.tonalIcon(
                                            onPressed: () => ref.read(cartProvider.notifier).removeItem(index),
                                            icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.errorRed),
                                            label: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.errorRed,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: FilledButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              backgroundColor: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                                              foregroundColor: AppColors.errorRed,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              minimumSize: const Size(64, 36),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Bar: Summary & Proceed to Checkout
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(top: BorderSide(color: isDark ? AppColors.darkOutline : AppColors.lightOutline)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GST & Totals Breakup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: AppTypography.caption),
                      Text(Formatters.currency(cart.rawSubtotal, symbol: currencySymbol), style: AppTypography.captionBold),
                    ],
                  ),
                  if (cart.itemsDiscountTotal > 0 || cart.billDiscountTotal > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount', style: AppTypography.caption),
                        Text(
                          '- ${Formatters.currency(cart.itemsDiscountTotal + cart.billDiscountTotal, symbol: currencySymbol)}',
                          style: AppTypography.captionBold.copyWith(color: AppColors.successGreen),
                        ),
                      ],
                    ),
                  ],
                  if (cart.gstType != 'none' && cart.totalGst > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Taxable value', style: AppTypography.caption),
                        Text(Formatters.currency(cart.taxableAmount, symbol: currencySymbol), style: AppTypography.captionBold),
                      ],
                    ),
                    if (cart.isInterState)
                      for (final b in cart.rateBreakups) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('IGST ${b.igstRate.toStringAsFixed(b.igstRate.truncateToDouble() == b.igstRate ? 0 : 1)}%', style: AppTypography.caption),
                            Text(Formatters.currency(b.igstAmount, symbol: currencySymbol), style: AppTypography.captionBold),
                          ],
                        ),
                      ]
                    else
                      for (final b in cart.rateBreakups) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CGST ${b.cgstRate.toStringAsFixed(b.cgstRate.truncateToDouble() == b.cgstRate ? 0 : 1)}%', style: AppTypography.caption),
                            Text(Formatters.currency(b.cgstAmount, symbol: currencySymbol), style: AppTypography.captionBold),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SGST ${b.sgstRate.toStringAsFixed(b.sgstRate.truncateToDouble() == b.sgstRate ? 0 : 1)}%', style: AppTypography.caption),
                            Text(Formatters.currency(b.sgstAmount, symbol: currencySymbol), style: AppTypography.captionBold),
                          ],
                        ),
                      ],
                  ],
                  if (cart.roundOff.abs() > 0.001) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Round-off', style: AppTypography.caption),
                        Text('${cart.roundOff >= 0 ? '+' : ''}${cart.roundOff.toStringAsFixed(2)}', style: AppTypography.captionBold),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('+ Add Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (ctx) => CheckoutSheet(currencySymbol: currencySymbol),
                            );
                          },
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: Text(
                            'Pay ${Formatters.currency(cart.grandTotal, symbol: currencySymbol)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
