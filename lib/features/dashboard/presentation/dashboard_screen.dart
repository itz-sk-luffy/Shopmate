import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/custom_card.dart';
import '../../orders/data/orders_repository.dart';
import '../data/dashboard_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardMetrics? _lastMetrics;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final range = ref.watch(dashboardRangeProvider);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    if (metricsAsync.hasValue) {
      _lastMetrics = metricsAsync.value;
    }
    final metrics = metricsAsync.valueOrNull ?? _lastMetrics;
    final hourlyAsync = ref.watch(hourlySalesProvider);
    final topProductsAsync = ref.watch(topProductsProvider);
    final paymentAsync = ref.watch(paymentBreakdownProvider);
    final recentBillsAsync = ref.watch(billsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(settings.storeName, style: AppTypography.heading3.copyWith(fontSize: 18)),
            Text(
              'POS & Store Analytics',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'View Reports',
            onPressed: () => context.push(AppRoutes.reports),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Printer Settings',
            onPressed: () => context.push(AppRoutes.printer),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardMetricsFamilyProvider);
          ref.invalidate(hourlySalesProvider);
          ref.invalidate(topProductsProvider);
          ref.invalidate(paymentBreakdownProvider);
          ref.invalidate(billsStreamProvider);
          await ref.read(dashboardMetricsFamilyProvider(range).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Time Range Selector Row
            Row(
              children: ['Today', 'This Week', 'This Month'].map((r) {
                final isSelected = range == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(r),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) ref.read(dashboardRangeProvider.notifier).state = r;
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Hero Sales Card & 2x2 Grid with Micro-Animations (Keeps previous data to prevent blinking)
            if (metrics != null) ...[
              CustomCard(
                backgroundColor: theme.colorScheme.primary,
                borderColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${range.toUpperCase()}'S TOTAL SALES",
                          style: AppTypography.captionBold.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                metrics.deltaPercentVsYesterday >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${metrics.deltaPercentVsYesterday >= 0 ? '+' : ''}${metrics.deltaPercentVsYesterday.toStringAsFixed(1)}%',
                                style: AppTypography.captionBold.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedCurrencyText(
                      value: metrics.totalSales,
                      symbol: settings.currencySymbol,
                      style: AppTypography.priceLarge.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeroMetric(
                          label: 'Total Bills',
                          valueWidget: AnimatedCountText(
                            value: metrics.totalBills,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        _buildHeroMetric(
                          label: 'Avg Bill',
                          valueWidget: AnimatedCurrencyText(
                            value: metrics.averageBill,
                            symbol: settings.currencySymbol,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        _buildHeroMetric(
                          label: 'GST Collected',
                          valueWidget: AnimatedCurrencyText(
                            value: metrics.gstCollected,
                            symbol: settings.currencySymbol,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Key Quick Metrics 2x2 Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _buildMetricTile(
                    icon: Icons.receipt_long_rounded,
                    iconColor: Colors.blue,
                    title: 'Bills Count',
                    valueWidget: AnimatedCountText(
                      value: metrics.totalBills,
                      style: AppTypography.priceBold.copyWith(fontSize: 16),
                    ),
                    subtitle: 'Completed sales',
                    isDark: isDark,
                  ),
                  _buildMetricTile(
                    icon: Icons.history_edu_rounded,
                    iconColor: AppColors.errorRed,
                    title: 'Udhaar (Credit)',
                    valueWidget: AnimatedCurrencyText(
                      value: metrics.todayUdhaar,
                      symbol: settings.currencySymbol,
                      style: AppTypography.priceBold.copyWith(fontSize: 16),
                    ),
                    subtitle: 'Unpaid balance',
                    isDark: isDark,
                  ),
                  _buildMetricTile(
                    icon: Icons.payments_rounded,
                    iconColor: AppColors.successGreen,
                    title: 'Cash Sales',
                    valueWidget: AnimatedCurrencyText(
                      value: metrics.cashCollected,
                      symbol: settings.currencySymbol,
                      style: AppTypography.priceBold.copyWith(fontSize: 16),
                    ),
                    subtitle: 'Collected cash',
                    isDark: isDark,
                  ),
                  _buildMetricTile(
                    icon: Icons.qr_code_rounded,
                    iconColor: Colors.purple,
                    title: 'Digital Sales',
                    valueWidget: AnimatedCurrencyText(
                      value: metrics.digitalCollected,
                      symbol: settings.currencySymbol,
                      style: AppTypography.priceBold.copyWith(fontSize: 16),
                    ),
                    subtitle: 'UPI / Card',
                    isDark: isDark,
                  ),
                ],
              ),
            ] else ...[
              // Placeholder on initial cold start to eliminate layout jumps
              const CustomCard(
                child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 140),
            ],
            const SizedBox(height: 20),

            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.billing),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                    label: const Text('New Bill'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.productAdd),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add Product'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hourly Sales Trend Line Chart (wrapped in RepaintBoundary for 60 fps)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          range == 'This Week'
                              ? 'Daily Sales Trend (This Week)'
                              : (range == 'This Month' ? 'Daily Sales Trend (This Month)' : 'Hourly Sales Trend (Today)'),
                          style: AppTypography.captionBold,
                        ),
                        Text(
                          range == 'This Week'
                              ? 'Mon - Sun'
                              : (range == 'This Month' ? 'Day 1 - ${DateTime.now().day}' : '6 AM - 11 PM'),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: hourlyAsync.when(
                          data: (points) {
                            final totalAmt = points.fold(0.0, (acc, p) => acc + p.amount);

                            if (points.isEmpty || totalAmt == 0.0) {
                              return Center(
                                key: const ValueKey('hourly_no_sales'),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.show_chart_rounded,
                                      size: 36,
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      range == 'Today'
                                          ? 'No sales recorded yet today'
                                          : 'No sales recorded for this period',
                                      style: AppTypography.captionBold.copyWith(
                                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Completed sales will plot here in real-time.',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11,
                                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final spots = points.map((p) => FlSpot(p.hour.toDouble(), p.amount)).toList();
                            final maxY = points.fold(100.0, (acc, p) => max(acc, p.amount * 1.2));
                            final intervalY = (maxY / 4).clamp(1.0, double.infinity);

                            return RepaintBoundary(
                              key: ValueKey('hourly_${points.length}_$totalAmt'),
                              child: LineChart(
                                LineChartData(
                                  minX: points.first.hour.toDouble(),
                                  maxX: points.last.hour.toDouble(),
                                  minY: 0,
                                  maxY: maxY,
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (_) => theme.colorScheme.primary,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final idx = spot.x.toInt();
                                          final match = points.where((p) => p.hour == idx);
                                          final lbl = match.isNotEmpty ? match.first.label : '$idx';
                                          return LineTooltipItem(
                                            '$lbl\n${Formatters.currency(spot.y, symbol: settings.currencySymbol)}',
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: intervalY,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEEEEEE),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 42,
                                        interval: intervalY,
                                        getTitlesWidget: (val, _) {
                                          if (val == 0) return const SizedBox.shrink();
                                          return Text(
                                            val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : '${val.toInt()}',
                                            style: AppTypography.caption.copyWith(fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: range == 'This Month' ? 5 : (range == 'This Week' ? 1 : 3),
                                        getTitlesWidget: (val, _) {
                                          final idx = val.toInt();
                                          final match = points.where((p) => p.hour == idx);
                                          final lbl = match.isNotEmpty ? match.first.label : '';
                                          if (lbl.isEmpty) return const SizedBox.shrink();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              lbl,
                                              style: AppTypography.caption.copyWith(fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: range != 'This Month',
                                      color: theme.colorScheme.primary,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        checkToShowDot: (spot, barData) => spot.y > 0,
                                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                          radius: 3.5,
                                          color: theme.colorScheme.primary,
                                          strokeWidth: 1.5,
                                          strokeColor: Colors.white,
                                        ),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => const Center(key: ValueKey('hourly_loading'), child: CircularProgressIndicator()),
                          error: (err, _) => Center(key: const ValueKey('hourly_error'), child: Text('Error: $err')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Selling Products & Payment Split Row
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Selling Products', style: AppTypography.captionBold),
                    const SizedBox(height: 12),
                    topProductsAsync.when(
                      data: (topProducts) {
                        if (topProducts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: Text('No product sales yet')),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topProducts.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final prod = topProducts[index];
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  child: Text('${index + 1}', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(prod.productName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${prod.quantity.toInt()} sold',
                                      style: AppTypography.captionBold,
                                    ),
                                    Text(
                                      Formatters.currency(prod.totalAmount, symbol: settings.currencySymbol),
                                      style: AppTypography.priceBold.copyWith(fontSize: 12, color: theme.colorScheme.primary),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Modes Pie Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Mode Split', style: AppTypography.captionBold),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: paymentAsync.when(
                          data: (breakdown) {
                            final total = breakdown.values.fold(0.0, (acc, val) => acc + val);
                            if (total <= 0) {
                              return const Center(key: ValueKey('payment_empty'), child: Text('No payment data available yet'));
                            }

                            final colors = [
                              AppColors.successGreen,
                              Colors.purple,
                              Colors.blue,
                              AppColors.errorRed,
                            ];

                            int cIndex = 0;
                            final sections = breakdown.entries.where((e) => e.value > 0).map((e) {
                              final color = colors[cIndex % colors.length];
                              cIndex++;
                              final pct = (e.value / total) * 100.0;
                              return PieChartSectionData(
                                value: e.value,
                                title: '${e.key}\n${pct.toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                color: color,
                                radius: 55,
                              );
                            }).toList();

                            return RepaintBoundary(
                              key: ValueKey('payment_${total.toStringAsFixed(2)}_${breakdown.length}'),
                              child: PieChart(
                                PieChartData(
                                  sections: sections,
                                  centerSpaceRadius: 24,
                                  sectionsSpace: 2,
                                ),
                              ),
                            );
                          },
                          loading: () => const Center(key: ValueKey('payment_loading'), child: CircularProgressIndicator()),
                          error: (err, _) => Center(key: const ValueKey('payment_error'), child: Text('Error: $err')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recent Bills Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Bills', style: AppTypography.captionBold),
                TextButton(
                  onPressed: () => context.go(AppRoutes.orders),
                  child: const Text('View All Orders'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Recent 5 Bills List
            recentBillsAsync.when(
              data: (bills) {
                final recent = bills.take(5).toList();
                if (recent.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No bills yet. Start your first sale!')),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final b = recent[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          child: Icon(Icons.receipt_outlined, color: theme.colorScheme.primary),
                        ),
                        title: Text(b.billNumber, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${b.customerName ?? 'Walk-in'} • ${Formatters.time(b.date)}',
                          style: AppTypography.caption,
                        ),
                        trailing: Text(
                          Formatters.currency(b.grandTotal, symbol: settings.currencySymbol),
                          style: AppTypography.priceBold.copyWith(fontSize: 14, color: theme.colorScheme.primary),
                        ),
                        onTap: () => context.push(AppRoutes.orderDetailPath(b.id)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMetric({required String label, required Widget valueWidget}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        valueWidget,
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget valueWidget,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: AppTypography.captionBold, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          valueWidget,
          Text(subtitle, style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class AnimatedCurrencyText extends StatelessWidget {
  final double value;
  final String symbol;
  final TextStyle style;
  final TextAlign? textAlign;

  const AnimatedCurrencyText({
    super.key,
    required this.value,
    required this.symbol,
    required this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          Formatters.currency(val, symbol: symbol),
          style: style,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class AnimatedCountText extends StatelessWidget {
  final num value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final TextAlign? textAlign;

  const AnimatedCountText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '$prefix${val.round()}$suffix',
          style: style,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
