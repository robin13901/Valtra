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
import '../widgets/charts/month_selector.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/monthly_summary_card.dart';
import '../widgets/charts/year_comparison_chart.dart';

/// Inline Analyse tab content for smart plug analytics.
/// Used as a child of IndexedStack in SmartPlugsScreen.
///
/// Follows the reference composition pattern established in Phase 29:
/// MonthSelector -> MonthlySummaryCard -> MonthlyBarChart ->
/// YearComparisonChart -> HouseholdComparisonChart -> per-plug/room pie + list.
class SmartPlugAnalyseTab extends StatefulWidget {
  const SmartPlugAnalyseTab({super.key});

  @override
  State<SmartPlugAnalyseTab> createState() => _SmartPlugAnalyseTabState();
}

class _SmartPlugAnalyseTabState extends State<SmartPlugAnalyseTab> {
  bool _showByRoom = false;

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

        ],

        // Per-plug/room breakdown section with toggle
        if (spProvider.data != null && spProvider.data!.byPlug.isNotEmpty) ...[
          // Toggle + title row
          Row(
            children: [
              Expanded(
                child: Text(
                  _showByRoom ? l10n.consumptionByRoomTitle : l10n.consumptionByPlugTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.byPlug),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.byRoom),
                  ),
                ],
                selected: {_showByRoom},
                onSelectionChanged: (selection) {
                  setState(() => _showByRoom = selection.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ConsumptionPieChart(
              slices: _showByRoom
                  ? _buildRoomSlices(spProvider.data!)
                  : _buildPlugSlices(spProvider.data!),
              unit: spProvider.data!.unit,
              locale: locale,
            ),
          ),
          const SizedBox(height: 8),
          if (_showByRoom)
            ..._buildRoomBreakdownItems(spProvider.data!, locale)
          else
            ..._buildPlugBreakdownItems(spProvider.data!, locale),
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
    final sorted = data.byPlug.toList()
      ..sort((a, b) => b.consumption.compareTo(a.consumption));
    return sorted
        .map((p) => PieSliceData(
              label: p.plugName,
              value: p.consumption,
              percentage: (p.consumption / total) * 100,
              color: p.color,
            ))
        .toList();
  }

  List<PieSliceData> _buildRoomSlices(SmartPlugAnalyticsData data) {
    final total = data.totalSmartPlug;
    if (total == 0) return [];
    final sorted = data.byRoom.where((r) => r.consumption > 0).toList()
      ..sort((a, b) => b.consumption.compareTo(a.consumption));
    int i = 0;
    return sorted
        .map((r) => PieSliceData(
              label: r.roomName,
              value: r.consumption,
              percentage: (r.consumption / total) * 100,
              color: pieChartColors[i++ % pieChartColors.length],
            ))
        .toList();
  }

  List<Widget> _buildPlugBreakdownItems(SmartPlugAnalyticsData data, String locale) {
    final sorted = data.byPlug.toList()
      ..sort((a, b) => b.consumption.compareTo(a.consumption));
    return sorted
        .map((plug) => _PlugBreakdownItem(plug: plug, locale: locale))
        .toList();
  }

  List<Widget> _buildRoomBreakdownItems(SmartPlugAnalyticsData data, String locale) {
    final sorted = data.byRoom.where((r) => r.consumption > 0).toList()
      ..sort((a, b) => b.consumption.compareTo(a.consumption));
    int i = 0;
    return sorted.map((room) {
      final color = pieChartColors[i++ % pieChartColors.length];
      return _RoomBreakdownItem(room: room, color: color, locale: locale);
    }).toList();
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

class _RoomBreakdownItem extends StatelessWidget {
  final RoomConsumption room;
  final Color color;
  final String locale;

  const _RoomBreakdownItem({
    required this.room,
    required this.color,
    required this.locale,
  });

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
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(room.roomName),
      trailing: Text(
        '${ValtraNumberFormat.consumption(room.consumption, locale)} kWh',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
