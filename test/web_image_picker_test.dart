import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopmate/core/database/app_database.dart';
import 'package:shopmate/core/providers/database_provider.dart';
import 'package:shopmate/features/products/presentation/web_image_picker_screen.dart';

class FakeAppDatabase implements AppDatabase {
  final Map<String, String> settings = {};

  @override
  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    return settings[key] ?? defaultValue;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pre-fill fix: empty query or "New Product" leaves field empty and shows idle prompt',
      (tester) async {
    final db = FakeAppDatabase();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    // 1. Test empty query
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WebImagePickerScreen(initialQuery: ''),
        ),
      ),
    );
    await tester.pump();

    final textFieldEmpty = tester.widget<TextField>(find.byType(TextField));
    expect(textFieldEmpty.controller?.text, '');
    expect(find.text('Type a product name to search for images'), findsOneWidget);

    // 2. Test "New Product"
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WebImagePickerScreen(initialQuery: 'New Product'),
        ),
      ),
    );
    await tester.pump();

    final textFieldGeneric = tester.widget<TextField>(find.byType(TextField));
    expect(textFieldGeneric.controller?.text, '');
    expect(find.text('Type a product name to search for images'), findsOneWidget);
  });

  testWidgets('Pre-fill with actual product starts in loading state with shimmer tiles', (tester) async {
    final db = FakeAppDatabase();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WebImagePickerScreen(initialQuery: 'Organic Honey'),
        ),
      ),
    );
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'Organic Honey');

    // Shows engine switch chips
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Bing'), findsOneWidget);
    expect(find.text('DuckDuckGo'), findsOneWidget);

    // Starts in shimmer loading state (15 shimmer grid tiles)
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('Switching engine to Bing persists in settings and updates chip', (tester) async {
    final db = FakeAppDatabase();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WebImagePickerScreen(initialQuery: 'Organic Honey'),
        ),
      ),
    );
    await tester.pump();

    // Tap Bing chip
    await tester.tap(find.text('Bing'));
    await tester.pump();

    // Verify setting saved to db
    final savedEngine = await db.getSetting('search_engine');
    expect(savedEngine, 'bing');
  });
}
