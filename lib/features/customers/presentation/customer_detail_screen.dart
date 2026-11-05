import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/database_provider.dart';
import '../../orders/data/orders_repository.dart';
import '../../recycle_bin/data/recycle_bin_repository.dart';
import '../data/customers_repository.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  Customer? _customer;
  List<Bill> _customerBills = [];
  double _totalCreditGiven = 0.0;
  double _totalReceived = 0.0;
  double _netPending = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final custRepo = ref.read(customersRepositoryProvider);
    final cust = await custRepo.getCustomerById(widget.customerId);

    final db = ref.read(databaseProvider);
    final bills = await (db.select(db.bills)
          ..where((tbl) => tbl.customerId.equals(widget.customerId) & tbl.isDeleted.equals(false))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.desc)]))
        .get();

    double creditGiven = 0.0;
    for (final b in bills) {
      if (b.paymentMode == 'Credit') {
        creditGiven += b.grandTotal;
      }
    }
    final net = (cust?.balance ?? 0.0).clamp(0.0, double.infinity);
    final received = (creditGiven - net).clamp(0.0, double.infinity);

    if (mounted) {
      setState(() {
        _customer = cust;
        _customerBills = bills;
        _totalCreditGiven = creditGiven;
        _totalReceived = received;
        _netPending = net;
        _isLoading = false;
      });
    }
  }

  void _recordPayment() {
    if (_customer == null) return;
    final amountCtrl = TextEditingController(
      text: _customer!.balance > 0 ? _customer!.balance.toStringAsFixed(0) : '',
    );
    String mode = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Record Udhaar Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Outstanding: ${Formatters.currency(_customer!.balance)}',
                style: AppTypography.captionBold.copyWith(color: AppColors.errorRed),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount Received *',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              const Text('Payment Mode', style: AppTypography.captionBold),
              const SizedBox(height: 6),
              Row(
                children: ['Cash', 'UPI', 'Bank'].map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m),
                      selected: mode == m,
                      onSelected: (val) {
                        if (val) setDlgState(() => mode = m);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }

                final db = ref.read(databaseProvider);
                await db.transaction(() async {
                  final newBalance = (_customer!.balance - amt).clamp(0.0, double.infinity);
                  await (db.update(db.customers)..where((tbl) => tbl.id.equals(_customer!.id))).write(
                    CustomersCompanion(
                      balance: drift.Value(newBalance),
                      updatedAt: drift.Value(DateTime.now()),
                    ),
                  );

                  // Update unpaid credit bills starting from oldest
                  final unpaidBills = await (db.select(db.bills)
                        ..where((tbl) =>
                            tbl.customerId.equals(_customer!.id) &
                            tbl.paymentMode.equals('Credit') &
                            tbl.isCreditPaid.equals(false) &
                            tbl.isDeleted.equals(false))
                        ..orderBy([(t) => drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.asc)]))
                      .get();

                  double remainingPayment = amt;
                  for (final b in unpaidBills) {
                    if (remainingPayment <= 0) break;
                    if (remainingPayment >= b.grandTotal - 0.01) {
                      await (db.update(db.bills)..where((tbl) => tbl.id.equals(b.id))).write(
                        BillsCompanion(
                          isCreditPaid: const drift.Value(true),
                          notes: drift.Value(
                            '${b.notes ?? ''} [Settled via $mode on ${DateTime.now().toString().split('.').first}]'.trim(),
                          ),
                          updatedAt: drift.Value(DateTime.now()),
                        ),
                      );
                      remainingPayment -= b.grandTotal;
                    } else {
                      // Partial settlement on this bill
                      await (db.update(db.bills)..where((tbl) => tbl.id.equals(b.id))).write(
                        BillsCompanion(
                          notes: drift.Value(
                            '${b.notes ?? ''} [Partially paid ${Formatters.currency(remainingPayment)} via $mode on ${DateTime.now().toString().split('.').first}]'.trim(),
                          ),
                          updatedAt: drift.Value(DateTime.now()),
                        ),
                      );
                      remainingPayment = 0;
                    }
                  }
                });

                ref.invalidate(customersStreamProvider);
                _loadData();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recorded payment of ${Formatters.currency(amt)} via $mode'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendPaymentReminder() {
    if (_customer == null) return;
    if (_customer!.balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer has no pending balance.')),
      );
      return;
    }

    final settings = ref.read(settingsProvider);
    final msg =
        'Hello ${_customer!.name}, this is a gentle reminder from ${settings.storeName}. Your pending Udhaar balance is ₹${_customer!.balance.toStringAsFixed(2)}. Kindly settle it at your earliest convenience. Thank you!';

    Share.share(msg, subject: 'Payment Reminder - ${settings.storeName}');
  }

  void _deleteCustomer() async {
    if (_customer == null) return;
    final cust = _customer!;
    final settings = ref.read(settingsProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          cust.balance > 0
              ? '${cust.name} has a pending Udhaar balance of ${Formatters.currency(cust.balance, symbol: settings.currencySymbol)}.\n\nAre you sure you want to delete this customer?'
              : 'Are you sure you want to delete "${cust.name}" from the customer ledger?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(customersRepositoryProvider);
      await repo.deleteCustomer(cust.id);
      ref.invalidate(customersStreamProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted customer "${cust.name}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await repo.addCustomer(
                  CustomersCompanion(
                    id: drift.Value(cust.id),
                    name: drift.Value(cust.name),
                    phone: drift.Value(cust.phone),
                    balance: drift.Value(cust.balance),
                    createdAt: drift.Value(cust.createdAt),
                  ),
                );
                ref.invalidate(customersStreamProvider);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final cust = _customer!;

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackRoute: AppRoutes.customers),
        title: Text(cust.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Send Payment Reminder',
            onPressed: _sendPaymentReminder,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
            tooltip: 'Delete Customer',
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Udhaar Ledger Summary Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Total Credit Given', style: AppTypography.caption.copyWith(fontSize: 10)),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.currency(_totalCreditGiven, symbol: settings.currencySymbol),
                          style: AppTypography.priceBold.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 26, width: 1, color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Total Received', style: AppTypography.caption.copyWith(fontSize: 10)),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.currency(_totalReceived, symbol: settings.currencySymbol),
                          style: AppTypography.priceBold.copyWith(fontSize: 13, color: AppColors.successGreen),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 26, width: 1, color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Net Pending Udhaar', style: AppTypography.caption.copyWith(fontSize: 10)),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.currency(_netPending, symbol: settings.currencySymbol),
                          style: AppTypography.priceBold.copyWith(
                            fontSize: 13,
                            color: _netPending > 0 ? AppColors.errorRed : AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Profile & Balance Hero Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          cust.name.isNotEmpty ? cust.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cust.name, style: AppTypography.heading3.copyWith(fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(cust.phone ?? 'No phone number', style: AppTypography.caption),
                            Text(
                              'Customer since ${Formatters.date(cust.createdAt)}',
                              style: AppTypography.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Outstanding Udhaar Balance',
                              style: AppTypography.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Formatters.currency(cust.balance, symbol: settings.currencySymbol),
                                style: AppTypography.priceBold.copyWith(
                                  fontSize: 22,
                                  color: cust.balance > 0 ? AppColors.errorRed : AppColors.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _recordPayment,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text(
                          'Record Payment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Send Reminder Action Card (if has balance)
          if (cust.balance > 0)
            Card(
              color: const Color(0xFF25D366).withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: const Color(0xFF25D366).withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, color: Color(0xFF15803D), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pending Udhaar Reminder',
                            style: AppTypography.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share payment reminder via WhatsApp or SMS',
                      style: AppTypography.caption.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _sendPaymentReminder,
                        icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'Send Payment Reminder',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Transaction History Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Purchase History (${_customerBills.length})', style: AppTypography.captionBold),
              if (_customerBills.isNotEmpty)
                Text('Swipe left to delete', style: AppTypography.caption.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),

          // Customer Bills List
          if (_customerBills.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No past bills recorded for this customer.')),
              ),
            )
          else
            ListView.separated(
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _customerBills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bill = _customerBills[index];
                return Dismissible(
                  key: ValueKey('cust_bill_${bill.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Move to Recycle Bin?'),
                        content: Text('Delete ${bill.billNumber}? It can be restored within 30 days.'),
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
                  },
                  onDismissed: (_) async {
                    setState(() {
                      _customerBills.removeWhere((b) => b.id == bill.id);
                    });
                    await ref.read(ordersRepositoryProvider).softDeleteBill(bill.id);
                    _loadData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Moved ${bill.billNumber} to Recycle Bin'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () async {
                              await ref.read(recycleBinRepositoryProvider).restoreBillById(bill.id);
                              _loadData();
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
                      ),
                      title: Text(bill.billNumber, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${Formatters.date(bill.date)} • ${bill.paymentMode}',
                        style: AppTypography.caption,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.currency(bill.grandTotal, symbol: settings.currencySymbol),
                            style: AppTypography.priceBold.copyWith(fontSize: 14),
                          ),
                          if (bill.paymentMode == 'Credit')
                            Text(
                              bill.isCreditPaid ? 'Paid' : 'Unpaid Udhaar',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: bill.isCreditPaid ? AppColors.successGreen : AppColors.errorRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      onTap: () => context.push(AppRoutes.orderDetailPath(bill.id)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
