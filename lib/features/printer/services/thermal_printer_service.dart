import 'dart:developer' as dev;
import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../domain/receipt_model.dart';
import 'pdf_invoice_service.dart';

class ThermalPrinterService {
  final Ref _ref;

  ThermalPrinterService(this._ref);

  Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      dev.log('[ThermalPrinterService] Requesting Bluetooth permissions...', name: 'Printer');
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? true;
      dev.log('[ThermalPrinterService] Permissions: connect=$connectGranted, scan=$scanGranted', name: 'Printer');
      return connectGranted && scanGranted;
    } catch (e) {
      dev.log('[ThermalPrinterService] Permission request error: $e', name: 'Printer');
      return false;
    }
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      await requestBluetoothPermissions();
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      dev.log('[ThermalPrinterService] Found ${devices.length} paired devices', name: 'Printer');
      return devices;
    } catch (e) {
      dev.log('[ThermalPrinterService] getPairedDevices error: $e', name: 'Printer');
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      await requestBluetoothPermissions();
      // Disconnect any stale or hanging socket first
      try {
        await PrintBluetoothThermal.disconnect;
      } catch (_) {}

      dev.log('[ThermalPrinterService] Connecting to $macAddress...', name: 'Printer');
      bool success = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);

      // Retry once if first socket attempt fails (common on Android RFCOMM channels)
      if (!success) {
        dev.log('[ThermalPrinterService] Attempt 1 failed, retrying in 500ms...', name: 'Printer');
        await Future.delayed(const Duration(milliseconds: 500));
        success = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      }

      if (success) {
        final db = _ref.read(databaseProvider);
        await db.setSetting('last_printer_mac', macAddress);
        dev.log('[ThermalPrinterService] Successfully connected to $macAddress', name: 'Printer');
      } else {
        dev.log('[ThermalPrinterService] Failed to connect to $macAddress', name: 'Printer');
      }
      return success;
    } catch (e) {
      dev.log('[ThermalPrinterService] connect exception: $e', name: 'Printer');
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final success = await PrintBluetoothThermal.disconnect;
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ensureConnected() async {
    try {
      if (await isConnected()) return true;
    } catch (_) {}

    try {
      final db = _ref.read(databaseProvider);
      final lastMac = await db.getSetting('last_printer_mac');
      if (lastMac.isNotEmpty) {
        try {
          final success = await connect(lastMac).timeout(const Duration(seconds: 3), onTimeout: () => false);
          if (success) return true;
        } catch (_) {}
      }
    } catch (_) {}

    try {
      return await isConnected();
    } catch (_) {
      return false;
    }
  }

  Future<String?> checkBluetoothIssue({
    Future<bool> Function()? bluetoothEnabledChecker,
    Future<bool> Function()? permissionGrantedChecker,
  }) async {
    try {
      final isPermGranted = permissionGrantedChecker != null
          ? await permissionGrantedChecker()
          : await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (!isPermGranted) {
        return 'Bluetooth permission needed';
      }
    } catch (_) {}

    try {
      final isBtOn = bluetoothEnabledChecker != null
          ? await bluetoothEnabledChecker()
          : await PrintBluetoothThermal.bluetoothEnabled;
      if (!isBtOn) {
        return 'Bluetooth is turned off';
      }
    } catch (_) {}

    return null;
  }

  Future<void> printOrPrompt58mmReceipt(
    BuildContext context, {
    required Bill bill,
    required List<BillItem> items,
    Future<bool> Function()? bluetoothEnabledChecker,
    Future<bool> Function()? permissionGrantedChecker,
  }) async {
    // 1. Check connection and attempt reconnect if needed (up to 3 seconds)
    final connected = await ensureConnected();

    if (connected) {
      final ok = await printBill(bill: bill, items: items);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Receipt printed on 58 mm' : 'Print failed. Check paper & printer.'),
            backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
          ),
        );
      }
      return;
    }

    // 2. Not connected: Check bluetooth status
    final btIssue = await checkBluetoothIssue(
      bluetoothEnabledChecker: bluetoothEnabledChecker,
      permissionGrantedChecker: permissionGrantedChecker,
    );
    final title = btIssue ?? 'Printer not connected';
    const message = 'Would you like to print the 58 mm receipt as a PDF instead?';

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
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
              final pdfService = _ref.read(pdfInvoiceServiceProvider);
              await pdfService.previewOrPrint58mmReceipt(bill: bill, items: items);
            },
            child: const Text('Print as PDF'),
          ),
        ],
      ),
    );
  }

  Future<bool> printBill({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    final connected = await isConnected();
    if (!connected) return false;

    final settings = _ref.read(settingsProvider);
    final receipt = ReceiptModel.fromBill(bill: bill, items: items, settings: settings);
    final bytes = await generate58mmReceiptBytes(receipt);
    if (bytes.isEmpty) return false;

    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  Future<bool> printTestReceipt() async {
    final connected = await isConnected();
    if (!connected) return false;

    final settings = _ref.read(settingsProvider);
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      settings.storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(settings.storeAddress, styles: const PosStyles(align: PosAlign.center));
    if (settings.storePhone.isNotEmpty) {
      bytes += generator.text('Tel: ${settings.storePhone}', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr(ch: '-');
    bytes += generator.text('58 MM PRINTER TEST OK', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Date: ${Formatters.dateTime(DateTime.now())}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '-');
    bytes += generator.text('Shopmate POS Ready', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(settings.printCutFeed);
    bytes += generator.cut();

    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  Future<List<int>> generate58mmReceiptBytes(ReceiptModel receipt) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    // 1. Store Header (Centered)
    bytes += generator.text(
      receipt.storeName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    if (receipt.storeAddress.isNotEmpty) {
      bytes += generator.text(
        receipt.storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (receipt.storePhone.isNotEmpty) {
      bytes += generator.text(
        'Phone: ${receipt.storePhone}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (receipt.storeGstin.isNotEmpty) {
      bytes += generator.text(
        'GSTIN: ${receipt.storeGstin}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr(ch: '-');

    // 2. Bill & Customer Metadata
    bytes += generator.row([
      PosColumn(text: 'Bill: ${receipt.billNumber}', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: receipt.dateFormatted, width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Time: ${receipt.timeFormatted}', width: 6),
      PosColumn(text: 'Mode: ${receipt.paymentMode}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (receipt.customerName != null && receipt.customerName!.isNotEmpty) {
      bytes += generator.text('Customer: ${receipt.customerName}');
      if (receipt.customerPhone != null && receipt.customerPhone!.isNotEmpty) {
        bytes += generator.text('Phone: ${receipt.customerPhone}');
      }
    }

    bytes += generator.hr(ch: '-');

    // 3. Items Header: Total 32 characters in 58mm (12 + 6 + 6 + 8)
    bytes += generator.row([
      PosColumn(text: 'Item', width: 5, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'Rate', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'Total', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr(ch: '-');

    // 4. Items List
    for (final item in receipt.items) {
      final name = item.productName.length > 14
          ? '${item.productName.substring(0, 12)}..'
          : item.productName;
      final qtyStr = item.quantity == item.quantity.roundToDouble()
          ? '${item.quantity.toInt()}'
          : item.quantity.toStringAsFixed(2);
      final rateStr = item.unitPrice.toStringAsFixed(0);
      final totalStr = item.totalAmount.toStringAsFixed(0);

      bytes += generator.row([
        PosColumn(text: name, width: 5),
        PosColumn(text: qtyStr, width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: rateStr, width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: totalStr, width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr(ch: '-');

    // 5. Financial Summary Breakdown
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 7),
      PosColumn(
        text: Formatters.currency(receipt.subtotal, symbol: receipt.currencySymbol),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (receipt.itemDiscountTotal > 0) {
      bytes += generator.row([
        PosColumn(text: 'Item Discounts:', width: 7),
        PosColumn(
          text: '-${Formatters.currency(receipt.itemDiscountTotal, symbol: receipt.currencySymbol)}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (receipt.billDiscountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Bill Discount:', width: 7),
        PosColumn(
          text: '-${Formatters.currency(receipt.billDiscountAmount, symbol: receipt.currencySymbol)}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    for (final tax in receipt.taxLines) {
      bytes += generator.row([
        PosColumn(text: '${tax.label}:', width: 7),
        PosColumn(
          text: Formatters.currency(tax.amount, symbol: receipt.currencySymbol),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    if (receipt.roundOff.abs() > 0.001) {
      bytes += generator.row([
        PosColumn(text: 'Round Off:', width: 7),
        PosColumn(
          text: '${receipt.roundOff >= 0 ? '+' : ''}${receipt.roundOff.toStringAsFixed(2)}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // 6. Grand Total (Double Height & Width, Bold)
    bytes += generator.hr(ch: '=');
    bytes += generator.text(
      'TOTAL: ${Formatters.currency(receipt.grandTotal, symbol: receipt.currencySymbol)}',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.hr(ch: '=');

    // 7. Payment details
    if (receipt.paymentMode == 'Cash' && receipt.changeTendered > 0) {
      bytes += generator.row([
        PosColumn(text: 'Cash Tendered:', width: 7),
        PosColumn(
          text: Formatters.currency(receipt.cashAmount + receipt.changeTendered, symbol: receipt.currencySymbol),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Change Returned:', width: 7),
        PosColumn(
          text: Formatters.currency(receipt.changeTendered, symbol: receipt.currencySymbol),
          width: 5,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }

    // 8. Store Footer Note (Centered)
    if (receipt.storeFooter.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text(
        receipt.storeFooter,
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    // 9. Feed & Cut
    bytes += generator.feed(receipt.printCutFeed);
    bytes += generator.cut();

    return bytes;
  }
}

final thermalPrinterServiceProvider = Provider<ThermalPrinterService>((ref) {
  return ThermalPrinterService(ref);
});

final bluetoothEnabledProvider = FutureProvider.autoDispose<bool>((ref) {
  final service = ref.watch(thermalPrinterServiceProvider);
  return service.isBluetoothEnabled();
});

final bluetoothDevicesProvider = FutureProvider.autoDispose<List<BluetoothInfo>>((ref) {
  final service = ref.watch(thermalPrinterServiceProvider);
  return service.getPairedDevices();
});

final printerConnectedProvider = FutureProvider.autoDispose<bool>((ref) {
  final service = ref.watch(thermalPrinterServiceProvider);
  return service.isConnected();
});
