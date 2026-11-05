import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/database_provider.dart';
import '../../customers/data/customers_repository.dart';
import '../../pos/domain/cart_item.dart';
import '../../pos/presentation/providers/cart_provider.dart';
import '../../printer/services/receipt_actions.dart';
import '../data/orders_repository.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int billId;

  const OrderDetailScreen({super.key, required this.billId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isLoading = true;
  Bill? _bill;
  List<BillItem> _items = [];
  List<BillEdit> _edits = [];

  @override
  void initState() {
    super.initState();
    _loadBillData();
  }

  void _loadBillData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(ordersRepositoryProvider);
    final bill = await repo.getBillById(widget.billId);
    final items = await repo.getBillItems(widget.billId);
    final edits = await repo.getBillEdits(widget.billId);

    if (mounted) {
      setState(() {
        _bill = bill;
        _items = items;
        _edits = edits;
        _isLoading = false;
      });
    }
  }

  void _markCreditAsPaid() {
    if (_bill == null) return;
    String chosenMode = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Mark Credit as Paid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collect ${Formatters.currency(_bill!.grandTotal)} from ${_bill!.customerName ?? 'Customer'}',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 14),
              const Text('Payment Mode Received:', style: AppTypography.captionBold),
              const SizedBox(height: 8),
              Row(
                children: ['Cash', 'UPI'].map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m),
                      selected: chosenMode == m,
                      onSelected: (val) {
                        if (val) setDlgState(() => chosenMode = m);
                      },
                    ),
                  );
                }).toList(),
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
                Navigator.pop(ctx);
                final repo = ref.read(ordersRepositoryProvider);
                await repo.markCreditAsPaid(_bill!.id, paymentMode: chosenMode);
                _loadBillData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Marked bill ${_bill!.billNumber} as Paid via $chosenMode'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _editBill() async {
    if (_bill == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Past Bill?'),
        content: Text(
          'This will load ${_bill!.billNumber} into the billing cart. The SAME bill number will be preserved when you save your edits.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed to Edit')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    Customer? customer;
    if (_bill!.customerId != null) {
      final custRepo = ref.read(customersRepositoryProvider);
      customer = await custRepo.getCustomerById(_bill!.customerId!);
    }

    if (!mounted) return;

    final cartItems = _items.map((it) {
      return CartItem(
        productId: it.productId,
        productName: it.productName,
        unit: it.unit,
        isDecimalAllowed: it.unit == 'kg' || it.unit == 'ltr' || it.unit == 'gm' || it.unit == 'ml',
        quantity: it.quantity,
        unitPrice: it.unitPrice,
        discountAmount: it.discountAmount,
        gstRate: it.gstRate,
      );
    }).toList();

    // Load into cart
    ref.read(cartProvider.notifier).loadFromHeldBill(
      items: cartItems,
      customer: customer,
      heldBillId: _bill!.id, // Used to identify edit in billing repo
      notes: _bill!.notes,
      billDiscountPercent: _bill!.billDiscountPercent,
      billDiscountAmount: _bill!.billDiscountAmount,
      isBillDiscountPercent: _bill!.billDiscountPercent > 0,
    );

    // Switch to billing tab
    context.go(AppRoutes.billing);
  }

  void _duplicateBill() {
    if (_bill == null) return;

    final cartItems = _items.map((it) {
      return CartItem(
        productId: it.productId,
        productName: it.productName,
        unit: it.unit,
        isDecimalAllowed: it.unit == 'kg' || it.unit == 'ltr' || it.unit == 'gm' || it.unit == 'ml',
        quantity: it.quantity,
        unitPrice: it.unitPrice,
        discountAmount: it.discountAmount,
        gstRate: it.gstRate,
      );
    }).toList();

    ref.read(cartProvider.notifier).clearCart();
    for (final item in cartItems) {
      ref.read(cartProvider.notifier).addCustomItem(
        name: item.productName,
        price: item.unitPrice,
        quantity: item.quantity,
        unit: item.unit,
        gstRate: item.gstRate,
        isDecimalAllowed: item.isDecimalAllowed,
      );
    }

    context.go(AppRoutes.billing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cloned items from ${_bill!.billNumber} into new bill')),
    );
  }

  void _deleteBill() async {
    if (_bill == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Recycle Bin?'),
        content: Text(
          'Bill ${_bill!.billNumber} will be moved to the 30-day Recycle Bin. You can restore it anytime.',
        ),
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

    if (confirm != true || !mounted) return;

    final repo = ref.read(ordersRepositoryProvider);
    await repo.softDeleteBill(_bill!.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill ${_bill!.billNumber} moved to Recycle Bin')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: Text('Bill not found')),
      );
    }

    final bill = _bill!;

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackRoute: AppRoutes.orders),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bill.billNumber, style: AppTypography.heading3.copyWith(fontSize: 18)),
            Text(Formatters.dateTime(bill.date), style: AppTypography.caption),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Duplicate Bill',
            onPressed: _duplicateBill,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
            tooltip: 'Move to Recycle Bin',
            onPressed: _deleteBill,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                avatar: const Icon(Icons.payment_rounded, size: 16),
                label: Text(bill.paymentMode),
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                side: BorderSide.none,
              ),
              if (bill.isEdited)
                const Chip(
                  avatar: Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFD97706)),
                  label: Text('Edited'),
                  backgroundColor: Color(0xFFFEF3C7),
                  side: BorderSide.none,
                ),
              if (bill.paymentMode == 'Credit')
                Chip(
                  avatar: Icon(
                    bill.isCreditPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                    size: 16,
                    color: bill.isCreditPaid ? AppColors.successGreen : AppColors.errorRed,
                  ),
                  label: Text(bill.isCreditPaid ? 'Udhaar Paid' : 'Udhaar Unpaid'),
                  backgroundColor: (bill.isCreditPaid ? AppColors.successGreen : AppColors.errorRed)
                      .withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bill.customerName ?? 'Walk-in Customer',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty)
                          Text(
                            bill.customerPhone!,
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (bill.paymentMode == 'Credit' && !bill.isCreditPaid) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _markCreditAsPaid,
                      child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Items List Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items Purchased', style: AppTypography.captionBold),
                      Text('${_items.length} item(s)', style: AppTypography.caption),
                    ],
                  ),
                  const Divider(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${Formatters.formatQuantity(item.quantity, item.unit)} × ${Formatters.currency(item.unitPrice, symbol: settings.currencySymbol)}',
                                  style: AppTypography.caption,
                                ),
                                if (item.discountAmount > 0)
                                  Text(
                                    'Disc: -${Formatters.currency(item.discountAmount, symbol: settings.currencySymbol)}',
                                    style: AppTypography.captionBold.copyWith(
                                      color: AppColors.successGreen,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.currency(item.totalAmount, symbol: settings.currencySymbol),
                            style: AppTypography.priceBold.copyWith(fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Financial Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildSummaryLine('Subtotal', Formatters.currency(bill.subtotal, symbol: settings.currencySymbol)),
                  if (bill.itemDiscountTotal > 0)
                    _buildSummaryLine(
                      'Item Discounts',
                      '- ${Formatters.currency(bill.itemDiscountTotal, symbol: settings.currencySymbol)}',
                      color: AppColors.successGreen,
                    ),
                  if (bill.billDiscountAmount > 0)
                    _buildSummaryLine(
                      'Bill Discount',
                      '- ${Formatters.currency(bill.billDiscountAmount, symbol: settings.currencySymbol)}',
                      color: AppColors.successGreen,
                    ),
                  if (bill.gstType != 'none' && (bill.cgstTotal > 0 || bill.sgstTotal > 0 || bill.igstTotal > 0)) ...[
                    _buildSummaryLine(
                      'Taxable Value',
                      Formatters.currency(
                        _items.fold(0.0, (acc, i) => acc + (i.taxableValue > 0 ? i.taxableValue : (i.quantity * i.unitPrice - i.discountAmount))),
                        symbol: settings.currencySymbol,
                      ),
                    ),
                    if (bill.igstTotal > 0)
                      ..._buildIgstBreakupLines(bill, settings.currencySymbol)
                    else
                      ..._buildCgstSgstBreakupLines(bill, settings.currencySymbol),
                  ],
                  if (bill.roundOff.abs() > 0.001)
                    _buildSummaryLine(
                      'Round-off',
                      '${bill.roundOff >= 0 ? '+' : ''}${bill.roundOff.toStringAsFixed(2)}',
                    ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grand Total', style: AppTypography.heading3.copyWith(fontSize: 18)),
                      Text(
                        Formatters.currency(bill.grandTotal, symbol: settings.currencySymbol),
                        style: AppTypography.priceBold.copyWith(
                          fontSize: 22,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Edit History Timeline (if bill was edited)
          if (_edits.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 20, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Text('Edit History (${_edits.length})', style: AppTypography.captionBold),
                      ],
                    ),
                    const Divider(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _edits.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final edit = _edits[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  Formatters.dateTime(edit.editedAt),
                                  style: AppTypography.captionBold,
                                ),
                                Text(
                                  '${Formatters.currency(edit.previousTotal, symbol: settings.currencySymbol)} → ${Formatters.currency(edit.newTotal, symbol: settings.currencySymbol)}',
                                  style: AppTypography.priceBold.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                            if (edit.reasonNotes != null && edit.reasonNotes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Reason: ${edit.reasonNotes}', style: AppTypography.caption),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action Buttons: Print & Share
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(receiptActionsProvider).printThermal(bill.id, context: context);
                  },
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('58 mm Receipt'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(receiptActionsProvider).shareA4(bill.id, context: context);
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share A4 PDF'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(receiptActionsProvider).a4Pdf(bill.id, context: context);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Preview / Print A4 PDF Invoice'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
          const SizedBox(height: 12),
          // Action Buttons: Edit Bill
          FilledButton.icon(
            onPressed: _editBill,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Edit Bill (Same Bill #)'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildIgstBreakupLines(Bill bill, String currencySymbol) {
    final rateMap = <double, double>{};
    for (final item in _items) {
      if (item.gstRate > 0) {
        rateMap[item.gstRate] = (rateMap[item.gstRate] ?? 0.0) + item.igstAmount;
      }
    }
    if (rateMap.isEmpty) {
      return [_buildSummaryLine('IGST', Formatters.currency(bill.igstTotal, symbol: currencySymbol))];
    }
    final sorted = rateMap.keys.toList()..sort();
    return sorted.map((r) {
      final label = 'IGST ${r.toStringAsFixed(r.truncateToDouble() == r ? 0 : 1)}%';
      return _buildSummaryLine(label, Formatters.currency(rateMap[r]!, symbol: currencySymbol));
    }).toList();
  }

  List<Widget> _buildCgstSgstBreakupLines(Bill bill, String currencySymbol) {
    final cgstMap = <double, double>{};
    final sgstMap = <double, double>{};
    for (final item in _items) {
      if (item.gstRate > 0) {
        cgstMap[item.gstRate] = (cgstMap[item.gstRate] ?? 0.0) + item.cgstAmount;
        sgstMap[item.gstRate] = (sgstMap[item.gstRate] ?? 0.0) + item.sgstAmount;
      }
    }
    if (cgstMap.isEmpty) {
      return [
        _buildSummaryLine('CGST', Formatters.currency(bill.cgstTotal, symbol: currencySymbol)),
        _buildSummaryLine('SGST', Formatters.currency(bill.sgstTotal, symbol: currencySymbol)),
      ];
    }
    final sorted = cgstMap.keys.toList()..sort();
    final widgets = <Widget>[];
    for (final r in sorted) {
      final halfRate = r / 2.0;
      final rateStr = halfRate.toStringAsFixed(halfRate.truncateToDouble() == halfRate ? 0 : 1);
      final cgstAmt = cgstMap[r] ?? 0.0;
      final sgstAmt = sgstMap[r] ?? 0.0;
      widgets.add(_buildSummaryLine('CGST $rateStr%', Formatters.currency(cgstAmt > 0 ? cgstAmt : bill.cgstTotal / sorted.length, symbol: currencySymbol)));
      widgets.add(_buildSummaryLine('SGST $rateStr%', Formatters.currency(sgstAmt > 0 ? sgstAmt : bill.sgstTotal / sorted.length, symbol: currencySymbol)));
    }
    return widgets;
  }

  Widget _buildSummaryLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: AppTypography.priceRegular.copyWith(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
