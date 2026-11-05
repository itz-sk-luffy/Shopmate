import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopmate/features/dashboard/data/dashboard_repository.dart';
import 'package:shopmate/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shopmate/features/orders/data/orders_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Rapid-tapping Today -> This Week -> This Month -> Today preserves data without blank frames',
      (tester) async {
    const todayMetrics = DashboardMetrics(
      totalSales: 500.0,
      totalBills: 2,
      averageBill: 250.0,
      todayUdhaar: 0.0,
      cashCollected: 500.0,
      digitalCollected: 0.0,
      gstCollected: 25.0,
      deltaPercentVsYesterday: 10.0,
    );

    const weekMetrics = DashboardMetrics(
      totalSales: 2500.0,
      totalBills: 10,
      averageBill: 250.0,
      todayUdhaar: 100.0,
      cashCollected: 2000.0,
      digitalCollected: 500.0,
      gstCollected: 125.0,
      deltaPercentVsYesterday: 15.0,
    );

    const monthMetrics = DashboardMetrics(
      totalSales: 10000.0,
      totalBills: 40,
      averageBill: 250.0,
      todayUdhaar: 500.0,
      cashCollected: 7000.0,
      digitalCollected: 3000.0,
      gstCollected: 500.0,
      deltaPercentVsYesterday: 20.0,
    );

    final container = ProviderContainer(
      overrides: [
        dashboardMetricsFamilyProvider('Today').overrideWith((ref) async => todayMetrics),
        dashboardMetricsFamilyProvider('This Week').overrideWith((ref) async => weekMetrics),
        dashboardMetricsFamilyProvider('This Month').overrideWith((ref) async => monthMetrics),
        hourlySalesProvider.overrideWith((ref) async => []),
        topProductsProvider.overrideWith((ref) async => []),
        paymentBreakdownProvider.overrideWith((ref) async => {'Cash': 500.0}),
        billsStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Verify initial data rendered
    expect(find.text("TODAY'S TOTAL SALES"), findsOneWidget);
    expect(find.byType(AnimatedCurrencyText), findsWidgets);
    expect(find.byType(AnimatedCountText), findsWidgets);

    // 1. Rapid tap 'This Week'
    await tester.tap(find.widgetWithText(ChoiceChip, 'This Week'));
    await tester.pump(); // immediate frame after tap

    // Zero blank frames: CustomCard remains rendered, not replaced with full-page spinner
    expect(find.text("THIS WEEK'S TOTAL SALES"), findsOneWidget);
    expect(find.byType(AnimatedCurrencyText), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // 2. Rapid tap 'This Month'
    await tester.tap(find.widgetWithText(ChoiceChip, 'This Month'));
    await tester.pump(); // immediate frame after tap

    expect(find.text("THIS MONTH'S TOTAL SALES"), findsOneWidget);
    expect(find.byType(AnimatedCurrencyText), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // 3. Rapid tap 'Today' again
    await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
    await tester.pump(); // immediate frame after tap

    // Instant switch back with cached data and count micro-animations
    expect(find.text("TODAY'S TOTAL SALES"), findsOneWidget);
    expect(find.byType(AnimatedCurrencyText), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();
  });
}
