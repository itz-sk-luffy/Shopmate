import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/formatters.dart';
import '../domain/receipt_model.dart';

class PdfInvoiceService {
  final Ref _ref;
  static pw.Font? _cachedInterFont;
  static pw.Font? _cachedPlayfairFont;

  PdfInvoiceService(this._ref);

  static Future<pw.Font> loadInterFont() async {
    if (_cachedInterFont != null) return _cachedInterFont!;
    final fontData = await rootBundle.load('assets/fonts/Inter.ttf');
    _cachedInterFont = pw.Font.ttf(fontData);
    return _cachedInterFont!;
  }

  static Future<pw.Font> _loadInterFont() => loadInterFont();

  static Future<pw.Font> _loadPlayfairFont() async {
    if (_cachedPlayfairFont != null) return _cachedPlayfairFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/PlayfairDisplay.ttf');
      _cachedPlayfairFont = pw.Font.ttf(fontData);
      return _cachedPlayfairFont!;
    } catch (_) {
      try {
        _cachedPlayfairFont = await PdfGoogleFonts.playfairDisplayBold();
        return _cachedPlayfairFont!;
      } catch (_) {
        return loadInterFont();
      }
    }
  }

  // Premium Brand Colors
  static const _brandColor = PdfColor(0.04, 0.45, 0.42); // Deep Teal #0A736B
  static const _brandDark = PdfColor(0.02, 0.28, 0.26);  // Rich Slate Teal #054742
  static const _textDark = PdfColor(0.12, 0.15, 0.18);   // Charcoal Slate #1E293B
  static const _textMuted = PdfColor(0.40, 0.45, 0.50);  // Cool Grey #64748B
  static const _bgLight = PdfColor(0.97, 0.98, 0.99);    // Soft Slate #F8FAFC
  static const _borderLight = PdfColor(0.88, 0.91, 0.94); // Border Grey #E2E8F0

  Future<Uint8List> generateA4InvoicePdf({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    final settings = _ref.read(settingsProvider);
    final inter = await _loadInterFont();
    final playfair = await _loadPlayfairFont();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: inter,
        bold: inter,
        italic: inter,
        boldItalic: inter,
      ),
    );

    final invoiceTitle = settings.gstEnabled && bill.gstType != 'none'
        ? 'TAX INVOICE'
        : 'RETAIL INVOICE';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER: STORE BRANDING & INVOICE METADATA ───────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Store Branding & Contact
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.storeName,
                          style: pw.TextStyle(
                            font: playfair,
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: _brandColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        if (settings.storeAddress.isNotEmpty)
                          pw.Text(settings.storeAddress,
                              style: const pw.TextStyle(fontSize: 9.5, color: _textMuted)),
                        pw.SizedBox(height: 1),
                        pw.Row(
                          children: [
                            if (settings.storePhone.isNotEmpty)
                              pw.Text('Ph: ${settings.storePhone}',
                                  style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
                            if (settings.storePhone.isNotEmpty && settings.storeEmail.isNotEmpty)
                              pw.Text('   •   ',
                                  style: const pw.TextStyle(fontSize: 9, color: _borderLight)),
                            if (settings.storeEmail.isNotEmpty)
                              pw.Text(settings.storeEmail,
                                  style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
                          ],
                        ),
                        if (settings.storeGstin.isNotEmpty || settings.storeState.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Row(
                            children: [
                              if (settings.storeGstin.isNotEmpty) ...[
                                pw.Text('GSTIN: ',
                                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _brandDark)),
                                pw.Text(settings.storeGstin,
                                    style: const pw.TextStyle(fontSize: 9, color: _textDark)),
                              ],
                              if (settings.storeGstin.isNotEmpty && settings.storeState.isNotEmpty)
                                pw.Text('   |   ',
                                    style: const pw.TextStyle(fontSize: 9, color: _borderLight)),
                              if (settings.storeState.isNotEmpty) ...[
                                pw.Text('State: ',
                                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _brandDark)),
                                pw.Text(settings.storeState,
                                    style: const pw.TextStyle(fontSize: 9, color: _textDark)),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Invoice Metadata (Elegant Typography, No Button)
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          invoiceTitle,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: _brandColor,
                            letterSpacing: 2.5,
                          ),
                        ),
                        pw.Container(
                          width: 44,
                          height: 2,
                          color: _brandColor,
                          margin: const pw.EdgeInsets.only(top: 3, bottom: 6),
                        ),
                        _invoiceMetaRow('Invoice No:', bill.billNumber, isBold: true),
                        _invoiceMetaRow('Date:', Formatters.date(bill.date)),
                        _invoiceMetaRow('Time:', Formatters.time(bill.date)),
                        _invoiceMetaRow('Payment Mode:', bill.paymentMode),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Decorative Brand Accent Line
              pw.Container(
                height: 2,
                decoration: const pw.BoxDecoration(color: _brandColor),
              ),
              pw.SizedBox(height: 12),

              // ── 2. BILL TO / CUSTOMER CARD ────────────────────────────────
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: _bgLight,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.fromBorderSide(pw.BorderSide(color: _borderLight, width: 0.8)),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 4,
                      height: 52,
                      decoration: const pw.BoxDecoration(
                        color: _brandColor,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(6),
                          bottomLeft: pw.Radius.circular(6),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'BILLED TO',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _brandColor,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  bill.customerName?.isNotEmpty == true ? bill.customerName! : 'Walk-in Customer',
                                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _textDark),
                                ),
                                if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty)
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(top: 2),
                                    child: pw.Text('Phone: ${bill.customerPhone}',
                                        style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
                                  ),
                              ],
                            ),
                            if (bill.paymentMode == 'Credit')
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: pw.BoxDecoration(
                                  color: bill.isCreditPaid ? const PdfColor(0.92, 0.98, 0.92) : const PdfColor(1.0, 0.95, 0.88),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                  border: pw.Border.all(
                                    color: bill.isCreditPaid ? const PdfColor(0.2, 0.65, 0.25) : const PdfColor(0.9, 0.55, 0.1),
                                    width: 0.8,
                                  ),
                                ),
                                child: pw.Text(
                                  bill.isCreditPaid ? '✓ PAID' : 'UDHAAR (CREDIT)',
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: bill.isCreditPaid ? const PdfColor(0.12, 0.5, 0.18) : const PdfColor(0.8, 0.4, 0.0),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // ── 3. ITEMS TABLE ────────────────────────────────────────────
              pw.TableHelper.fromTextArray(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: _borderLight, width: 0.6),
                  bottom: pw.BorderSide(color: _borderLight, width: 1.0),
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 0.4,
                ),
                headerDecoration: const pw.BoxDecoration(color: _brandColor),
                headerHeight: 26,
                cellHeight: 23,
                cellStyle: const pw.TextStyle(fontSize: 9, color: _textDark),
                oddRowDecoration: const pw.BoxDecoration(color: _bgLight),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FixedColumnWidth(22),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FixedColumnWidth(30),
                  3: const pw.FixedColumnWidth(30),
                  4: const pw.FixedColumnWidth(55),
                  5: const pw.FixedColumnWidth(40),
                  6: const pw.FixedColumnWidth(40),
                  7: const pw.FixedColumnWidth(55),
                },
                headers: ['#', 'Item Description', 'Qty', 'Unit', 'Rate', 'Disc', 'Tax', 'Amount'],
                data: List.generate(items.length, (index) {
                  final item = items[index];
                  return [
                    '${index + 1}',
                    item.productName,
                    item.quantity == item.quantity.roundToDouble()
                        ? '${item.quantity.toInt()}'
                        : item.quantity.toStringAsFixed(2),
                    item.unit,
                    Formatters.currency(item.unitPrice, symbol: settings.currencySymbol),
                    item.discountAmount > 0
                        ? Formatters.currency(item.discountAmount, symbol: settings.currencySymbol)
                        : '-',
                    item.gstAmount > 0
                        ? Formatters.currency(item.gstAmount, symbol: settings.currencySymbol)
                        : '-',
                    Formatters.currency(item.totalAmount, symbol: settings.currencySymbol),
                  ];
                }),
              ),

              pw.SizedBox(height: 14),

              // ── 4. TOTALS & WORDS BREAKDOWN ───────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Amount Chargeable in words & Notes & GST Breakup
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          decoration: const pw.BoxDecoration(
                            color: _bgLight,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.fromBorderSide(pw.BorderSide(color: _borderLight, width: 0.8)),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 3.5,
                                height: 38,
                                decoration: const pw.BoxDecoration(
                                  color: _brandColor,
                                  borderRadius: pw.BorderRadius.only(
                                    topLeft: pw.Radius.circular(4),
                                    bottomLeft: pw.Radius.circular(4),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Amount Chargeable (in words):',
                                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _brandColor),
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        '${settings.currencySymbol} ${Formatters.numberToWordsIndian(bill.grandTotal)}',
                                        style: pw.TextStyle(
                                          fontSize: 9.5,
                                          fontStyle: pw.FontStyle.italic,
                                          fontWeight: pw.FontWeight.bold,
                                          color: _textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                          pw.SizedBox(height: 6),
                          pw.Text('Notes: ${bill.notes}', style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
                        ],
                        _buildGstBreakupTable(bill, items, settings),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Right side: Financial Summary Card
                  pw.Container(
                    width: 210,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.fromBorderSide(pw.BorderSide(color: _borderLight, width: 1.0)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: pw.Column(
                            children: [
                              _buildPdfSummaryRow('Subtotal', Formatters.currency(bill.subtotal, symbol: settings.currencySymbol)),
                              if (bill.itemDiscountTotal > 0)
                                _buildPdfSummaryRow('Item Discounts', '- ${Formatters.currency(bill.itemDiscountTotal, symbol: settings.currencySymbol)}', isNeg: true),
                              if (bill.billDiscountAmount > 0)
                                _buildPdfSummaryRow('Bill Discount', '- ${Formatters.currency(bill.billDiscountAmount, symbol: settings.currencySymbol)}', isNeg: true),
                              if (settings.gstEnabled && bill.gstType != 'none' && (bill.cgstTotal > 0 || bill.sgstTotal > 0 || bill.igstTotal > 0)) ...[
                                if (bill.igstTotal > 0)
                                  _buildPdfSummaryRow('IGST', Formatters.currency(bill.igstTotal, symbol: settings.currencySymbol))
                                else ...[
                                  _buildPdfSummaryRow('CGST', Formatters.currency(bill.cgstTotal, symbol: settings.currencySymbol)),
                                  _buildPdfSummaryRow('SGST', Formatters.currency(bill.sgstTotal, symbol: settings.currencySymbol)),
                                ],
                              ],
                              if (bill.roundOff.abs() > 0.001)
                                _buildPdfSummaryRow('Round Off', '${bill.roundOff >= 0 ? '+' : ''}${bill.roundOff.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                        // Highlighted Grand Total Strip
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const pw.BoxDecoration(
                            color: _brandColor,
                            borderRadius: pw.BorderRadius.only(
                              bottomLeft: pw.Radius.circular(5),
                              bottomRight: pw.Radius.circular(5),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.5)),
                              pw.Text(
                                Formatters.currency(bill.grandTotal, symbol: settings.currencySymbol),
                                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ── 5. FOOTER & AUTHORIZED SIGNATORY ──────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _borderLight, width: 0.8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.storeFooter.isNotEmpty ? settings.storeFooter : 'Thank you for your visit!',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _brandColor),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Terms: Subject to local jurisdiction. Computer generated invoice.',
                          style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 120, height: 0.8, color: _borderLight),
                        pw.SizedBox(height: 2),
                        pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
                        pw.Text(settings.storeName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _brandColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _invoiceMetaRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label ', style: const pw.TextStyle(fontSize: 8.5, color: _textMuted)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGstBreakupTable(Bill bill, List<BillItem> items, AppSettingsState settings) {
    if (!settings.gstEnabled || bill.gstType == 'none' || (bill.cgstTotal <= 0 && bill.sgstTotal <= 0 && bill.igstTotal <= 0)) {
      return pw.SizedBox.shrink();
    }

    final rateData = <double, ({double taxable, double cgst, double sgst, double igst})>{};
    for (final item in items) {
      if (item.gstRate > 0) {
        final cur = rateData[item.gstRate] ?? (taxable: 0.0, cgst: 0.0, sgst: 0.0, igst: 0.0);
        final taxVal = item.taxableValue > 0 ? item.taxableValue : (item.quantity * item.unitPrice - item.discountAmount);
        rateData[item.gstRate] = (
          taxable: cur.taxable + taxVal,
          cgst: cur.cgst + item.cgstAmount,
          sgst: cur.sgst + item.sgstAmount,
          igst: cur.igst + item.igstAmount,
        );
      }
    }

    final isInterState = bill.igstTotal > 0;
    final sortedRates = rateData.keys.toList()..sort();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('GST Breakup (by Rate):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Rate', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Taxable', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  if (isInterState)
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('IGST', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))
                  else ...[
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('CGST', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('SGST', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  ],
                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Total Tax', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              if (sortedRates.isEmpty)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('GST', style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(bill.subtotal, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                    if (isInterState)
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(bill.igstTotal, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7)))
                    else ...[
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(bill.cgstTotal, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(bill.sgstTotal, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                    ],
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(bill.cgstTotal + bill.sgstTotal + bill.igstTotal, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                  ],
                )
              else
                for (final r in sortedRates) ...[
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${r.toStringAsFixed(r.truncateToDouble() == r ? 0 : 1)}%', style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(rateData[r]!.taxable, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                      if (isInterState)
                        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(rateData[r]!.igst, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7)))
                      else ...[
                        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(rateData[r]!.cgst, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(rateData[r]!.sgst, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                      ],
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(Formatters.currency(rateData[r]!.cgst + rateData[r]!.sgst + rateData[r]!.igst, symbol: settings.currencySymbol), style: const pw.TextStyle(fontSize: 7))),
                    ],
                  ),
                ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummaryRow(String label, String value, {bool isNeg = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _textDark)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, color: isNeg ? const PdfColor(0.7, 0.1, 0.1) : _textDark)),
        ],
      ),
    );
  }

  Future<void> previewOrPrintInvoice({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    final pdfBytes = await generateA4InvoicePdf(bill: bill, items: items);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${bill.billNumber}',
    );
  }

  Future<void> shareInvoicePdf({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    final pdfBytes = await generateA4InvoicePdf(bill: bill, items: items);
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Invoice_${bill.billNumber}.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Invoice ${bill.billNumber}',
      );
    } catch (_) {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Invoice_${bill.billNumber}.pdf',
      );
    }
  }

  Future<Uint8List> generate58mmReceiptPdf(ReceiptModel receipt) async {
    final inter = await _loadInterFont();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: inter,
        bold: inter,
        italic: inter,
        boldItalic: inter,
      ),
    );

    const receiptFormat = PdfPageFormat(
      58 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 2 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: receiptFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Store Header
              pw.Text(
                receipt.storeName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              if (receipt.storeAddress.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  receipt.storeAddress,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
              if (receipt.storePhone.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'Phone: ${receipt.storePhone}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
              if (receipt.storeGstin.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'GSTIN: ${receipt.storeGstin}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),

              // 2. Bill & Customer Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill: ${receipt.billNumber}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text(receipt.dateFormatted, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Time: ${receipt.timeFormatted}', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('Mode: ${receipt.paymentMode}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              if (receipt.customerName != null) ...[
                pw.Text('Customer: ${receipt.customerName}', style: const pw.TextStyle(fontSize: 7)),
                if (receipt.customerPhone != null)
                  pw.Text('Phone: ${receipt.customerPhone}', style: const pw.TextStyle(fontSize: 7)),
              ],
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),

              // 3. Items Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Rate', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),

              // 4. Items List
              for (final item in receipt.items) ...[
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.quantity == item.quantity.roundToDouble()
                              ? '${item.quantity.toInt()}'
                              : item.quantity.toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.unitPrice.toStringAsFixed(0),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          item.totalAmount.toStringAsFixed(0),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 2),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),

              // 5. Financial Summary
              _buildReceiptRow('Subtotal:', Formatters.currency(receipt.subtotal, symbol: receipt.currencySymbol)),
              if (receipt.itemDiscountTotal > 0)
                _buildReceiptRow('Item Discounts:', '-${Formatters.currency(receipt.itemDiscountTotal, symbol: receipt.currencySymbol)}'),
              if (receipt.billDiscountAmount > 0)
                _buildReceiptRow('Bill Discount:', '-${Formatters.currency(receipt.billDiscountAmount, symbol: receipt.currencySymbol)}'),
              for (final tax in receipt.taxLines)
                _buildReceiptRow('${tax.label}:', Formatters.currency(tax.amount, symbol: receipt.currencySymbol)),
              if (receipt.roundOff.abs() > 0.001)
                _buildReceiptRow('Round Off:', '${receipt.roundOff >= 0 ? '+' : ''}${receipt.roundOff.toStringAsFixed(2)}'),

              pw.SizedBox(height: 3),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 2),

              // 6. Grand Total
              pw.Text(
                'TOTAL: ${Formatters.currency(receipt.grandTotal, symbol: receipt.currencySymbol)}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 2),

              // 7. Payment details
              if (receipt.paymentMode == 'Cash' && receipt.changeTendered > 0) ...[
                _buildReceiptRow(
                  'Cash Tendered:',
                  Formatters.currency(receipt.cashAmount + receipt.changeTendered, symbol: receipt.currencySymbol),
                ),
                _buildReceiptRow(
                  'Change Returned:',
                  Formatters.currency(receipt.changeTendered, symbol: receipt.currencySymbol),
                  bold: true,
                ),
                pw.SizedBox(height: 2),
              ],

              // 8. Footer note
              if (receipt.storeFooter.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  receipt.storeFooter,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],

              pw.SizedBox(height: 6),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildReceiptRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> previewOrPrint58mmReceipt({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    final settings = _ref.read(settingsProvider);
    final receipt = ReceiptModel.fromBill(bill: bill, items: items, settings: settings);
    final pdfBytes = await generate58mmReceiptPdf(receipt);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Receipt_${bill.billNumber}',
      format: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm),
    );
  }

  Future<void> share58mmReceiptPdf({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    final settings = _ref.read(settingsProvider);
    final receipt = ReceiptModel.fromBill(bill: bill, items: items, settings: settings);
    final pdfBytes = await generate58mmReceiptPdf(receipt);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Receipt_${bill.billNumber}.pdf',
    );
  }
}

final pdfInvoiceServiceProvider = Provider<PdfInvoiceService>((ref) {
  return PdfInvoiceService(ref);
});
