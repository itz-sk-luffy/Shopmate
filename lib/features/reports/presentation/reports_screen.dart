import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/safe_back_button.dart';
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
  String _selectedPreset = 'This Month';
  bool _isLoading = true;
  String _itemSearchQuery = '';

  List<DayWiseSalesRow> _dayWiseRows = [];
  List<ItemWiseSalesRow> _itemRows = [];
  List<GstReportRow> _gstRows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _applyPreset('This Month', reload: false);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset, {bool reload = true}) {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = preset;
      if (preset == 'Today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'Yesterday') {
        final yest = now.subtract(const Duration(days: 1));
        _startDate = DateTime(yest.year, yest.month, yest.day);
        _endDate = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
      } else if (preset == 'This Week') {
        _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'This Month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
    });

    if (reload) {
      _loadReports();
    }
  }

  void _loadReports() async {
    setState(() => _isLoading = true);
    final repo = ref.read(reportsRepositoryProvider);
    final dayWise = await repo.getDayWiseSummary(_startDate, _endDate);
    final itemWise = await repo.getItemWiseSummary(_startDate, _endDate);
    final gst = await repo.getGstBreakdown(_startDate, _endDate);

    if (mounted) {
      setState(() {
        _dayWiseRows = dayWise;
        _itemRows = itemWise;
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
        _selectedPreset = 'Custom';
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
    } else if (_tabController.index == 1) {
      await repo.shareItemWiseCsv(_itemRows);
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
        leading: const SafeBackButton(),
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Day-wise'),
            Tab(text: 'Item Sales'),
            Tab(text: 'GST Tax'),
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
          // Date Presets & Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Today', 'Yesterday', 'This Week', 'This Month'].map((p) {
                      final isSel = _selectedPreset == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) _applyPreset(p);
                          },
                        ),
                      );
                    }).toList()
                      ..add(
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.calendar_today_rounded, size: 14),
                            label: Text(_selectedPreset == 'Custom'
                                ? '${Formatters.date(_startDate)} - ${Formatters.date(_endDate)}'
                                : 'Custom Date'),
                            onPressed: _pickCustomDateRange,
                          ),
                        ),
                      ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Day-wise Sales Table
                      _buildDayWiseTable(settings.currencySymbol, isDark, theme),
                      // 2. Item-wise Sales Table
                      _buildItemSalesTable(settings.currencySymbol, isDark, theme),
                      // 3. GST Tax Breakdown Table
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No sales found for the selected period', style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    final totalBills = _dayWiseRows.fold(0, (acc, r) => acc + r.billsCount);
    final totalSales = _dayWiseRows.fold(0.0, (acc, r) => acc + r.grandTotal);
    final totalTax = _dayWiseRows.fold(0.0, (acc, r) => acc + r.tax);
    final avgBill = totalBills > 0 ? (totalSales / totalBills) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSmallSummaryCard('Total Bills', '$totalBills', isDark),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSmallSummaryCard('Average Bill', Formatters.currency(avgBill, symbol: currency), isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallSummaryCard('Total Tax', Formatters.currency(totalTax, symbol: currency), isDark),
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
                DataColumn(label: Text('Tax', style: AppTypography.captionBold)),
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

  Widget _buildItemSalesTable(String currency, bool isDark, ThemeData theme) {
    if (_itemRows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No item sales in selected period', style: AppTypography.bodyMedium),
          ],
        ),
      );
    }

    final query = _itemSearchQuery.trim().toLowerCase();
    final filtered = _itemRows.where((r) => query.isEmpty || r.productName.toLowerCase().contains(query)).toList();

    final totalQuantity = _itemRows.fold(0.0, (acc, r) => acc + r.quantitySold);
    final totalAmount = _itemRows.fold(0.0, (acc, r) => acc + r.totalAmount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallSummaryCard('Distinct Items', '${_itemRows.length}', isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallSummaryCard(
                'Total Revenue',
                Formatters.currency(totalAmount, symbol: currency),
                isDark,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search items...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _itemSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() => _itemSearchQuery = ''),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onChanged: (val) => setState(() => _itemSearchQuery = val),
        ),
        const SizedBox(height: 12),

        // Table
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
                DataColumn(label: Text('Product', style: AppTypography.captionBold)),
                DataColumn(label: Text('Qty Sold', style: AppTypography.captionBold)),
                DataColumn(label: Text('Avg Price', style: AppTypography.captionBold)),
                DataColumn(label: Text('Total', style: AppTypography.captionBold)),
              ],
              rows: [
                ...filtered.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            r.productName,
                            style: AppTypography.captionBold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${r.quantitySold.toStringAsFixed(r.quantitySold % 1 == 0 ? 0 : 2)} ${r.unit}', style: AppTypography.caption)),
                      DataCell(Text(Formatters.currency(r.averagePrice, symbol: currency), style: AppTypography.caption)),
                      DataCell(Text(Formatters.currency(r.totalAmount, symbol: currency), style: AppTypography.priceBold.copyWith(fontSize: 12))),
                    ],
                  );
                }),
                // Total Summary Row
                DataRow(
                  color: WidgetStateProperty.all(theme.colorScheme.primary.withValues(alpha: 0.08)),
                  cells: [
                    const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('${totalQuantity.toStringAsFixed(totalQuantity % 1 == 0 ? 0 : 2)} units', style: const TextStyle(fontWeight: FontWeight.bold))),
                    const DataCell(Text('-')),
                    DataCell(Text(Formatters.currency(totalAmount, symbol: currency), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_rounded, size: 48, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No GST taxable sales in selected period', style: AppTypography.bodyMedium),
          ],
        ),
      );
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
              child: _buildSmallSummaryCard('Taxable Value', Formatters.currency(totalTaxable, symbol: currency), isDark),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSmallSummaryCard('Total CGST', Formatters.currency(totalCgst, symbol: currency), isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallSummaryCard('Total SGST', Formatters.currency(totalSgst, symbol: currency), isDark),
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
