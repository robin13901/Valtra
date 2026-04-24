import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/interpolation/models.dart';
import '../../services/number_format_service.dart';
import 'chart_axis_style.dart';

class MonthlyBarChart extends StatefulWidget {
  final List<PeriodConsumption> periods;
  final Color primaryColor;
  final String unit;
  final DateTime? highlightMonth;
  final String locale;

  /// Optional cost data for kWh/EUR toggle support (parallel to periods).
  final List<double?>? periodCosts;

  /// When true, chart displays cost values instead of consumption.
  final bool showCosts;

  /// Unit label for cost mode (e.g. 'EUR').
  final String? costUnit;

  /// Number of bars visible at once before scrolling kicks in.
  final int visibleBars;

  const MonthlyBarChart({
    super.key,
    required this.periods,
    required this.primaryColor,
    required this.unit,
    this.highlightMonth,
    this.locale = 'de',
    this.periodCosts,
    this.showCosts = false,
    this.costUnit,
    this.visibleBars = 12,
  });

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlight());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlight() {
    if (widget.highlightMonth == null || widget.periods.isEmpty) return;
    final index = widget.periods.indexWhere((p) =>
        p.periodStart.year == widget.highlightMonth!.year &&
        p.periodStart.month == widget.highlightMonth!.month);
    if (index < 0) return;

    final barWidth = _barWidth;
    final spacing = _barSpacing;
    final targetOffset = (index * (barWidth + spacing)) - (barWidth * 2);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  double get _barWidth => 24.0;
  double get _barSpacing => 12.0;

  @override
  Widget build(BuildContext context) {
    if (widget.periods.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }

    // If all bars fit, don't scroll -- just render normally
    if (widget.periods.length <= widget.visibleBars) {
      return BarChart(
        _buildBarChartData(context, useInternalTitles: true),
        swapAnimationDuration: const Duration(milliseconds: 300),
      );
    }

    // AXIS-03: Fixed Y-axis labels + scrollable chart area
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fixed Y-axis labels column
        SizedBox(
          width: 52,
          child: BarChart(
            _buildYAxisOnlyData(context),
            swapAnimationDuration: Duration.zero,
          ),
        ),
        // Scrollable chart area
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: SizedBox(
              width: _calculateChartWidth(),
              child: BarChart(
                _buildBarChartData(context, useInternalTitles: false),
                swapAnimationDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateChartWidth() {
    return widget.periods.length * (_barWidth + _barSpacing) + _barSpacing;
  }

  BarChartGroupData _buildBarGroup(int index, BuildContext context) {
    final period = widget.periods[index];
    final isHighlighted = widget.highlightMonth != null &&
        period.periodStart.year == widget.highlightMonth!.year &&
        period.periodStart.month == widget.highlightMonth!.month;
    final isExtrapolated = period.isExtrapolated;
    final now = DateTime.now();
    final isFuture =
        period.periodStart.isAfter(DateTime(now.year, now.month, 1));

    // Get the bar value (cost or consumption)
    final double barValue;
    if (widget.showCosts &&
        widget.periodCosts != null &&
        index < widget.periodCosts!.length &&
        widget.periodCosts![index] != null) {
      barValue = widget.periodCosts![index]!;
    } else {
      barValue = period.consumption;
    }

    // Dimmer non-selected bars, strong highlight for selected
    final double alpha;
    if (isHighlighted) {
      alpha = 1.0;
    } else if (isExtrapolated || isFuture) {
      alpha = 0.25;
    } else {
      alpha = 0.5;
    }

    return BarChartGroupData(
      x: index,
      showingTooltipIndicators: isHighlighted ? [0] : [],
      barRods: [
        BarChartRodData(
          toY: barValue,
          color: widget.primaryColor.withValues(alpha: alpha),
          width: _barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: isHighlighted
              ? BackgroundBarChartRodData(
                  show: true,
                  toY: barValue,
                  color: widget.primaryColor.withValues(alpha: 0.4),
                )
              : BackgroundBarChartRodData(show: false),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(
      BuildContext context, {required bool useInternalTitles}) {
    final groups = List.generate(
      widget.periods.length,
      (i) => _buildBarGroup(i, context),
    );

    return BarChartData(
      barGroups: groups,
      alignment: BarChartAlignment.spaceEvenly,
      maxY: _calculateMaxY(),
      titlesData: FlTitlesData(
        topTitles: ChartAxisStyle.hiddenTitles,
        rightTitles: ChartAxisStyle.hiddenTitles,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= widget.periods.length) {
                return const SizedBox.shrink();
              }
              final monthName = DateFormat.MMM(widget.locale)
                  .format(widget.periods[index].periodStart);
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(monthName,
                    style: Theme.of(context).textTheme.bodySmall),
              );
            },
          ),
        ),
        leftTitles: useInternalTitles
            ? ChartAxisStyle.leftTitles(context: context)
            : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: ChartAxisStyle.gridData(context),
      borderData: ChartAxisStyle.borderData(context),
      barTouchData: _buildTouchData(context),
    );
  }

  BarChartData _buildYAxisOnlyData(BuildContext context) {
    return BarChartData(
      barGroups: [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(toY: 0, color: Colors.transparent, width: 0),
        ]),
      ],
      maxY: _calculateMaxY(),
      titlesData: FlTitlesData(
        topTitles: ChartAxisStyle.hiddenTitles,
        rightTitles: ChartAxisStyle.hiddenTitles,
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
        ),
        leftTitles: ChartAxisStyle.leftTitles(context: context),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
    );
  }

  BarTouchData _buildTouchData(BuildContext context) {
    final displayUnit =
        widget.showCosts && widget.costUnit != null ? widget.costUnit! : widget.unit;
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tooltipMargin: 6,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final period = widget.periods[group.x.toInt()];
          final isHighlighted = widget.highlightMonth != null &&
              period.periodStart.year == widget.highlightMonth!.year &&
              period.periodStart.month == widget.highlightMonth!.month;
          if (isHighlighted) {
            final monthName =
                DateFormat.MMM(widget.locale).format(period.periodStart);
            return BarTooltipItem(
              '$monthName\n${ValtraNumberFormat.consumption(rod.toY, widget.locale)} $displayUnit',
              TextStyle(
                  color: widget.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
            );
          }
          final monthName =
              DateFormat.yMMM(widget.locale).format(period.periodStart);
          return BarTooltipItem(
            '$monthName\n${ValtraNumberFormat.consumption(rod.toY, widget.locale)} $displayUnit',
            TextStyle(
                color: widget.primaryColor, fontWeight: FontWeight.bold),
          );
        },
      ),
    );
  }

  double _calculateMaxY() {
    if (widget.periods.isEmpty) return 1.0;
    final values = widget.periods.asMap().entries.map((entry) {
      final i = entry.key;
      if (widget.showCosts &&
          widget.periodCosts != null &&
          i < widget.periodCosts!.length &&
          widget.periodCosts![i] != null) {
        return widget.periodCosts![i]!;
      }
      return entry.value.consumption;
    });
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal * 1.2 : 1.0;
  }
}
