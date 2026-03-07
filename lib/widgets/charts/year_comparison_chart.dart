import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/interpolation/models.dart';

/// A line chart overlaying current year vs previous year monthly consumption.
class YearComparisonChart extends StatelessWidget {
  final List<PeriodConsumption> currentYear;
  final List<PeriodConsumption>? previousYear;
  final Color primaryColor;
  final String unit;

  const YearComparisonChart({
    super.key,
    required this.currentYear,
    this.previousYear,
    required this.primaryColor,
    required this.unit,
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

  LineChartData _buildData(BuildContext context) {
    final currentSpots = currentYear
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.consumption))
        .toList();

    final previousSpots = previousYear
        ?.asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.consumption))
        .toList();

    final allValues = [
      ...currentYear.map((p) => p.consumption),
      if (previousYear != null) ...previousYear!.map((p) => p.consumption),
    ];
    final maxVal = allValues.isEmpty
        ? 1.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;

    return LineChartData(
      minX: 0,
      maxX: (currentYear.length - 1).toDouble(),
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
              strokeColor: Colors.white,
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
                color: Colors.white,
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
              final index = spot.x.toInt();
              final monthName = index < currentYear.length
                  ? DateFormat.MMM().format(currentYear[index].periodStart)
                  : '';
              final valueStr = spot.y.toStringAsFixed(1);
              return LineTooltipItem(
                '$monthName\n$valueStr $unit',
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
            if (index < 0 || index >= currentYear.length) {
              return const SizedBox.shrink();
            }
            // Show every other month label to avoid crowding
            if (currentYear.length > 6 && index % 2 != 0) {
              return const SizedBox.shrink();
            }
            final monthName =
                DateFormat.MMM().format(currentYear[index].periodStart);
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
