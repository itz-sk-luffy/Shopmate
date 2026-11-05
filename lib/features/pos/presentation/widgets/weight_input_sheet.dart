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
  String _input = '';
  double _currentQuantity = 0.0;
  bool _replaceOnNextDigit = false;

  void _setWeight(double weight) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentQuantity = weight;
      _input = weight.toStringAsFixed(3);
      _replaceOnNextDigit = true;
    });
  }

  void _appendDigit(String char) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_replaceOnNextDigit) {
        _input = '';
        _replaceOnNextDigit = false;
      }

      if (char == '.') {
        if (_input.contains('.')) return;
        _input = _input.isEmpty ? '0.' : '$_input.';
      } else {
        if (_input == '0') {
          _input = char;
        } else {
          if (_input.contains('.')) {
            final parts = _input.split('.');
            if (parts.length > 1 && parts[1].length >= 3) return;
          }
          _input = '$_input$char';
        }
      }
      _currentQuantity = double.tryParse(_input) ?? 0.0;
    });
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() {
      _replaceOnNextDigit = false;
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
      }
      _currentQuantity = _input.isEmpty ? 0.0 : (double.tryParse(_input) ?? 0.0);
    });
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _input = '';
      _replaceOnNextDigit = false;
      _currentQuantity = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalAmount = _currentQuantity * widget.product.price;
    final unit = widget.product.unit.toLowerCase();
    final dimColor = theme.colorScheme.onSurface.withValues(alpha: 0.30);
    final hasTyped = _input.isNotEmpty;
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

    final displayQuantity = hasTyped ? _input : '0';
    final buttonQtyText = hasTyped
        ? (_input.endsWith('.') ? _input.substring(0, _input.length - 1) : _input)
        : '0';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

          // Total Price & Quantity Display
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity (${widget.product.unit})', style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(
                      displayQuantity,
                      style: AppTypography.priceMedium.copyWith(
                        fontSize: 22,
                        color: hasTyped
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                            : dimColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Calculated Amount', style: AppTypography.caption),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(isValidQuantity ? totalAmount : 0.0, symbol: widget.currencySymbol),
                      style: AppTypography.priceBold.copyWith(
                        fontSize: 24,
                        color: isValidQuantity ? theme.colorScheme.primary : dimColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Mini Keypad
          _buildNumericKeypad(isDark),
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
    );
  }

  Widget _buildNumericKeypad(bool isDark) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: row.map((char) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      if (char == '⌫') {
                        _backspace();
                      } else {
                        _appendDigit(char);
                      }
                    },
                    onLongPress: char == '⌫' ? _clear : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: char == '⌫'
                          ? const Icon(Icons.backspace_outlined, size: 20)
                          : Text(
                              char,
                              style: AppTypography.priceMedium.copyWith(fontSize: 18),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
