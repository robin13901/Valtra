import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/cost_config_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/services/cost_calculation_service.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late CostConfigDao dao;
  late CostConfigProvider provider;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = CostConfigDao(database);
    provider = CostConfigProvider(
      costConfigDao: dao,
      costCalculationService: const CostCalculationService(),
    );

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('CostConfigProvider', () {
    test('initial state has no configs', () {
      expect(provider.configs, isEmpty);
      expect(provider.hasCostConfigs, false);
      expect(provider.householdId, isNull);
    });

    test('setHouseholdId updates householdId getter', () {
      provider.setHouseholdId(householdId);
      expect(provider.householdId, householdId);
    });

    test('setHouseholdId to null clears configs', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setHouseholdId(null);
      expect(provider.configs, isEmpty);
      expect(provider.hasCostConfigs, false);
    });

    test('configs update when household is set and data exists', () async {
      // Insert a config before setting household
      await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.configs.length, 1);
      expect(provider.hasCostConfigs, true);
    });

    test('getActiveConfig returns matching config', () async {
      await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      final config = provider.getActiveConfig(
        CostMeterType.electricity,
        DateTime(2024, 6, 1),
      );
      expect(config, isNotNull);
      expect(config!.unitPrice, 0.30);
    });

    test('getActiveConfig returns null for no matching config', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final config = provider.getActiveConfig(
        CostMeterType.electricity,
        DateTime(2024, 6, 1),
      );
      expect(config, isNull);
    });

    test('getActiveConfig returns null for future validFrom', () async {
      await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2025, 1, 1),
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      final config = provider.getActiveConfig(
        CostMeterType.electricity,
        DateTime(2024, 6, 1),
      );
      expect(config, isNull);
    });

    test('getConfigsForMeterType filters by type', () async {
      await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));
      await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.gas,
        unitPrice: 0.08,
        standingCharge: const Value(5.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      final elecConfigs =
          provider.getConfigsForMeterType(CostMeterType.electricity);
      expect(elecConfigs.length, 1);
      expect(elecConfigs[0].unitPrice, 0.30);

      final gasConfigs = provider.getConfigsForMeterType(CostMeterType.gas);
      expect(gasConfigs.length, 1);
      expect(gasConfigs[0].unitPrice, 0.08);
    });

    test('calculateCost returns result when config exists', () async {
      await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      final result = provider.calculateCost(
        meterType: CostMeterType.electricity,
        consumption: 100.0,
        periodStart: DateTime(2024, 3, 1),
        periodEnd: DateTime(2024, 4, 1),
      );

      expect(result, isNotNull);
      expect(result!.totalCost, greaterThan(0));
    });

    test('calculateCost returns null when no config exists', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final result = provider.calculateCost(
        meterType: CostMeterType.electricity,
        consumption: 100.0,
        periodStart: DateTime(2024, 3, 1),
        periodEnd: DateTime(2024, 4, 1),
      );

      expect(result, isNull);
    });

    test('addConfig inserts config to database', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final id = await provider.addConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(id, greaterThan(0));
      expect(provider.configs.length, 1);
    });

    test('updateConfig modifies existing config', () async {
      final id = await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      final config = provider.configs.first;
      final updated = config.copyWith(unitPrice: 0.40);
      final success = await provider.updateConfig(updated);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(success, true);
      expect(provider.configs.first.unitPrice, 0.40);
    });

    test('deleteConfig removes config', () async {
      final id = await dao.insertConfig(CostConfigsCompanion.insert(
        householdId: householdId,
        meterType: CostMeterType.electricity,
        unitPrice: 0.30,
        standingCharge: const Value(10.0),
        currencySymbol: const Value('EUR'),
        validFrom: DateTime(2024, 1, 1),
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.configs.length, 1);

      await provider.deleteConfig(id);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.configs, isEmpty);
    });

    test('dispose cancels subscription', () {
      final localProvider = CostConfigProvider(
        costConfigDao: dao,
        costCalculationService: const CostCalculationService(),
      );
      localProvider.setHouseholdId(householdId);
      // Should not throw
      localProvider.dispose();
    });
  });
}
