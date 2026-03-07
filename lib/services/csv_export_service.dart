import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import 'analytics/analytics_models.dart';
import 'interpolation/models.dart';

/// Stateless service that transforms analytics data into CSV strings.
class CsvExportService {
  const CsvExportService();

  static const _converter = ListToCsvConverter();

  /// Export monthly analytics data to CSV string.
  String exportMonthlyData(MonthlyAnalyticsData data) {
    final rows = <List<dynamic>>[
      ['Month', 'Consumption', 'Unit', 'Interpolated'],
    ];

    for (final period in data.recentMonths) {
      rows.add([
        DateFormat('yyyy-MM').format(period.periodStart),
        period.consumption.toStringAsFixed(2),
        data.unit,
        (period.startInterpolated || period.endInterpolated) ? 'Yes' : 'No',
      ]);
    }

    return _converter.convert(rows);
  }

  /// Export yearly analytics data to CSV string.
  String exportYearlyData(YearlyAnalyticsData data) {
    final hasPrevious = data.previousYearBreakdown != null &&
        data.previousYearBreakdown!.isNotEmpty;

    final headers = <String>[
      'Month',
      'Consumption',
      if (hasPrevious) 'Previous Year',
      'Unit',
      'Interpolated',
    ];

    final rows = <List<dynamic>>[headers];

    for (int i = 0; i < data.monthlyBreakdown.length; i++) {
      final period = data.monthlyBreakdown[i];
      final row = <dynamic>[
        DateFormat('yyyy-MM').format(period.periodStart),
        period.consumption.toStringAsFixed(2),
        if (hasPrevious)
          i < data.previousYearBreakdown!.length
              ? data.previousYearBreakdown![i].consumption.toStringAsFixed(2)
              : '',
        data.unit,
        (period.startInterpolated || period.endInterpolated) ? 'Yes' : 'No',
      ];
      rows.add(row);
    }

    return _converter.convert(rows);
  }

  /// Export all meter types for a year.
  String exportAllMeters({
    required int year,
    required Map<MeterType, List<PeriodConsumption>> dataByType,
  }) {
    final rows = <List<dynamic>>[
      ['Meter Type', 'Month', 'Consumption', 'Unit', 'Interpolated'],
    ];

    for (final entry in dataByType.entries) {
      final type = entry.key;
      final unit = unitForMeterType(type);
      final displayUnit = type == MeterType.gas ? 'kWh' : unit;

      for (final period in entry.value) {
        rows.add([
          type.name,
          DateFormat('yyyy-MM').format(period.periodStart),
          period.consumption.toStringAsFixed(2),
          displayUnit,
          (period.startInterpolated || period.endInterpolated) ? 'Yes' : 'No',
        ]);
      }
    }

    return _converter.convert(rows);
  }
}
