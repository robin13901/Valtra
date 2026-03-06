import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/gas_dao.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late GasDao dao;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = GasDao(database);

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));
  });

  tearDown(() async {
    await database.close();
  });

  group('GasDao', () {
    test('insert and retrieve reading', () async {
      final timestamp = DateTime(2024, 3, 15, 10, 30);

      final id = await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: timestamp,
        valueCubicMeters: 1234.5,
      ));

      expect(id, isPositive);

      final reading = await dao.getReading(id);
      expect(reading.householdId, householdId);
      expect(reading.timestamp, timestamp);
      expect(reading.valueCubicMeters, 1234.5);
    });

    test('getReadingsForHousehold returns readings ordered by timestamp desc',
        () async {
      final now = DateTime.now();

      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now.subtract(const Duration(days: 2)),
        valueCubicMeters: 1000.0,
      ));
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now.subtract(const Duration(days: 1)),
        valueCubicMeters: 1100.0,
      ));
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now,
        valueCubicMeters: 1200.0,
      ));

      final readings = await dao.getReadingsForHousehold(householdId);
      expect(readings.length, 3);
      expect(readings[0].valueCubicMeters, 1200.0); // Newest first
      expect(readings[1].valueCubicMeters, 1100.0);
      expect(readings[2].valueCubicMeters, 1000.0);
    });

    test('watchReadingsForHousehold emits on changes', () async {
      final stream = dao.watchReadingsForHousehold(householdId);

      final expectation = expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty state
          hasLength(1), // After insert
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now(),
        valueCubicMeters: 1000.0,
      ));

      await expectation;
    });

    test('updateReading modifies existing record', () async {
      final id = await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime(2024, 3, 15),
        valueCubicMeters: 1000.0,
      ));

      final newTimestamp = DateTime(2024, 3, 16);
      final updated = await dao.updateReading(GasReadingsCompanion(
        id: Value(id),
        timestamp: Value(newTimestamp),
        valueCubicMeters: const Value(1100.0),
      ));

      expect(updated, isTrue);

      final reading = await dao.getReading(id);
      expect(reading.timestamp, newTimestamp);
      expect(reading.valueCubicMeters, 1100.0);
    });

    test('updateReading returns false for non-existent id', () async {
      final updated = await dao.updateReading(const GasReadingsCompanion(
        id: Value(9999),
        valueCubicMeters: Value(1000.0),
      ));

      expect(updated, isFalse);
    });

    test('deleteReading removes record', () async {
      final id = await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now(),
        valueCubicMeters: 1000.0,
      ));

      await dao.deleteReading(id);

      final readings = await dao.getReadingsForHousehold(householdId);
      expect(readings, isEmpty);
    });

    test('getPreviousReading returns correct reading', () async {
      final now = DateTime.now();

      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now.subtract(const Duration(days: 3)),
        valueCubicMeters: 1000.0,
      ));
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now.subtract(const Duration(days: 1)),
        valueCubicMeters: 1100.0,
      ));

      // Get reading before "now" - should return the 1100 reading
      final previous = await dao.getPreviousReading(householdId, now);
      expect(previous, isNotNull);
      expect(previous!.valueCubicMeters, 1100.0);

      // Get reading before the 1100 reading - should return the 1000 reading
      final earlier = await dao.getPreviousReading(
        householdId,
        now.subtract(const Duration(days: 1)),
      );
      expect(earlier, isNotNull);
      expect(earlier!.valueCubicMeters, 1000.0);
    });

    test('getPreviousReading returns null when no previous exists', () async {
      final now = DateTime.now();

      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now,
        valueCubicMeters: 1000.0,
      ));

      final previous = await dao.getPreviousReading(
        householdId,
        now.subtract(const Duration(days: 1)),
      );
      expect(previous, isNull);
    });

    test('getLatestReading returns most recent reading', () async {
      final now = DateTime.now();

      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now.subtract(const Duration(days: 2)),
        valueCubicMeters: 1000.0,
      ));
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now,
        valueCubicMeters: 1200.0,
      ));
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now.subtract(const Duration(days: 1)),
        valueCubicMeters: 1100.0,
      ));

      final latest = await dao.getLatestReading(householdId);
      expect(latest, isNotNull);
      expect(latest!.valueCubicMeters, 1200.0);
    });

    test('getLatestReading returns null when no readings exist', () async {
      final latest = await dao.getLatestReading(householdId);
      expect(latest, isNull);
    });

    test('readings are filtered by householdId', () async {
      // Create another household
      final otherHouseholdId = await database
          .into(database.households)
          .insert(HouseholdsCompanion.insert(name: 'Other Household'));

      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now(),
        valueCubicMeters: 1000.0,
      ));
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: otherHouseholdId,
        timestamp: DateTime.now(),
        valueCubicMeters: 2000.0,
      ));

      final readings = await dao.getReadingsForHousehold(householdId);
      expect(readings.length, 1);
      expect(readings[0].valueCubicMeters, 1000.0);
    });

    test('getNextReading returns correct reading', () async {
      final now = DateTime.now();

      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now.subtract(const Duration(days: 2)),
        valueCubicMeters: 1000.0,
      ));
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: now,
        valueCubicMeters: 1200.0,
      ));

      final next = await dao.getNextReading(
        householdId,
        now.subtract(const Duration(days: 2)),
      );
      expect(next, isNotNull);
      expect(next!.valueCubicMeters, 1200.0);
    });

    test('getNextReading returns null when no next exists', () async {
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now(),
        valueCubicMeters: 1000.0,
      ));

      final next = await dao.getNextReading(
        householdId,
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(next, isNull);
    });
  });
}
