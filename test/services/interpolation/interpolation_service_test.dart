import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/services/interpolation/models.dart';

void main() {
  late InterpolationService service;

  setUp(() {
    service = InterpolationService();
  });

  group('interpolateAt', () {
    test('linear midpoint returns average', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 1, 31),
        valueB: 200.0,
        targetTime: DateTime(2024, 1, 16),
      );

      expect(result, closeTo(150.0, 0.5));
    });

    test('linear quarter point returns 25% interpolation', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 0.0,
        timeB: DateTime(2024, 5, 1),
        valueB: 400.0,
        targetTime: DateTime(2024, 2, 1),
        method: InterpolationMethod.linear,
      );

      // Uses millisecond precision: Jan 1 to May 1, Jan 1 to Feb 1
      final totalMs = DateTime(2024, 5, 1).difference(DateTime(2024, 1, 1)).inMilliseconds;
      final targetMs = DateTime(2024, 2, 1).difference(DateTime(2024, 1, 1)).inMilliseconds;
      expect(result, closeTo(400.0 * targetMs / totalMs, 0.01));
    });

    test('linear at start returns valueA', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 2, 1),
        valueB: 200.0,
        targetTime: DateTime(2024, 1, 1),
      );

      expect(result, 100.0);
    });

    test('linear at end returns valueB', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 2, 1),
        valueB: 200.0,
        targetTime: DateTime(2024, 2, 1),
      );

      expect(result, 200.0);
    });

    test('linear with same timestamps returns valueA', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 1, 1),
        valueB: 200.0,
        targetTime: DateTime(2024, 1, 1),
      );

      expect(result, 100.0);
    });

    test('step always returns valueA', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 2, 1),
        valueB: 200.0,
        targetTime: DateTime(2024, 1, 16),
        method: InterpolationMethod.step,
      );

      expect(result, 100.0);
    });

    test('step at end still returns valueA', () {
      final result = service.interpolateAt(
        timeA: DateTime(2024, 1, 1),
        valueA: 100.0,
        timeB: DateTime(2024, 2, 1),
        valueB: 200.0,
        targetTime: DateTime(2024, 2, 1),
        method: InterpolationMethod.step,
      );

      expect(result, 100.0);
    });
  });

  group('getMonthlyBoundaries', () {
    test('standard case: 2 readings spanning 3 months', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 15), value: 100.0),
        (timestamp: DateTime(2024, 4, 15), value: 400.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 5, 1),
      );

      // Should get Feb 1, Mar 1, Apr 1 (not Jan 1—before first reading, not May 1—after last)
      expect(boundaries.length, 3);
      expect(boundaries[0].timestamp, DateTime(2024, 2, 1));
      expect(boundaries[1].timestamp, DateTime(2024, 3, 1));
      expect(boundaries[2].timestamp, DateTime(2024, 4, 1));
      expect(boundaries[0].isInterpolated, true);
      expect(boundaries[1].isInterpolated, true);
      expect(boundaries[2].isInterpolated, true);
    });

    test('exact boundary reading marked as not interpolated', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 1), value: 100.0),
        (timestamp: DateTime(2024, 3, 1), value: 300.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 3, 1),
      );

      expect(boundaries.length, 3);
      expect(boundaries[0].timestamp, DateTime(2024, 1, 1));
      expect(boundaries[0].value, 100.0);
      expect(boundaries[0].isInterpolated, false);
      expect(boundaries[1].timestamp, DateTime(2024, 2, 1));
      expect(boundaries[1].isInterpolated, true);
      expect(boundaries[2].timestamp, DateTime(2024, 3, 1));
      expect(boundaries[2].value, 300.0);
      expect(boundaries[2].isInterpolated, false);
    });

    test('no readings returns empty', () {
      final boundaries = service.getMonthlyBoundaries(
        readings: [],
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 6, 1),
      );

      expect(boundaries, isEmpty);
    });

    test('single reading on boundary returns it only', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 3, 1), value: 200.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 6, 1),
      );

      expect(boundaries.length, 1);
      expect(boundaries[0].value, 200.0);
      expect(boundaries[0].isInterpolated, false);
    });

    test('single reading not on boundary returns empty', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 3, 15), value: 200.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 6, 1),
      );

      expect(boundaries, isEmpty);
    });

    test('sparse data: 6-month gap', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 1), value: 100.0),
        (timestamp: DateTime(2024, 7, 1), value: 700.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 7, 1),
      );

      expect(boundaries.length, 7); // Jan-Jul inclusive
      expect(boundaries.first.value, 100.0);
      expect(boundaries.first.isInterpolated, false);
      expect(boundaries.last.value, 700.0);
      expect(boundaries.last.isInterpolated, false);
    });

    test('readings out of order get sorted first', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 4, 15), value: 400.0),
        (timestamp: DateTime(2024, 1, 15), value: 100.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 5, 1),
      );

      expect(boundaries.length, 3);
      expect(boundaries[0].timestamp, DateTime(2024, 2, 1));
    });

    test('duplicate timestamps keeps last value', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 15), value: 100.0),
        (timestamp: DateTime(2024, 1, 15), value: 150.0), // Corrected value
        (timestamp: DateTime(2024, 3, 15), value: 300.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 4, 1),
      );

      // Feb 1 should interpolate between 150 (corrected Jan 15) and 300 (Mar 15)
      expect(boundaries.length, 2); // Feb 1, Mar 1
      expect(boundaries[0].timestamp, DateTime(2024, 2, 1));
      // Feb 1 is 17 days after Jan 15, total span Jan 15 to Mar 15 = 60 days
      // fraction = 17/60; value = 150 + 17/60 * (300-150) = 150 + 42.5 = 192.5
      expect(boundaries[0].value, closeTo(150.0 + (17 / 60) * 150.0, 0.1));
    });

    test('no extrapolation past edges', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 3, 15), value: 300.0),
        (timestamp: DateTime(2024, 5, 15), value: 500.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 8, 1),
      );

      // Only Apr 1 and May 1 can be interpolated (between the two readings)
      expect(boundaries.length, 2);
      expect(boundaries[0].timestamp, DateTime(2024, 4, 1));
      expect(boundaries[1].timestamp, DateTime(2024, 5, 1));
    });

    test('step method returns previous value for boundaries', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 1), value: 100.0),
        (timestamp: DateTime(2024, 3, 1), value: 300.0),
      ];

      final boundaries = service.getMonthlyBoundaries(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 3, 1),
        method: InterpolationMethod.step,
      );

      expect(boundaries.length, 3);
      expect(boundaries[0].value, 100.0); // exact
      expect(boundaries[1].value, 100.0); // step: returns valueA
      expect(boundaries[2].value, 300.0); // exact
    });
  });

  group('getMonthlyConsumption', () {
    test('derives from boundaries correctly', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 1), value: 100.0),
        (timestamp: DateTime(2024, 4, 1), value: 400.0),
      ];

      final consumption = service.getMonthlyConsumption(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 4, 1),
      );

      expect(consumption.length, 3); // Jan→Feb, Feb→Mar, Mar→Apr
      expect(consumption[0].periodStart, DateTime(2024, 1, 1));
      expect(consumption[0].periodEnd, DateTime(2024, 2, 1));
      expect(consumption[2].periodEnd, DateTime(2024, 4, 1));

      // Total consumption should sum to 300
      final total =
          consumption.fold(0.0, (sum, c) => sum + c.consumption);
      expect(total, closeTo(300.0, 0.01));
    });

    test('empty readings returns empty result', () {
      final consumption = service.getMonthlyConsumption(
        readings: [],
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 6, 1),
      );

      expect(consumption, isEmpty);
    });

    test('single month consumption', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 1), value: 100.0),
        (timestamp: DateTime(2024, 2, 1), value: 150.0),
      ];

      final consumption = service.getMonthlyConsumption(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 2, 1),
      );

      expect(consumption.length, 1);
      expect(consumption[0].consumption, 50.0);
      expect(consumption[0].startInterpolated, false);
      expect(consumption[0].endInterpolated, false);
    });

    test('preserves interpolated flags', () {
      final readings = <ReadingPoint>[
        (timestamp: DateTime(2024, 1, 15), value: 100.0),
        (timestamp: DateTime(2024, 3, 15), value: 300.0),
      ];

      final consumption = service.getMonthlyConsumption(
        readings: readings,
        rangeStart: DateTime(2024, 1, 1),
        rangeEnd: DateTime(2024, 4, 1),
      );

      expect(consumption.length, 1); // Feb 1 → Mar 1
      expect(consumption[0].startInterpolated, true);
      expect(consumption[0].endInterpolated, true);
    });
  });
}
