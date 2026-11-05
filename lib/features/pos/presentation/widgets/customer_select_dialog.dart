import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../customers/data/customers_repository.dart';

class CustomerSelectDialog extends ConsumerStatefulWidget {
  final Customer? currentCustomer;
  final String currencySymbol;
  final Function(Customer?) onSelected;

  const CustomerSelectDialog({
    super.key,
    required this.currentCustomer,
    required this.currencySymbol,
    required this.onSelected,
  });

  @override
  ConsumerState<CustomerSelectDialog> createState() => _CustomerSelectDialogState();
}

class _CustomerSelectDialogState extends ConsumerState<CustomerSelectDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCreatingNew = false;
  final _newCustFormKey = GlobalKey<FormState>();
  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();
  final _newBalanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    _newPhoneController.dispose();
    _newBalanceController.dispose();
    super.dispose();
  }

  void _saveNewCustomer() async {
    if (!(_newCustFormKey.currentState?.validate() ?? false)) return;

    final repo = ref.read(customersRepositoryProvider);
    final openingBal = double.tryParse(_newBalanceController.text.trim()) ?? 0.0;

    final newId = await repo.addCustomer(
      CustomersCompanion.insert(
        name: _newNameController.text.trim(),
        phone: drift.Value(_newPhoneController.text.trim().isEmpty ? null : _newPhoneController.text.trim()),
        balance: drift.Value(openingBal),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final createdCust = await repo.getCustomerById(newId);
    if (createdCust != null && mounted) {
      widget.onSelected(createdCust);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customersAsync = ref.watch(customersStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCreatingNew ? 'Add New Customer' : 'Select Customer',
                  style: AppTypography.heading3.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isCreatingNew) ...[
              Form(
                key: _newCustFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _newNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter customer name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Opening Balance / Udhaar (optional)',
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isCreatingNew = false),
                            child: const Text('Back to Search'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saveNewCustomer,
                            child: const Text('Save & Select'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Search input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Add new button or Remove customer
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isCreatingNew = true),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Create New Customer'),
                    ),
                  ),
                  if (widget.currentCustomer != null) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: () {
                        widget.onSelected(null);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.person_remove_rounded, color: AppColors.errorRed),
                      tooltip: 'Remove Customer from Bill',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Customers List
              Flexible(
                child: SizedBox(
                  height: 280,
                  child: customersAsync.when(
                    data: (customers) {
                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = customers.where((c) {
                        if (query.isEmpty) return true;
                        final nameMatches = c.name.toLowerCase().contains(query);
                        final phoneMatches = c.phone?.toLowerCase().contains(query) ?? false;
                        return nameMatches || phoneMatches;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            query.isEmpty ? 'No customers yet' : 'No customers matching "$query"',
                            style: AppTypography.caption,
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cust = filtered[index];
                          final isCurrent = widget.currentCustomer?.id == cust.id;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              child: Text(
                                cust.name.isNotEmpty ? cust.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              cust.name,
                              style: AppTypography.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              cust.phone ?? 'No phone',
                              style: AppTypography.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.currency(cust.balance, symbol: widget.currencySymbol),
                                  style: AppTypography.priceBold.copyWith(
                                    fontSize: 14,
                                    color: cust.balance > 0
                                        ? AppColors.errorRed
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                ),
                                if (cust.balance > 0)
                                  Text(
                                    'Udhaar',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.errorRed,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            selected: isCurrent,
                            selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            onTap: () {
                              widget.onSelected(cust);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
