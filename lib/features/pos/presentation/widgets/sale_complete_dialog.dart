import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../printer/services/receipt_actions.dart';

class SaleCompleteDialog extends ConsumerStatefulWidget {
  final int billId;
  final Bill? initialBill;

  const SaleCompleteDialog({
    super.key,
    required this.billId,
    this.initialBill,
  });

  @override
  ConsumerState<SaleCompleteDialog> createState() => _SaleCompleteDialogState();
}

class _SaleCompleteDialogState extends ConsumerState<SaleCompleteDialog> {
  Bill? _bill;
  bool _isLoading = true;
  String? _workingAction; // 'print', 'pdf', 'share'

  @override
  void initState() {
    super.initState();
    if (widget.initialBill != null) {
      _bill = widget.initialBill;
      _isLoading = false;
    } else {
      _loadBill();
    }
  }

  Future<void> _loadBill() async {
    try {
      dev.log('[SaleCompleteDialog] Loading bill #${widget.billId} from database...', name: 'SaleComplete');
      final db = ref.read(databaseProvider);
      final b = await (db.select(db.bills)..where((tbl) => tbl.id.equals(widget.billId))).getSingleOrNull();
      if (mounted) {
        setState(() {
          _bill = b;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      dev.log('[SaleCompleteDialog] Error loading bill: $e', error: e, stackTrace: stack, name: 'SaleComplete');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onPrintThermal() async {
    if (_workingAction != null || _bill == null) return;
    setState(() => _workingAction = 'print');
    dev.log('[SaleCompleteDialog] Print 58 mm tapped for bill ${_bill!.billNumber}', name: 'SaleComplete');

    try {
      await ref.read(receiptActionsProvider).printThermal(_bill!.id, context: context);
    } catch (e, stack) {
      dev.log('[SaleCompleteDialog] Print thermal error: $e', error: e, stackTrace: stack, name: 'SaleComplete');
    } finally {
      if (mounted) setState(() => _workingAction = null);
    }
  }

  Future<void> _onShareA4() async {
    if (_workingAction != null || _bill == null) return;
    setState(() => _workingAction = 'share');
    dev.log('[SaleCompleteDialog] Share A4 PDF tapped for bill ${_bill!.billNumber}', name: 'SaleComplete');

    try {
      await ref.read(receiptActionsProvider).shareA4(_bill!.id, context: context);
    } catch (e, stack) {
      dev.log('[SaleCompleteDialog] Share error: $e', error: e, stackTrace: stack, name: 'SaleComplete');
    } finally {
      if (mounted) setState(() => _workingAction = null);
    }
  }

  Future<void> _onA4Pdf() async {
    if (_workingAction != null || _bill == null) return;
    setState(() => _workingAction = 'pdf');
    dev.log('[SaleCompleteDialog] View/Print A4 PDF tapped for bill ${_bill!.billNumber}', name: 'SaleComplete');

    try {
      await ref.read(receiptActionsProvider).a4Pdf(_bill!.id, context: context);
    } catch (e, stack) {
      dev.log('[SaleCompleteDialog] A4 PDF error: $e', error: e, stackTrace: stack, name: 'SaleComplete');
    } finally {
      if (mounted) setState(() => _workingAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Complete'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Big Success Checkmark
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.successGreen,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sale Complete!',
                  style: AppTypography.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_bill == null)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Could not load bill details from database.')),
                  )
                else ...[
                  Text(
                    _bill!.billNumber,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                          // Total & Details Card
                          Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Text('Total Amount Paid', style: AppTypography.caption),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.currency(_bill!.grandTotal, symbol: settings.currencySymbol),
                                    style: AppTypography.priceBold.copyWith(fontSize: 32, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Payment Mode', style: AppTypography.bodyMedium),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _bill!.paymentMode,
                                          style: AppTypography.captionBold.copyWith(color: theme.colorScheme.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_bill!.paymentMode == 'Cash' && _bill!.changeTendered > 0) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Change Due', style: AppTypography.bodyMedium),
                                        Text(
                                          Formatters.currency(_bill!.changeTendered, symbol: settings.currencySymbol),
                                          style: AppTypography.priceBold.copyWith(color: AppColors.successGreen, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (_bill!.paymentMode == 'Credit' && _bill!.customerName != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentAmber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Added to ${_bill!.customerName}\'s Udhaar',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.captionBold.copyWith(color: const Color(0xFFB45309)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Action Buttons
                          // 1. Print Thermal Receipt
                          OutlinedButton.icon(
                            onPressed: _workingAction != null ? null : _onPrintThermal,
                            icon: _workingAction == 'print'
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.print_rounded),
                            label: const Text('Print Thermal Receipt (58 mm)'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. Share A4 PDF Invoice
                          FilledButton.tonalIcon(
                            onPressed: _workingAction != null ? null : _onShareA4,
                            icon: _workingAction == 'share'
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.share_rounded),
                            label: const Text('Share A4 PDF Invoice'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3. View / Print A4 PDF
                          OutlinedButton.icon(
                            onPressed: _workingAction != null ? null : _onA4Pdf,
                            icon: _workingAction == 'pdf'
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf_rounded),
                            label: const Text('View / Print A4 PDF'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. New Sale / Done Button
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('New Sale / Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
            );
  }
}

