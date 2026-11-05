import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/database_provider.dart';
import '../../printer/services/receipt_actions.dart';
import '../data/day_closing_repository.dart';

class DayClosingScreen extends ConsumerStatefulWidget {
  const DayClosingScreen({super.key});

  @override
  ConsumerState<DayClosingScreen> createState() => _DayClosingScreenState();
}

class _DayClosingScreenState extends ConsumerState<DayClosingScreen> {
  final TextEditingController _countedCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  double _countedAmount = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _countedCtrl.addListener(() {
      final val = double.tryParse(_countedCtrl.text.trim()) ?? 0.0;
      setState(() => _countedAmount = val);
    });
  }

  @override
  void dispose() {
    _countedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addCash(double amt) {
    final cur = double.tryParse(_countedCtrl.text.trim()) ?? 0.0;
    final next = cur + amt;
    _countedCtrl.text = next.toStringAsFixed(0);
  }

  void _saveClosing(DaySummaryData data) async {
    final diff = _countedAmount - data.expectedCash;

    setState(() => _isSaving = true);
    final repo = ref.read(dayClosingRepositoryProvider);
    final created = await repo.saveDayClosing(
      openingCash: data.openingCash,
      cashSales: data.cashSales,
      cashExpenses: data.cashExpenses,
      expectedCash: data.expectedCash,
      countedCash: _countedAmount,
      difference: diff,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      _showClosingSuccessDialog(created);
    }
  }

  void _showClosingSuccessDialog(DayClosing closing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
            SizedBox(width: 8),
            Text('Register Closed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${Formatters.date(closing.closedAt)}', style: AppTypography.captionBold),
            const SizedBox(height: 6),
            Text('Counted Cash: ${Formatters.currency(closing.countedCash)}', style: AppTypography.bodyMedium),
            Text(
              'Difference: ${closing.difference >= 0 ? '+' : ''}${Formatters.currency(closing.difference)}',
              style: AppTypography.priceBold.copyWith(
                color: closing.difference == 0
                    ? AppColors.successGreen
                    : (closing.difference < 0 ? AppColors.errorRed : Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print 58 mm Summary',
            onPressed: () async {
              await ref.read(receiptActionsProvider).printDayClosingThermal(closing, context: ctx);
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final summaryAsync = ref.watch(todaySummaryProvider);
    final pastClosingsAsync = ref.watch(pastClosingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day-End Closing & Register'),
      ),
      body: summaryAsync.when(
        data: (summary) {
          final diff = _countedAmount - summary.expectedCash;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Register Breakdown Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Today\'s Cash Reconciliation', style: AppTypography.captionBold),
                          Text(Formatters.date(DateTime.now()), style: AppTypography.caption),
                        ],
                      ),
                      const Divider(height: 18),
                      _buildLine('Opening Cash in Drawer', Formatters.currency(summary.openingCash, symbol: settings.currencySymbol)),
                      _buildLine('+ Today\'s Cash Sales', Formatters.currency(summary.cashSales, symbol: settings.currencySymbol), color: AppColors.successGreen),
                      _buildLine('- Cash Expenses', '- ${Formatters.currency(summary.cashExpenses, symbol: settings.currencySymbol)}', color: AppColors.errorRed),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expected Cash in Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            Formatters.currency(summary.expectedCash, symbol: settings.currencySymbol),
                            style: AppTypography.priceBold.copyWith(fontSize: 18, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Counted Cash Input Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Actual Counted Cash', style: AppTypography.captionBold),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _countedCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTypography.priceBold.copyWith(fontSize: 24),
                        decoration: InputDecoration(
                          prefixText: '${settings.currencySymbol} ',
                          hintText: '0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Denomination Helpers
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(label: const Text('+₹100'), onPressed: () => _addCash(100)),
                          ActionChip(label: const Text('+₹200'), onPressed: () => _addCash(200)),
                          ActionChip(label: const Text('+₹500'), onPressed: () => _addCash(500)),
                          ActionChip(label: const Text('+₹2000'), onPressed: () => _addCash(2000)),
                          ActionChip(
                            label: const Text('Exact'),
                            onPressed: () => _countedCtrl.text = summary.expectedCash.toStringAsFixed(0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Reconciliation Status Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: diff == 0
                              ? AppColors.successGreen.withValues(alpha: 0.12)
                              : (diff < 0 ? AppColors.errorRed.withValues(alpha: 0.12) : Colors.blue.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  diff == 0
                                      ? Icons.check_circle_rounded
                                      : (diff < 0 ? Icons.error_outline_rounded : Icons.info_outline_rounded),
                                  size: 18,
                                  color: diff == 0
                                      ? AppColors.successGreen
                                      : (diff < 0 ? AppColors.errorRed : Colors.blue),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  diff == 0
                                      ? 'Cash Register Balanced'
                                      : (diff < 0 ? 'Cash Shortage' : 'Cash Surplus'),
                                  style: AppTypography.captionBold.copyWith(
                                    color: diff == 0
                                        ? AppColors.successGreen
                                        : (diff < 0 ? AppColors.errorRed : Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${diff >= 0 ? '+' : ''}${Formatters.currency(diff, symbol: settings.currencySymbol)}',
                              style: AppTypography.priceBold.copyWith(
                                fontSize: 16,
                                color: diff == 0
                                    ? AppColors.successGreen
                                    : (diff < 0 ? AppColors.errorRed : Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Closing Notes / Reason for Difference (optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save & Close Button
              FilledButton.icon(
                onPressed: _isSaving ? null : () => _saveClosing(summary),
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.lock_clock_rounded),
                label: const Text('Save & Close Day-End Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Past Closings History
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Past Day Closings', style: AppTypography.captionBold),
                ],
              ),
              const SizedBox(height: 8),

              pastClosingsAsync.when(
                data: (closings) {
                  if (closings.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No previous day closings recorded')),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: closings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final c = closings[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(Formatters.dateTime(c.closedAt), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Counted: ${Formatters.currency(c.countedCash, symbol: settings.currencySymbol)} • Exp: ${Formatters.currency(c.expectedCash, symbol: settings.currencySymbol)}',
                            style: AppTypography.caption,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${c.difference >= 0 ? '+' : ''}${Formatters.currency(c.difference, symbol: settings.currencySymbol)}',
                                style: AppTypography.priceBold.copyWith(
                                  fontSize: 13,
                                  color: c.difference == 0
                                      ? AppColors.successGreen
                                      : (c.difference < 0 ? AppColors.errorRed : Colors.blue),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.print_rounded, size: 20),
                                tooltip: 'Print Receipt',
                                onPressed: () {
                                  ref.read(dayClosingRepositoryProvider).printDayEndReceipt(c);
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
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildLine(String label, String value, {Color? color}) {
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
