import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/services/csv_export_service.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/interpolation/models.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a [PeriodConsumption] for a single month starting at [year]-[month].
PeriodConsumption makePeriod({
  required int year,
  required int month,
  double consumption = 100.0,
  bool startInterpolated = false,
  bool endInterpolated = false,
}) {
  final start = DateTime(year, month);
  final end = DateTime(year, month + 1);
  return PeriodConsumption(
    periodStart: start,
    periodEnd: end,
    startValue: 1000.0,
    endValue: 1000.0 + consumption,
    consumption: consumption,
    startInterpolated: startInterpolated,
    endInterpolated: endInterpolated,
  );
}

/// Builds a [MonthlyAnalyticsData] from a list of [PeriodConsumption].
MonthlyAnalyticsData makeMonthlyData({
  MeterType meterType = MeterType.electricity,
  DateTime? month,
  List<PeriodConsumption>? recentMonths,
  double? totalConsumption,
  String unit = 'kWh',
}) {
  return MonthlyAnalyticsData(
    meterType: meterType,
    month: month ?? DateTime(2025, 1),
    dailyValues: const [],
    recentMonths: recentMonths ?? [],
    totalConsumption: totalConsumption,
    unit: unit,
  );
}

/// Builds a [YearlyAnalyticsData] from monthly breakdown lists.
YearlyAnalyticsData makeYearlyData({
  MeterType meterType = MeterType.electricity,
  int year = 2025,
  List<PeriodConsumption>? monthlyBreakdown,
  List<PeriodConsumption>? previousYearBreakdown,
  double? totalConsumption,
  double? previousYearTotal,
  String unit = 'kWh',
}) {
  return YearlyAnalyticsData(
    meterType: meterType,
    year: year,
    monthlyBreakdown: monthlyBreakdown ?? [],
    previousYearBreakdown: previousYearBreakdown,
    totalConsumption: totalConsumption,
    previousYearTotal: previousYearTotal,
    unit: unit,
  );
}

