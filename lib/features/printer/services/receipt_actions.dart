import 'dart:developer' as dev;
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../domain/receipt_model.dart';
import 'pdf_invoice_service.dart';
import 'thermal_printer_service.dart';

class ReceiptActions {
  final Ref _ref;

  ReceiptActions(this._ref);

  BuildContext? _resolveContext(BuildContext? context) {
    if (context != null && context.mounted) return context;
    final rootCtx = rootNavigatorKey.currentContext;
    if (rootCtx != null && rootCtx.mounted) return rootCtx;
    return null;
  }

  /// Print 58 mm thermal receipt for a bill
  Future<void> printThermal(int billId, {BuildContext? context}) async {
    final ctx = _resolveContext(context);
    dev.log('[ReceiptActions] printThermal called for billId=$billId', name: 'ReceiptActions');

    try {
      final db = _ref.read(databaseProvider);
      final bill = await (db.select(db.bills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
      if (bill == null) {
        dev.log('[ReceiptActions] Bill #$billId not found in database', name: 'ReceiptActions');
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Bill not found'), backgroundColor: AppColors.errorRed),
          );
        }
        return;
      }

      final items = await (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
      final settings = _ref.read(settingsProvider);
      final receipt = ReceiptModel.fromBill(bill: bill, items: items, settings: settings);

      // 1. Check runtime Bluetooth permissions on Android
      if (Platform.isAndroid) {
        dev.log('[ReceiptActions] Checking runtime permissions...', name: 'ReceiptActions');
        final statuses = await [
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ].request();

        final connectStatus = statuses[Permission.bluetoothConnect];
        if (connectStatus == PermissionStatus.denied || connectStatus == PermissionStatus.permanentlyDenied) {
          dev.log('[ReceiptActions] Bluetooth connect permission denied', name: 'ReceiptActions');
          if (ctx != null && ctx.mounted) {
            _showPrinterErrorDialog(ctx, bill: bill, items: items, reason: 'Bluetooth permission needed');
          }
          return;
        }
      }

      // 2. Check if Bluetooth is turned on
      bool isBtOn = false;
      try {
        isBtOn = await PrintBluetoothThermal.bluetoothEnabled;
      } catch (e) {
        dev.log('[ReceiptActions] Error querying bluetoothEnabled: $e', name: 'ReceiptActions');
      }

      if (!isBtOn) {
        dev.log('[ReceiptActions] Bluetooth is turned off on device', name: 'ReceiptActions');
        if (ctx != null && ctx.mounted) {
          _showPrinterErrorDialog(ctx, bill: bill, items: items, reason: 'Bluetooth is turned off');
        }
        return;
      }

      // 3. Check connection / Reconnect with 3-second timeout
      final lastMac = await db.getSetting('last_printer_mac');
      if (lastMac.isEmpty) {
        dev.log('[ReceiptActions] No default printer saved in settings', name: 'ReceiptActions');
        if (ctx != null && ctx.mounted) {
          _showPrinterErrorDialog(ctx, bill: bill, items: items, reason: 'No default printer paired');
        }
        return;
      }

      bool isConn = false;
      try {
        isConn = await PrintBluetoothThermal.connectionStatus;
      } catch (_) {}

      if (!isConn) {
        dev.log('[ReceiptActions] Attempting reconnect to $lastMac with 3s timeout...', name: 'ReceiptActions');
        try {
          isConn = await PrintBluetoothThermal.connect(macPrinterAddress: lastMac)
              .timeout(const Duration(seconds: 3), onTimeout: () => false);
        } catch (e) {
          dev.log('[ReceiptActions] Reconnect attempt threw error: $e', name: 'ReceiptActions');
          isConn = false;
        }
      }

      if (!isConn) {
        dev.log('[ReceiptActions] Printer connection failed or timed out', name: 'ReceiptActions');
        if (ctx != null && ctx.mounted) {
          _showPrinterErrorDialog(ctx, bill: bill, items: items, reason: 'Printer not connected');
        }
        return;
      }

      // 4. Connected: Print receipt bytes
      dev.log('[ReceiptActions] Generating and sending ESC/POS bytes...', name: 'ReceiptActions');
      final printerService = _ref.read(thermalPrinterServiceProvider);
      final bytes = await printerService.generate58mmReceiptBytes(receipt);

      if (bytes.isEmpty) {
        throw Exception('Failed to generate receipt bytes');
      }

      final success = await PrintBluetoothThermal.writeBytes(bytes);
      if (success) {
        dev.log('[ReceiptActions] Receipt printed successfully!', name: 'ReceiptActions');
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Receipt printed'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } else {
        dev.log('[ReceiptActions] writeBytes failed (paper-out or printer error)', name: 'ReceiptActions');
        if (ctx != null && ctx.mounted) {
          _showPrinterErrorDialog(ctx, bill: bill, items: items, reason: 'Print failed. Check paper & printer.');
        }
      }
    } catch (e, stack) {
      dev.log('[ReceiptActions] Unexpected exception in printThermal: $e', error: e, stackTrace: stack, name: 'ReceiptActions');
      if (ctx != null && ctx.mounted) {
        try {
          final db = _ref.read(databaseProvider);
          final bill = await (db.select(db.bills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
          final items = await (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
          if (bill != null && ctx.mounted) {
            _showPrinterErrorDialog(ctx, bill: bill, items: items, reason: 'Printer not connected');
          } else if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.errorRed),
            );
          }
        } catch (_) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.errorRed),
            );
          }
        }
      }
    }
  }

  /// Share 58 mm Receipt as PDF
  Future<void> shareThermalPdf(int billId, {BuildContext? context}) async {
    final ctx = _resolveContext(context);
    try {
      final db = _ref.read(databaseProvider);
      final bill = await (db.select(db.bills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
      if (bill == null) return;

      final items = await (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
      final pdfService = _ref.read(pdfInvoiceServiceProvider);
      await pdfService.share58mmReceiptPdf(bill: bill, items: items);
    } catch (e, stack) {
      dev.log('[ReceiptActions] Error sharing thermal PDF: $e', error: e, stackTrace: stack, name: 'ReceiptActions');
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  /// Open / Print A4 PDF Invoice preview
  Future<void> a4Pdf(int billId, {BuildContext? context}) async {
    final ctx = _resolveContext(context);
    try {
      final db = _ref.read(databaseProvider);
      final bill = await (db.select(db.bills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
      if (bill == null) return;

      final items = await (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
      final pdfService = _ref.read(pdfInvoiceServiceProvider);
      await pdfService.previewOrPrintInvoice(bill: bill, items: items);
    } catch (e, stack) {
      dev.log('[ReceiptActions] Error opening A4 PDF: $e', error: e, stackTrace: stack, name: 'ReceiptActions');
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to generate A4 invoice: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  /// Share A4 Invoice PDF
  Future<void> shareA4(int billId, {BuildContext? context}) async {
    final ctx = _resolveContext(context);
    try {
      final db = _ref.read(databaseProvider);
      final bill = await (db.select(db.bills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
      if (bill == null) return;

      final items = await (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
      final pdfService = _ref.read(pdfInvoiceServiceProvider);
      await pdfService.shareInvoicePdf(bill: bill, items: items);
    } catch (e, stack) {
      dev.log('[ReceiptActions] Error sharing A4 PDF: $e', error: e, stackTrace: stack, name: 'ReceiptActions');
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to share A4 invoice: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  /// Shows the 58 mm bottom sheet for Print/Preview, Share, and Save to device
  Future<void> show58mmPdfSheet(int billId, {BuildContext? context}) async {
    final ctx = _resolveContext(context);
    if (ctx == null) return;

    try {
      final db = _ref.read(databaseProvider);
      final bill = await (db.select(db.bills)..where((tbl) => tbl.id.equals(billId))).getSingleOrNull();
      if (bill == null) return;

      final items = await (db.select(db.billItems)..where((tbl) => tbl.billId.equals(billId))).get();
      final settings = _ref.read(settingsProvider);
      final receipt = ReceiptModel.fromBill(bill: bill, items: items, settings: settings);

      final pdfService = _ref.read(pdfInvoiceServiceProvider);
      final pdfBytes = await pdfService.generate58mmReceiptPdf(receipt);

      if (!ctx.mounted) return;

      await showModalBottomSheet<void>(
        context: ctx,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetCtx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('58 mm Receipt • ${bill.billNumber}', style: AppTypography.heading3),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.print_rounded, color: AppColors.primaryTeal),
                    title: const Text('Print / Preview'),
                    subtitle: const Text('Open Android system print dialog for 58 mm'),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      await Printing.layoutPdf(
                        onLayout: (format) async => pdfBytes,
                        name: 'Receipt_${bill.billNumber}',
                        format: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_rounded, color: Colors.blue),
                    title: const Text('Share Receipt PDF'),
                    subtitle: const Text('Send via WhatsApp, Email, or other apps'),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      await Printing.sharePdf(
                        bytes: pdfBytes,
                        filename: '${bill.billNumber}_receipt58.pdf',
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.save_alt_rounded, color: AppColors.successGreen),
                    title: const Text('Save to device'),
                    subtitle: const Text('Save PDF file to device storage'),
                    onTap: () async {
                      Navigator.pop(sheetCtx);
                      try {
                        final savedPath = await FilePicker.platform.saveFile(
                          dialogTitle: 'Save 58 mm Receipt',
                          fileName: '${bill.billNumber}_receipt58.pdf',
                          bytes: pdfBytes,
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );

                        if (savedPath != null && ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Saved: ${p.basename(savedPath)}'),
                              backgroundColor: AppColors.successGreen,
                              action: SnackBarAction(
                                label: 'Open',
                                textColor: Colors.white,
                                onPressed: () async {
                                  await Printing.sharePdf(
                                    bytes: pdfBytes,
                                    filename: '${bill.billNumber}_receipt58.pdf',
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        dev.log('[ReceiptActions] Error saving file: $e', error: e, name: 'ReceiptActions');
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed to save PDF: $e'), backgroundColor: AppColors.errorRed),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e, stack) {
      dev.log('[ReceiptActions] Error generating 58 mm sheet: $e', error: e, stackTrace: stack, name: 'ReceiptActions');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Could not generate 58 mm PDF: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  void _showPrinterErrorDialog(
    BuildContext context, {
    required Bill bill,
    required List<BillItem> items,
    String? reason,
  }) {
    final title = (reason != null && (reason.contains('permission') || reason.contains('turned off')))
        ? reason
        : 'Printer not connected';
    final message = (reason != null && reason.contains('paper'))
        ? '$reason Do you want to print the 58 mm receipt as a PDF instead?'
        : 'Do you want to print the 58 mm receipt as a PDF instead?';

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.print_disabled_rounded, color: AppColors.errorRed, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.push(AppRoutes.printer);
            },
            child: const Text('Connect printer'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await show58mmPdfSheet(bill.id, context: context);
            },
            child: const Text('Print as PDF'),
          ),
        ],
      ),
    );
  }

  /// Print Day Closing Summary on 58 mm Thermal Printer with reconnect and PDF fallback
  Future<void> printDayClosingThermal(DayClosing closing, {BuildContext? context}) async {
    final ctx = _resolveContext(context);
    dev.log('[ReceiptActions] printDayClosingThermal called for closing #${closing.id}', name: 'ReceiptActions');

    try {
      final db = _ref.read(databaseProvider);

      // 1. Check runtime Bluetooth permissions on Android
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ].request();

        final connectStatus = statuses[Permission.bluetoothConnect];
        if (connectStatus == PermissionStatus.denied || connectStatus == PermissionStatus.permanentlyDenied) {
          if (ctx != null && ctx.mounted) {
            _showDayClosingPrinterErrorDialog(ctx, closing: closing, reason: 'Bluetooth permission needed');
          }
          return;
        }
      }

      // 2. Check if Bluetooth is turned on
      bool isBtOn = false;
      try {
        isBtOn = await PrintBluetoothThermal.bluetoothEnabled;
      } catch (_) {}

      if (!isBtOn) {
        if (ctx != null && ctx.mounted) {
          _showDayClosingPrinterErrorDialog(ctx, closing: closing, reason: 'Bluetooth is turned off');
        }
        return;
      }

      // 3. Reconnect with 3-second timeout if not connected
      final lastMac = await db.getSetting('last_printer_mac');
      if (lastMac.isEmpty) {
        if (ctx != null && ctx.mounted) {
          _showDayClosingPrinterErrorDialog(ctx, closing: closing, reason: 'No default printer paired');
        }
        return;
      }

      bool isConn = false;
      try {
        isConn = await PrintBluetoothThermal.connectionStatus;
      } catch (_) {}

      if (!isConn) {
        try {
          isConn = await PrintBluetoothThermal.connect(macPrinterAddress: lastMac)
              .timeout(const Duration(seconds: 3), onTimeout: () => false);
        } catch (_) {
          isConn = false;
        }
      }

      if (!isConn) {
        if (ctx != null && ctx.mounted) {
          _showDayClosingPrinterErrorDialog(ctx, closing: closing, reason: 'Printer not connected');
        }
        return;
      }

      // 4. Print Day Closing ESC/POS Bytes
      final settings = _ref.read(settingsProvider);
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.reset();
      bytes += generator.text(
        settings.storeName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
      bytes += generator.text('DAY END CLOSING SUMMARY', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Date: ${Formatters.dateTime(closing.closedAt)}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr(ch: '-');

      bytes += generator.row([
        PosColumn(text: 'Opening Cash:', width: 7),
        PosColumn(text: Formatters.currency(closing.openingCash, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: '+ Cash Sales:', width: 7),
        PosColumn(text: Formatters.currency(closing.cashSales, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: '- Expenses:', width: 7),
        PosColumn(text: Formatters.currency(closing.cashExpenses, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.hr(ch: '-');

      bytes += generator.row([
        PosColumn(text: 'Expected Cash:', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: Formatters.currency(closing.expectedCash, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Counted Cash:', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: Formatters.currency(closing.countedCash, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Difference:', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: Formatters.currency(closing.difference, symbol: settings.currencySymbol), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);

      if (closing.notes != null && closing.notes!.isNotEmpty) {
        bytes += generator.feed(1);
        bytes += generator.text('Notes: ${closing.notes}');
      }

      bytes += generator.feed(settings.printCutFeed);
      bytes += generator.cut();

      final success = await PrintBluetoothThermal.writeBytes(bytes);
      if (success) {
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Summary printed on 58 mm'), backgroundColor: AppColors.successGreen),
          );
        }
      } else {
        if (ctx != null && ctx.mounted) {
          _showDayClosingPrinterErrorDialog(ctx, closing: closing, reason: 'Print failed. Check paper & printer.');
        }
      }
    } catch (e, stack) {
      dev.log('[ReceiptActions] Error in printDayClosingThermal: $e', error: e, stackTrace: stack, name: 'ReceiptActions');
      if (ctx != null && ctx.mounted) {
        _showDayClosingPrinterErrorDialog(ctx, closing: closing, reason: 'Printer not connected');
      }
    }
  }

  void _showDayClosingPrinterErrorDialog(
    BuildContext context, {
    required DayClosing closing,
    String? reason,
  }) {
    final title = (reason != null && (reason.contains('permission') || reason.contains('turned off')))
        ? reason
        : 'Printer not connected';
    const message = 'Do you want to preview the closing summary as a PDF instead?';

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.print_disabled_rounded, color: AppColors.errorRed, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: const Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.push(AppRoutes.printer);
            },
            child: const Text('Connect printer'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await showDayClosing58mmPdfSheet(closing, context: context);
            },
            child: const Text('Print as PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> showDayClosing58mmPdfSheet(DayClosing closing, {BuildContext? context}) async {
    final ctx = _resolveContext(context);
    if (ctx == null) return;

    try {
      final settings = _ref.read(settingsProvider);
      final inter = await PdfInvoiceService.loadInterFont();
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: inter,
          bold: inter,
          italic: inter,
          boldItalic: inter,
        ),
      );

      const format = PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm);
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context pageCtx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(settings.storeName, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('DAY END CLOSING SUMMARY', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${Formatters.dateTime(closing.closedAt)}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7)),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
                _buildReceiptRow('Opening Cash:', Formatters.currency(closing.openingCash, symbol: settings.currencySymbol)),
                _buildReceiptRow('+ Cash Sales:', Formatters.currency(closing.cashSales, symbol: settings.currencySymbol)),
                _buildReceiptRow('- Expenses:', Formatters.currency(closing.cashExpenses, symbol: settings.currencySymbol)),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
                _buildReceiptRow('Expected Cash:', Formatters.currency(closing.expectedCash, symbol: settings.currencySymbol), bold: true),
                _buildReceiptRow('Counted Cash:', Formatters.currency(closing.countedCash, symbol: settings.currencySymbol), bold: true),
                _buildReceiptRow('Difference:', Formatters.currency(closing.difference, symbol: settings.currencySymbol), bold: true),
                if (closing.notes != null && closing.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text('Notes: ${closing.notes}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      if (!ctx.mounted) return;

      await Printing.layoutPdf(
        onLayout: (fmt) async => pdfBytes,
        name: 'DayClosing_${Formatters.date(closing.closedAt)}',
        format: format,
      );
    } catch (e, stack) {
      dev.log('[ReceiptActions] Error showing day closing PDF: $e', error: e, stackTrace: stack, name: 'ReceiptActions');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to generate day closing PDF: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
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
}

final receiptActionsProvider = Provider<ReceiptActions>((ref) {
  return ReceiptActions(ref);
});