import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/cost_config_provider.dart';
import '../providers/gas_provider.dart';
import '../providers/locale_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/interpolation/models.dart';
import '../services/number_format_service.dart';
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/household_comparison_chart.dart';
import '../widgets/charts/month_selector.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/monthly_summary_card.dart';
import '../widgets/charts/year_comparison_chart.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/gas_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying gas readings with bottom navigation
/// for switching between Analyse and Liste tabs.
class GasScreen extends StatefulWidget {
  const GasScreen({super.key});

  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen> {
  int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)
  bool _showCosts = false; // m³/€ toggle for Analyse tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.setSelectedMeterType(MeterType.gas);
      provider.setSelectedMonth(DateTime.now()); // triggers _loadMonthlyData
      provider.setSelectedYear(DateTime.now().year); // triggers _loadYearlyData + household comparison
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.gas,
        actions: [
          // Visibility toggle: only on Liste tab
          if (_currentTab == 1)
            Builder(builder: (context) {
              final provider = context.watch<GasProvider>();
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
            bottom: 0,
            left: 0,
            right: 0,
            child: LiquidGlassBottomNav(
              icons: const [Icons.analytics, Icons.list],
              labels: [l10n.analysis, l10n.list],
              keys: const [
                Key('gas_nav_analyse'),
                Key('gas_nav_liste'),
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
    final hasGasCostConfig =
        costProvider.getConfigsForMeterType(CostMeterType.gas).isNotEmpty;

    if (!hasGasCostConfig) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(_showCosts ? Icons.euro : Icons.local_fire_department),
      onPressed: () => setState(() => _showCosts = !_showCosts),
      tooltip: _showCosts ? l10n.showConsumption : l10n.showCosts,
    );
  }

  Widget _buildListeTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<GasProvider>();
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
            unit: l10n.cubicMeters,
            icon: Icons.local_fire_department,
          );
        }
        return _GasReadingCard(
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
    final locale = context.watch<LocaleProvider>().localeString;
    final color = colorForMeterType(MeterType.gas);
    final monthlyData = analyticsProvider.monthlyData;
    final yearlyData = analyticsProvider.yearlyData;

    if (analyticsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (monthlyData == null) {
      return Center(child: Text(l10n.noData));
    }

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
            // Sync year if month crossed a year boundary
            if (month.year != analyticsProvider.selectedYear) {
              analyticsProvider.setSelectedYear(month.year);
            }
          },
          locale: locale,
        ),
        const SizedBox(height: 16),

        // Monthly summary card
        MonthlySummaryCard(
          totalConsumption: monthlyData.totalConsumption,
          previousMonthTotal: previousMonthTotal,
          unit: monthlyData.unit,
          month: analyticsProvider.selectedMonth,
          color: color,
          locale: locale,
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
              color: color.withValues(alpha: 0.5),
              label: l10n.previousYear,
              isDashed: true,
            ),
          ]),
          const SizedBox(height: 24),
        ],

        // Household comparison (only if >1 household has data)
        if (analyticsProvider.householdComparisonData.length > 1) ...[
          Text(l10n.households, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: HouseholdComparisonChart(
              households: analyticsProvider.householdComparisonData,
              unit: monthlyData.unit,
              locale: locale,
            ),
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
            Icons.local_fire_department_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noGasReadings,
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
    final provider = context.read<GasProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await GasReadingFormDialog.show(context);
    if (result == null) return;

    final validationError = await provider.validateReading(
      result.valueCubicMeters,
      result.timestamp,
    );

    if (validationError != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content: Text(l10n.gasReadingMustBeGreaterOrEqual(
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

    await provider.addReading(result.timestamp, result.valueCubicMeters);
  }

  Future<void> _editReading(BuildContext context, int readingId) async {
    final provider = context.read<GasProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final reading = provider.readings.firstWhere((r) => r.id == readingId);

    final result = await GasReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null) return;

    final validationError = await provider.validateReading(
      result.valueCubicMeters,
      result.timestamp,
      excludeId: reading.id,
    );

    if (validationError != null && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.readingMustBePositive),
          content: Text(l10n.gasReadingMustBeGreaterOrEqual(
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

    await provider.updateReading(
        reading.id, result.timestamp, result.valueCubicMeters);
  }

  Future<void> _deleteReading(BuildContext context, int readingId) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<GasProvider>();

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemLabel: l10n.gasReading,
    );

    if (confirmed) {
      await provider.deleteReading(readingId);
    }
  }
}

/// Card displaying a single gas reading.
class _GasReadingCard extends StatelessWidget {
  final ReadingDisplayItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GasReadingCard({
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
                    Icons.local_fire_department,
                    color: AppColors.gasColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ValtraNumberFormat.consumption(item.value, locale)} ${l10n.cubicMeters}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (item.delta != null)
                Text(
                  l10n.gasConsumptionSince(
                      ValtraNumberFormat.consumption(item.delta!, locale)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.gasColor,
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
  final IconData icon;

  const _InterpolatedReadingCard({
    required this.item,
    required this.unit,
    required this.icon,
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
                  icon,
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
          ],
        ),
      ),
    );
  }
}
