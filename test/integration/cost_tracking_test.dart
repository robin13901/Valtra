import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/cost_config_dao.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/services/cost_calculation_service.dart';

import '../helpers/test_database.dart';

void main() {
  group('Cost Tracking Integration', () {
    late AppDatabase db;
    late HouseholdDao householdDao;
    late ElectricityDao electricityDao;
    late CostConfigDao costConfigDao;
    const costService = CostCalculationService();

    setUp(() async {
      db = createTestDatabase();
      householdDao = db.householdDao;
      electricityDao = db.electricityDao;
      costConfigDao = db.costConfigDao;
    });

    tearDown(() async {
      await db.close();
    });

    test('full flow: configure cost -> add readings -> calculate cost',
        () async {
      // 1. Create household
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Cost Test House', personCount: 1),
      );

      // 2. Add electricity cost config: 0.30 EUR/kWh, 12.50 EUR/month standing
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(12.50),
        currencySymbol: const Value('\u20AC'),
        validFrom: DateTime(2025, 1, 1),
      ));

      // 3. Add electricity readings: Jan 1 = 1000, Feb 1 = 1100 (delta = 100 kWh)
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

      // 4. Retrieve cost config and calculate
      final config = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.electricity,
        DateTime(2025, 1, 15),
      );
      expect(config, isNotNull);
      expect(config!.unitPrice, 0.30);
      expect(config.standingCharge, 12.50);

      // Calculate cost for 100 kWh over January (31 days)
      final result = costService.calculateMonthlyCost(
        consumption: 100.0,
        unitPrice: config.unitPrice,
        standingCharge: config.standingCharge,
        currencySymbol: config.currencySymbol,
        daysInPeriod: 31,
        daysInMonth: 31,
      );

      // 100 * 0.30 = 30.00 unit cost + 12.50 standing = 42.50 total
      expect(result.unitCost, closeTo(30.0, 0.01));
      expect(result.standingCost, closeTo(12.50, 0.01));
      expect(result.totalCost, closeTo(42.50, 0.01));
      expect(result.currencySymbol, '\u20AC');
    });

    test('tiered pricing calculates correctly', () async {
      // 1. Create household
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Tiered House', personCount: 1),
      );

      // 2. Configure tiered pricing via the service directly
      //    First 50 kWh at 0.25, rest at 0.35
      final tiers = [
        const PriceTier(limit: 50, rate: 0.25),
        const PriceTier(rate: 0.35),
      ];

      // Store config with tiered pricing JSON
      final tiersJson = costService.serializeTiers(tiers);
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.0, // ignored when tiers present
        standingCharge: const Value(0.0),
        priceTiers: Value(tiersJson),
        currencySymbol: const Value('\u20AC'),
        validFrom: DateTime(2025, 1, 1),
      ));

      // 3. Retrieve config and parse tiers
      final config = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.electricity,
        DateTime(2025, 1, 15),
      );
      expect(config, isNotNull);

      final parsedTiers = costService.parseTiers(config!.priceTiers);
      expect(parsedTiers.length, 2);

      // 4. Calculate cost for 100 kWh
      // Expected: 50 * 0.25 + 50 * 0.35 = 12.50 + 17.50 = 30.00
      final result = costService.calculateMonthlyCost(
        consumption: 100.0,
        unitPrice: 0.0,
        standingCharge: 0.0,
        currencySymbol: '\u20AC',
        tiers: parsedTiers,
      );

      expect(result.unitCost, closeTo(30.0, 0.01));
      expect(result.totalCost, closeTo(30.0, 0.01));
    });

    test('cost config with standing charge only', () async {
      // 1. Create household
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Standing Only House', personCount: 1),
      );

      // 2. Configure 0 unit price, 15.00 standing charge
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.0,
        standingCharge: const Value(15.0),
        currencySymbol: const Value('\u20AC'),
        validFrom: DateTime(2025, 1, 1),
      ));

      // 3. Calculate cost for any consumption
      final config = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.electricity,
        DateTime(2025, 1, 15),
      );
      expect(config, isNotNull);

      final result = costService.calculateMonthlyCost(
        consumption: 500.0, // Any amount
        unitPrice: config!.unitPrice,
        standingCharge: config.standingCharge,
        currencySymbol: config.currencySymbol,
        daysInPeriod: 30,
        daysInMonth: 30,
      );

      // 500 * 0.0 = 0 unit cost + 15.00 standing = 15.00 total
      expect(result.unitCost, closeTo(0.0, 0.01));
      expect(result.standingCost, closeTo(15.0, 0.01));
      expect(result.totalCost, closeTo(15.0, 0.01));
    });

    test('no cost config returns null cost', () async {
      // 1. Create household with readings but no cost config
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'No Config House', personCount: 1),
      );

      await electricityDao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2025, 1, 1),
        valueKwh: 1000.0,
      ));

      // 2. Try to get active config -- should be null
      final config = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.electricity,
        DateTime(2025, 1, 15),
      );
      expect(config, isNull);
    });

    test('cost config temporal validity', () async {
      // Create household
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Temporal House', personCount: 1),
      );

      // Add config valid from Jan 2025
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.25,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('\u20AC'),
        validFrom: DateTime(2025, 1, 1),
      ));

      // Add config valid from Jul 2025 (price increase)
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.35,
        standingCharge: const Value(12.0),
        currencySymbol: const Value('\u20AC'),
        validFrom: DateTime(2025, 7, 1),
      ));

      // Query before Jul: should get old price
      final configBefore = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.electricity,
        DateTime(2025, 3, 15),
      );
      expect(configBefore, isNotNull);
      expect(configBefore!.unitPrice, 0.25);

      // Query after Jul: should get new price
      final configAfter = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.electricity,
        DateTime(2025, 9, 1),
      );
      expect(configAfter, isNotNull);
      expect(configAfter!.unitPrice, 0.35);
    });

    test('multi-meter-type cost configs are isolated', () async {
      final householdId = await householdDao.insert(
        HouseholdsCompanion.insert(name: 'Multi-meter House', personCount: 1),
      );

      // Electricity config
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        validFrom: DateTime(2025, 1, 1),
      ));

      // Gas config (different price)
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.gas,
        unitPrice: 0.08,
        validFrom: DateTime(2025, 1, 1),
      ));

      // Water config
      await costConfigDao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.water,
        unitPrice: 2.50,
        validFrom: DateTime(2025, 1, 1),
      ));

      // Verify each meter type returns the correct config
      final elConfig = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.electricity,
        DateTime(2025, 6, 1),
      );
      final gasConfig = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.gas,
        DateTime(2025, 6, 1),
      );
      final waterConfig = await costConfigDao.getActiveConfig(
        householdId,
        CostMeterType.water,
        DateTime(2025, 6, 1),
      );

      expect(elConfig!.unitPrice, 0.30);
      expect(gasConfig!.unitPrice, 0.08);
      expect(waterConfig!.unitPrice, 2.50);
    });
  });
}
