import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/custom_card.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Management & More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Store Info Mini Card
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/launcher_icons/launcher_${settings.launcherIconPreset}.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/icons/app_icon.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(settings.storeName, style: AppTypography.section),
                      const SizedBox(height: 2),
                      Text(
                        'Role: OWNER',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.settings),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(60, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Operations Section
          _buildSectionHeader('FINANCIAL & OPERATIONS'),
          const SizedBox(height: 8),
          _buildMenuItem(
            context,
            icon: Icons.people_alt_outlined,
            title: 'Customers & Udhaar Ledger',
            subtitle: 'Credit balance, WhatsApp reminders',
            color: AppColors.infoBlue,
            onTap: () => context.push(AppRoutes.customers),
          ),
          _buildMenuItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Expenses Tracker',
            subtitle: 'Daily operational expenses & payouts',
            color: Colors.deepOrange,
            onTap: () => context.push(AppRoutes.expenses),
          ),
          _buildMenuItem(
            context,
            icon: Icons.lock_clock_outlined,
            title: 'Day-End Closing',
            subtitle: 'Opening cash, daily tally, summary print',
            color: AppColors.accentAmber,
            onTap: () => context.push(AppRoutes.dayClosing),
          ),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart_rounded,
            title: 'Reports & Analytics',
            subtitle: 'Day-wise, GST summary, item sales CSV/PDF',
            color: Colors.indigo,
            onTap: () => context.push(AppRoutes.reports),
          ),
          const SizedBox(height: 20),

          // Hardware & Tools
          _buildSectionHeader('HARDWARE & SYSTEM'),
          const SizedBox(height: 8),
          _buildMenuItem(
            context,
            icon: Icons.print_outlined,
            title: '58 mm Thermal Printer',
            subtitle: 'Bluetooth pairing, test print, alignment',
            color: Colors.purple,
            onTap: () => context.push(AppRoutes.printer),
          ),
          _buildMenuItem(
            context,
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            subtitle: 'Single .zip export, auto-backup, restore',
            color: Colors.teal,
            onTap: () => context.push(AppRoutes.backup),
          ),
          _buildMenuItem(
            context,
            icon: Icons.delete_outline_rounded,
            title: 'Recycle Bin',
            subtitle: '30-day recovery for deleted items and bills',
            color: Colors.blueGrey,
            onTap: () => context.push(AppRoutes.recycleBin),
          ),
          const SizedBox(height: 20),

          // App Settings & Preferences
          _buildSectionHeader('CONFIGURATION'),
          const SizedBox(height: 8),
          _buildMenuItem(
            context,
            icon: Icons.tune_rounded,
            title: 'Store Settings & Tax',
            subtitle: 'Profile, GST rate, bills prefix, formatting',
            color: AppColors.primaryTeal,
            onTap: () => context.push(AppRoutes.settings),
          ),
          _buildMenuItem(
            context,
            icon: Icons.security_rounded,
            title: 'App Lock & Security',
            subtitle: 'PIN code and biometric security',
            color: Colors.green,
            onTap: () => context.push(AppRoutes.lockSettings),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Shopmate v1.0.0 (Offline-first POS)',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.captionBold.copyWith(
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.section.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
