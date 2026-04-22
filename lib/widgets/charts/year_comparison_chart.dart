import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/interpolation/models.dart';
import '../../services/number_format_service.dart';
import 'chart_axis_style.dart';

class YearComparisonChart extends StatelessWidget {
  final List<PeriodConsumption> currentYear;
  final List<PeriodConsumption>? previousYear;
  final Color primaryColor;
  final String unit;
  final String locale;

  final List<double?>? currentYearCosts;
  final List<double?>? previousYearCosts;

  final bool showCosts;
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
    // Build current year spots (actual data only, skip extrapolated)
    List<FlSpot> currentSpots;
    if (showCosts && currentYearCosts != null) {
      currentSpots = [];
      for (int i = 0; i < currentYear.length; i++) {
        if (currentYear[i].isExtrapolated) continue;
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
      currentSpots = currentYear
          .where((p) => !p.isExtrapolated)
          .map((p) =>
              FlSpot((p.periodStart.month - 1).toDouble(), p.consumption))
          .toList();
    }

    // Build previous year spots
    List<FlSpot>? previousSpots;
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
        // Current year: solid line, full color
        if (currentSpots.isNotEmpty)
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.3),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        // Previous year: dotted line, faded
        if (previousSpots != null && previousSpots.isNotEmpty)
          LineChartBarData(
            spots: previousSpots,
            color: primaryColor.withValues(alpha: 0.4),
            barWidth: 1.5,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: [2, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 2.5,
                color: Theme.of(context).colorScheme.surface,
                strokeColor: primaryColor.withValues(alpha: 0.4),
                strokeWidth: 1.5,
              ),
            ),
          ),
      ],
      titlesData: _buildTitles(context),
      gridData: ChartAxisStyle.gridData(context),
      borderData: ChartAxisStyle.borderData(context),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final monthIndex = spot.x.toInt();
              final monthName =
                  DateFormat.MMM(locale).format(DateTime(2024, monthIndex + 1));
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
    final displayUnit = showCosts && costUnit != null ? costUnit! : unit;
    return FlTitlesData(
      topTitles: ChartAxisStyle.hiddenTitles,
      rightTitles: ChartAxisStyle.hiddenTitles,
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
            final monthRange = _computeMaxX().toInt() + 1;
            if (monthRange > 6 && index % 2 != 0) {
              return const SizedBox.shrink();
            }
            final monthName =
                DateFormat.MMM(locale).format(DateTime(2024, index + 1));
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(monthName,
                  style: Theme.of(context).textTheme.bodySmall),
            );
          },
        ),
      ),
      leftTitles: ChartAxisStyle.leftTitles(context: context, unit: displayUnit),
    );
  }
}
