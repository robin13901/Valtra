import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/cost_config_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/water_provider.dart';
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
import '../widgets/dialogs/water_meter_form_dialog.dart';
import '../widgets/dialogs/water_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying water meters with bottom navigation
/// for switching between Analyse and Liste tabs.
class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)
  bool _showCosts = false; // m³/€ toggle for Analyse tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      provider.setSelectedMeterType(MeterType.water);
      provider.setSelectedMonth(previousMonth);
      provider.setSelectedYear(previousMonth.year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.waterMeters,
        actions: [
          // Visibility toggle: only on Liste tab
          if (_currentTab == 1)
            Builder(builder: (context) {
              final provider = context.watch<WaterProvider>();
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
                Key('water_nav_analyse'),
                Key('water_nav_liste'),
              ],
              currentIndex: _currentTab,
              onTap: (index) => setState(() => _currentTab = index),
              rightIcon: Icons.add,
              onRightTap: () => _addMeter(context),
              rightVisibleForIndices: const {1},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostToggle(BuildContext context, AppLocalizations l10n) {
    final costProvider = context.watch<CostConfigProvider>();
    final hasWaterCostConfig =
        costProvider.getConfigsForMeterType(CostMeterType.water).isNotEmpty;

    if (!hasWaterCostConfig) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(_showCosts ? Icons.euro : Icons.water_drop),
      onPressed: () => setState(() => _showCosts = !_showCosts),
      tooltip: _showCosts ? l10n.showConsumption : l10n.showCosts,
    );
  }

  Widget _buildListeTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<WaterProvider>();
    final meters = provider.meters;

    if (meters.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return _WaterMetersList(meters: meters);
  }

  Widget _buildAnalyseTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final locale = context.watch<LocaleProvider>().localeString;
    final color = colorForMeterType(MeterType.water);
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
            Icons.water_drop,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noWaterMeters,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMeter(BuildContext context) async {
    final provider = context.read<WaterProvider>();

    final result = await WaterMeterFormDialog.show(context);
    if (result == null || !context.mounted) return;

    await provider.addMeter(result.name, result.type);
  }
}

class _WaterMetersList extends StatelessWidget {
  final List<WaterMeter> meters;

  const _WaterMetersList({required this.meters});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: meters.length,
      itemBuilder: (context, index) {
        return _WaterMeterCard(meter: meters[index]);
      },
    );
  }
}

class _WaterMeterCard extends StatefulWidget {
  final WaterMeter meter;

  const _WaterMeterCard({required this.meter});

  @override
  State<_WaterMeterCard> createState() => _WaterMeterCardState();
}

class _WaterMeterCardState extends State<_WaterMeterCard> {
  bool _isExpanded = false;

  String _getTypeName(AppLocalizations l10n, WaterMeterType type) {
    switch (type) {
      case WaterMeterType.cold:
        return l10n.coldWater;
      case WaterMeterType.hot:
        return l10n.hotWater;
      case WaterMeterType.other:
        return l10n.otherWater;
    }
  }

