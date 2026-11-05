import 'package:flutter_test/flutter_test.dart';
import 'package:shopmate/core/routing/app_router.dart';
import 'package:shopmate/core/routing/app_routes.dart';

void main() {
  group('AppRoutes Navigation & Resolution Test', () {
    late final router = createRouter(
      hasCompletedOnboarding: true,
      isAppLockEnabled: false,
      isUnlocked: true,
      isLoading: false,
    );

    test('Every AppRoutes constant resolves to a valid route in GoRouter', () {
      for (final route in AppRoutes.allRoutes) {
        // Replace dynamic path parameters with mock IDs
        final testLocation = route.replaceAll(RegExp(r':\w+'), '1');
        final match = router.configuration.findMatch(Uri.parse(testLocation));

        expect(
          match.matches.isNotEmpty,
          isTrue,
          reason: 'Route "$route" (tested as "$testLocation") failed to resolve in GoRouter.',
        );
      }
    });

    test('Billing route /billing resolves successfully without GoException', () {
      final match = router.configuration.findMatch(Uri.parse(AppRoutes.billing));
      expect(match.matches.isNotEmpty, isTrue);
      expect(match.matches.last.matchedLocation, AppRoutes.billing);
    });

    test('Main shell navigation routes resolve to all 5 required branches', () {
      final shellBranches = [
        AppRoutes.dashboard,
        AppRoutes.orders,
        AppRoutes.billing,
        AppRoutes.products,
        AppRoutes.more,
      ];

      for (final branchPath in shellBranches) {
        final match = router.configuration.findMatch(Uri.parse(branchPath));
        expect(
          match.matches.isNotEmpty,
          isTrue,
          reason: 'Shell branch "$branchPath" failed to resolve.',
        );
      }
    });

    test('Parameterized routes resolve with valid ID paths', () {
      final customerPath = AppRoutes.customerDetailPath(42);
      expect(
        router.configuration.findMatch(Uri.parse(customerPath)).matches.isNotEmpty,
        isTrue,
      );

      final orderPath = AppRoutes.orderDetailPath(101);
      expect(
        router.configuration.findMatch(Uri.parse(orderPath)).matches.isNotEmpty,
        isTrue,
      );

      final productEditPath = AppRoutes.productEditPath(7);
      expect(
        router.configuration.findMatch(Uri.parse(productEditPath)).matches.isNotEmpty,
        isTrue,
      );
    });
  });
}
