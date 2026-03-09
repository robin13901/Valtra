import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/locale_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/number_format_service.dart';
import '../widgets/liquid_glass_widgets.dart';
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/year_comparison_chart.dart';

class YearlyAnalyticsScreen extends StatefulWidget {
  final MeterType meterType;

  const YearlyAnalyticsScreen({super.key, required this.meterType});

  @override
  State<YearlyAnalyticsScreen> createState() => _YearlyAnalyticsScreenState();
}

class _YearlyAnalyticsScreenState extends State<YearlyAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.setSelectedMeterType(widget.meterType);
      provider.setSelectedYear(DateTime.now().year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AnalyticsProvider>();
    final data = provider.yearlyData;
    final color = colorForMeterType(widget.meterType);

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: '${_meterTypeLabel(l10n, widget.meterType)} - ${l10n.yearlyAnalytics}',
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? Center(child: Text(l10n.noData))
              : _buildContent(context, data, color, l10n, provider),
    );
  }

  Widget _buildContent(
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
      padding: const EdgeInsets.all(16),
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
}

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
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      child: Column(
        children: [
          Text(l10n.totalForYear(year.toString()),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            totalConsumption != null
                ? '${ValtraNumberFormat.consumption(totalConsumption!, locale)} $unit'
                : '\u2014',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (extrapolatedTotal != null) ...[
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
          if (totalConsumption != null &&
              previousYearTotal != null &&
              previousYearTotal! > 0) ...[
            const SizedBox(height: 8),
            _buildChangeText(context, l10n),
          ],
          if (totalCost != null) ...[
            const SizedBox(height: 8),
            Text(
              '~${currencySymbol ?? '\u20AC'}${ValtraNumberFormat.currency(totalCost!, locale)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeText(BuildContext context, AppLocalizations l10n) {
    final change =
        ((totalConsumption! - previousYearTotal!) / previousYearTotal!) * 100;
    final prefix = change >= 0 ? '+' : '';
    final changeText = '$prefix${ValtraNumberFormat.consumption(change, locale)}';

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
