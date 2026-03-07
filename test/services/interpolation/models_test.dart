import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/services/interpolation/models.dart';

void main() {
  group('TimestampedValue', () {
    test('constructs with required fields', () {
      final tv = TimestampedValue(
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
        isInterpolated: false,
      );

      expect(tv.timestamp, DateTime(2024, 1, 1));
      expect(tv.value, 100.0);
      expect(tv.isInterpolated, false);
    });

    test('equality works correctly', () {
      final a = TimestampedValue(
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
        isInterpolated: true,
      );
      final b = TimestampedValue(
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
        isInterpolated: true,
      );
      final c = TimestampedValue(
        timestamp: DateTime(2024, 2, 1),
        value: 100.0,
        isInterpolated: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('toString returns descriptive string', () {
      final tv = TimestampedValue(
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
        isInterpolated: true,
      );

      expect(tv.toString(), contains('TimestampedValue'));
      expect(tv.toString(), contains('100.0'));
      expect(tv.toString(), contains('true'));
    });
  });

  group('PeriodConsumption', () {
    test('constructs with required fields', () {
      final pc = PeriodConsumption(
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 2, 1),
        startValue: 100.0,
        endValue: 150.0,
        consumption: 50.0,
        startInterpolated: false,
        endInterpolated: true,
      );

      expect(pc.periodStart, DateTime(2024, 1, 1));
      expect(pc.periodEnd, DateTime(2024, 2, 1));
      expect(pc.startValue, 100.0);
      expect(pc.endValue, 150.0);
      expect(pc.consumption, 50.0);
      expect(pc.startInterpolated, false);
      expect(pc.endInterpolated, true);
    });

    test('equality works correctly', () {
      final a = PeriodConsumption(
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 2, 1),
        startValue: 100.0,
        endValue: 150.0,
        consumption: 50.0,
        startInterpolated: false,
        endInterpolated: true,
      );
      final b = PeriodConsumption(
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 2, 1),
        startValue: 100.0,
        endValue: 150.0,
        consumption: 50.0,
        startInterpolated: false,
        endInterpolated: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toString returns descriptive string', () {
      final pc = PeriodConsumption(
        periodStart: DateTime(2024, 1, 1),
        periodEnd: DateTime(2024, 2, 1),
        startValue: 100.0,
        endValue: 150.0,
        consumption: 50.0,
        startInterpolated: false,
        endInterpolated: true,
      );

      expect(pc.toString(), contains('PeriodConsumption'));
      expect(pc.toString(), contains('50.0'));
    });
  });

  group('InterpolationMethod', () {
    test('has linear and step values', () {
      expect(InterpolationMethod.values, contains(InterpolationMethod.linear));
      expect(InterpolationMethod.values, contains(InterpolationMethod.step));
      expect(InterpolationMethod.values.length, 2);
    });
  });
}
