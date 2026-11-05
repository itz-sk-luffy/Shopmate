import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopmate/features/dashboard/data/dashboard_repository.dart';
import 'package:shopmate/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shopmate/features/orders/data/orders_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dashboard renders HourlySales graph without exception when sales exist', (tester) async {
    const todayMetrics = DashboardMetrics(
      totalSales: 1500.0,
      totalBills: 3,
      averageBill: 500.0,
      todayUdhaar: 0.0,
      cashCollected: 1500.0,
      digitalCollected: 0.0,
      gstCollected: 75.0,
      deltaPercentVsYesterday: 10.0,
    );

    final hourlyPoints = [
      for (int h = 8; h <= 22; h++)
        HourlySalesPoint(hour: h, amount: h == 10 ? 500.0 : (h == 14 ? 1000.0 : 0.0)),
    ];

    final container = ProviderContainer(
      overrides: [
        dashboardMetricsFamilyProvider('Today').overrideWith((ref) async => todayMetrics),
        hourlySalesProvider.overrideWith((ref) async => hourlyPoints),
        topProductsProvider.overrideWith((ref) async => []),
        paymentBreakdownProvider.overrideWith((ref) async => {'Cash': 1500.0}),
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

    await tester.pumpAndSettle();

    final chartHeader = find.text('Hourly Sales Trend (Today)');
    await tester.scrollUntilVisible(chartHeader, 300, scrollable: find.byType(Scrollable).first);

    expect(chartHeader, findsOneWidget);
    expect(find.byKey(const ValueKey('hourly_error')), findsNothing);
  });

  testWidgets('Dashboard renders clean empty state when sales are zero', (tester) async {
    const todayMetrics = DashboardMetrics(
      totalSales: 0.0,
      totalBills: 0,
      averageBill: 0.0,
      todayUdhaar: 0.0,
      cashCollected: 0.0,
      digitalCollected: 0.0,
      gstCollected: 0.0,
      deltaPercentVsYesterday: 0.0,
    );

    final hourlyPoints = [
      for (int h = 6; h <= 23; h++)
        HourlySalesPoint(hour: h, amount: 0.0, label: '${h}AM'),
    ];

    final container = ProviderContainer(
      overrides: [
        dashboardMetricsFamilyProvider('Today').overrideWith((ref) async => todayMetrics),
        hourlySalesProvider.overrideWith((ref) async => hourlyPoints),
        topProductsProvider.overrideWith((ref) async => []),
        paymentBreakdownProvider.overrideWith((ref) async => {'Cash': 0.0}),
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

    await tester.pumpAndSettle();

    final noSalesFinder = find.byKey(const ValueKey('hourly_no_sales'));
    await tester.scrollUntilVisible(noSalesFinder, 300, scrollable: find.byType(Scrollable).first);

    expect(noSalesFinder, findsOneWidget);
    expect(find.text('No sales recorded yet today'), findsOneWidget);
  });
}
