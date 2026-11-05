import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/providers/database_provider.dart';
import '../data/expenses_repository.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final List<String> _categories = [
    'All',
    'General',
    'Tea & Refreshment',
    'Rent',
    'Electricity',
    'Supplies',
    'Transportation',
    'Staff',
    'Maintenance',
  ];

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'General';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Store Expense'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title *',
                      hintText: 'e.g. Milk & Tea, Shop Rent, Bags',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      prefixText: '₹ ',
                    ),
                    validator: (val) {
                      final p = double.tryParse(val ?? '');
                      if (p == null || p <= 0) return 'Valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Category', style: AppTypography.captionBold),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories.where((c) => c != 'All').map((cat) {
                      return ChoiceChip(
                        label: Text(cat),
                        selected: category == cat,
                        onSelected: (val) {
                          if (val) setDlgState(() => category = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Paid to (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final amt = double.parse(amountCtrl.text.trim());
                  final repo = ref.read(expensesRepositoryProvider);
                  await repo.addExpense(
                    title: titleCtrl.text.trim(),
                    amount: amt,
                    category: category,
                    date: DateTime.now(),
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                }
              },
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final filter = ref.watch(expensesFilterProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Expenses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: Column(
        children: [
          // Filter Row: Date Range & Category
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Today'),
                  selected: filter.dateFilter == 'Today',
                  onSelected: (val) {
                    if (val) {
                      ref.read(expensesFilterProvider.notifier).state =
                          (category: filter.category, dateFilter: 'Today');
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('This Month'),
                  selected: filter.dateFilter == 'This Month',
                  onSelected: (val) {
                    if (val) {
                      ref.read(expensesFilterProvider.notifier).state =
                          (category: filter.category, dateFilter: 'This Month');
                    }
                  },
                ),
              ],
            ),
          ),

          // Categories Horizontal Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = filter.category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      ref.read(expensesFilterProvider.notifier).state =
                          (category: cat, dateFilter: filter.dateFilter);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Content Area
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No Expenses Recorded',
                    message: 'Track daily store expenses like rent, tea, electricity, and bags.',
                    actionLabel: 'Record Expense',
                    onAction: _showAddExpenseDialog,
                  );
                }

                final totalAmount = expenses.fold(0.0, (acc, e) => acc + e.amount);

                return Column(
                  children: [
                    // Summary Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${filter.dateFilter} Total Expenses', style: AppTypography.captionBold),
                              const SizedBox(height: 2),
                              Text('${expenses.length} expense transactions', style: AppTypography.caption.copyWith(fontSize: 11)),
                            ],
                          ),
                          Text(
                            Formatters.currency(totalAmount, symbol: settings.currencySymbol),
                            style: AppTypography.priceBold.copyWith(fontSize: 18, color: AppColors.errorRed),
                          ),
                        ],
                      ),
                    ),

                    // Expenses List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final e = expenses[index];

                          return Dismissible(
                            key: ValueKey('expense_${e.id}'),
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
                              ref.read(expensesRepositoryProvider).softDeleteExpense(e.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Deleted expense "${e.title}"')),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
                                  child: const Icon(Icons.arrow_upward_rounded, color: AppColors.errorRed, size: 20),
                                ),
                                title: Text(e.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${e.category} • ${Formatters.date(e.date)}',
                                  style: AppTypography.caption,
                                ),
                                trailing: Text(
                                  '- ${Formatters.currency(e.amount, symbol: settings.currencySymbol)}',
                                  style: AppTypography.priceBold.copyWith(
                                    fontSize: 15,
                                    color: AppColors.errorRed,
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
