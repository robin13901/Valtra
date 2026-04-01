import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/cost_config_dao.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/database/daos/gas_dao.dart';
import 'package:valtra/database/daos/heating_dao.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/database/daos/water_dao.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/services/cost_calculation_service.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';

import '../helpers/test_database.dart';

void main() {
  group('Reading to Analytics Integration', () {
    late AppDatabase db;
    late HouseholdDao householdDao;
    late ElectricityDao electricityDao;
    late GasDao gasDao;
    late WaterDao waterDao;
    late HeatingDao heatingDao;
    late CostConfigDao costConfigDao;
    late AnalyticsProvider analyticsProvider;
    late InterpolationSettingsProvider settingsProvider;
    late CostConfigProvider costConfigProvider;

    setUp(() async {
      db = createTestDatabase();
      householdDao = db.householdDao;
      electricityDao = db.electricityDao;
      gasDao = db.gasDao;
      waterDao = db.waterDao;
      heatingDao = db.heatingDao;
      costConfigDao = db.costConfigDao;

      settingsProvider = InterpolationSettingsProvider();
      costConfigProvider = CostConfigProvider(
        costConfigDao: costConfigDao,
        costCalculationService: const CostCalculationService(),
      );

      analyticsProvider = AnalyticsProvider(
        electricityDao: electricityDao,
        gasDao: gasDao,
        waterDao: waterDao,
        heatingDao: heatingDao,
        householdDao: householdDao,
        interpolationService: InterpolationService(),
        gasConversionService: GasConversionService(),
        settingsProvider: settingsProvider,
        costConfigProvider: costConfigProvider,
      );
    });

    tearDown(() async {
      analyticsProvider.dispose();
      costConfigProvider.dispose();
      await db.close();
    });

    test('full flow: add household -> add readings -> query analytics',
        () async {
      // 1. Create a household
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Test House', personCount: 1),
      );
      expect(householdId, greaterThan(0));

      // 2. Add 4 electricity readings spanning 3 months (need 4 boundaries
      //    for 3 deltas).
      //    Readings: Jan 1 = 1000, Feb 1 = 1100, Mar 1 = 1250, Apr 1 = 1500
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2025, 1, 1),
        valueKwh: 1000.0,
      ));
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2025, 2, 1),
        valueKwh: 1100.0,
      ));
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2025, 3, 1),
        valueKwh: 1250.0,
      ));
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2025, 4, 1),
        valueKwh: 1500.0,
      ));

      // 3. Verify readings were stored
      final readings =
          await electricityDao.getReadingsForHousehold(householdId);
      expect(readings.length, 4);

      // 4. Use InterpolationService directly to verify analytics calculation
      //    (AnalyticsProvider uses private _loadMonthlyData internally)
      final interpolationService = InterpolationService();
      final readingPoints = readings
          .map((r) => (timestamp: r.timestamp, value: r.valueKwh))
          .toList();

      final consumption = interpolationService.getMonthlyConsumption(
        readings: readingPoints,
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 4, 1),
      );

      // Jan->Feb delta: 1100 - 1000 = 100
      // Feb->Mar delta: 1250 - 1100 = 150
      // Mar->Apr delta: 1500 - 1250 = 250
      expect(consumption.length, 3);
      expect(consumption[0].consumption, closeTo(100.0, 0.01));
      expect(consumption[1].consumption, closeTo(150.0, 0.01));
      expect(consumption[2].consumption, closeTo(250.0, 0.01));

      // Verify total = 500
      final total =
          consumption.fold<double>(0, (sum, p) => sum + p.consumption);
      expect(total, closeTo(500.0, 0.01));
    });

    test('analytics handles empty readings gracefully', () async {
      // Create household with no readings
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Empty House', personCount: 1),
      );

      // Query readings -- should be empty
      final readings =
          await electricityDao.getReadingsForHousehold(householdId);
      expect(readings, isEmpty);

      // InterpolationService with empty readings returns empty
      final interpolationService = InterpolationService();
      final consumption = interpolationService.getMonthlyConsumption(
        readings: [],
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 12, 1),
      );
      expect(consumption, isEmpty);
    });

    test('multi-household isolation', () async {
      // Create two households
      final houseAId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'House A', personCount: 1),
      );
      final houseBId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'House B', personCount: 1),
      );

      // Add readings to House A
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: houseAId,
        timestamp: DateTime(2025, 1, 1),
        valueKwh: 1000.0,
      ));
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: houseAId,
        timestamp: DateTime(2025, 2, 1),
        valueKwh: 1200.0,
      ));

      // Add different readings to House B
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: houseBId,
        timestamp: DateTime(2025, 1, 1),
        valueKwh: 5000.0,
      ));
      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: houseBId,
        timestamp: DateTime(2025, 2, 1),
        valueKwh: 5500.0,
      ));

      // Verify House A readings only contain House A data
      final readingsA =
          await electricityDao.getReadingsForHousehold(houseAId);
      expect(readingsA.length, 2);
      expect(readingsA.every((r) => r.householdId == houseAId), isTrue);

      // Verify House B readings only contain House B data
      final readingsB =
          await electricityDao.getReadingsForHousehold(houseBId);
      expect(readingsB.length, 2);
      expect(readingsB.every((r) => r.householdId == houseBId), isTrue);

      // Verify consumption values are isolated
      final interpolationService = InterpolationService();

      final consumptionA = interpolationService.getMonthlyConsumption(
        readings:
            readingsA.map((r) => (timestamp: r.timestamp, value: r.valueKwh)).toList(),
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 2, 1),
      );

      final consumptionB = interpolationService.getMonthlyConsumption(
        readings:
            readingsB.map((r) => (timestamp: r.timestamp, value: r.valueKwh)).toList(),
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 2, 1),
      );

      // House A: 1200 - 1000 = 200
      expect(consumptionA.length, 1);
      expect(consumptionA[0].consumption, closeTo(200.0, 0.01));

      // House B: 5500 - 5000 = 500
      expect(consumptionB.length, 1);
      expect(consumptionB[0].consumption, closeTo(500.0, 0.01));
    });

    test('gas readings with interpolation produce correct monthly values',
        () async {
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Gas House', personCount: 1),
      );

      // Add gas readings: not exactly on month boundaries to test interpolation
      await gasDao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2025, 1, 15),
        valueCubicMeters: 100.0,
      ));
      await gasDao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2025, 3, 15),
        valueCubicMeters: 200.0,
      ));

      final readings = await gasDao.getReadingsForHousehold(householdId);
      expect(readings.length, 2);

      // Interpolation should produce boundary values at Feb 1 and Mar 1
      final interpolationService = InterpolationService();
      final readingPoints = readings
          .map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters))
          .toList();

      final boundaries = interpolationService.getMonthlyBoundaries(
        readings: readingPoints,
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 4, 1),
      );

      // Should have boundaries at Feb 1 and Mar 1 (within the range of readings)
      expect(boundaries.length, greaterThanOrEqualTo(2));
      // Feb 1 interpolated between Jan 15 (100) and Mar 15 (200)
      // Fraction: (Feb 1 - Jan 15) / (Mar 15 - Jan 15) = 17/59 ~ 0.288
      // Value: 100 + 0.288 * 100 ~ 128.8
      final feb = boundaries.firstWhere((b) => b.timestamp.month == 2);
      expect(feb.isInterpolated, isTrue);
      expect(feb.value, greaterThan(100.0));
      expect(feb.value, lessThan(200.0));
    });
  });
}
