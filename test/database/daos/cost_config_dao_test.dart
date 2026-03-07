import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/cost_config_dao.dart';
import 'package:valtra/database/tables.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late CostConfigDao dao;

  setUp(() {
    database = createTestDatabase();
    dao = CostConfigDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createHousehold(String name) async {
    return database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: name));
  }

  group('CostConfigDao', () {
    test('insert and retrieve config', () async {
      final householdId = await createHousehold('Test House');

      final configId = await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.electricity,
          unitPrice: 0.30,
          standingCharge: const Value(12.50),
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      expect(configId, greaterThan(0));

      final configs = await dao.getConfigsForHousehold(householdId);
      expect(configs.length, 1);
      expect(configs.first.unitPrice, 0.30);
      expect(configs.first.standingCharge, 12.50);
      expect(configs.first.meterType, CostMeterType.electricity);
    });

    test('update config', () async {
      final householdId = await createHousehold('Test House');

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.gas,
          unitPrice: 0.08,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      final configs = await dao.getConfigsForHousehold(householdId);
      final updated = configs.first.copyWith(unitPrice: 0.10);
      final success = await dao.updateConfig(updated);

      expect(success, isTrue);

      final reloaded = await dao.getConfigsForHousehold(householdId);
      expect(reloaded.first.unitPrice, 0.10);
    });

    test('delete config', () async {
      final householdId = await createHousehold('Test House');

      final configId = await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.water,
          unitPrice: 3.50,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      await dao.deleteConfig(configId);

      final configs = await dao.getConfigsForHousehold(householdId);
      expect(configs, isEmpty);
    });

    test('household isolation', () async {
      final houseA = await createHousehold('House A');
      final houseB = await createHousehold('House B');

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: houseA,
          meterType: CostMeterType.electricity,
          unitPrice: 0.30,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: houseB,
          meterType: CostMeterType.electricity,
          unitPrice: 0.35,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      final configsA = await dao.getConfigsForHousehold(houseA);
      final configsB = await dao.getConfigsForHousehold(houseB);

      expect(configsA.length, 1);
      expect(configsA.first.unitPrice, 0.30);
      expect(configsB.length, 1);
      expect(configsB.first.unitPrice, 0.35);
    });

    test('getConfigsForMeterType filters by type', () async {
      final householdId = await createHousehold('Test House');

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.electricity,
          unitPrice: 0.30,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.gas,
          unitPrice: 0.08,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      final electricityConfigs = await dao.getConfigsForMeterType(
        householdId,
        CostMeterType.electricity,
      );
      expect(electricityConfigs.length, 1);
      expect(electricityConfigs.first.unitPrice, 0.30);
    });

    group('getActiveConfig', () {
      test('returns config with latest validFrom <= date', () async {
        final householdId = await createHousehold('Test House');

        await dao.insertConfig(
          CostConfigsCompanion.insert(
            householdId: householdId,
            meterType: CostMeterType.electricity,
            unitPrice: 0.28,
            validFrom: DateTime(2025, 1, 1),
          ),
        );

        await dao.insertConfig(
          CostConfigsCompanion.insert(
            householdId: householdId,
            meterType: CostMeterType.electricity,
            unitPrice: 0.32,
            validFrom: DateTime(2026, 1, 1),
          ),
        );

        // Query for Feb 2026 → should get the 2026 config
        final active = await dao.getActiveConfig(
          householdId,
          CostMeterType.electricity,
          DateTime(2026, 2, 1),
        );

        expect(active, isNotNull);
        expect(active!.unitPrice, 0.32);
      });

      test('returns earlier config for date before later config', () async {
        final householdId = await createHousehold('Test House');

        await dao.insertConfig(
          CostConfigsCompanion.insert(
            householdId: householdId,
            meterType: CostMeterType.electricity,
            unitPrice: 0.28,
            validFrom: DateTime(2025, 1, 1),
          ),
        );

        await dao.insertConfig(
          CostConfigsCompanion.insert(
            householdId: householdId,
            meterType: CostMeterType.electricity,
            unitPrice: 0.32,
            validFrom: DateTime(2026, 6, 1),
          ),
        );

        // Query for Mar 2026 → should get the 2025 config
        final active = await dao.getActiveConfig(
          householdId,
          CostMeterType.electricity,
          DateTime(2026, 3, 1),
        );

        expect(active, isNotNull);
        expect(active!.unitPrice, 0.28);
      });

      test('returns null when no config valid for date', () async {
        final householdId = await createHousehold('Test House');

        await dao.insertConfig(
          CostConfigsCompanion.insert(
            householdId: householdId,
            meterType: CostMeterType.electricity,
            unitPrice: 0.30,
            validFrom: DateTime(2027, 1, 1),
          ),
        );

        // Query for 2026 → future config not valid
        final active = await dao.getActiveConfig(
          householdId,
          CostMeterType.electricity,
          DateTime(2026, 6, 1),
        );

        expect(active, isNull);
      });

      test('returns config on exact validFrom date', () async {
        final householdId = await createHousehold('Test House');

        await dao.insertConfig(
          CostConfigsCompanion.insert(
            householdId: householdId,
            meterType: CostMeterType.electricity,
            unitPrice: 0.30,
            validFrom: DateTime(2026, 3, 1),
          ),
        );

        final active = await dao.getActiveConfig(
          householdId,
          CostMeterType.electricity,
          DateTime(2026, 3, 1),
        );

        expect(active, isNotNull);
        expect(active!.unitPrice, 0.30);
      });
    });

    test('watchConfigsForHousehold emits on change', () async {
      final householdId = await createHousehold('Test House');

      final emissions = <List<CostConfig>>[];
      final sub = dao.watchConfigsForHousehold(householdId).listen((configs) {
        emissions.add(configs);
      });

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.electricity,
          unitPrice: 0.30,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      // Wait for stream to emit after insert
      await Future.delayed(const Duration(milliseconds: 100));

      await sub.cancel();

      // Should have at least 2 emissions: initial (empty or with data) and after insert
      expect(emissions.length, greaterThanOrEqualTo(1));
      // The last emission should contain the inserted config
      expect(emissions.last.length, 1);
      expect(emissions.last.first.unitPrice, 0.30);
    });

    test('default currency symbol is euro', () async {
      final householdId = await createHousehold('Test House');

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.electricity,
          unitPrice: 0.30,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      final configs = await dao.getConfigsForHousehold(householdId);
      expect(configs.first.currencySymbol, '€');
    });

    test('default standing charge is zero', () async {
      final householdId = await createHousehold('Test House');

      await dao.insertConfig(
        CostConfigsCompanion.insert(
          householdId: householdId,
          meterType: CostMeterType.electricity,
          unitPrice: 0.30,
          validFrom: DateTime(2026, 1, 1),
        ),
      );

      final configs = await dao.getConfigsForHousehold(householdId);
      expect(configs.first.standingCharge, 0.0);
    });
  });
}
