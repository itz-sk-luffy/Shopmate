import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/database_provider.dart';
import '../data/reports_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = true;
  List<DayWiseSalesRow> _dayWiseRows = [];
  List<GstReportRow> _gstRows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1); // Start of month
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReports() async {
    setState(() => _isLoading = true);
    final repo = ref.read(reportsRepositoryProvider);
    final dayWise = await repo.getDayWiseSummary(_startDate, _endDate);
    final gst = await repo.getGstBreakdown(_startDate, _endDate);

    if (mounted) {
      setState(() {
        _dayWiseRows = dayWise;
        _gstRows = gst;
        _isLoading = false;
      });
    }
  }

  void _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _loadReports();
    }
  }

  void _exportCurrentReport() async {
    final repo = ref.read(reportsRepositoryProvider);
    if (_tabController.index == 0) {
      await repo.shareDayWiseCsv(_dayWiseRows);
    } else {
      await repo.shareGstCsv(_gstRows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Tax Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Day-wise Sales'),
            Tab(text: 'GST Tax Summary'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: _exportCurrentReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Selector Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${Formatters.date(_startDate)} - ${Formatters.date(_endDate)}',
                      style: AppTypography.captionBold,
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _pickCustomDateRange,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: const Text('Change Date'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Day-wise Sales Table
                      _buildDayWiseTable(settings.currencySymbol, isDark, theme),
                      // 2. GST Tax Breakdown Table
                      _buildGstTable(settings.currencySymbol, isDark, theme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayWiseTable(String currency, bool isDark, ThemeData theme) {
    if (_dayWiseRows.isEmpty) {
      return const Center(child: Text('No sales found for the selected date range'));
    }

    final totalBills = _dayWiseRows.fold(0, (acc, r) => acc + r.billsCount);
    final totalSales = _dayWiseRows.fold(0.0, (acc, r) => acc + r.grandTotal);
    final totalTax = _dayWiseRows.fold(0.0, (acc, r) => acc + r.tax);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSmallSummaryCard('Total Bills', '$totalBills', isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallSummaryCard(
                'Total Revenue',
                Formatters.currency(totalSales, symbol: currency),
                isDark,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        Card(
          margin: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 38,
              columns: const [
                DataColumn(label: Text('Date', style: AppTypography.captionBold)),
                DataColumn(label: Text('Bills', style: AppTypography.captionBold)),
                DataColumn(label: Text('Tax (₹)', style: AppTypography.captionBold)),
                DataColumn(label: Text('Grand Total', style: AppTypography.captionBold)),
              ],
              rows: [
                ..._dayWiseRows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(Formatters.date(row.date), style: AppTypography.caption)),
                      DataCell(Text('${row.billsCount}', style: AppTypography.caption)),
                      DataCell(Text(Formatters.currency(row.tax, symbol: currency), style: AppTypography.caption)),
                      DataCell(Text(Formatters.currency(row.grandTotal, symbol: currency), style: AppTypography.priceBold.copyWith(fontSize: 12))),
                    ],
                  );
                }),
                // Total Summary Row
                DataRow(
                  color: WidgetStateProperty.all(theme.colorScheme.primary.withValues(alpha: 0.08)),
                  cells: [
                    const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('$totalBills', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(Formatters.currency(totalTax, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(Formatters.currency(totalSales, symbol: currency), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGstTable(String currency, bool isDark, ThemeData theme) {
    if (_gstRows.isEmpty) {
      return const Center(child: Text('No GST taxable sales in selected period'));
    }

    final totalTaxable = _gstRows.fold(0.0, (acc, r) => acc + r.taxableAmount);
    final totalCgst = _gstRows.fold(0.0, (acc, r) => acc + r.cgst);
    final totalSgst = _gstRows.fold(0.0, (acc, r) => acc + r.sgst);
    final totalGst = _gstRows.fold(0.0, (acc, r) => acc + r.totalTax);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallSummaryCard('Total Taxable Value', Formatters.currency(totalTaxable, symbol: currency), isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallSummaryCard(
                'Total GST Collected',
                Formatters.currency(totalGst, symbol: currency),
                isDark,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Card(
          margin: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 14,
              headingRowHeight: 40,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 38,
              columns: const [
                DataColumn(label: Text('GST Rate', style: AppTypography.captionBold)),
                DataColumn(label: Text('Taxable Value', style: AppTypography.captionBold)),
                DataColumn(label: Text('CGST', style: AppTypography.captionBold)),
                DataColumn(label: Text('SGST', style: AppTypography.captionBold)),
                DataColumn(label: Text('Total GST', style: AppTypography.captionBold)),
              ],
              rows: [
                ..._gstRows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text('${row.gstRate.toInt()}%', style: AppTypography.captionBold)),
                      DataCell(Text(Formatters.currency(row.taxableAmount, symbol: currency), style: AppTypography.caption)),
                      DataCell(Text(Formatters.currency(row.cgst, symbol: currency), style: AppTypography.caption)),
                      DataCell(Text(Formatters.currency(row.sgst, symbol: currency), style: AppTypography.caption)),
                      DataCell(Text(Formatters.currency(row.totalTax, symbol: currency), style: AppTypography.priceBold.copyWith(fontSize: 12))),
                    ],
                  );
                }),
                DataRow(
                  color: WidgetStateProperty.all(theme.colorScheme.primary.withValues(alpha: 0.08)),
                  cells: [
                    const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(Formatters.currency(totalTaxable, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(Formatters.currency(totalCgst, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(Formatters.currency(totalSgst, symbol: currency), style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(Formatters.currency(totalGst, symbol: currency), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallSummaryCard(String title, String value, bool isDark, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.priceBold.copyWith(fontSize: 16, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
