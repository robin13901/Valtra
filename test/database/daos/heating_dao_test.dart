import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/heating_dao.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late HeatingDao dao;
  late int householdId;
  late int roomId;

  setUp(() async {
    database = createTestDatabase();
    dao = HeatingDao(database);

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));

    roomId = await database
        .into(database.rooms)
        .insert(RoomsCompanion.insert(
          householdId: householdId,
          name: 'Living Room',
        ));
  });

  tearDown(() async {
    await database.close();
  });

  group('HeatingDao - Meter Methods', () {
    test('insert and retrieve meter with room', () async {
      final id = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      final meter = await dao.getMeter(id);

      expect(meter.id, id);
      expect(meter.householdId, householdId);
      expect(meter.roomId, roomId);
    });

    test('getMetersForHousehold returns meters ordered by id', () async {
      final id1 = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));
      final id2 = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));
      final id3 = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      final meters = await dao.getMetersForHousehold(householdId);

      expect(meters.length, 3);
      expect(meters[0].id, id1);
      expect(meters[1].id, id2);
      expect(meters[2].id, id3);
    });

    test('watchMetersForHousehold emits on changes', () async {
      final stream = dao.watchMetersForHousehold(householdId);

      final emissions = <List<HeatingMeter>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 1);
    });

    test('getMetersForRoom returns meters for specific room', () async {
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(
            householdId: householdId,
            name: 'Kitchen',
          ));

      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));
      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: room2Id,
      ));

      final livingRoomMeters = await dao.getMetersForRoom(roomId);
      final kitchenMeters = await dao.getMetersForRoom(room2Id);

      expect(livingRoomMeters.length, 1);
      expect(livingRoomMeters.first.roomId, roomId);
      expect(kitchenMeters.length, 1);
      expect(kitchenMeters.first.roomId, room2Id);
    });

    test('watchMetersForRoom emits on changes', () async {
      final stream = dao.watchMetersForRoom(roomId);

      final emissions = <List<HeatingMeter>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 1);
    });

    test('getRoomForMeter returns correct room', () async {
      final meterId = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      final room = await dao.getRoomForMeter(meterId);

      expect(room.id, roomId);
      expect(room.name, 'Living Room');
    });

    test('updateMeter modifies existing record', () async {
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(
            householdId: householdId,
            name: 'Bedroom',
          ));

      final id = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      final updated = await dao.updateMeter(HeatingMetersCompanion(
        id: Value(id),
        roomId: Value(room2Id),
      ));

      expect(updated, true);

      final meter = await dao.getMeter(id);
      expect(meter.roomId, room2Id);
    });

    test('updateMeter throws without id', () async {
      expect(
        () => dao.updateMeter(const HeatingMetersCompanion()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteMeter removes meter and cascades to readings', () async {
      final meterId = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now(),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        value: 110.0,
      ));

      final readingsBeforeDelete = await dao.getReadingsForMeter(meterId);
      expect(readingsBeforeDelete.length, 2);

      await dao.deleteMeter(meterId);

      final meters = await dao.getMetersForHousehold(householdId);
      expect(meters, isEmpty);

      final readingsAfterDelete = await dao.getReadingsForMeter(meterId);
      expect(readingsAfterDelete, isEmpty);
    });

    test('getReadingCountForMeter returns correct count', () async {
      final meterId = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      expect(await dao.getReadingCountForMeter(meterId), 0);

      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now(),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        value: 110.0,
      ));

      expect(await dao.getReadingCountForMeter(meterId), 2);
    });
  });

  group('HeatingDao - Reading Methods', () {
    late int meterId;

    setUp(() async {
      meterId = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));
    });

    test('insert and retrieve reading', () async {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final id = await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: timestamp,
        value: 1234.5,
      ));

      final reading = await dao.getReading(id);

      expect(reading.id, id);
      expect(reading.heatingMeterId, meterId);
      expect(reading.timestamp, timestamp);
      expect(reading.value, 1234.5);
    });

    test('getReadingsForMeter returns readings ordered by timestamp desc',
        () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        value: 200.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        value: 150.0,
      ));

      final readings = await dao.getReadingsForMeter(meterId);

      expect(readings.length, 3);
      expect(readings[0].value, 200.0);
      expect(readings[1].value, 150.0);
      expect(readings[2].value, 100.0);
    });

    test('watchReadingsForMeter emits on changes', () async {
      final stream = dao.watchReadingsForMeter(meterId);

      final emissions = <List<HeatingReading>>[];
      final subscription = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now(),
        value: 100.0,
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 1);
    });

    test('updateReading modifies existing record', () async {
      final id = await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 15),
        value: 100.0,
      ));

      final newTimestamp = DateTime(2024, 1, 20);
      final updated = await dao.updateReading(HeatingReadingsCompanion(
        id: Value(id),
        timestamp: Value(newTimestamp),
        value: const Value(150.0),
      ));

      expect(updated, true);

      final reading = await dao.getReading(id);
      expect(reading.timestamp, newTimestamp);
      expect(reading.value, 150.0);
    });

    test('updateReading returns false for non-existent id', () async {
      final updated = await dao.updateReading(const HeatingReadingsCompanion(
        id: Value(999),
        value: Value(200.0),
      ));

      expect(updated, false);
    });

    test('updateReading throws without id', () async {
      expect(
        () => dao.updateReading(const HeatingReadingsCompanion(
          value: Value(100.0),
        )),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deleteReading removes record', () async {
      final id = await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now(),
        value: 100.0,
      ));

      await dao.deleteReading(id);

      final readings = await dao.getReadingsForMeter(meterId);
      expect(readings, isEmpty);
    });

    test('deleteReadingsForMeter removes all readings for meter', () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now(),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        value: 110.0,
      ));

      expect((await dao.getReadingsForMeter(meterId)).length, 2);

      await dao.deleteReadingsForMeter(meterId);

      expect((await dao.getReadingsForMeter(meterId)), isEmpty);
    });

    test('getPreviousReading returns correct reading', () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        value: 150.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        value: 200.0,
      ));

      final previous = await dao.getPreviousReading(
        meterId,
        DateTime(2024, 2, 15),
      );

      expect(previous, isNotNull);
      expect(previous!.value, 150.0);
    });

    test('getPreviousReading returns null when no previous exists', () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        value: 150.0,
      ));

      final previous = await dao.getPreviousReading(
        meterId,
        DateTime(2024, 1, 1),
      );

      expect(previous, isNull);
    });

    test('getLatestReading returns most recent reading', () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        value: 200.0,
      ));

      final latest = await dao.getLatestReading(meterId);

      expect(latest, isNotNull);
      expect(latest!.value, 200.0);
    });

    test('getLatestReading returns null when no readings exist', () async {
      final latest = await dao.getLatestReading(meterId);

      expect(latest, isNull);
    });

    test('getNextReading returns correct reading', () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 2, 1),
        value: 150.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 3, 1),
        value: 200.0,
      ));

      final next = await dao.getNextReading(
        meterId,
        DateTime(2024, 1, 15),
      );

      expect(next, isNotNull);
      expect(next!.value, 150.0);
    });

    test('getNextReading returns null when no next exists', () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
      ));

      final next = await dao.getNextReading(
        meterId,
        DateTime(2024, 2, 1),
      );

      expect(next, isNull);
    });
  });

  group('HeatingDao - getReadingsForRange', () {
    late int meterId;

    setUp(() async {
      meterId = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));
    });

    test('returns readings inside range plus before and after', () async {
      // Before range
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
      ));
      // Inside range
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 15),
        value: 150.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 20),
        value: 175.0,
      ));
      // After range
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 2, 15),
        value: 250.0,
      ));

      final results = await dao.getReadingsForRange(
        meterId,
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 31),
      );

      expect(results.length, 4);
      expect(results[0].value, 100.0); // before
      expect(results[1].value, 150.0); // in-range
      expect(results[2].value, 175.0); // in-range
      expect(results[3].value, 250.0); // after
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
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 1),
        value: 100.0,
      ));

      final results = await dao.getReadingsForRange(
        meterId,
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 31),
      );

      expect(results.length, 1);
      expect(results[0].value, 100.0);
    });

    test('includes reading on exact boundary', () async {
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 10),
        value: 120.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meterId,
        timestamp: DateTime(2024, 1, 31),
        value: 180.0,
      ));

      final results = await dao.getReadingsForRange(
        meterId,
        DateTime(2024, 1, 10),
        DateTime(2024, 1, 31),
      );

      expect(results.length, 2);
      expect(results[0].value, 120.0);
      expect(results[1].value, 180.0);
    });
  });

  group('HeatingDao - Meter Isolation', () {
    test('readings are filtered by meter', () async {
      final meter1Id = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(
            householdId: householdId,
            name: 'Kitchen',
          ));
      final meter2Id = await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: room2Id,
      ));

      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meter1Id,
        timestamp: DateTime.now(),
        value: 100.0,
      ));
      await dao.insertReading(HeatingReadingsCompanion.insert(
        heatingMeterId: meter2Id,
        timestamp: DateTime.now(),
        value: 200.0,
      ));

      final meter1Readings = await dao.getReadingsForMeter(meter1Id);
      final meter2Readings = await dao.getReadingsForMeter(meter2Id);

      expect(meter1Readings.length, 1);
      expect(meter1Readings.first.value, 100.0);
      expect(meter2Readings.length, 1);
      expect(meter2Readings.first.value, 200.0);
    });

    test('meters are filtered by household', () async {
      final household2Id = await database
          .into(database.households)
          .insert(HouseholdsCompanion.insert(name: 'Household 2', personCount: 1));
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(
            householdId: household2Id,
            name: 'Other Room',
          ));

      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));
      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: household2Id,
        roomId: room2Id,
      ));

      final h1Meters = await dao.getMetersForHousehold(householdId);
      final h2Meters = await dao.getMetersForHousehold(household2Id);

      expect(h1Meters.length, 1);
      expect(h1Meters.first.householdId, householdId);
      expect(h2Meters.length, 1);
      expect(h2Meters.first.householdId, household2Id);
    });
  });
}
