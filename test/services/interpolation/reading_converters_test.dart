import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/services/interpolation/reading_converters.dart';

void main() {
  group('Reading Converters', () {
    group('fromElectricityReadings', () {
      test('maps fields correctly', () {
        final readings = [
          ElectricityReading(
            id: 1,
            householdId: 1,
            timestamp: DateTime(2024, 1, 1),
            valueKwh: 100.0,
          ),
          ElectricityReading(
            id: 2,
            householdId: 1,
            timestamp: DateTime(2024, 2, 1),
            valueKwh: 200.0,
          ),
        ];

        final result = fromElectricityReadings(readings);

        expect(result.length, 2);
        expect(result[0].timestamp, DateTime(2024, 1, 1));
        expect(result[0].value, 100.0);
        expect(result[1].timestamp, DateTime(2024, 2, 1));
        expect(result[1].value, 200.0);
      });

      test('empty list returns empty', () {
        expect(fromElectricityReadings([]), isEmpty);
      });
    });

    group('fromGasReadings', () {
      test('maps fields correctly', () {
        final readings = [
          GasReading(
            id: 1,
            householdId: 1,
            timestamp: DateTime(2024, 1, 1),
            valueCubicMeters: 50.0,
          ),
        ];

        final result = fromGasReadings(readings);

        expect(result.length, 1);
        expect(result[0].timestamp, DateTime(2024, 1, 1));
        expect(result[0].value, 50.0);
      });

      test('empty list returns empty', () {
        expect(fromGasReadings([]), isEmpty);
      });
    });

    group('fromWaterReadings', () {
      test('maps fields correctly', () {
        final readings = [
          WaterReading(
            id: 1,
            waterMeterId: 1,
            timestamp: DateTime(2024, 1, 1),
            valueCubicMeters: 30.0,
          ),
        ];

        final result = fromWaterReadings(readings);

        expect(result.length, 1);
        expect(result[0].value, 30.0);
      });

      test('empty list returns empty', () {
        expect(fromWaterReadings([]), isEmpty);
      });
    });

    group('fromHeatingReadings', () {
      test('maps fields correctly', () {
        final readings = [
          HeatingReading(
            id: 1,
            heatingMeterId: 1,
            timestamp: DateTime(2024, 1, 1),
            value: 75.5,
          ),
        ];

        final result = fromHeatingReadings(readings);

        expect(result.length, 1);
        expect(result[0].value, 75.5);
      });

      test('empty list returns empty', () {
        expect(fromHeatingReadings([]), isEmpty);
      });
    });

    test('preserves order across all converters', () {
      final electricityReadings = [
        ElectricityReading(
            id: 1,
            householdId: 1,
            timestamp: DateTime(2024, 3, 1),
            valueKwh: 300.0),
        ElectricityReading(
            id: 2,
            householdId: 1,
            timestamp: DateTime(2024, 1, 1),
            valueKwh: 100.0),
      ];

      final result = fromElectricityReadings(electricityReadings);

      // Order should be preserved (not sorted)
      expect(result[0].value, 300.0);
      expect(result[1].value, 100.0);
    });
  });
}
