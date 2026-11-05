import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/barcode_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../printer/services/receipt_actions.dart';
import '../data/orders_repository.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDateFilter = 'All';
  String _selectedPaymentMode = 'All';
  final List<({String char, int timeMs})> _keyBurstBuffer = [];

  final List<String> _dateFilters = ['All', 'Today', 'Yesterday', 'This Week', 'This Month', 'Credit Only'];
  final List<String> _paymentModes = ['All', 'Cash', 'UPI', 'Card', 'Credit', 'Split'];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _searchController.dispose();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_keyBurstBuffer.isNotEmpty) {
          bool isBurst = true;
          for (int i = 1; i < _keyBurstBuffer.length; i++) {
            if (_keyBurstBuffer[i].timeMs - _keyBurstBuffer[i - 1].timeMs > 50) {
              isBurst = false;
              break;
            }
          }
          final code = _keyBurstBuffer.map((e) => e.char).join();
          _keyBurstBuffer.clear();

          if (isBurst && code.isNotEmpty) {
            _openBillByCode(code);
            return true;
          }
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (_keyBurstBuffer.isNotEmpty && (now - _keyBurstBuffer.last.timeMs) > 100) {
          _keyBurstBuffer.clear();
        }
        _keyBurstBuffer.add((char: event.character!, timeMs: now));
      }
    }
    return false;
  }

  void _openBillByCode(String code) async {
    final clean = BarcodeUtils.sanitize(code);
    if (clean.isEmpty) return;

    final repo = ref.read(ordersRepositoryProvider);
    final bill = await repo.getBillByNumber(clean);
    if (!mounted) return;

    if (bill != null) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.lightImpact();
      context.push(AppRoutes.orderDetailPath(bill.id));
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No bill found matching: $clean'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showPrintOptionsSheet(Bill bill) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bill #${bill.billNumber}',
                      style: AppTypography.heading3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print 58 mm Receipt'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(receiptActionsProvider).printThermal(bill.id, context: context);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Share as A4 PDF'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(receiptActionsProvider).shareA4(bill.id, context: context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _applyFilters() {
    DateTime? start;
    DateTime? end;
    bool? onlyCredit;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedDateFilter == 'Today') {
      start = todayStart;
      end = todayEnd;
    } else if (_selectedDateFilter == 'Yesterday') {
      final yest = now.subtract(const Duration(days: 1));
      start = DateTime(yest.year, yest.month, yest.day);
      end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
    } else if (_selectedDateFilter == 'This Week') {
      start = todayStart.subtract(Duration(days: now.weekday - 1));
      end = todayEnd;
    } else if (_selectedDateFilter == 'This Month') {
      start = DateTime(now.year, now.month, 1);
      end = todayEnd;
    } else if (_selectedDateFilter == 'Credit Only') {
      onlyCredit = true;
    }

    ref.read(ordersFilterProvider.notifier).state = (
      startDate: start,
      endDate: end,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      paymentMode: _selectedPaymentMode == 'All' ? null : _selectedPaymentMode,
      onlyCreditUnpaid: onlyCredit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final billsAsync = ref.watch(billsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Orders & Bills'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by bill # or customer name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (_) {
                setState(() {});
                _applyFilters();
              },
            ),
          ),

          // Date Filter Chips Row
          SizedBox(
            height: 38,
            child: ListView.separated(
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              cacheExtent: 200.0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _dateFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _dateFilters[index];
                final isSelected = _selectedDateFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedDateFilter = filter);
                      _applyFilters();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Payment Mode Filter Chips Row
          SizedBox(
            height: 38,
            child: ListView.separated(
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              cacheExtent: 200.0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _paymentModes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final mode = _paymentModes[index];
                final isSelected = _selectedPaymentMode == mode;
                return ChoiceChip(
                  label: Text(mode == 'All' ? 'All Modes' : mode),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedPaymentMode = mode);
                      _applyFilters();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Content Area
          Expanded(
            child: billsAsync.when(
              data: (bills) {
                if (bills.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Orders Found',
                    message: _searchController.text.isNotEmpty || _selectedDateFilter != 'All'
                        ? 'No orders matching the active search or filters.'
                        : 'Past bills will appear here once you start billing customers.',
                    actionLabel: 'New Bill',
                    onAction: () => context.go(AppRoutes.billing),
                  );
                }

                // Calculate summary stats
                final totalSales = bills.fold(0.0, (acc, b) => acc + b.grandTotal);
                final totalCredit = bills
                    .where((b) => b.paymentMode == 'Credit' && !b.isCreditPaid)
                    .fold(0.0, (acc, b) => acc + b.grandTotal);

                return Column(
                  children: [
                    // Summary Metrics Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Orders', style: AppTypography.caption),
                              const SizedBox(height: 2),
                              Text('${bills.length}', style: AppTypography.priceBold.copyWith(fontSize: 16)),
                            ],
                          ),
                          Container(width: 1, height: 28, color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                          Column(
                            children: [
                              const Text('Total Sales', style: AppTypography.caption),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.currency(totalSales, symbol: settings.currencySymbol),
                                style: AppTypography.priceBold.copyWith(
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          if (totalCredit > 0) ...[
                            Container(width: 1, height: 28, color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                            Column(
                              children: [
                                const Text('Unpaid Udhaar', style: AppTypography.caption),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.currency(totalCredit, symbol: settings.currencySymbol),
                                  style: AppTypography.priceBold.copyWith(
                                    fontSize: 16,
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Orders List
                    Expanded(
                      child: ListView.separated(
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        cacheExtent: 200.0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: bills.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final bill = bills[index];

                          return Dismissible(
                            key: ValueKey('order_${bill.id}'),
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
                            onDismissed: (_) {
                              ref.read(ordersRepositoryProvider).softDeleteBill(bill.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Moved ${bill.billNumber} to Recycle Bin')),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: InkWell(
                                onTap: () => context.push(AppRoutes.orderDetailPath(bill.id)),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Payment Icon
                                      CircleAvatar(
                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        child: Icon(
                                          bill.paymentMode == 'Cash'
                                              ? Icons.payments_rounded
                                              : (bill.paymentMode == 'UPI'
                                                  ? Icons.account_balance_rounded
                                                  : (bill.paymentMode == 'Card'
                                                      ? Icons.credit_card_rounded
                                                      : Icons.history_edu_rounded)),
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Bill Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 6,
                                              children: [
                                                Text(
                                                  bill.billNumber,
                                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                                if (bill.isEdited)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'Edited',
                                                      style: TextStyle(
                                                        color: Color(0xFFD97706),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              bill.customerName ?? 'Walk-in Customer',
                                              style: AppTypography.caption.copyWith(
                                                color: bill.customerName != null
                                                    ? theme.colorScheme.primary
                                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              Formatters.dateTime(bill.date),
                                              style: AppTypography.caption.copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Amount & Payment Status
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            Formatters.currency(bill.grandTotal, symbol: settings.currencySymbol),
                                            style: AppTypography.priceBold.copyWith(
                                              fontSize: 15,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (bill.paymentMode == 'Credit' && !bill.isCreditPaid)
                                                  ? AppColors.errorRed.withValues(alpha: 0.12)
                                                  : theme.colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              bill.paymentMode == 'Credit'
                                                  ? (bill.isCreditPaid ? 'Paid' : 'Unpaid')
                                                  : bill.paymentMode,
                                              style: AppTypography.captionBold.copyWith(
                                                fontSize: 10,
                                                color: (bill.paymentMode == 'Credit' && !bill.isCreditPaid)
                                                    ? AppColors.errorRed
                                                    : theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.print_outlined, size: 20),
                                        tooltip: 'Print or Share Bill',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: () => _showPrintOptionsSheet(bill),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
