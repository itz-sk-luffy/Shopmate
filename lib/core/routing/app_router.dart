import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/database_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_routes.dart';

import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/pos/presentation/billing_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/more/presentation/more_screen.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/lock_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/category_settings_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/customers/presentation/customer_detail_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/day_closing/presentation/day_closing_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/printer/presentation/printer_screen.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/backup/presentation/backup_log_screen.dart';
import '../../features/recycle_bin/presentation/recycle_bin_screen.dart';
import '../../features/products/presentation/product_edit_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../main.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Observer that clears all SnackBars when any route is pushed so they
/// never bleed through to unrelated screens (e.g. "Product deleted"
/// appearing on Merge / Printer / Barcode screens).
class _SnackBarClearingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _clearSnackBars();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _clearSnackBars();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _clearSnackBars();
  }

  void _clearSnackBars() {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
  }
}

/// Helper to create GoRouter configuration (useful for app and unit tests)
GoRouter createRouter({
  bool hasCompletedOnboarding = true,
  bool isAppLockEnabled = false,
  bool isUnlocked = true,
  bool isLoading = false,
}) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.billing,
    observers: [_SnackBarClearingObserver()],
    redirect: (BuildContext context, GoRouterState state) {
      if (isLoading) return null;

      final path = state.matchedLocation;

      // Onboarding check
      if (!hasCompletedOnboarding) {
        if (path != AppRoutes.onboarding) {
          return AppRoutes.onboarding;
        }
        return null;
      }

      // App lock check
      if (isAppLockEnabled && !isUnlocked) {
        if (path != AppRoutes.lock) {
          return AppRoutes.lock;
        }
        return null;
      }

      // If unlocked or onboarding complete and user was at /lock or /onboarding, go to billing
      if (hasCompletedOnboarding && path == AppRoutes.onboarding) {
        return AppRoutes.billing;
      }
      if ((!isAppLockEnabled || isUnlocked) && path == AppRoutes.lock) {
        return AppRoutes.billing;
      }

      return null;
    },
    errorBuilder: (context, state) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppColors.errorRed,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Page Not Found', style: AppTypography.title),
                  const SizedBox(height: 8),
                  Text(
                    state.error?.message ??
                        'The page you are looking for does not exist or has been moved.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    icon: const Icon(Icons.dashboard_rounded),
                    label: const Text('Go to Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    routes: [
      // Root redirect to billing
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, __) => AppRoutes.billing,
      ),

      // Stateful shell for main bottom navigation branches:
      // Index 0: Dashboard
      // Index 1: Orders
      // Index 2: Billing
      // Index 3: Products
      // Index 4: More
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),

          // Branch 2: Billing
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.billing,
                builder: (context, state) => const BillingScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const BillingScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Products
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (context, state) => const ProductsScreen(),
              ),
            ],
          ),

          // Branch 4: More
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // Other top-level application routes
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.lock,
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: AppRoutes.lockSettings,
        builder: (context, state) => const LockSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategorySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.expenses,
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.dayClosing,
        builder: (context, state) => const DayClosingScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.printer,
        builder: (context, state) => const PrinterScreen(),
      ),
      GoRoute(
        path: AppRoutes.backup,
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: AppRoutes.backupLog,
        builder: (context, state) => const BackupLogScreen(),
      ),
      GoRoute(
        path: AppRoutes.recycleBin,
        builder: (context, state) => const RecycleBinScreen(),
      ),
      GoRoute(
        path: AppRoutes.productAdd,
        builder: (context, state) {
          final imagePath = state.extra as String?;
          return ProductEditScreen(initialImagePath: imagePath);
        },
      ),
      GoRoute(
        path: AppRoutes.productEdit,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ProductEditScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return OrderDetailScreen(billId: id);
        },
      ),
    ],
  );

  router.routerDelegate.addListener(() {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();
  });

  return router;
}

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsProvider);
  final isUnlocked = ref.watch(isUnlockedProvider);

  return createRouter(
    hasCompletedOnboarding: settings.hasCompletedOnboarding,
    isAppLockEnabled: settings.isAppLockEnabled,
    isUnlocked: isUnlocked,
    isLoading: settings.isLoading,
  );
});
