import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/services/interpolation/models.dart';

void main() {
  late InterpolationService service;

  setUp(() {
    service = InterpolationService();
  });

  group('interpolateAt', () {
    test('returns valueA when totalDuration is zero', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 1, 1),
        valueB: 200.0,
        targetTime: DateTime(2024, 1, 1),
      );
      expect(result, 100.0);
    });

    test('interpolates midpoint correctly', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 3, 1),
        valueB: 200.0,
        targetTime: DateTime(2024, 2, 1),
      );
      // ~halfway through Jan-Mar (31 of 60 days)
      expect(result, closeTo(151.67, 0.5));
    });
  });

  group('getMonthlyBoundaries', () {
    test('returns empty list for empty readings', () {
      final result = service.getMonthlyBoundaries(
        readings: [],
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 6, 1),
      );
      expect(result, isEmpty);
    });

    test('returns exact value when reading matches boundary', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 3, 1), value: 150.0),
      ];
      final result = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 3, 1),
        rangeEnd: DateTime(2024, 4, 1),
      );
      expect(result, hasLength(1));
      expect(result[0].value, 150.0);
      expect(result[0].isInterpolated, false);
    });

    test('interpolates between two readings', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 15), value: 100.0),
        (timestamp: DateTime(2024, 3, 15), value: 200.0),
      ];
      final result = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 2, 1),
        rangeEnd: DateTime(2024, 3, 1),
      );
      // Both Feb 1 and Mar 1 fall between the two readings
      expect(result, hasLength(2));
      expect(result[0].isInterpolated, true);
      expect(result[0].timestamp, DateTime(2024, 2, 1));
      expect(result[1].timestamp, DateTime(2024, 3, 1));
    });
  });

  group('getMonthlyConsumption', () {
    test('returns empty for single boundary', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 3, 1), value: 100.0),
      ];
      final result = service.getMonthlyConsumption(
        readings: readings,
        rangeStart: DateTime(2024, 3, 1),
        rangeEnd: DateTime(2024, 4, 1),
      );
      expect(result, isEmpty);
    });

    test('computes consumption between two boundaries', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 1), value: 100.0),
        (timestamp: DateTime(2024, 4, 1), value: 400.0),
      ];
      final result = service.getMonthlyConsumption(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 4, 1),
      );
      // Boundaries: Jan 1, Feb 1, Mar 1, Apr 1 => 3 consumption periods
      expect(result, hasLength(3));
      expect(result[0].periodStart, DateTime(2024, 1, 1));
      expect(result[0].periodEnd, DateTime(2024, 2, 1));
      // Total consumption across all periods should equal 300
      final totalConsumption =
          result.fold<double>(0, (sum, p) => sum + p.consumption);
      expect(totalConsumption, closeTo(300.0, 0.1));
    });
  });

  group('extrapolateYearEnd', () {
    test('returns null for empty actual months', () {
      final result = service.extrapolateYearEnd(
        actualMonths: [],
        year: 2024,
      );
      expect(result, isNull);
    });

    test('3 months of data projects 12 months', () {
      final actualMonths = [
        PeriodConsumption(
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 2, 1),
          startValue: 0,
          endValue: 100,
          consumption: 100.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
        PeriodConsumption(
          periodStart: DateTime(2024, 2, 1),
          periodEnd: DateTime(2024, 3, 1),
          startValue: 100,
          endValue: 200,
          consumption: 100.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
        PeriodConsumption(
          periodStart: DateTime(2024, 3, 1),
          periodEnd: DateTime(2024, 4, 1),
          startValue: 200,
          endValue: 300,
          consumption: 100.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
      ];

      final result = service.extrapolateYearEnd(
        actualMonths: actualMonths,
        year: 2024,
      );

      expect(result, isNotNull);
      expect(result!.actualMonthCount, 3);
      // 3 months * 100 = 300 actual + 9 months * 100 = 900 projected = 1200
      expect(result.projectedTotal, 1200.0);
      expect(result.projectedMonths, hasLength(9));
      // All projected months should be marked as extrapolated
      for (final month in result.projectedMonths) {
        expect(month.isExtrapolated, true);
      }
    });

    test('full year (12 months) produces no extrapolation', () {
      final actualMonths = List.generate(12, (i) {
        return PeriodConsumption(
          periodStart: DateTime(2024, i + 1, 1),
          periodEnd: DateTime(2024, i + 2, 1),
          startValue: 0,
          endValue: 50,
          consumption: 50.0,
          startInterpolated: false,
          endInterpolated: false,
        );
      });

      final result = service.extrapolateYearEnd(
        actualMonths: actualMonths,
        year: 2024,
      );

      expect(result, isNotNull);
      expect(result!.projectedMonths, isEmpty);
      expect(result.projectedTotal, 600.0); // 12 * 50
      expect(result.actualMonthCount, 12);
    });

    test('1 month projects with average from single month', () {
      final actualMonths = [
        PeriodConsumption(
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 2, 1),
          startValue: 0,
          endValue: 200,
          consumption: 200.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
      ];

      final result = service.extrapolateYearEnd(
        actualMonths: actualMonths,
        year: 2024,
      );

      expect(result, isNotNull);
      expect(result!.actualMonthCount, 1);
      // 1 month * 200 = 200 actual + 11 months * 200 = 2200 projected = 2400
      expect(result.projectedTotal, 2400.0);
      expect(result.projectedMonths, hasLength(11));
    });

    test('projected months cover only missing months', () {
      final actualMonths = [
        PeriodConsumption(
          periodStart: DateTime(2024, 3, 1),
          periodEnd: DateTime(2024, 4, 1),
          startValue: 0,
          endValue: 60,
          consumption: 60.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
        PeriodConsumption(
          periodStart: DateTime(2024, 5, 1),
          periodEnd: DateTime(2024, 6, 1),
          startValue: 60,
          endValue: 120,
          consumption: 60.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
      ];

      final result = service.extrapolateYearEnd(
        actualMonths: actualMonths,
        year: 2024,
      );

      expect(result, isNotNull);
      // Covered months: 3, 5 => missing: 1,2,4,6,7,8,9,10,11,12 = 10 months
      expect(result!.projectedMonths, hasLength(10));
      // Average = 120/2 = 60 per month
      // Projected total = 120 (actual) + 10 * 60 (projected) = 720
      expect(result.projectedTotal, 720.0);
    });

    test('extrapolated periods have correct month values', () {
      final actualMonths = [
        PeriodConsumption(
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 2, 1),
          startValue: 0,
          endValue: 100,
          consumption: 100.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
      ];

      final result = service.extrapolateYearEnd(
        actualMonths: actualMonths,
        year: 2024,
      );

      expect(result, isNotNull);
      // Should have months 2-12 as extrapolated
      final months = result!.projectedMonths.map((p) => p.periodStart.month).toList();
      expect(months, [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    });
  });
}
