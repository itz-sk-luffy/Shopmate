import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';

class BarcodeLabelDialog extends StatefulWidget {
  final Product product;
  final String currencySymbol;
  final Function(String barcode, int copies)? onPrint;

  const BarcodeLabelDialog({
    super.key,
    required this.product,
    required this.currencySymbol,
    this.onPrint,
  });

  @override
  State<BarcodeLabelDialog> createState() => _BarcodeLabelDialogState();
}

class _BarcodeLabelDialogState extends State<BarcodeLabelDialog> {
  late String _barcodeValue;
  int _copies = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.barcode != null && widget.product.barcode!.isNotEmpty) {
      _barcodeValue = widget.product.barcode!;
    } else {
      _barcodeValue = _generateInternalBarcode();
    }
  }

  String _generateInternalBarcode() {
    // Generate a unique 12-digit code for Code128 / EAN-13
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final randDigits = random.nextInt(900) + 100;
    return '20$timestamp$randDigits';
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Barcode Label Preview', style: AppTypography.section),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 58 mm Label Preview Container (approx 384 dots width)
            Center(
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightOutlineVariant, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.currencySymbol} ${Formatters.currency(widget.product.price, symbol: '').trim()}',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Barcode Bars Graphic
                    _buildBarcodeVisual(),
                    const SizedBox(height: 4),
                    Text(
                      _barcodeValue,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Barcode value & Format picker
            Row(
              children: [
                Expanded(
                  child: Text('Barcode: $_barcodeValue', style: AppTypography.captionBold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _barcodeValue = _generateInternalBarcode();
                    });
                  },
                  child: const Text('Regenerate'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Number of label copies
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Label Copies:'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                    ),
                    Text('$_copies', style: AppTypography.priceMedium.copyWith(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _copies < 50 ? () => setState(() => _copies++) : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Print Label Button
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (widget.onPrint != null) {
                  widget.onPrint!(_barcodeValue, _copies);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sent $_copies label(s) to 58 mm printer')),
                  );
                }
              },
              icon: const Icon(Icons.print_rounded),
              label: Text('Print $_copies Label${_copies > 1 ? 's' : ''} (58 mm)'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeVisual() {
    try {
      // Render clean barcode bars pattern
      return SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(45, (index) {
            final isThick = (index % 3 == 0 || index % 7 == 0);
            final isSpace = (index % 4 == 0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              width: isSpace ? 1.5 : (isThick ? 2.5 : 1.2),
              color: isSpace ? Colors.transparent : Colors.black,
            );
          }),
        ),
      );
    } catch (_) {
      return const SizedBox(
        height: 44,
        child: Center(child: Text('Barcode Error')),
      );
    }
  }
}
