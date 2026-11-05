import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/theme/app_colors.dart';
import 'package:shopmate/core/theme/app_typography.dart';
import 'package:shopmate/core/utils/formatters.dart';
import 'package:shopmate/features/pos/data/billing_repository.dart';
import 'package:shopmate/features/pos/presentation/widgets/held_bills_sheet.dart';

void main() {
  group('Narrow screen (320dp) & 1.3x text scale layout tests', () {
    testWidgets('renders held-bills sheet at 320 dp width and 1.3x text scale with no overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final dummyBills = [
        HeldBillEntry(
          bill: Bill(
            id: 1,
            billNumber: 'INV-1001',
            date: DateTime(2026, 10, 31, 14, 30),
            customerName: 'A Very Long Customer Name Walk-in Deluxe',
            paymentMode: 'Cash',
            cashAmount: 200.0,
            digitalAmount: 0.0,
            changeTendered: 0.0,
            subtotal: 200.0,
            itemDiscountTotal: 0.0,
            billDiscountPercent: 0.0,
            billDiscountAmount: 0.0,
            gstType: 'exclusive',
            cgstTotal: 0.0,
            sgstTotal: 0.0,
            igstTotal: 0.0,
            roundOff: 0.0,
            grandTotal: 200.0,
            isHeld: true,
            isCreditPaid: false,
            isEdited: false,
            isDeleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          itemCount: 4,
        ),
        HeldBillEntry(
          bill: Bill(
            id: 2,
            billNumber: 'INV-1002',
            date: DateTime(2026, 10, 31, 14, 45),
            customerName: 'Walk-in Customer',
            paymentMode: 'UPI',
            cashAmount: 0.0,
            digitalAmount: 1450.50,
            changeTendered: 0.0,
            subtotal: 1450.50,
            itemDiscountTotal: 0.0,
            billDiscountPercent: 0.0,
            billDiscountAmount: 0.0,
            gstType: 'exclusive',
            cgstTotal: 0.0,
            sgstTotal: 0.0,
            igstTotal: 0.0,
            roundOff: 0.0,
            grandTotal: 1450.50,
            isHeld: true,
            isCreditPaid: false,
            isEdited: false,
            isDeleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          itemCount: 1,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heldBillsStreamProvider.overrideWith((ref) => Stream.value(dummyBills)),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 700),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(
                body: HeldBillsSheet(currencySymbol: '₹'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that held bills sheet rendered without overflow
      expect(find.text('Held Bills'), findsOneWidget);
      expect(find.text('Resume'), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
      expect(find.textContaining('Walk-in Customer'), findsOneWidget);
      expect(find.textContaining('1 item'), findsOneWidget);
      expect(find.textContaining('4 items'), findsOneWidget);

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders order tile at 320 dp width and 1.3x text scale with no overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 400 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final bill = Bill(
        id: 10,
        billNumber: 'INV-10999',
        date: DateTime.now(),
        customerName: 'Shri Venkateshwara General Store & Emporium',
        paymentMode: 'Credit',
        cashAmount: 0.0,
        digitalAmount: 0.0,
        changeTendered: 0.0,
        subtotal: 5432.0,
        itemDiscountTotal: 100.0,
        billDiscountPercent: 0.0,
        billDiscountAmount: 0.0,
        gstType: 'exclusive',
        cgstTotal: 120.0,
        sgstTotal: 120.0,
        igstTotal: 0.0,
        roundOff: 0.0,
        grandTotal: 5572.0,
        isHeld: false,
        isCreditPaid: false,
        isEdited: true,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 400),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.history_edu_rounded)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                bill.billNumber,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bill.customerName ?? 'Walk-in Customer',
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.currency(bill.grandTotal, symbol: '₹'),
                              style: AppTypography.priceBold.copyWith(fontSize: 15),
                            ),
                            const Text('Unpaid', style: TextStyle(fontSize: 10, color: AppColors.errorRed)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final err = tester.takeException();
      if (err is FlutterError) {
        for (final d in err.diagnostics) {
          debugPrint('${d.name}: ${d.value}');
        }
      }
      expect(find.text('INV-10999'), findsOneWidget);
      expect(find.textContaining('Shri Venkateshwara'), findsOneWidget);
      expect(err, isNull);
    });

    testWidgets('renders customer tile at 320 dp width and 1.3x text scale with no overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 400 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final customer = Customer(
        id: 1,
        name: 'Ramachandra Murthy Subrahmanyam Sastry',
        phone: '+91 9876543210',
        balance: 1250.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 400),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Text('R')),
                    title: Text(
                      customer.name,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      customer.phone ?? 'No phone',
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(customer.balance, symbol: '₹'),
                          style: AppTypography.priceBold.copyWith(fontSize: 14),
                        ),
                        const Text('Udhaar', style: TextStyle(fontSize: 10, color: AppColors.errorRed)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Ramachandra'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
