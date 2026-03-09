import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/interpolation/models.dart';
import '../../services/number_format_service.dart';

/// A line chart overlaying current year vs previous year monthly consumption.
///
/// X-axis positions use calendar month indices (0=Jan, 11=Dec) so both
/// current and previous year lines are aligned by calendar month regardless
/// of which months have data.
class YearComparisonChart extends StatelessWidget {
  final List<PeriodConsumption> currentYear;
  final List<PeriodConsumption>? previousYear;
  final Color primaryColor;
  final String unit;
  final String locale;

  /// Optional cost data for kWh/EUR toggle support (parallel to consumption periods).
  final List<double?>? currentYearCosts;
  final List<double?>? previousYearCosts;

  /// When true, chart displays cost values instead of consumption.
  final bool showCosts;

  /// Unit label for cost mode (e.g. 'EUR').
  final String? costUnit;

  const YearComparisonChart({
    super.key,
    required this.currentYear,
    this.previousYear,
    required this.primaryColor,
    required this.unit,
    this.locale = 'de',
    this.currentYearCosts,
    this.previousYearCosts,
    this.showCosts = false,
    this.costUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (currentYear.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return LineChart(
      _buildData(context),
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Compute the maximum calendar month index across both datasets.
  double _computeMaxX() {
    double maxMonth = 0;
    for (final p in currentYear) {
      final m = (p.periodStart.month - 1).toDouble();
      if (m > maxMonth) maxMonth = m;
    }
    if (previousYear != null) {
      for (final p in previousYear!) {
        final m = (p.periodStart.month - 1).toDouble();
        if (m > maxMonth) maxMonth = m;
      }
    }
    return maxMonth;
  }

  LineChartData _buildData(BuildContext context) {
    List<FlSpot> currentSpots;
    List<FlSpot>? previousSpots;

    if (showCosts && currentYearCosts != null) {
      // Cost mode: pair each period's calendar month with its cost value
      currentSpots = [];
      for (int i = 0; i < currentYear.length; i++) {
        final cost =
            i < currentYearCosts!.length ? currentYearCosts![i] : null;
        if (cost != null) {
          currentSpots.add(FlSpot(
            (currentYear[i].periodStart.month - 1).toDouble(),
            cost,
          ));
        }
      }
    } else {
      // Consumption mode: use calendar month position
      currentSpots = currentYear
          .map((p) =>
              FlSpot((p.periodStart.month - 1).toDouble(), p.consumption))
          .toList();
    }

    if (showCosts && previousYearCosts != null && previousYear != null) {
      previousSpots = [];
      for (int i = 0; i < previousYear!.length; i++) {
        final cost =
            i < previousYearCosts!.length ? previousYearCosts![i] : null;
        if (cost != null) {
          previousSpots.add(FlSpot(
            (previousYear![i].periodStart.month - 1).toDouble(),
            cost,
          ));
        }
      }
    } else {
      previousSpots = previousYear
          ?.map((p) =>
              FlSpot((p.periodStart.month - 1).toDouble(), p.consumption))
          .toList();
    }

    final allValues = [
      ...currentSpots.map((s) => s.y),
      if (previousSpots != null) ...previousSpots.map((s) => s.y),
    ];
    final maxVal = allValues.isEmpty
        ? 1.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;

    final displayUnit = showCosts && costUnit != null ? costUnit! : unit;

    return LineChartData(
      minX: 0,
      maxX: _computeMaxX(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        // Current year: solid line
        LineChartBarData(
          spots: currentSpots,
          color: primaryColor,
          barWidth: 2.5,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 4,
              color: primaryColor,
              strokeColor: Theme.of(context).colorScheme.surface,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: primaryColor.withValues(alpha: 0.1),
          ),
        ),
        // Previous year: dashed line
        if (previousSpots != null && previousSpots.isNotEmpty)
          LineChartBarData(
            spots: previousSpots,
            color: primaryColor.withValues(alpha: 0.5),
            barWidth: 2.0,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: [8, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: Theme.of(context).colorScheme.surface,
                strokeColor: primaryColor.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          ),
      ],
      titlesData: _buildTitles(context),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final monthIndex = spot.x.toInt();
              final monthName =
                  DateFormat.MMM().format(DateTime(2024, monthIndex + 1));
              final valueStr = ValtraNumberFormat.consumption(spot.y, locale);
              return LineTooltipItem(
                '$monthName\n$valueStr $displayUnit',
                TextStyle(
                  color: spot.bar.color ?? primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  FlTitlesData _buildTitles(BuildContext context) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index > 11) {
              return const SizedBox.shrink();
            }
            // Show every other month label if range > 6 months
            final monthRange = _computeMaxX().toInt() + 1;
            if (monthRange > 6 && index % 2 != 0) {
              return const SizedBox.shrink();
            }
            final monthName =
                DateFormat.MMM().format(DateTime(2024, index + 1));
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(monthName,
                  style: Theme.of(context).textTheme.bodySmall),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            if (value == meta.min) return const SizedBox.shrink();
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
      ),
    );
  }
}
