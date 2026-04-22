import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/number_format_service.dart';
import 'chart_axis_style.dart';
import 'chart_legend.dart';
import 'household_comparison_chart.dart';

class AllTimeHouseholdChart extends StatefulWidget {
  final List<HouseholdChartData> households;
  final String unit;
  final String locale;

  const AllTimeHouseholdChart({
    super.key,
    required this.households,
    required this.unit,
    this.locale = 'de',
  });

  @override
  State<AllTimeHouseholdChart> createState() => _AllTimeHouseholdChartState();
}

class _AllTimeHouseholdChartState extends State<AllTimeHouseholdChart> {
  bool _perPerson = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.households.isEmpty ||
        widget.households.every((h) => h.periods.isEmpty)) {
      return Center(child: Text(l10n.noData));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.households,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ToggleButtons(
              isSelected: [!_perPerson, _perPerson],
              onPressed: (index) => setState(() => _perPerson = index == 1),
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
              textStyle: Theme.of(context).textTheme.bodySmall,
              children: [
                Text(l10n.total),
                Text(l10n.perPerson),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: LineChart(
            _buildData(context),
            duration: const Duration(milliseconds: 300),
          ),
        ),
        const SizedBox(height: 8),
        ChartLegend(
          items: widget.households
              .map((h) => ChartLegendItem(color: h.color, label: h.name))
              .toList(),
        ),
      ],
    );
  }

  int get _minYear {
    int min = 9999;
    for (final h in widget.households) {
      for (final p in h.periods) {
        if (p.periodStart.year < min) min = p.periodStart.year;
      }
    }
    return min == 9999 ? DateTime.now().year : min;
  }

  LineChartData _buildData(BuildContext context) {
    final lineBars = <LineChartBarData>[];
    final baseYear = _minYear;

    for (final household in widget.households) {
      if (household.periods.isEmpty) continue;

      final divisor =
          _perPerson && household.personCount > 0 ? household.personCount : 1;

      final spots = <FlSpot>[];
      for (final period in household.periods) {
        if (period.consumption <= 0 && !period.isExtrapolated) continue;
        final x = (period.periodStart.month - 1).toDouble() +
            ((period.periodStart.year - baseYear) * 12);
        spots.add(FlSpot(x, period.consumption / divisor));
      }

      if (spots.isNotEmpty) {
        lineBars.add(LineChartBarData(
          spots: spots,
          color: household.color,
          barWidth: 2.5,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 3,
              color: household.color,
              strokeColor: Theme.of(context).colorScheme.surface,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }

    final allValues = lineBars
        .expand((bar) => bar.spots)
        .where((s) => s != FlSpot.nullSpot)
        .map((s) => s.y);
    final maxVal =
        allValues.isEmpty ? 1.0 : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;

    final allX = lineBars
        .expand((bar) => bar.spots)
        .where((s) => s != FlSpot.nullSpot)
        .map((s) => s.x);
    final maxX = allX.isEmpty ? 11.0 : allX.reduce((a, b) => a > b ? a : b);
    final minX = allX.isEmpty ? 0.0 : allX.reduce((a, b) => a < b ? a : b);

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: lineBars,
      titlesData: _buildTitles(context, minX, maxX, baseYear),
      gridData: ChartAxisStyle.gridData(context),
      borderData: ChartAxisStyle.borderData(context),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final monthIndex = spot.x.toInt() % 12;
              final year = baseYear + spot.x.toInt() ~/ 12;
              final monthName = DateFormat.MMM(widget.locale)
                  .format(DateTime(year, monthIndex + 1));
              final valueStr =
                  ValtraNumberFormat.consumption(spot.y, widget.locale);
              return LineTooltipItem(
                '$monthName $year\n$valueStr ${widget.unit}',
                TextStyle(
                  color: spot.bar.color ?? Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  FlTitlesData _buildTitles(
      BuildContext context, double minX, double maxX, int baseYear) {
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
            final monthIndex = index % 12;
            if (monthIndex < 0 || monthIndex > 11) {
              return const SizedBox.shrink();
            }
            final range = (maxX - minX).toInt() + 1;
            if (range > 12 && index % 3 != 0) {
              return const SizedBox.shrink();
            } else if (range > 6 && range <= 12 && index % 2 != 0) {
              return const SizedBox.shrink();
            }
            final year = baseYear + index ~/ 12;
            final monthName = DateFormat.MMM(widget.locale)
                .format(DateTime(year, monthIndex + 1));
            final label = monthIndex == 0 ? '$monthName\n$year' : monthName;
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child:
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
            );
          },
        ),
      ),
      leftTitles:
          ChartAxisStyle.leftTitles(context: context, unit: widget.unit),
    );
  }
}
