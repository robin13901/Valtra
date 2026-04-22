import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/smart_plug_analytics_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/number_format_service.dart';
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/consumption_pie_chart.dart';
import '../widgets/charts/household_comparison_chart.dart';
import '../widgets/charts/month_selector.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/monthly_summary_card.dart';
import '../widgets/charts/year_comparison_chart.dart';

/// Inline Analyse tab content for smart plug analytics.
/// Used as a child of IndexedStack in SmartPlugsScreen.
///
/// Follows the reference composition pattern established in Phase 29:
/// MonthSelector → MonthlySummaryCard → MonthlyBarChart →
/// YearComparisonChart → HouseholdComparisonChart → per-plug pie + list.
///
/// Satisfies SPLG-01 (unified analytics design), SPLG-02 (single-hue colors),
/// SPLG-03 (per-plug pie + list), SPLG-04 (room grouping removed from Analyse tab).
class SmartPlugAnalyseTab extends StatelessWidget {
  const SmartPlugAnalyseTab({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final spProvider = context.watch<SmartPlugAnalyticsProvider>();

    if (analyticsProvider.isLoading || spProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildBody(context, analyticsProvider, spProvider);
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsProvider analyticsProvider,
    SmartPlugAnalyticsProvider spProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().localeString;
    final color = colorForMeterType(MeterType.electricity);
    final monthlyData = analyticsProvider.monthlyData;
    final yearlyData = analyticsProvider.yearlyData;

    if (monthlyData == null && (spProvider.data == null || spProvider.data!.byPlug.isEmpty)) {
      return _buildEmptyState(context, l10n);
    }

    // Compute previousMonthTotal from recentMonths
    double? previousMonthTotal;
    if (monthlyData != null) {
      final selectedMonth = analyticsProvider.selectedMonth;
      for (final period in monthlyData.recentMonths) {
        final pm = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
        if (period.periodStart.year == pm.year &&
            period.periodStart.month == pm.month) {
          previousMonthTotal = period.consumption;
          break;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Month navigation -- syncs both providers
        MonthSelector(
          selectedMonth: analyticsProvider.selectedMonth,
          onMonthChanged: (month) {
            analyticsProvider.setSelectedMonth(month);
            spProvider.setSelectedMonth(month);
            if (month.year != analyticsProvider.selectedYear) {
              analyticsProvider.setSelectedYear(month.year);
            }
          },
          locale: locale,
        ),
        const SizedBox(height: 16),

        // Monthly summary card (no smartPlugKwh/smartPlugPercent -- redundant here)
        if (monthlyData != null) ...[
          MonthlySummaryCard(
            totalConsumption: monthlyData.totalConsumption,
            previousMonthTotal: previousMonthTotal,
            unit: monthlyData.unit,
            month: analyticsProvider.selectedMonth,
            color: color,
            locale: locale,
          ),
          const SizedBox(height: 24),

          // Monthly bar chart
          Text(l10n.monthlyBreakdown,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: MonthlyBarChart(
              periods: monthlyData.recentMonths,
              primaryColor: color,
              unit: monthlyData.unit,
              highlightMonth: analyticsProvider.selectedMonth,
              locale: locale,
              showCosts: false,
            ),
          ),
          const SizedBox(height: 24),

          // Year-over-year comparison
          if (yearlyData != null &&
              yearlyData.previousYearBreakdown != null &&
              yearlyData.previousYearBreakdown!.isNotEmpty) ...[
            Text(l10n.yearOverYear,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: YearComparisonChart(
                currentYear: yearlyData.monthlyBreakdown,
                previousYear: yearlyData.previousYearBreakdown,
                primaryColor: color,
                unit: yearlyData.unit,
                locale: locale,
                showCosts: false,
              ),
            ),
            const SizedBox(height: 8),
            ChartLegend(items: [
              ChartLegendItem(color: color, label: l10n.currentYear),
              ChartLegendItem(
                color: color.withValues(alpha: 0.4),
                label: l10n.previousYear,
                dashPattern: const [2, 4],
              ),
            ]),
            const SizedBox(height: 24),
          ],

          // Household comparison (only if >1 household has data)
          if (analyticsProvider.householdComparisonData.length > 1) ...[
            Text(l10n.households,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: HouseholdComparisonChart(
                households: analyticsProvider.householdComparisonData,
                unit: monthlyData.unit,
                locale: locale,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],

        // Per-plug breakdown section
        if (spProvider.data != null && spProvider.data!.byPlug.isNotEmpty) ...[
          Text(l10n.consumptionByPlugTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ConsumptionPieChart(
              slices: _buildPlugSlices(spProvider.data!),
              unit: spProvider.data!.unit,
              locale: locale,
            ),
          ),
          const SizedBox(height: 8),
          ...spProvider.data!.byPlug
              .map((plug) => _PlugBreakdownItem(plug: plug, locale: locale)),
        ] else if (monthlyData == null) ...[
          _buildEmptyState(context, l10n),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.power_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSmartPlugData,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieSliceData> _buildPlugSlices(SmartPlugAnalyticsData data) {
    final total = data.totalSmartPlug;
    if (total == 0) return [];
    return data.byPlug
        .map((p) => PieSliceData(
              label: p.plugName,
              value: p.consumption,
              percentage: (p.consumption / total) * 100,
              color: p.color,
            ))
        .toList();
  }
}

class _PlugBreakdownItem extends StatelessWidget {
  final PlugConsumption plug;
  final String locale;

  const _PlugBreakdownItem({required this.plug, required this.locale});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: plug.color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(plug.plugName),
      subtitle: Text(plug.roomName),
      trailing: Text(
        '${ValtraNumberFormat.consumption(plug.consumption, locale)} kWh',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
