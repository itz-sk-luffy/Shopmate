import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_routes.dart';

/// A robust back button that cleanly pops the current screen if navigation
/// history exists, or safely routes to [fallbackRoute] (defaulting to the POS
/// Billing screen) if the navigation stack has no previous entries.
class SafeBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;
  final String fallbackRoute;

  const SafeBackButton({
    super.key,
    this.color,
    this.onPressed,
    this.fallbackRoute = AppRoutes.billing,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackRoute);
        }
      },
    );
  }
}

