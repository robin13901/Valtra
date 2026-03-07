import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/interpolation/models.dart';

void main() {
  group('MeterType', () {
    test('has exactly 4 values', () {
      expect(MeterType.values.length, 4);
    });

    test('contains electricity, gas, water, heating', () {
      expect(MeterType.values, contains(MeterType.electricity));
      expect(MeterType.values, contains(MeterType.gas));
      expect(MeterType.values, contains(MeterType.water));
      expect(MeterType.values, contains(MeterType.heating));
    });
  });

  group('MeterTypeSummary', () {
    test('constructs with required fields', () {
      final summary = MeterTypeSummary(
        meterType: MeterType.electricity,
        latestMonthConsumption: 350.5,
        hasInterpolation: true,
        unit: 'kWh',
      );

      expect(summary.meterType, MeterType.electricity);
      expect(summary.latestMonthConsumption, 350.5);
      expect(summary.hasInterpolation, true);
      expect(summary.unit, 'kWh');
    });

    test('allows null latestMonthConsumption for insufficient data', () {
      final summary = MeterTypeSummary(
        meterType: MeterType.gas,
        latestMonthConsumption: null,
        hasInterpolation: false,
        unit: 'm\u00B3',
      );

      expect(summary.latestMonthConsumption, isNull);
      expect(summary.hasInterpolation, false);
    });

    test('constructs for each meter type', () {
      for (final type in MeterType.values) {
        final summary = MeterTypeSummary(
          meterType: type,
          latestMonthConsumption: 100.0,
          hasInterpolation: false,
          unit: unitForMeterType(type),
        );
        expect(summary.meterType, type);
      }
    });
  });

  group('ChartDataPoint', () {
    test('constructs with required fields', () {
      final point = ChartDataPoint(
        timestamp: DateTime(2024, 6, 15),
        value: 42.0,
        isInterpolated: false,
      );

      expect(point.timestamp, DateTime(2024, 6, 15));
      expect(point.value, 42.0);
      expect(point.isInterpolated, false);
    });

    test('constructs interpolated data point', () {
      final point = ChartDataPoint(
        timestamp: DateTime(2024, 6, 10),
        value: 37.5,
        isInterpolated: true,
      );

      expect(point.isInterpolated, true);
      expect(point.value, 37.5);
    });
  });

  group('MonthlyAnalyticsData', () {
    test('constructs with required fields', () {
      final dailyValues = [
        ChartDataPoint(
          timestamp: DateTime(2024, 6, 1),
          value: 10.0,
          isInterpolated: false,
        ),
        ChartDataPoint(
          timestamp: DateTime(2024, 6, 15),
          value: 25.0,
          isInterpolated: true,
        ),
      ];

      final recentMonths = [
        PeriodConsumption(
          periodStart: DateTime(2024, 5, 1),
          periodEnd: DateTime(2024, 6, 1),
          startValue: 100.0,
          endValue: 150.0,
          consumption: 50.0,
          startInterpolated: false,
          endInterpolated: false,
        ),
      ];

      final data = MonthlyAnalyticsData(
        meterType: MeterType.electricity,
        month: DateTime(2024, 6, 1),
        dailyValues: dailyValues,
        recentMonths: recentMonths,
        totalConsumption: 75.0,
        unit: 'kWh',
      );

      expect(data.meterType, MeterType.electricity);
      expect(data.month, DateTime(2024, 6, 1));
      expect(data.dailyValues, hasLength(2));
      expect(data.recentMonths, hasLength(1));
      expect(data.totalConsumption, 75.0);
      expect(data.unit, 'kWh');
    });

    test('allows null totalConsumption', () {
      final data = MonthlyAnalyticsData(
        meterType: MeterType.water,
        month: DateTime(2024, 6, 1),
        dailyValues: [],
        recentMonths: [],
        totalConsumption: null,
        unit: 'm\u00B3',
      );

      expect(data.totalConsumption, isNull);
      expect(data.dailyValues, isEmpty);
      expect(data.recentMonths, isEmpty);
    });

    test('holds PeriodConsumption from interpolation models', () {
      final recentMonths = [
        PeriodConsumption(
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 2, 1),
          startValue: 1000.0,
          endValue: 1050.0,
          consumption: 50.0,
          startInterpolated: true,
          endInterpolated: false,
        ),
        PeriodConsumption(
          periodStart: DateTime(2024, 2, 1),
          periodEnd: DateTime(2024, 3, 1),
          startValue: 1050.0,
          endValue: 1120.0,
          consumption: 70.0,
          startInterpolated: false,
          endInterpolated: true,
        ),
      ];

      final data = MonthlyAnalyticsData(
        meterType: MeterType.gas,
        month: DateTime(2024, 3, 1),
        dailyValues: [],
        recentMonths: recentMonths,
        totalConsumption: 80.0,
        unit: 'm\u00B3',
      );

      expect(data.recentMonths, hasLength(2));
      expect(data.recentMonths[0].consumption, 50.0);
      expect(data.recentMonths[1].startInterpolated, false);
    });
  });

  group('unitForMeterType', () {
    test('returns kWh for electricity', () {
      expect(unitForMeterType(MeterType.electricity), 'kWh');
    });

    test('returns m\u00B3 for gas', () {
      expect(unitForMeterType(MeterType.gas), 'm\u00B3');
    });

    test('returns m\u00B3 for water', () {
      expect(unitForMeterType(MeterType.water), 'm\u00B3');
    });

    test('returns units for heating', () {
      expect(unitForMeterType(MeterType.heating), 'units');
    });
  });

  group('colorForMeterType', () {
    test('returns electricityColor for electricity', () {
      expect(colorForMeterType(MeterType.electricity), AppColors.electricityColor);
    });

    test('returns gasColor for gas', () {
      expect(colorForMeterType(MeterType.gas), AppColors.gasColor);
    });

    test('returns waterColor for water', () {
      expect(colorForMeterType(MeterType.water), AppColors.waterColor);
    });

    test('returns heatingColor for heating', () {
      expect(colorForMeterType(MeterType.heating), AppColors.heatingColor);
    });

    test('returns unique color for each meter type', () {
      final colors = MeterType.values.map(colorForMeterType).toSet();
      expect(colors.length, 4);
    });
  });

  group('iconForMeterType', () {
    test('returns electric_bolt for electricity', () {
      expect(iconForMeterType(MeterType.electricity), Icons.electric_bolt);
    });

    test('returns local_fire_department for gas', () {
      expect(iconForMeterType(MeterType.gas), Icons.local_fire_department);
    });

    test('returns water_drop for water', () {
      expect(iconForMeterType(MeterType.water), Icons.water_drop);
    });

    test('returns thermostat for heating', () {
      expect(iconForMeterType(MeterType.heating), Icons.thermostat);
    });

    test('returns unique icon for each meter type', () {
      final icons = MeterType.values.map(iconForMeterType).toSet();
      expect(icons.length, 4);
    });
  });
}
