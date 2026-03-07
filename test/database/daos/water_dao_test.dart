import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/water_dao.dart';
import 'package:valtra/database/tables.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late WaterDao dao;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = WaterDao(database);

    // Create a household for testing
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));
  });

  tearDown(() async {
    await database.close();
  });

  group('WaterDao - Meter Methods', () {
    test('insert and retrieve meter', () async {
      final id = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Cold Water Main',
        type: WaterMeterType.cold,
      ));

      final meter = await dao.getMeter(id);

      expect(meter.id, id);
      expect(meter.householdId, householdId);
      expect(meter.name, 'Cold Water Main');
      expect(meter.type, WaterMeterType.cold);
    });

    test('getMetersForHousehold returns meters ordered by name', () async {
      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Z Meter',
        type: WaterMeterType.cold,
      ));
      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'A Meter',
        type: WaterMeterType.hot,
      ));
      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'M Meter',
        type: WaterMeterType.other,
      ));

      final meters = await dao.getMetersForHousehold(householdId);

      expect(meters.length, 3);
      expect(meters[0].name, 'A Meter');
      expect(meters[1].name, 'M Meter');
      expect(meters[2].name, 'Z Meter');
    });

    test('watchMetersForHousehold emits on changes', () async {
      final stream = dao.watchMetersForHousehold(householdId);

      final emissions = <List<WaterMeter>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'New Meter',
        type: WaterMeterType.cold,
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 1);
      expect(emissions.last.first.name, 'New Meter');
    });

    test('updateMeter modifies existing record', () async {
      final id = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Original Name',
        type: WaterMeterType.cold,
      ));

      final updated = await dao.updateMeter(WaterMetersCompanion(
        id: Value(id),
        name: const Value('Updated Name'),
        type: const Value(WaterMeterType.hot),
      ));

      expect(updated, true);

      final meter = await dao.getMeter(id);
      expect(meter.name, 'Updated Name');
      expect(meter.type, WaterMeterType.hot);
    });

    test('updateMeter throws without id', () async {
      expect(
        () => dao.updateMeter(const WaterMetersCompanion(
          name: Value('Test'),
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteMeter removes meter and cascades to readings', () async {
      final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Test Meter',
        type: WaterMeterType.cold,
      ));

      // Add some readings
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now(),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        valueCubicMeters: 110.0,
      ));

      final readingsBeforeDelete = await dao.getReadingsForMeter(meterId);
      expect(readingsBeforeDelete.length, 2);

      await dao.deleteMeter(meterId);

      final meters = await dao.getMetersForHousehold(householdId);
      expect(meters, isEmpty);

      // Readings should also be deleted
      final readingsAfterDelete = await dao.getReadingsForMeter(meterId);
      expect(readingsAfterDelete, isEmpty);
    });

    test('getReadingCountForMeter returns correct count', () async {
      final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Test Meter',
        type: WaterMeterType.cold,
      ));

      expect(await dao.getReadingCountForMeter(meterId), 0);

      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now(),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        valueCubicMeters: 110.0,
      ));

      expect(await dao.getReadingCountForMeter(meterId), 2);
    });
  });

  group('WaterDao - Reading Methods', () {
    late int meterId;

    setUp(() async {
      meterId = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Test Meter',
        type: WaterMeterType.cold,
      ));
    });

    test('insert and retrieve reading', () async {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final id = await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: timestamp,
        valueCubicMeters: 123.456,
      ));

      final reading = await dao.getReading(id);

      expect(reading.id, id);
      expect(reading.waterMeterId, meterId);
      expect(reading.timestamp, timestamp);
      expect(reading.valueCubicMeters, 123.456);
    });

    test('getReadingsForMeter returns readings ordered by timestamp desc', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        valueCubicMeters: 200.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        valueCubicMeters: 150.0,
      ));

      final readings = await dao.getReadingsForMeter(meterId);

      expect(readings.length, 3);
      expect(readings[0].valueCubicMeters, 200.0); // March
      expect(readings[1].valueCubicMeters, 150.0); // February
      expect(readings[2].valueCubicMeters, 100.0); // January
    });

    test('watchReadingsForMeter emits on changes', () async {
      final stream = dao.watchReadingsForMeter(meterId);

      final emissions = <List<WaterReading>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now(),
        valueCubicMeters: 100.0,
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 1);
    });

    test('updateReading modifies existing record', () async {
      final id = await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 15),
        valueCubicMeters: 100.0,
      ));

      final newTimestamp = DateTime(2024, 1, 20);
      final updated = await dao.updateReading(WaterReadingsCompanion(
        id: Value(id),
        timestamp: Value(newTimestamp),
        valueCubicMeters: const Value(150.0),
      ));

      expect(updated, true);

      final reading = await dao.getReading(id);
      expect(reading.timestamp, newTimestamp);
      expect(reading.valueCubicMeters, 150.0);
    });

    test('updateReading returns false for non-existent id', () async {
      final updated = await dao.updateReading(const WaterReadingsCompanion(
        id: Value(999),
        valueCubicMeters: Value(200.0),
      ));

      expect(updated, false);
    });

    test('updateReading throws without id', () async {
      expect(
        () => dao.updateReading(const WaterReadingsCompanion(
          valueCubicMeters: Value(100.0),
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteReading removes record', () async {
      final id = await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now(),
        valueCubicMeters: 100.0,
      ));

      await dao.deleteReading(id);

      final readings = await dao.getReadingsForMeter(meterId);
      expect(readings, isEmpty);
    });

    test('deleteReadingsForMeter removes all readings for meter', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now(),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        valueCubicMeters: 110.0,
      ));

      expect((await dao.getReadingsForMeter(meterId)).length, 2);

      await dao.deleteReadingsForMeter(meterId);

      expect((await dao.getReadingsForMeter(meterId)), isEmpty);
    });

    test('getPreviousReading returns correct reading', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        valueCubicMeters: 150.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        valueCubicMeters: 200.0,
      ));

      final previous = await dao.getPreviousReading(
        meterId,
        DateTime(2024, 2, 15),
      );

      expect(previous, isNotNull);
      expect(previous!.valueCubicMeters, 150.0);
    });

    test('getPreviousReading returns null when no previous exists', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        valueCubicMeters: 150.0,
      ));

      final previous = await dao.getPreviousReading(
        meterId,
        DateTime(2024, 1, 1), // Before any readings
      );

      expect(previous, isNull);
    });

    test('getLatestReading returns most recent reading', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        valueCubicMeters: 200.0,
      ));

      final latest = await dao.getLatestReading(meterId);

      expect(latest, isNotNull);
      expect(latest!.valueCubicMeters, 200.0);
    });

    test('getLatestReading returns null when no readings exist', () async {
      final latest = await dao.getLatestReading(meterId);

      expect(latest, isNull);
    });

    test('getNextReading returns correct reading', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        valueCubicMeters: 150.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        valueCubicMeters: 200.0,
      ));

      final next = await dao.getNextReading(
        meterId,
        DateTime(2024, 1, 15),
      );

      expect(next, isNotNull);
      expect(next!.valueCubicMeters, 150.0);
    });

    test('getNextReading returns null when no next exists', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      ));

      final next = await dao.getNextReading(
        meterId,
        DateTime(2024, 2, 1), // After all readings
      );

      expect(next, isNull);
    });
  });

  group('WaterDao - getReadingsForRange', () {
    late int meterId;

    setUp(() async {
      meterId = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Range Test Meter',
        type: WaterMeterType.cold,
      ));
    });

    test('returns readings inside range plus before and after', () async {
      // Before range
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      ));
      // Inside range
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 15),
        valueCubicMeters: 150.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 20),
        valueCubicMeters: 175.0,
      ));
      // After range
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 2, 15),
        valueCubicMeters: 250.0,
      ));

      final results = await dao.getReadingsForRange(
        meterId,
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 31),
      );

      expect(results.length, 4);
      expect(results[0].valueCubicMeters, 100.0); // before
      expect(results[1].valueCubicMeters, 150.0); // in-range
      expect(results[2].valueCubicMeters, 175.0); // in-range
      expect(results[3].valueCubicMeters, 250.0); // after
    });

    test('returns empty list when no readings exist', () async {
      final results = await dao.getReadingsForRange(
        meterId,
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 31),
      );

      expect(results, isEmpty);
    });

    test('returns only before reading when no in-range or after', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      ));

      final results = await dao.getReadingsForRange(
        meterId,
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 31),
      );

      expect(results.length, 1);
      expect(results[0].valueCubicMeters, 100.0);
    });

    test('includes reading on exact boundary', () async {
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 10),
        valueCubicMeters: 120.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(2024, 1, 31),
        valueCubicMeters: 180.0,
      ));

      final results = await dao.getReadingsForRange(
        meterId,
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 31),
      );

      expect(results.length, 2);
      expect(results[0].valueCubicMeters, 120.0);
      expect(results[1].valueCubicMeters, 180.0);
    });
  });

  group('WaterDao - Meter Isolation', () {
    test('readings are filtered by meter', () async {
      final meter1Id = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Meter 1',
        type: WaterMeterType.cold,
      ));
      final meter2Id = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Meter 2',
        type: WaterMeterType.hot,
      ));

      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meter1Id,
        timestamp: DateTime.now(),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meter2Id,
        timestamp: DateTime.now(),
        valueCubicMeters: 200.0,
      ));

      final meter1Readings = await dao.getReadingsForMeter(meter1Id);
      final meter2Readings = await dao.getReadingsForMeter(meter2Id);

      expect(meter1Readings.length, 1);
      expect(meter1Readings.first.valueCubicMeters, 100.0);
      expect(meter2Readings.length, 1);
      expect(meter2Readings.first.valueCubicMeters, 200.0);
    });

    test('meters are filtered by household', () async {
      final household2Id = await database
          .into(database.households)
          .insert(HouseholdsCompanion.insert(name: 'Household 2'));

      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Meter in H1',
        type: WaterMeterType.cold,
      ));
      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: household2Id,
        name: 'Meter in H2',
        type: WaterMeterType.hot,
      ));

      final h1Meters = await dao.getMetersForHousehold(householdId);
      final h2Meters = await dao.getMetersForHousehold(household2Id);

      expect(h1Meters.length, 1);
      expect(h1Meters.first.name, 'Meter in H1');
      expect(h2Meters.length, 1);
      expect(h2Meters.first.name, 'Meter in H2');
    });
  });
}