  Color _getTypeColor(WaterMeterType type) {
    switch (type) {
      case WaterMeterType.cold:
        return Colors.blue;
      case WaterMeterType.hot:
        return Colors.red;
      case WaterMeterType.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(WaterMeterType type) {
    switch (type) {
      case WaterMeterType.cold:
        return Icons.water_drop;
      case WaterMeterType.hot:
        return Icons.water_drop;
      case WaterMeterType.other:
        return Icons.water_drop;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = context.watch<WaterProvider>();
    final readings = provider.getReadingsWithDeltas(widget.meter.id);
    final displayItems = provider.getDisplayItems(widget.meter.id);
    final locale = context.watch<LocaleProvider>().localeString;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Meter header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(widget.meter.type),
                    color: _getTypeColor(widget.meter.type),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.meter.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(widget.meter.type)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getTypeName(l10n, widget.meter.type),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getTypeColor(widget.meter.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (readings.isNotEmpty)
                              Text(
                                '${ValtraNumberFormat.waterReading(readings.first.reading.valueCubicMeters, locale)} m\u00B3',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editMeter(context);
                      } else if (value == 'delete') {
                        _deleteMeter(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
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
            ),
          ),
          // Expanded readings section
          if (_isExpanded) ...[
            const Divider(height: 1),
            provider.showInterpolatedValues
                ? _buildDisplayItemsSection(context, l10n, displayItems)
                : _buildReadingsSection(context, l10n, readings),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<WaterReadingWithDelta> readings,
  ) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    return Column(
      children: [
        // Add reading button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                l10n.waterReadings,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addReading(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addWaterReading),
              ),
            ],
          ),
        ),
        if (readings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.noWaterReadings,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final readingWithDelta = readings[index];
              final reading = readingWithDelta.reading;
              final delta = readingWithDelta.deltaCubicMeters;

              return ListTile(
                leading: Icon(
                  Icons.water_drop,
                  color: _getTypeColor(widget.meter.type),
                ),
                title: Text(
                  '${ValtraNumberFormat.waterReading(reading.valueCubicMeters, locale)} m\u00B3',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ValtraNumberFormat.dateTime(reading.timestamp, locale),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (delta != null)
                      Text(
                        l10n.waterConsumptionSince(ValtraNumberFormat.waterReading(delta, locale)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.waterColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        l10n.firstReading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editReading(context, reading);
                    } else if (value == 'delete') {
                      _deleteReading(context, reading);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
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
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDisplayItemsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<ReadingDisplayItem> items,
  ) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                l10n.waterReadings,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addReading(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addWaterReading),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.noWaterReadings,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              if (item.isInterpolated) {
                return ListTile(
                  tileColor: AppColors.ultraViolet.withValues(alpha: 0.08),
                  leading: Icon(
                    Icons.water_drop,
                    color: AppColors.ultraViolet.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    '${ValtraNumberFormat.waterReading(item.value, locale)} m\u00B3',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ValtraNumberFormat.dateTime(item.timestamp, locale),
                        style: theme.textTheme.bodySmall,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.ultraViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.interpolated,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ultraViolet,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (item.delta != null)
                        Builder(builder: (context) {
                          final prevMonth = DateTime(
                              item.timestamp.year, item.timestamp.month - 1, 1);
                          final monthName = DateFormat.yMMMM(locale).format(prevMonth);
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '+${ValtraNumberFormat.waterReading(item.delta!, locale)} m³ im $monthName',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.ultraViolet.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              }

              return ListTile(
                leading: Icon(
                  Icons.water_drop,
                  color: _getTypeColor(widget.meter.type),
                ),
                title: Text(
                  '${ValtraNumberFormat.waterReading(item.value, locale)} m\u00B3',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ValtraNumberFormat.dateTime(item.timestamp, locale),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.delta != null)
                      Text(
                        l10n.waterConsumptionSince(ValtraNumberFormat.waterReading(item.delta!, locale)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.waterColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        l10n.firstReading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editReadingById(context, item.readingId!);
                    } else if (value == 'delete') {
                      _deleteReadingById(context, item.readingId!);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
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
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _editMeter(BuildContext context) async {
    final provider = context.read<WaterProvider>();

    final result = await WaterMeterFormDialog.show(
      context,
      meter: widget.meter,
    );
    if (result == null || !context.mounted) return;

    await provider.updateMeter(widget.meter.id, result.name, result.type);
  }

  Future<void> _deleteMeter(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<WaterProvider>();

    // Get reading count for warning message
    final readingCount = await provider.getReadingCountForMeter(widget.meter.id);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteWaterMeter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteWaterMeterConfirm),
            if (readingCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.waterMeterHasReadings(readingCount),
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteMeter(widget.meter.id);
    }
  }

  Future<void> _addReading(BuildContext context) async {
    final provider = context.read<WaterProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await WaterReadingFormDialog.show(context);
    if (result == null || !context.mounted) return;

    // Validate against previous reading
    final error = await provider.validateReading(
      widget.meter.id,
      result.valueCubicMeters,
      result.timestamp,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.waterReadingMustBeGreaterOrEqual(
              ValtraNumberFormat.waterReading(error, locale))),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.addReading(
      widget.meter.id,
      result.timestamp,
      result.valueCubicMeters,
    );
  }

  Future<void> _editReading(BuildContext context, WaterReading reading) async {
    final provider = context.read<WaterProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await WaterReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null || !context.mounted) return;

    // Validate against surrounding readings
    final error = await provider.validateReading(
      widget.meter.id,
      result.valueCubicMeters,
      result.timestamp,
      excludeId: reading.id,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.waterReadingMustBeGreaterOrEqual(
              ValtraNumberFormat.waterReading(error, locale))),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.updateReading(
      reading.id,
      result.timestamp,
      result.valueCubicMeters,
    );
  }

  Future<void> _deleteReading(BuildContext context, WaterReading reading) async {
    await _deleteReadingById(context, reading.id);
  }

  Future<void> _editReadingById(BuildContext context, int readingId) async {
    final provider = context.read<WaterProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final readings = provider.getReadingsWithDeltas(widget.meter.id);
    final readingWithDelta = readings.firstWhere((r) => r.reading.id == readingId);
    final reading = readingWithDelta.reading;

    final result = await WaterReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null || !context.mounted) return;

    final error = await provider.validateReading(
      widget.meter.id,
      result.valueCubicMeters,
      result.timestamp,
      excludeId: reading.id,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.waterReadingMustBeGreaterOrEqual(
              ValtraNumberFormat.waterReading(error, locale))),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.updateReading(
      reading.id,
      result.timestamp,
      result.valueCubicMeters,
    );
  }

  Future<void> _deleteReadingById(BuildContext context, int readingId) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<WaterProvider>();

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemLabel: l10n.waterReading,
    );

    if (confirmed && context.mounted) {
      await provider.deleteReading(readingId);
    }
  }
}
