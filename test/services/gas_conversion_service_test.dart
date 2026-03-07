import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/models.dart';

void main() {
  late GasConversionService service;

  setUp(() {
    service = GasConversionService();
  });

  group('GasConversionService', () {
    group('toKwh', () {
      test('converts with default factor (10.3)', () {
        expect(service.toKwh(1.0), 10.3);
        expect(service.toKwh(100.0), 1030.0);
      });

      test('converts with custom factor', () {
        expect(service.toKwh(100.0, factor: 11.0), 1100.0);
      });

      test('zero value returns zero', () {
        expect(service.toKwh(0.0), 0.0);
      });
    });

    group('toKwhConsumption', () {
      test('converts PeriodConsumption values to kWh', () {
        final period = PeriodConsumption(
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 2, 1),
          startValue: 10.0,
          endValue: 20.0,
          consumption: 10.0,
          startInterpolated: false,
          endInterpolated: true,
        );

        final result = service.toKwhConsumption(period);

        expect(result.startValue, 10.0 * 10.3);
        expect(result.endValue, 20.0 * 10.3);
        expect(result.consumption, 10.0 * 10.3);
      });

      test('preserves dates and interpolation flags', () {
        final period = PeriodConsumption(
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 2, 1),
          startValue: 10.0,
          endValue: 20.0,
          consumption: 10.0,
          startInterpolated: true,
          endInterpolated: false,
        );

        final result = service.toKwhConsumption(period);

        expect(result.periodStart, DateTime(2024, 1, 1));
        expect(result.periodEnd, DateTime(2024, 2, 1));
        expect(result.startInterpolated, true);
        expect(result.endInterpolated, false);
      });

      test('works with custom factor', () {
        final period = PeriodConsumption(
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 2, 1),
          startValue: 10.0,
          endValue: 20.0,
          consumption: 10.0,
          startInterpolated: false,
          endInterpolated: false,
        );

        final result = service.toKwhConsumption(period, factor: 11.0);

        expect(result.consumption, 110.0);
      });
    });

    group('toKwhConsumptions', () {
      test('converts a list of periods', () {
        final periods = [
          PeriodConsumption(
            periodStart: DateTime(2024, 1, 1),
            periodEnd: DateTime(2024, 2, 1),
            startValue: 10.0,
            endValue: 20.0,
            consumption: 10.0,
            startInterpolated: false,
            endInterpolated: true,
          ),
          PeriodConsumption(
            periodStart: DateTime(2024, 2, 1),
            periodEnd: DateTime(2024, 3, 1),
            startValue: 20.0,
            endValue: 35.0,
            consumption: 15.0,
            startInterpolated: true,
            endInterpolated: false,
          ),
        ];

        final results = service.toKwhConsumptions(periods);

        expect(results.length, 2);
        expect(results[0].consumption, 10.0 * 10.3);
        expect(results[1].consumption, 15.0 * 10.3);
      });

      test('empty list returns empty', () {
        expect(service.toKwhConsumptions([]), isEmpty);
      });
    });
  });
}
