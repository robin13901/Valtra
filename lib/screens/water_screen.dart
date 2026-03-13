import 'package:flutter/material.dart';
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
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/year_comparison_chart.dart';
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
      context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.water);
      context.read<AnalyticsProvider>().setSelectedYear(DateTime.now().year);
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
            bottom: 0,
            left: 0,
            right: 0,
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
              onLeftTap: null,
              leftVisibleForIndices: const {},
              keepLeftPlaceholder: false,
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
    final data = analyticsProvider.yearlyData;
    final color = colorForMeterType(MeterType.water);

    if (analyticsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null) {
      return Center(child: Text(l10n.noData));
    }

    return _buildAnalyseContent(context, data, color, l10n, analyticsProvider);
  }

  Widget _buildAnalyseContent(
    BuildContext context,
    YearlyAnalyticsData data,
    Color color,
    AppLocalizations l10n,
    AnalyticsProvider provider,
  ) {
    final locale = context.watch<LocaleProvider>().localeString;

    if (data.monthlyBreakdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _YearNavigationHeader(
              year: provider.selectedYear,
              onPrevious: () => provider.navigateYear(-1),
              onNext: () => provider.navigateYear(1),
            ),
            const SizedBox(height: 32),
            Text(l10n.noYearlyData(provider.selectedYear.toString())),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Year navigation header
        _YearNavigationHeader(
          year: provider.selectedYear,
          onPrevious: () => provider.navigateYear(-1),
          onNext: () => provider.navigateYear(1),
        ),
        const SizedBox(height: 16),

        // Summary card
        _YearlySummaryCard(
          totalConsumption: data.totalConsumption,
          previousYearTotal: data.previousYearTotal,
          unit: data.unit,
          year: data.year,
          color: color,
          totalCost: data.totalCost,
          previousYearTotalCost: data.previousYearTotalCost,
          currencySymbol: data.currencySymbol,
          locale: locale,
          extrapolatedTotal: data.extrapolatedTotal,
          extrapolationBasisMonths: data.extrapolationBasisMonths,
          showCosts: _showCosts,
        ),
        const SizedBox(height: 24),

        // Bar chart section: monthly breakdown
        Text(l10n.monthlyBreakdown,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: MonthlyBarChart(
            periods: data.monthlyBreakdown,
            primaryColor: color,
            unit: data.unit,
            locale: locale,
            showCosts: _showCosts,
            periodCosts: _showCosts ? data.monthlyCosts : null,
            costUnit: _showCosts ? (data.currencySymbol ?? '\u20AC') : null,
          ),
        ),
        const SizedBox(height: 24),

        // Year-over-year comparison (only if previous year data exists)
        if (data.previousYearBreakdown != null &&
            data.previousYearBreakdown!.isNotEmpty) ...[
          Text(l10n.yearOverYear,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: YearComparisonChart(
              currentYear: data.monthlyBreakdown,
              previousYear: data.previousYearBreakdown,
              primaryColor: color,
              unit: data.unit,
              locale: locale,
              showCosts: _showCosts,
              currentYearCosts: _showCosts ? data.monthlyCosts : null,
              previousYearCosts:
                  _showCosts ? data.previousYearMonthlyCosts : null,
              costUnit:
                  _showCosts ? (data.currencySymbol ?? '\u20AC') : null,
            ),
          ),
          const SizedBox(height: 8),
          ChartLegend(items: [
            ChartLegendItem(
              color: color,
              label: l10n.currentYear,
            ),
            ChartLegendItem(
              color: color.withValues(alpha: 0.5),
              label: l10n.previousYear,
              isDashed: true,
            ),
          ]),
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

/// Year navigation header for the Analyse tab.
class _YearNavigationHeader extends StatelessWidget {
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _YearNavigationHeader({
    required this.year,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentYear = year == now.year;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          tooltip: l10n.previousYear,
        ),
        Expanded(
          child: Text(
            year.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentYear ? null : onNext,
          tooltip: l10n.nextYear,
        ),
      ],
    );
  }
}

/// Summary card for yearly analytics on the Analyse tab.
class _YearlySummaryCard extends StatelessWidget {
  final double? totalConsumption;
  final double? previousYearTotal;
  final String unit;
  final int year;
  final Color color;
  final double? totalCost;
  final double? previousYearTotalCost;
  final String? currencySymbol;
  final String locale;
  final double? extrapolatedTotal;
  final int? extrapolationBasisMonths;
  final bool showCosts;

  const _YearlySummaryCard({
    required this.totalConsumption,
    required this.previousYearTotal,
    required this.unit,
    required this.year,
    required this.color,
    this.totalCost,
    this.previousYearTotalCost,
    this.currencySymbol,
    required this.locale,
    this.extrapolatedTotal,
    this.extrapolationBasisMonths,
    this.showCosts = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = currencySymbol ?? '\u20AC';

    // Determine primary display value and unit based on cost toggle
    final double? displayValue = showCosts ? totalCost : totalConsumption;
    final String displayUnit = showCosts ? symbol : unit;
    final double? previousValue =
        showCosts ? previousYearTotalCost : previousYearTotal;

    return GlassCard(
      child: Column(
        children: [
          Text(l10n.totalForYear(year.toString()),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            displayValue != null
                ? showCosts
                    ? '${ValtraNumberFormat.currency(displayValue, locale)} $displayUnit'
                    : '${ValtraNumberFormat.consumption(displayValue, locale)} $displayUnit'
                : '\u2014',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!showCosts && extrapolatedTotal != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.projectedTotal(
                '~${ValtraNumberFormat.consumption(extrapolatedTotal!, locale)} $unit',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            if (extrapolationBasisMonths != null)
              Text(
                l10n.basedOnMonths(extrapolationBasisMonths!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
          if (displayValue != null &&
              previousValue != null &&
              previousValue > 0) ...[
            const SizedBox(height: 8),
            _buildChangeText(context, l10n, displayValue, previousValue),
          ],
          // Show cost as secondary info only when NOT in cost mode
          if (!showCosts && totalCost != null) ...[
            const SizedBox(height: 8),
            Text(
              '~$symbol${ValtraNumberFormat.currency(totalCost!, locale)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeText(BuildContext context, AppLocalizations l10n,
      double currentValue, double previousValue) {
    final change = ((currentValue - previousValue) / previousValue) * 100;
    final prefix = change >= 0 ? '+' : '';
    final changeText =
        '$prefix${ValtraNumberFormat.consumption(change, locale)}';

    return Text(
      l10n.changeFromLastYear(changeText),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: change > 0
                ? Theme.of(context).colorScheme.error
                : AppColors.successColor,
          ),
    );
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
