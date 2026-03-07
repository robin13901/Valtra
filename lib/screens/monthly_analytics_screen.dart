import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/consumption_line_chart.dart';
import '../widgets/charts/monthly_bar_chart.dart';

class MonthlyAnalyticsScreen extends StatelessWidget {
  const MonthlyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AnalyticsProvider>();
    final data = provider.monthlyData;
    final color = colorForMeterType(provider.selectedMeterType);

    return Scaffold(
      appBar: AppBar(
        title: Text(_meterTypeLabel(l10n, provider.selectedMeterType)),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _pickDateRange(context),
            tooltip: l10n.customDateRange,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? Center(child: Text(l10n.noData))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Month navigation header
                    _MonthNavigationHeader(
                      selectedMonth: provider.selectedMonth,
                      customRange: provider.customRange,
                      onPrevious: () => provider.navigateMonth(-1),
                      onNext: () => provider.navigateMonth(1),
                    ),
                    const SizedBox(height: 16),

                    // Consumption summary card
                    _ConsumptionSummaryCard(
                      totalConsumption: data.totalConsumption,
                      unit: data.unit,
                      color: color,
                    ),
                    const SizedBox(height: 24),

                    // Line chart section
                    Text(l10n.dailyTrends,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: ConsumptionLineChart(
                        dataPoints: data.dailyValues,
                        rangeStart: provider.customRange?.start ??
                            provider.selectedMonth,
                        rangeEnd: provider.customRange?.end ??
                            DateTime(provider.selectedMonth.year,
                                provider.selectedMonth.month + 1, 0),
                        primaryColor: color,
                        unit: data.unit,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ChartLegend(items: [
                      ChartLegendItem(color: color, label: l10n.actual),
                      ChartLegendItem(
                        color: color.withValues(alpha: 0.5),
                        label: l10n.interpolated,
                        isDashed: true,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Bar chart section
                    Text(l10n.monthlyComparison,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: MonthlyBarChart(
                        periods: data.recentMonths,
                        primaryColor: color,
                        unit: data.unit,
                        highlightMonth: provider.selectedMonth,
                      ),
                    ),
                  ],
                ),
    );
  }

  String _meterTypeLabel(AppLocalizations l10n, MeterType type) {
    switch (type) {
      case MeterType.electricity:
        return l10n.electricity;
      case MeterType.gas:
        return l10n.gas;
      case MeterType.water:
        return l10n.water;
      case MeterType.heating:
        return l10n.heating;
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<AnalyticsProvider>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: provider.customRange ??
          DateTimeRange(
            start: provider.selectedMonth,
            end: DateTime(provider.selectedMonth.year,
                provider.selectedMonth.month + 1, 0),
          ),
    );
    if (range != null) {
      provider.setCustomRange(range);
    }
  }
}

class _MonthNavigationHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTimeRange? customRange;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthNavigationHeader({
    required this.selectedMonth,
    required this.customRange,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          tooltip: AppLocalizations.of(context)!.previousMonth,
        ),
        Expanded(
          child: Text(
            customRange != null
                ? '${DateFormat.MMMd().format(customRange!.start)} \u2013 ${DateFormat.MMMd().format(customRange!.end)}'
                : DateFormat.yMMMM().format(selectedMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentMonth && customRange == null ? null : onNext,
          tooltip: AppLocalizations.of(context)!.nextMonth,
        ),
      ],
    );
  }
}

class _ConsumptionSummaryCard extends StatelessWidget {
  final double? totalConsumption;
  final String unit;
  final Color color;

  const _ConsumptionSummaryCard({
    required this.totalConsumption,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(l10n.totalConsumption,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              totalConsumption != null
                  ? '${totalConsumption!.toStringAsFixed(1)} $unit'
                  : '\u2014',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
