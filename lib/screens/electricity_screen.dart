import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/cost_config_provider.dart';
import '../providers/electricity_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/smart_plug_analytics_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/interpolation/models.dart';
import '../services/number_format_service.dart';
import '../widgets/charts/all_time_household_chart.dart';
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/month_selector.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/monthly_summary_card.dart';
import '../widgets/charts/year_comparison_chart.dart';
import '../widgets/charts/yearly_summary_card.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/electricity_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying electricity readings with bottom navigation
/// for switching between Analyse and Liste tabs.
class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)
  bool _showCosts = false; // kWh/EUR toggle for Analyse tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      provider.setSelectedMeterType(MeterType.electricity);
      provider.setSelectedMonth(previousMonth);
      provider.setSelectedYear(previousMonth.year);
      context.read<SmartPlugAnalyticsProvider>().setSelectedMonth(previousMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Re-sync meter type when returning from another screen via Navigator.pop
    final analyticsProvider = context.read<AnalyticsProvider>();
    if (analyticsProvider.selectedMeterType != MeterType.electricity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) analyticsProvider.ensureMeterType(MeterType.electricity);
      });
    }

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.electricity,
        actions: [
          // Visibility toggle: only on Liste tab
          if (_currentTab == 1)
            Builder(builder: (context) {
              final provider = context.watch<ElectricityProvider>();
              return IconButton(
                icon: Icon(
                  provider.showInterpolatedValues
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () => provider.toggleInterpolatedValues(),
                tooltip: provider.showInterpolatedValues
                    ? l10n.hideInterpolatedValues
                    : l10n.showInterpolatedValues,
              );
            }),
          // Cost toggle: only on Analyse tab + cost config exists
          if (_currentTab == 0) _buildCostToggle(context, l10n),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTab,
            children: [
              _buildAnalyseTab(context),
              _buildListeTab(context),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 8,
            right: 8,
            child: LiquidGlassBottomNav(
              icons: const [Icons.analytics, Icons.list],
              labels: [l10n.analysis, l10n.list],
              keys: const [
                Key('electricity_nav_analyse'),
                Key('electricity_nav_liste'),
              ],
              currentIndex: _currentTab,
              onTap: (index) => setState(() => _currentTab = index),
              rightIcon: Icons.add,
              onRightTap: () => _addReading(context),
              rightVisibleForIndices: const {1},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostToggle(BuildContext context, AppLocalizations l10n) {
    final costProvider = context.watch<CostConfigProvider>();
    final hasElectricityCostConfig =
        costProvider.getConfigsForMeterType(CostMeterType.electricity).isNotEmpty;

    if (!hasElectricityCostConfig) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(_showCosts ? Icons.euro : Icons.electric_bolt),
      onPressed: () => setState(() => _showCosts = !_showCosts),
      tooltip: _showCosts ? l10n.showConsumption : l10n.showCosts,
    );
  }

  Widget _buildListeTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ElectricityProvider>();
    final items = provider.displayItems;

    if (items.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isInterpolated) {
          return _InterpolatedReadingCard(
            item: item,
            unit: l10n.kWh,
          );
        }
        return _ReadingCard(
          item: item,
          onTap: () => _editReading(context, item.readingId!),
          onDelete: () => _deleteReading(context, item.readingId!),
        );
      },
    );
  }

  Widget _buildAnalyseTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final spProvider = context.watch<SmartPlugAnalyticsProvider>();
    final locale = context.watch<LocaleProvider>().localeString;
    final color = colorForMeterType(MeterType.electricity);
    final monthlyData = analyticsProvider.monthlyData;
    final yearlyData = analyticsProvider.yearlyData;

    if (analyticsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (monthlyData == null) {
      return Center(child: Text(l10n.noData));
    }

    // Compute smart plug coverage (SUMM-02)
    final spData = spProvider.data;
    final double? spKwh = (spData != null && spData.totalSmartPlug > 0)
        ? spData.totalSmartPlug
        : null;
    final double? spPercent = (spKwh != null &&
            monthlyData.totalConsumption != null &&
            monthlyData.totalConsumption! > 0)
        ? (spKwh / monthlyData.totalConsumption!) * 100
        : null;

    // Compute previousMonthTotal from recentMonths
    double? previousMonthTotal;
    final selectedMonth = analyticsProvider.selectedMonth;
    for (final period in monthlyData.recentMonths) {
      final pm = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
      if (period.periodStart.year == pm.year &&
          period.periodStart.month == pm.month) {
        previousMonthTotal = period.consumption;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Month navigation
        MonthSelector(
          selectedMonth: analyticsProvider.selectedMonth,
          onMonthChanged: (month) {
            analyticsProvider.setSelectedMonth(month);
            spProvider.setSelectedMonth(month);
            // Sync year if month crossed a year boundary
            if (month.year != analyticsProvider.selectedYear) {
              analyticsProvider.setSelectedYear(month.year);
            }
          },
          locale: locale,
        ),
        const SizedBox(height: 16),

        // Monthly summary card with smart plug coverage
        MonthlySummaryCard(
          totalConsumption: monthlyData.totalConsumption,
          previousMonthTotal: previousMonthTotal,
          unit: monthlyData.unit,
          month: analyticsProvider.selectedMonth,
          color: color,
          locale: locale,
          smartPlugKwh: spKwh,
          smartPlugPercent: spPercent,
        ),
        const SizedBox(height: 24),

        // Monthly bar chart (scrollable, highlighted)
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
            showCosts: _showCosts,
            periodCosts: _showCosts ? monthlyData.periodCosts : null,
            costUnit: _showCosts ? (monthlyData.currencySymbol ?? '\u20AC') : null,
          ),
        ),
        const SizedBox(height: 24),

        // Year-over-year comparison (from yearlyData)
        if (yearlyData != null &&
            (yearlyData.monthlyBreakdown.isNotEmpty ||
                (yearlyData.previousYearBreakdown != null &&
                    yearlyData.previousYearBreakdown!.isNotEmpty))) ...[
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
              showCosts: _showCosts,
              currentYearCosts: _showCosts ? yearlyData.monthlyCosts : null,
              previousYearCosts:
                  _showCosts ? yearlyData.previousYearMonthlyCosts : null,
              costUnit:
                  _showCosts ? (yearlyData.currencySymbol ?? '\u20AC') : null,
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

        // Yearly KPI card (independent of previous year data)
        if (yearlyData != null && yearlyData.totalConsumption != null) ...[
          YearlySummaryCard(
            year: yearlyData.year,
            totalConsumption: yearlyData.totalConsumption,
            totalCost: yearlyData.totalCost,
            extrapolatedTotal: yearlyData.extrapolatedTotal,
            extrapolationBasisMonths: yearlyData.extrapolationBasisMonths,
            previousYearTotal: yearlyData.previousYearTotal,
            previousYearTotalCost: yearlyData.previousYearTotalCost,
            unit: yearlyData.unit,
            currencySymbol: yearlyData.currencySymbol,
            color: color,
            locale: locale,
          ),
          const SizedBox(height: 24),
        ],

        // All-time household chart (only if >1 household)
        if (analyticsProvider.allTimeHouseholdData.isNotEmpty) ...[
          AllTimeHouseholdChart(
            households: analyticsProvider.allTimeHouseholdData,
            unit: monthlyData.unit,
            locale: locale,
            selectedMonth: analyticsProvider.selectedMonth,
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.electric_meter_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noElectricityReadings,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _addReading(BuildContext context) async {
    final provider = context.read<ElectricityProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await ElectricityReadingFormDialog.show(context);
    if (result == null) return;

    // Validate against previous reading
    final validationError = await provider.validateReading(
      result.valueKwh,
      result.timestamp,
    );

    if (validationError != null && context.mounted) {
      // Show error dialog
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content: Text(l10n.readingMustBeGreaterOrEqual(
              ValtraNumberFormat.consumption(validationError, locale))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    await provider.addReading(result.timestamp, result.valueKwh);
  }

  Future<void> _editReading(BuildContext context, int readingId) async {
    final provider = context.read<ElectricityProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final reading = provider.readings.firstWhere((r) => r.id == readingId);

    final result = await ElectricityReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null) return;

    // Validate against previous/next readings
    final validationError = await provider.validateReading(
      result.valueKwh,
      result.timestamp,
      excludeId: reading.id,
    );

    if (validationError != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content: Text(l10n.readingMustBeGreaterOrEqual(
              ValtraNumberFormat.consumption(validationError, locale))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    await provider.updateReading(reading.id, result.timestamp, result.valueKwh);
  }

  Future<void> _deleteReading(BuildContext context, int readingId) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ElectricityProvider>();

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemLabel: l10n.electricityReading,
    );

    if (confirmed) {
      await provider.deleteReading(readingId);
    }
  }
}

/// Card displaying a single electricity reading.
class _ReadingCard extends StatelessWidget {
  final ReadingDisplayItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReadingCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ValtraNumberFormat.dateTime(item.timestamp, locale),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.delete,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.electric_bolt,
                    color: AppColors.electricityColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ValtraNumberFormat.consumption(item.value, locale)} ${l10n.kWh}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (item.delta != null)
                Text(
                  l10n.consumptionSince(
                      ValtraNumberFormat.consumption(item.delta!, locale)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.electricityColor,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  l10n.firstReading,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card displaying an interpolated reading value (non-editable).
class _InterpolatedReadingCard extends StatelessWidget {
  final ReadingDisplayItem item;
  final String unit;

  const _InterpolatedReadingCard({
    required this.item,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      color: AppColors.ultraViolet.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ValtraNumberFormat.dateTime(item.timestamp, locale),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.ultraViolet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.interpolated,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.ultraViolet,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.electric_bolt,
                  color: AppColors.ultraViolet.withValues(alpha: 0.6),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${ValtraNumberFormat.consumption(item.value, locale)} $unit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (item.delta != null) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final prevMonth = DateTime(
                    item.timestamp.year, item.timestamp.month - 1, 1);
                final monthName = DateFormat.yMMMM(locale).format(prevMonth);
                return Text(
                  '+${ValtraNumberFormat.consumption(item.delta!, locale)} $unit im $monthName',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ultraViolet.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
