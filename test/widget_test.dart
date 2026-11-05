import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopmate/main.dart';

void main() {
  testWidgets('Shopmate app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShopmateApp(),
      ),
    );

    // Initial frame renders
    expect(find.byType(ShopmateApp), findsOneWidget);
  });
}
