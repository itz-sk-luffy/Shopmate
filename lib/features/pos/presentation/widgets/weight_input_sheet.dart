import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';

class WeightInputSheet extends StatefulWidget {
  final Product product;
  final String currencySymbol;
  final Function(double quantity) onAdd;

  const WeightInputSheet({
    super.key,
    required this.product,
    required this.currencySymbol,
    required this.onAdd,
  });

  @override
  State<WeightInputSheet> createState() => _WeightInputSheetState();
}

class _WeightInputSheetState extends State<WeightInputSheet> {
  late final TextEditingController _qtyController;
  late final FocusNode _qtyFocus;
  double _currentQuantity = 0.0;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _qtyFocus = FocusNode();
    // Auto-focus device numpad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _qtyFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  void _setWeight(double weight) {
    HapticFeedback.lightImpact();
    final text = weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 3);
    _qtyController.text = text;
    setState(() {
      _currentQuantity = weight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalAmount = _currentQuantity * widget.product.price;
    final unit = widget.product.unit.toLowerCase();
    final dimColor = theme.colorScheme.onSurface.withValues(alpha: 0.30);
    final hasTyped = _qtyController.text.isNotEmpty;
    final isValidQuantity = _currentQuantity > 0;

    final isKg = unit == 'kg';
    final isLtr = unit == 'ltr';

    final presets = isKg
        ? [
            {'label': '100 g', 'val': 0.100},
            {'label': '250 g', 'val': 0.250},
            {'label': '500 g', 'val': 0.500},
            {'label': '1 kg', 'val': 1.000},
            {'label': '2 kg', 'val': 2.000},
            {'label': '5 kg', 'val': 5.000},
          ]
        : (isLtr
            ? [
                {'label': '100 ml', 'val': 0.100},
                {'label': '250 ml', 'val': 0.250},
                {'label': '500 ml', 'val': 0.500},
                {'label': '1 L', 'val': 1.000},
                {'label': '2 L', 'val': 2.000},
                {'label': '5 L', 'val': 5.000},
              ]
            : [
                {'label': '0.25', 'val': 0.25},
                {'label': '0.5', 'val': 0.5},
                {'label': '1.0', 'val': 1.0},
                {'label': '2.0', 'val': 2.0},
                {'label': '5.0', 'val': 5.0},
                {'label': '10.0', 'val': 10.0},
              ]);

    final buttonQtyText = hasTyped
        ? (_qtyController.text.endsWith('.') ? _qtyController.text.substring(0, _qtyController.text.length - 1) : _qtyController.text)
        : '0';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Product header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: AppTypography.heading3.copyWith(fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rate: ${Formatters.currency(widget.product.price, symbol: widget.currencySymbol)} / ${widget.product.unit}',
                          style: AppTypography.captionBold.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Presets Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((p) {
                  final val = p['val'] as double;
                  final label = p['label'] as String;
                  final isSelected = hasTyped && (_currentQuantity - val).abs() < 0.0001;

                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _setWeight(val),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Editable Quantity Input using device numpad
              TextField(
                controller: _qtyController,
                focusNode: _qtyFocus,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.priceBold.copyWith(fontSize: 22),
                decoration: InputDecoration(
                  labelText: 'Quantity (${widget.product.unit})',
                  hintText: '0.000',
                  prefixIcon: const Icon(Icons.scale_rounded),
                  suffixText: widget.product.unit,
                  suffixStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  suffixIcon: _qtyController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _qtyController.clear();
                            setState(() {
                              _currentQuantity = 0.0;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _currentQuantity = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Calculated Amount Display Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Price:', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      Formatters.currency(isValidQuantity ? totalAmount : 0.0, symbol: widget.currencySymbol),
                      style: AppTypography.priceBold.copyWith(
                        fontSize: 22,
                        color: isValidQuantity ? theme.colorScheme.primary : dimColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add to Cart button
              FilledButton.icon(
                onPressed: isValidQuantity
                    ? () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        final finalQty = double.parse(_currentQuantity.toStringAsFixed(3));
                        widget.onAdd(finalQty);
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(
                  'Add $buttonQtyText ${widget.product.unit} • ${Formatters.currency(isValidQuantity ? totalAmount : 0.0, symbol: widget.currencySymbol)}',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
