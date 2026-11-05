import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../products/data/products_repository.dart';
import '../../../products/presentation/product_edit_screen.dart';

typedef CustomItemAddCallback = void Function({
  required String name,
  required double price,
  required double quantity,
  required String unit,
  required double gstRate,
  required bool isDecimalAllowed,
  int? categoryId,
  String? barcode,
  bool saveToCatalog,
});

class CustomItemDialog extends ConsumerStatefulWidget {
  final CustomItemAddCallback onAdd;
  final double defaultGstRate;
  final bool isGstEnabled;

  const CustomItemDialog({
    super.key,
    required this.onAdd,
    this.defaultGstRate = 0.0,
    this.isGstEnabled = true,
  });

  @override
  ConsumerState<CustomItemDialog> createState() => _CustomItemDialogState();
}

class _CustomItemDialogState extends ConsumerState<CustomItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();

  String _selectedUnit = 'pcs';
  int? _selectedCategoryId;
  double _selectedGstRate = 0.0;
  bool _saveToCatalog = false;

  final List<String> _units = ['pcs', 'kg', 'ltr', 'gm', 'ml', 'pkt', 'box', 'can', 'bag'];
  final List<double> _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  void initState() {
    super.initState();
    _selectedGstRate = widget.isGstEnabled ? widget.defaultGstRate : 0.0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _generateBarcode() async {
    final repo = ref.read(productsRepositoryProvider);
    final code = await repo.generateInternalBarcode();
    setState(() {
      _barcodeController.text = code;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _openCameraScanner() async {
    final scanned = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProductBarcodeScannerSheet(),
    );
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() {
        _barcodeController.text = scanned;
      });
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 22,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Add Item', style: AppTypography.heading3),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card 1: Product Details (Matching Add Product Screen)
                CustomCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Details', style: AppTypography.section),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'e.g. Tata Salt 1kg, A1 Chips',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter product name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Price (${settings.currencySymbol}) *',
                                hintText: '0.00',
                                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                              ),
                              validator: (val) {
                                final p = double.tryParse(val?.trim() ?? '');
                                if (p == null || p < 0) return 'Valid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(labelText: 'Unit'),
                              items: _units.map((u) {
                                return DropdownMenuItem(value: u, child: Text(u));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedUnit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      categoriesAsync.when(
                        data: (categories) {
                          return DropdownButtonFormField<int?>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No Category / General'),
                              ),
                              ...categories.map((c) {
                                return DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }),
                            ],
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Card 2: Barcode / Scan (Matching Add Product Screen)
                CustomCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Barcode / Scan', style: AppTypography.section),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode Number',
                                hintText: 'Enter or scan barcode',
                                prefixIcon: Icon(Icons.qr_code_2_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Auto-generate Barcode',
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            onPressed: _generateBarcode,
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            tooltip: 'Scan Barcode with Camera',
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            onPressed: _openCameraScanner,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // GST Rate Section (if enabled)
                if (widget.isGstEnabled) ...[
                  const SizedBox(height: 14),
                  const Text('GST Rate', style: AppTypography.captionBold),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: _gstRates.map((rate) {
                      return ChoiceChip(
                        label: Text('${rate.toInt()}%'),
                        selected: _selectedGstRate == rate,
                        onSelected: (val) {
                          if (val) setState(() => _selectedGstRate = rate);
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                // Checkbox: Also save to Product Catalog
                Material(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: _saveToCatalog
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: 1.0,
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    value: _saveToCatalog,
                    dense: true,
                    title: const Text(
                      'Also save to Product Catalog',
                      style: AppTypography.bodyMedium,
                    ),
                    subtitle: const Text(
                      'Adds this product permanently to your inventory catalog',
                      style: AppTypography.caption,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setState(() => _saveToCatalog = val ?? false),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                        label: Text(
                          _saveToCatalog ? 'Add to Cart & Catalog' : 'Add to Cart',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final price = double.parse(_priceController.text.trim());
                            final isDec = _selectedUnit == 'kg' ||
                                _selectedUnit == 'ltr' ||
                                _selectedUnit == 'gm' ||
                                _selectedUnit == 'ml';
                            final barcode = _barcodeController.text.trim().isEmpty
                                ? null
                                : _barcodeController.text.trim();

                            widget.onAdd(
                              name: _nameController.text.trim(),
                              price: price,
                              quantity: 1.0,
                              unit: _selectedUnit,
                              gstRate: widget.isGstEnabled ? _selectedGstRate : 0.0,
                              isDecimalAllowed: isDec,
                              categoryId: _selectedCategoryId,
                              barcode: barcode,
                              saveToCatalog: _saveToCatalog,
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