/// Splits a CSV string into lines for easier assertion.
/// Handles both \r\n (Windows / csv package default) and \n line endings.
List<String> csvLines(String csv) =>
    csv.split(RegExp(r'\r?\n'));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CsvExportService service;

  setUp(() {
    service = const CsvExportService();
  });

  // -----------------------------------------------------------------------
  // exportMonthlyData
  // -----------------------------------------------------------------------
  group('exportMonthlyData', () {
    test('produces correct header row', () {
      final data = makeMonthlyData(recentMonths: []);
      final csv = service.exportMonthlyData(data);
      final lines = csvLines(csv);

      expect(lines.first, 'Month,Consumption,Unit,Interpolated');
    });

    test('exports single month row with correct values', () {
      final data = makeMonthlyData(
        unit: 'kWh',
        recentMonths: [
          makePeriod(year: 2025, month: 3, consumption: 42.5),
        ],
      );

      final csv = service.exportMonthlyData(data);
      final lines = csvLines(csv);

      expect(lines.length, 2);
      expect(lines[1], '2025-03,42.50,kWh,No');
    });

    test('exports multiple months in order', () {
      final data = makeMonthlyData(
        unit: 'kWh',
        recentMonths: [
          makePeriod(year: 2024, month: 10, consumption: 10.0),
          makePeriod(year: 2024, month: 11, consumption: 20.0),
          makePeriod(year: 2024, month: 12, consumption: 30.0),
        ],
      );

      final csv = service.exportMonthlyData(data);
      final lines = csvLines(csv);

      expect(lines.length, 4); // header + 3 rows
      expect(lines[1], '2024-10,10.00,kWh,No');
      expect(lines[2], '2024-11,20.00,kWh,No');
      expect(lines[3], '2024-12,30.00,kWh,No');
    });

    test('returns header only when recentMonths is empty', () {
      final data = makeMonthlyData(recentMonths: []);
      final csv = service.exportMonthlyData(data);
      final lines = csvLines(csv);

      expect(lines.length, 1);
      expect(lines.first, 'Month,Consumption,Unit,Interpolated');
    });

    test('marks row as interpolated when startInterpolated is true', () {
      final data = makeMonthlyData(
        recentMonths: [
          makePeriod(
            year: 2025, month: 1,
            startInterpolated: true,
            endInterpolated: false,
          ),
        ],
      );

      final csv = service.exportMonthlyData(data);
      expect(csvLines(csv)[1], contains(',Yes'));
    });

    test('marks row as interpolated when endInterpolated is true', () {
      final data = makeMonthlyData(
        recentMonths: [
          makePeriod(
            year: 2025, month: 2,
            startInterpolated: false,
            endInterpolated: true,
          ),
        ],
      );

      final csv = service.exportMonthlyData(data);
      expect(csvLines(csv)[1], endsWith(',Yes'));
    });

    test('marks row as not interpolated when both flags are false', () {
      final data = makeMonthlyData(
        recentMonths: [
          makePeriod(
            year: 2025, month: 5,
            startInterpolated: false,
            endInterpolated: false,
          ),
        ],
      );

      final csv = service.exportMonthlyData(data);
      expect(csvLines(csv)[1], endsWith(',No'));
    });

    test('uses the unit from data object', () {
      final data = makeMonthlyData(
        unit: 'm\u00B3',
        recentMonths: [
          makePeriod(year: 2025, month: 6, consumption: 5.0),
        ],
      );

      final csv = service.exportMonthlyData(data);
      expect(csvLines(csv)[1], contains('m\u00B3'));
    });
  });

  // -----------------------------------------------------------------------
  // exportYearlyData
  // -----------------------------------------------------------------------
  group('exportYearlyData', () {
    test('header omits Previous Year column when previousYearBreakdown is null',
        () {
      final data = makeYearlyData(
        monthlyBreakdown: [makePeriod(year: 2025, month: 1)],
        previousYearBreakdown: null,
      );

      final csv = service.exportYearlyData(data);
      final header = csvLines(csv).first;

      expect(header, 'Month,Consumption,Unit,Interpolated');
      expect(header, isNot(contains('Previous Year')));
    });

    test(
        'header omits Previous Year column when previousYearBreakdown is empty',
        () {
      final data = makeYearlyData(
        monthlyBreakdown: [makePeriod(year: 2025, month: 1)],
        previousYearBreakdown: [],
      );

      final csv = service.exportYearlyData(data);
      final header = csvLines(csv).first;

      expect(header, 'Month,Consumption,Unit,Interpolated');
    });

    test('includes Previous Year column when previousYearBreakdown has data',
        () {
      final data = makeYearlyData(
        monthlyBreakdown: [
          makePeriod(year: 2025, month: 1, consumption: 100.0),
        ],
        previousYearBreakdown: [
          makePeriod(year: 2024, month: 1, consumption: 90.0),
        ],
      );

      final csv = service.exportYearlyData(data);
      final lines = csvLines(csv);

      expect(lines.first, 'Month,Consumption,Previous Year,Unit,Interpolated');
      expect(lines[1], '2025-01,100.00,90.00,kWh,No');
    });

    test('fills empty string when previousYearBreakdown is shorter than monthlyBreakdown',
        () {
      final data = makeYearlyData(
        monthlyBreakdown: [
          makePeriod(year: 2025, month: 1, consumption: 50.0),
          makePeriod(year: 2025, month: 2, consumption: 60.0),
          makePeriod(year: 2025, month: 3, consumption: 70.0),
        ],
        previousYearBreakdown: [
          makePeriod(year: 2024, month: 1, consumption: 40.0),
        ],
      );

      final csv = service.exportYearlyData(data);
      final lines = csvLines(csv);

      // Row for month 1: has previous year value
      expect(lines[1], '2025-01,50.00,40.00,kWh,No');
      // Row for month 2: previous year index out of range -> empty
      expect(lines[2], '2025-02,60.00,,kWh,No');
      // Row for month 3: same
      expect(lines[3], '2025-03,70.00,,kWh,No');
    });

    test('returns header only when monthlyBreakdown is empty', () {
      final data = makeYearlyData(monthlyBreakdown: []);
      final csv = service.exportYearlyData(data);
      final lines = csvLines(csv);

      expect(lines.length, 1);
    });

    test('marks interpolated rows correctly', () {
      final data = makeYearlyData(
        monthlyBreakdown: [
          makePeriod(
            year: 2025, month: 4,
            consumption: 80.0,
            startInterpolated: true,
            endInterpolated: true,
          ),
          makePeriod(
            year: 2025, month: 5,
            consumption: 90.0,
            startInterpolated: false,
            endInterpolated: false,
          ),
        ],
      );

      final csv = service.exportYearlyData(data);
      final lines = csvLines(csv);

      expect(lines[1], endsWith(',Yes'));
      expect(lines[2], endsWith(',No'));
    });
  });

  // -----------------------------------------------------------------------
  // exportAllMeters
  // -----------------------------------------------------------------------
  group('exportAllMeters', () {
    test('produces correct header row', () {
      final csv = service.exportAllMeters(year: 2025, dataByType: {});
      final lines = csvLines(csv);

      expect(
        lines.first,
        'Meter Type,Month,Consumption,Unit,Interpolated',
      );
    });

    test('returns header only when dataByType is empty', () {
      final csv = service.exportAllMeters(year: 2025, dataByType: {});
      final lines = csvLines(csv);

      expect(lines.length, 1);
    });

    test('exports electricity rows with kWh unit', () {
      final csv = service.exportAllMeters(
        year: 2025,
        dataByType: {
          MeterType.electricity: [
            makePeriod(year: 2025, month: 1, consumption: 200.0),
          ],
        },
      );

      final lines = csvLines(csv);
      expect(lines[1], 'electricity,2025-01,200.00,kWh,No');
    });

    test('uses kWh display unit for gas instead of m\u00B3', () {
      final csv = service.exportAllMeters(
        year: 2025,
        dataByType: {
          MeterType.gas: [
            makePeriod(year: 2025, month: 3, consumption: 150.0),
          ],
        },
      );

      final lines = csvLines(csv);
      // Gas should show kWh (conversion unit), not m3
      expect(lines[1], 'gas,2025-03,150.00,kWh,No');
      expect(lines[1], isNot(contains('m\u00B3')));
    });

    test('uses m\u00B3 display unit for water', () {
      final csv = service.exportAllMeters(
        year: 2025,
        dataByType: {
          MeterType.water: [
            makePeriod(year: 2025, month: 6, consumption: 12.0),
          ],
        },
      );

      final lines = csvLines(csv);
      expect(lines[1], contains('m\u00B3'));
    });

    test('uses units display unit for heating', () {
      final csv = service.exportAllMeters(
        year: 2025,
        dataByType: {
          MeterType.heating: [
            makePeriod(year: 2025, month: 9, consumption: 500.0),
          ],
        },
      );

      final lines = csvLines(csv);
      expect(lines[1], 'heating,2025-09,500.00,units,No');
    });

    test('exports multiple meter types with multiple periods each', () {
      final csv = service.exportAllMeters(
        year: 2025,
        dataByType: {
          MeterType.electricity: [
            makePeriod(year: 2025, month: 1, consumption: 100.0),
            makePeriod(year: 2025, month: 2, consumption: 110.0),
          ],
          MeterType.water: [
            makePeriod(year: 2025, month: 1, consumption: 5.0),
          ],
        },
      );

      final lines = csvLines(csv);
      // header + 2 electricity + 1 water = 4 lines
      expect(lines.length, 4);
      expect(lines[1], startsWith('electricity,'));
      expect(lines[2], startsWith('electricity,'));
      expect(lines[3], startsWith('water,'));
    });

    test('marks interpolated flag correctly per period', () {
      final csv = service.exportAllMeters(
        year: 2025,
        dataByType: {
          MeterType.electricity: [
            makePeriod(
              year: 2025, month: 1,
              consumption: 100.0,
              startInterpolated: true,
            ),
            makePeriod(
              year: 2025, month: 2,
              consumption: 120.0,
              startInterpolated: false,
              endInterpolated: false,
            ),
          ],
        },
      );

      final lines = csvLines(csv);
      expect(lines[1], endsWith(',Yes'));
      expect(lines[2], endsWith(',No'));
    });

    test('handles meter type with empty period list gracefully', () {
      final csv = service.exportAllMeters(
        year: 2025,
        dataByType: {
          MeterType.electricity: [],
          MeterType.gas: [
            makePeriod(year: 2025, month: 1, consumption: 50.0),
          ],
        },
      );

      final lines = csvLines(csv);
      // header + 0 electricity + 1 gas = 2 lines
      expect(lines.length, 2);
      expect(lines[1], startsWith('gas,'));
    });
  });

  // -----------------------------------------------------------------------
  // CSV format correctness
  // -----------------------------------------------------------------------
  group('CSV format correctness', () {
    test('consumption values are formatted to 2 decimal places', () {
      final data = makeMonthlyData(
        recentMonths: [
          makePeriod(year: 2025, month: 1, consumption: 7.0),
          makePeriod(year: 2025, month: 2, consumption: 123.456),
        ],
      );

      final csv = service.exportMonthlyData(data);
      final lines = csvLines(csv);

      // 7.0 -> 7.00
      expect(lines[1], contains('7.00'));
      // 123.456 -> 123.46
      expect(lines[2], contains('123.46'));
    });

    test('date is formatted as yyyy-MM', () {
      final data = makeMonthlyData(
        recentMonths: [
          makePeriod(year: 2025, month: 1, consumption: 1.0),
        ],
      );

      final csv = service.exportMonthlyData(data);
      expect(csvLines(csv)[1], startsWith('2025-01,'));
    });

    test('CSV output uses comma as separator with no trailing newline', () {
      final data = makeMonthlyData(
        recentMonths: [
          makePeriod(year: 2025, month: 7, consumption: 50.0),
        ],
      );

      final csv = service.exportMonthlyData(data);

      // Should not end with a newline (ListToCsvConverter default)
      expect(csv.endsWith('\n'), isFalse);
      // Every line should use commas
      for (final line in csvLines(csv)) {
        expect(line, contains(','));
      }
    });

    test('const constructor allows service instantiation without state', () {
      const svc = CsvExportService();
      expect(svc, isA<CsvExportService>());
    });
  });
}
