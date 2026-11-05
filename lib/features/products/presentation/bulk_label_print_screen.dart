import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart' as bc;
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/safe_back_button.dart';
import '../data/products_repository.dart';

class BulkLabelPrintScreen extends ConsumerStatefulWidget {
  const BulkLabelPrintScreen({super.key});

  @override
  ConsumerState<BulkLabelPrintScreen> createState() => _BulkLabelPrintScreenState();
}

class _BulkLabelPrintScreenState extends ConsumerState<BulkLabelPrintScreen> {
  final Map<int, int> _selectedProductCopies = {};
  bool _selectAll = false;

  void _toggleSelectAll(List<Product> products) {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        for (final p in products) {
          if (p.barcode != null && p.barcode!.isNotEmpty) {
            _selectedProductCopies[p.id] = 1;
          }
        }
      } else {
        _selectedProductCopies.clear();
      }
    });
  }

  Future<void> _generatePdfLabels(List<Product> products, String currencySymbol, String storeName) async {
    final pdf = pw.Document();
    final itemsToPrint = <({Product product, int copies})>[];

    for (final p in products) {
      final copies = _selectedProductCopies[p.id] ?? 0;
      if (copies > 0 && p.barcode != null && p.barcode!.isNotEmpty) {
        itemsToPrint.add((product: p, copies: copies));
      }
    }

    if (itemsToPrint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product with a barcode')),
      );
      return;
    }

    // 58 mm width label roll
    const rollWidth = 58 * PdfPageFormat.mm;
    const labelHeight = 40 * PdfPageFormat.mm;

    for (final item in itemsToPrint) {
      for (int i = 0; i < item.copies; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: const PdfPageFormat(rollWidth, labelHeight, marginAll: 2 * PdfPageFormat.mm),
            build: (pw.Context ctx) {
              return pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      storeName,
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      maxLines: 1,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      item.product.name,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      maxLines: 1,
                    ),
                    pw.SizedBox(height: 3),
                    pw.BarcodeWidget(
                      data: item.product.barcode!,
                      barcode: bc.Barcode.code128(),
                      width: 130,
                      height: 45,
                      drawText: true,
                      textStyle: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '$currencySymbol ${item.product.price.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'shopmate_barcode_labels_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final repo = ref.watch(productsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallbackRoute: AppRoutes.products),
        title: const Text('Bulk Barcode Labels (58 mm)'),
      ),
      body: FutureBuilder<List<Product>>(
        future: repo.getAllActiveProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          final barcodedProducts = products.where((p) => p.barcode != null && p.barcode!.isNotEmpty).toList();

          if (barcodedProducts.isEmpty) {
            return const Center(
              child: Text('No products have barcodes assigned yet.\nAssign or generate barcodes first.', textAlign: TextAlign.center),
            );
          }

          final totalCopies = _selectedProductCopies.values.fold<int>(0, (sum, c) => sum + c);

          return Column(
            children: [
              // Header Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: (_) => _toggleSelectAll(barcodedProducts),
                    ),
                    const Text('Select All', style: AppTypography.captionBold),
                    const Spacer(),
                    Text('Total Labels: $totalCopies', style: AppTypography.captionBold.copyWith(color: AppColors.primaryTeal)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Product list with copy counters
              Expanded(
                child: ListView.separated(
                  itemCount: barcodedProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = barcodedProducts[index];
                    final copies = _selectedProductCopies[product.id] ?? 0;
                    final isSelected = copies > 0;

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedProductCopies[product.id] = 1;
                          } else {
                            _selectedProductCopies.remove(product.id);
                          }
                        });
                      },
                      title: Text(product.name, style: AppTypography.bodyMedium),
                      subtitle: Text(
                        'Barcode: ${product.barcode} • ${Formatters.currency(product.price, symbol: settings.currencySymbol)}',
                        style: AppTypography.caption,
                      ),
                      secondary: isSelected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                  onPressed: copies > 1
                                      ? () => setState(() => _selectedProductCopies[product.id] = copies - 1)
                                      : null,
                                ),
                                Text('$copies', style: AppTypography.captionBold),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                  onPressed: () => setState(() => _selectedProductCopies[product.id] = copies + 1),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              ),

              // Print / PDF Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.print_rounded),
                      label: Text('Print / Preview Labels ($totalCopies)'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: totalCopies == 0
                          ? null
                          : () => _generatePdfLabels(barcodedProducts, settings.currencySymbol, settings.storeName),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
