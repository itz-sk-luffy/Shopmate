import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/providers/database_provider.dart';
import 'package:shopmate/features/printer/domain/receipt_model.dart';
import 'package:shopmate/features/printer/services/pdf_invoice_service.dart';
import 'package:shopmate/features/printer/services/thermal_printer_service.dart';

class FakePrinterDb implements AppDatabase {
  final Map<String, String> settings = {
    'store_name': 'Shopmate Store',
    'store_address': '123 Market Road',
    'store_phone': '9876543210',
    'store_email': 'info@shopmate.com',
    'store_gstin': '29ABCDE1234F1Z5',
    'store_state': 'Karnataka',
    'currency_symbol': '₹',
    'gst_enabled': 'true',
    'tax_type': 'exclusive',
  };

  @override
  Future<Map<String, String>> getAllSettings() async => Map.from(settings);

  @override
  Future<String> getSetting(String key, {String defaultValue = ''}) async => settings[key] ?? defaultValue;

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyBill = Bill(
    id: 1,
    billNumber: 'INV-1001',
    date: DateTime(2026, 10, 31, 14, 30),
    customerId: 1,
    customerName: 'John Doe',
    customerPhone: '9876543210',
    subtotal: 500.0,
    itemDiscountTotal: 20.0,
    billDiscountPercent: 0.0,
    billDiscountAmount: 30.0,
    gstType: 'inclusive',
    cgstTotal: 10.71,
    sgstTotal: 10.72,
    igstTotal: 0.0,
    roundOff: 0.0,
    grandTotal: 450.0,
    paymentMode: 'Cash',
    cashAmount: 450.0,
    digitalAmount: 0.0,
    changeTendered: 50.0,
    isHeld: false,
    isCreditPaid: false,
    isEdited: false,
    isDeleted: false,
    createdAt: DateTime(2026, 10, 31, 14, 30),
    updatedAt: DateTime(2026, 10, 31, 14, 30),
  );

  final List<BillItem> dummyItems = [
    const BillItem(
      id: 1,
      billId: 1,
      productId: 10,
      productName: 'Organic Honey',
      quantity: 2.0,
      unit: 'bottle',
      unitPrice: 250.0,
      discountAmount: 20.0,
      totalAmount: 500.0,
      gstRate: 5.0,
      gstAmount: 21.43,
      taxableValue: 428.57,
      cgstAmount: 10.71,
      sgstAmount: 10.72,
      igstAmount: 0.0,
    ),
  ];

  const dummySettings = AppSettingsState(
    settings: {
      'store_name': 'Test Supermarket',
      'store_address': '123 Market St, Chennai',
      'store_phone': '044-12345678',
      'store_gstin': '33AAAAA0000A1Z5',
      'receipt_currency_symbol': 'Rs.',
      'receipt_show_gst': 'true',
      'receipt_show_customer': 'true',
      'receipt_show_footer': 'true',
      'store_footer': 'Thank you! Visit again.',
      'print_cut_feed': '2',
    },
    isLoading: false,
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('groons.web.app/print'), (call) async {
      switch (call.method) {
        case 'connectionstatus':
          return false;
        case 'bluetoothenabled':
          return true;
        case 'ispermissionbluetoothgranted':
          return true;
        case 'pairedbluetooths':
          return [];
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('groons.web.app/print'), null);
  });

  test('ReceiptModel.fromBill formats all fields and tax lines correctly', () {
    final receipt = ReceiptModel.fromBill(
      bill: dummyBill,
      items: dummyItems,
      settings: dummySettings,
    );

    expect(receipt.storeName, 'Test Supermarket');
    expect(receipt.billNumber, 'INV-1001');
    expect(receipt.customerName, 'John Doe');
    expect(receipt.customerPhone, '9876543210');
    expect(receipt.items.length, 1);
    expect(receipt.items.first.productName, 'Organic Honey');
    expect(receipt.currencySymbol, 'Rs.');
    expect(receipt.subtotal, 500.0);
    expect(receipt.grandTotal, 450.0);
    expect(receipt.taxLines.length, 2);
    expect(receipt.taxLines[0].label, contains('CGST'));
    expect(receipt.taxLines[1].label, contains('SGST'));
    expect(receipt.storeFooter, 'Thank you! Visit again.');
  });

  test('PdfInvoiceService generates valid 58mm continuous roll PDF', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
    final pdfService = container.read(pdfInvoiceServiceProvider);
    final receipt = ReceiptModel.fromBill(
      bill: dummyBill,
      items: dummyItems,
      settings: dummySettings,
    );

    final pdfBytes = await pdfService.generate58mmReceiptPdf(receipt);
    expect(pdfBytes.isNotEmpty, isTrue);
    expect(pdfBytes.length, greaterThan(500));
    await db.close();
  });

  test('PdfInvoiceService generates valid attractive A4 Invoice PDF with Playfair font', () async {
    final fakeDb = FakePrinterDb();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(fakeDb),
        settingsProvider.overrideWith((ref) => AppSettingsNotifier(fakeDb)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).loadSettings();

    final pdfService = container.read(pdfInvoiceServiceProvider);

    final pdfBytes = await pdfService.generateA4InvoicePdf(
      bill: dummyBill,
      items: dummyItems,
    );
    expect(pdfBytes.isNotEmpty, isTrue);
    expect(pdfBytes.length, greaterThan(1000));
  });

  testWidgets('Printer prompt dialog appears with correct options when printer is not connected', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final printer = container.read(thermalPrinterServiceProvider);
                  await printer.printOrPrompt58mmReceipt(context, bill: dummyBill, items: dummyItems);
                },
                child: const Text('Print 58 mm'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Print 58 mm'));
    await tester.pumpAndSettle();

    // Dialog should appear with prompt
    expect(find.text('Would you like to print the 58 mm receipt as a PDF instead?'), findsOneWidget);
    expect(find.text('Printer not connected'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Connect printer'), findsOneWidget);
    expect(find.text('Print as PDF'), findsOneWidget);

    // Tap Cancel to dismiss
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Would you like to print the 58 mm receipt as a PDF instead?'), findsNothing);

    await db.close();
  });

  testWidgets('Shows Bluetooth is turned off message when bluetooth is disabled', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final printer = container.read(thermalPrinterServiceProvider);
                  await printer.printOrPrompt58mmReceipt(
                    context,
                    bill: dummyBill,
                    items: dummyItems,
                    bluetoothEnabledChecker: () async => false,
                  );
                },
                child: const Text('Print 58 mm'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Print 58 mm'));
    await tester.pumpAndSettle();

    // Should indicate Bluetooth is turned off
    expect(find.text('Bluetooth is turned off'), findsOneWidget);
    expect(find.text('Would you like to print the 58 mm receipt as a PDF instead?'), findsOneWidget);

    await db.close();
  });

  testWidgets('Shows Bluetooth permission needed message when permission is missing', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final printer = container.read(thermalPrinterServiceProvider);
                  await printer.printOrPrompt58mmReceipt(
                    context,
                    bill: dummyBill,
                    items: dummyItems,
                    permissionGrantedChecker: () async => false,
                  );
                },
                child: const Text('Print 58 mm'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Print 58 mm'));
    await tester.pumpAndSettle();

    // Should indicate Bluetooth permission needed
    expect(find.text('Bluetooth permission needed'), findsOneWidget);
    expect(find.text('Would you like to print the 58 mm receipt as a PDF instead?'), findsOneWidget);

    await db.close();
  });
}
