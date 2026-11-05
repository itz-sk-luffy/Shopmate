import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/providers/database_provider.dart';
import '../data/customers_repository.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _onlyUdhaar = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter customer name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Opening Udhaar Balance',
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final repo = ref.read(customersRepositoryProvider);
                final bal = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
                await repo.addCustomer(
                  CustomersCompanion.insert(
                    name: nameCtrl.text.trim(),
                    phone: drift.Value(phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim()),
                    balance: drift.Value(bal),
                  ),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers & Udhaar Ledger'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('New Customer'),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Udhaar Filter Toggle Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Customers'),
                  selected: !_onlyUdhaar,
                  onSelected: (val) {
                    if (val) setState(() => _onlyUdhaar = false);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.errorRed),
                  label: const Text('Has Udhaar Balance'),
                  selected: _onlyUdhaar,
                  onSelected: (val) {
                    if (val) setState(() => _onlyUdhaar = true);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Content Area
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final query = _searchController.text.trim().toLowerCase();
                var filtered = customers.where((c) {
                  if (query.isNotEmpty) {
                    final nameMatch = c.name.toLowerCase().contains(query);
                    final phoneMatch = c.phone?.toLowerCase().contains(query) ?? false;
                    if (!nameMatch && !phoneMatch) return false;
                  }
                  if (_onlyUdhaar && c.balance <= 0) return false;
                  return true;
                }).toList();

                final totalUdhaar = customers.fold(0.0, (acc, c) => acc + (c.balance > 0 ? c.balance : 0.0));

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Customers Found',
                    message: query.isNotEmpty
                        ? 'No customers matching "$query"'
                        : 'Add customers to record credit sales and maintain Udhaar ledgers.',
                    actionLabel: 'Add First Customer',
                    onAction: _showAddCustomerDialog,
                  );
                }

                return Column(
                  children: [
                    // Udhaar Summary Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Udhaar Outstanding', style: AppTypography.captionBold),
                              const SizedBox(height: 2),
                              Text(
                                '${customers.where((c) => c.balance > 0).length} customer(s) with pending balance',
                                style: AppTypography.caption.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            Formatters.currency(totalUdhaar, symbol: settings.currencySymbol),
                            style: AppTypography.priceBold.copyWith(fontSize: 18, color: AppColors.errorRed),
                          ),
                        ],
                      ),
                    ),

                    // Customers List
                    Expanded(
                      child: ListView.separated(
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        cacheExtent: 200.0,
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final cust = filtered[index];

                          return RepaintBoundary(
                            child: Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cust.balance > 0
                                    ? AppColors.errorRed.withValues(alpha: 0.12)
                                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  cust.name.isNotEmpty ? cust.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cust.balance > 0 ? AppColors.errorRed : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(
                                cust.name,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                cust.phone ?? 'No phone number',
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.currency(cust.balance, symbol: settings.currencySymbol),
                                    style: AppTypography.priceBold.copyWith(
                                      fontSize: 15,
                                      color: cust.balance > 0
                                          ? AppColors.errorRed
                                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                  if (cust.balance > 0)
                                    Text(
                                      'Udhaar',
                                      style: AppTypography.captionBold.copyWith(color: AppColors.errorRed, fontSize: 10),
                                    ),
                                ],
                              ),
                              onTap: () => context.push(AppRoutes.customerDetailPath(cust.id)),
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
