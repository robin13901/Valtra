import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/interpolation/models.dart';
import '../../services/number_format_service.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<PeriodConsumption> periods;
  final Color primaryColor;
  final String unit;
  final DateTime? highlightMonth;
  final String locale;

  const MonthlyBarChart({
    super.key,
    required this.periods,
    required this.primaryColor,
    required this.unit,
    this.highlightMonth,
    this.locale = 'de',
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return BarChart(
      _buildData(context),
      swapAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  BarChartData _buildData(BuildContext context) {
    final groups = periods.asMap().entries.map((entry) {
      final i = entry.key;
      final period = entry.value;
      final isHighlighted = highlightMonth != null &&
          period.periodStart.year == highlightMonth!.year &&
          period.periodStart.month == highlightMonth!.month;
      final hasInterpolation =
          period.startInterpolated || period.endInterpolated;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: period.consumption,
            color: isHighlighted
                ? primaryColor
                : primaryColor.withValues(alpha: 0.6),
            width: 20,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
            borderDashArray: hasInterpolation ? [4, 2] : null,
          ),
        ],
      );
    }).toList();

    return BarChartData(
      barGroups: groups,
      alignment: BarChartAlignment.spaceEvenly,
      maxY: _calculateMaxY(),
      titlesData: _buildTitles(context),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final period = periods[group.x.toInt()];
            final monthName = DateFormat.yMMM().format(period.periodStart);
            return BarTooltipItem(
              '$monthName\n${ValtraNumberFormat.consumption(rod.toY, locale)} $unit',
              TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            );
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
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= periods.length) {
              return const SizedBox.shrink();
            }
            final monthName =
                DateFormat.MMM().format(periods[index].periodStart);
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

  double _calculateMaxY() {
    if (periods.isEmpty) return 1.0;
    final maxVal =
        periods.map((p) => p.consumption).reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal * 1.2 : 1.0;
  }
}
