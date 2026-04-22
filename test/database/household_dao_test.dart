import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/database/tables.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late HouseholdDao dao;

  setUp(() {
    database = createTestDatabase();
    dao = HouseholdDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('HouseholdDao', () {
    test('insert and retrieve household', () async {
      final id = await dao.insert(HouseholdsCompanion.insert(
        name: 'Test Household',
        description: const Value('A test description'),
        personCount: 1,
      ));

      expect(id, isPositive);

      final household = await dao.getHousehold(id);
      expect(household.name, 'Test Household');
      expect(household.description, 'A test description');
      expect(household.createdAt, isNotNull);
    });

    test('getAllHouseholds returns all households ordered by createdAt desc',
        () async {
      // Use explicit timestamps to ensure deterministic order
      final now = DateTime.now();
      await dao.insert(HouseholdsCompanion.insert(
        name: 'First',
        createdAt: Value(now.subtract(const Duration(minutes: 2))),
        personCount: 1,
      ));
      await dao.insert(HouseholdsCompanion.insert(
        name: 'Second',
        createdAt: Value(now.subtract(const Duration(minutes: 1))),
        personCount: 1,
      ));
      await dao.insert(HouseholdsCompanion.insert(
        name: 'Third',
        createdAt: Value(now),
        personCount: 1,
      ));

      final households = await dao.getAllHouseholds();
      expect(households.length, 3);
      expect(households[0].name, 'Third'); // Newest first
      expect(households[1].name, 'Second');
      expect(households[2].name, 'First');
    });

    test('watchAllHouseholds emits on changes', () async {
      final stream = dao.watchAllHouseholds();

      // Create expectation before inserting
      final expectation = expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty state
          hasLength(1), // After first insert
        ]),
      );

      // Allow stream to emit initial value
      await Future.delayed(const Duration(milliseconds: 50));

      // Insert household
      await dao.insert(HouseholdsCompanion.insert(name: 'Watched', personCount: 1));

      await expectation;
    });

    test('updateHousehold modifies existing record', () async {
      final id = await dao.insert(HouseholdsCompanion.insert(name: 'Original', personCount: 1));

      final updated = await dao.updateHousehold(HouseholdsCompanion(
        id: Value(id),
        name: const Value('Updated'),
        description: const Value('New description'),
      ));

      expect(updated, isTrue);

      final household = await dao.getHousehold(id);
      expect(household.name, 'Updated');
      expect(household.description, 'New description');
    });

    test('updateHousehold returns false for non-existent id', () async {
      final updated = await dao.updateHousehold(const HouseholdsCompanion(
        id: Value(9999),
        name: Value('Nonexistent'),
      ));

      expect(updated, isFalse);
    });

    test('deleteHousehold removes record', () async {
      final id = await dao.insert(HouseholdsCompanion.insert(name: 'ToDelete', personCount: 1));

      await dao.deleteHousehold(id);

      final households = await dao.getAllHouseholds();
      expect(households, isEmpty);
    });

    group('hasRelatedData', () {
      test('returns false when no related data', () async {
        final id =
            await dao.insert(HouseholdsCompanion.insert(name: 'Empty Household', personCount: 1));

        final hasData = await dao.hasRelatedData(id);
        expect(hasData, isFalse);
      });

      test('returns true when electricity readings exist', () async {
        final id = await dao
            .insert(HouseholdsCompanion.insert(name: 'With Electricity', personCount: 1));

        await database.into(database.electricityReadings).insert(
            ElectricityReadingsCompanion.insert(
                householdId: id, timestamp: DateTime.now(), valueKwh: 100.0));

        final hasData = await dao.hasRelatedData(id);
        expect(hasData, isTrue);
      });

      test('returns true when gas readings exist', () async {
        final id =
            await dao.insert(HouseholdsCompanion.insert(name: 'With Gas', personCount: 1));

        await database.into(database.gasReadings).insert(
            GasReadingsCompanion.insert(
                householdId: id,
                timestamp: DateTime.now(),
                valueCubicMeters: 50.0));

        final hasData = await dao.hasRelatedData(id);
        expect(hasData, isTrue);
      });

      test('returns true when water meters exist', () async {
        final id =
            await dao.insert(HouseholdsCompanion.insert(name: 'With Water', personCount: 1));

        await database.into(database.waterMeters).insert(
            WaterMetersCompanion.insert(
                householdId: id, name: 'Cold Water', type: WaterMeterType.cold));

        final hasData = await dao.hasRelatedData(id);
        expect(hasData, isTrue);
      });

      test('returns true when heating meters exist', () async {
        final id =
            await dao.insert(HouseholdsCompanion.insert(name: 'With Heating', personCount: 1));

        final roomId = await database.into(database.rooms).insert(
            RoomsCompanion.insert(householdId: id, name: 'Room 1'));

        await database.into(database.heatingMeters).insert(
            HeatingMetersCompanion.insert(householdId: id, roomId: roomId));

        final hasData = await dao.hasRelatedData(id);
        expect(hasData, isTrue);
      });

      test('returns true when rooms exist', () async {
        final id =
            await dao.insert(HouseholdsCompanion.insert(name: 'With Rooms', personCount: 1));

        await database.into(database.rooms).insert(
            RoomsCompanion.insert(householdId: id, name: 'Living Room'));

        final hasData = await dao.hasRelatedData(id);
        expect(hasData, isTrue);
      });

      test('returns true when cost configs exist', () async {
        final id = await dao
            .insert(HouseholdsCompanion.insert(name: 'With Cost Configs', personCount: 1));

        await database.into(database.costConfigs).insert(
            CostConfigsCompanion.insert(
          householdId: id,
          meterType: CostMeterType.electricity,
          unitPrice: 0.30,
          validFrom: DateTime(2024, 1, 1),
        ));

        final hasData = await dao.hasRelatedData(id);
        expect(hasData, isTrue);
      });
    });
  });
}
