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
  final DateTime selectedMonth;

  const AllTimeHouseholdChart({
    super.key,
    required this.households,
    required this.unit,
    required this.selectedMonth,
    this.locale = 'de',
  });

  @override
  State<AllTimeHouseholdChart> createState() => _AllTimeHouseholdChartState();
}

class _AllTimeHouseholdChartState extends State<AllTimeHouseholdChart> {
  bool _perPerson = false;

  /// Compute the 12-month window ending at selectedMonth and filter households.
  List<HouseholdChartData> get _windowedHouseholds {
    final end = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    final start = DateTime(end.year, end.month - 11, 1);

    return widget.households
        .map((h) {
          final filtered = h.periods.where((p) {
            final ps = DateTime(p.periodStart.year, p.periodStart.month, 1);
            return !ps.isBefore(start) && !ps.isAfter(end);
          }).toList();
          return HouseholdChartData(
            name: h.name,
            periods: filtered,
            color: h.color,
            personCount: h.personCount,
          );
        })
        .where((h) => h.periods.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final households = _windowedHouseholds;

    if (households.isEmpty || households.every((h) => h.periods.isEmpty)) {
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
              constraints: const BoxConstraints(minHeight: 32, minWidth: 72),
              textStyle: Theme.of(context).textTheme.bodySmall,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(l10n.total),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(l10n.perPerson),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: LineChart(
            _buildData(context, households),
            duration: const Duration(milliseconds: 300),
          ),
        ),
        const SizedBox(height: 8),
        ChartLegend(
          items: households
              .map((h) => ChartLegendItem(color: h.color, label: h.name))
              .toList(),
        ),
      ],
    );
  }

  LineChartData _buildData(
      BuildContext context, List<HouseholdChartData> households) {
    final lineBars = <LineChartBarData>[];

    final end =
        DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    final start = DateTime(end.year, end.month - 11, 1);
    final baseYear = start.year;

    for (final household in households) {
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
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }

    final windowMinX = (start.month - 1).toDouble() +
        ((start.year - baseYear) * 12);
    final windowMaxX = (end.month - 1).toDouble() +
        ((end.year - baseYear) * 12);

    final allValues = lineBars
        .expand((bar) => bar.spots)
        .where((s) => s != FlSpot.nullSpot)
        .map((s) => s.y);
    final maxVal =
        allValues.isEmpty ? 1.0 : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 1.0;

    return LineChartData(
      minX: windowMinX,
      maxX: windowMaxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: lineBars,
      titlesData: _buildTitles(context, windowMinX, windowMaxX, baseYear),
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
            if (index % 2 != 0) {
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
          ChartAxisStyle.leftTitles(context: context),
    );
  }
}
