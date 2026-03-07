import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/smart_plug_dao.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late SmartPlugDao dao;
  late int householdId;
  late int roomId;

  setUp(() async {
    database = createTestDatabase();
    dao = SmartPlugDao(database);

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

    // Create a test room
    roomId = await database
        .into(database.rooms)
        .insert(RoomsCompanion.insert(householdId: householdId, name: 'Test Room'));
  });

  tearDown(() async {
    await database.close();
  });

  group('SmartPlugDao - Smart Plug Methods', () {
    test('insert and retrieve smart plug', () async {
      final id = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'TV Plug',
      ));

      expect(id, isPositive);

      final plug = await dao.getSmartPlug(id);
      expect(plug.roomId, roomId);
      expect(plug.name, 'TV Plug');
    });

    test('getSmartPlugsForRoom returns plugs ordered by name', () async {
      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Lamp Plug',
      ));
      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'TV Plug',
      ));
      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Computer Plug',
      ));

      final plugs = await dao.getSmartPlugsForRoom(roomId);
      expect(plugs.length, 3);
      expect(plugs[0].name, 'Computer Plug'); // Alphabetical
      expect(plugs[1].name, 'Lamp Plug');
      expect(plugs[2].name, 'TV Plug');
    });

    test('watchSmartPlugsForRoom emits on changes', () async {
      final stream = dao.watchSmartPlugsForRoom(roomId);

      final expectation = expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty state
          hasLength(1), // After insert
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'New Plug',
      ));

      await expectation;
    });

    test('getSmartPlugsForHousehold returns all plugs via room join', () async {
      // Create another room
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(householdId: householdId, name: 'Room 2'));

      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Plug 1',
      ));
      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: room2Id,
        name: 'Plug 2',
      ));

      final plugs = await dao.getSmartPlugsForHousehold(householdId);
      expect(plugs.length, 2);
    });

    test('updateSmartPlug modifies existing record', () async {
      final id = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Original',
      ));

      final updated = await dao.updateSmartPlug(SmartPlugsCompanion(
        id: Value(id),
        name: const Value('Updated'),
      ));

      expect(updated, isTrue);

      final plug = await dao.getSmartPlug(id);
      expect(plug.name, 'Updated');
    });

    test('deleteSmartPlug removes plug and cascades to consumption', () async {
      final plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'To Delete',
      ));

      // Add consumption entries
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 3, 1),
        valueKwh: 10.0,
      ));

      await dao.deleteSmartPlug(plugId);

      // Verify plug is deleted
      final plugs = await dao.getSmartPlugsForRoom(roomId);
      expect(plugs, isEmpty);

      // Verify consumption is deleted
      final consumptions = await dao.getConsumptionsForPlug(plugId);
      expect(consumptions, isEmpty);
    });

    test('getRoomForSmartPlug returns correct room', () async {
      final plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Test Plug',
      ));

      final room = await dao.getRoomForSmartPlug(plugId);
      expect(room.id, roomId);
      expect(room.name, 'Test Room');
    });
  });

  group('SmartPlugDao - Consumption Methods', () {
    late int plugId;

    setUp(() async {
      plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Test Plug',
      ));
    });

    test('insert and retrieve consumption', () async {
      final month = DateTime(2024, 3, 1);
      final id = await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: month,
        valueKwh: 15.5,
      ));

      expect(id, isPositive);

      final consumption = await dao.getConsumption(id);
      expect(consumption.smartPlugId, plugId);
      expect(consumption.month, month);
      expect(consumption.valueKwh, 15.5);
    });

    test('getConsumptionsForPlug returns entries ordered by month desc', () async {
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 1, 1),
        valueKwh: 10.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 2, 1),
        valueKwh: 15.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 3, 1),
        valueKwh: 20.0,
      ));

      final consumptions = await dao.getConsumptionsForPlug(plugId);
      expect(consumptions.length, 3);
      expect(consumptions[0].valueKwh, 20.0); // Newest first (March)
      expect(consumptions[1].valueKwh, 15.0); // February
      expect(consumptions[2].valueKwh, 10.0); // January
    });

    test('watchConsumptionsForPlug emits on changes', () async {
      final stream = dao.watchConsumptionsForPlug(plugId);

      final expectation = expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty state
          hasLength(1), // After insert
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 3, 1),
        valueKwh: 5.0,
      ));

      await expectation;
    });

    test('updateConsumption modifies existing record', () async {
      final id = await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 3, 1),
        valueKwh: 10.0,
      ));

      final updated = await dao.updateConsumption(SmartPlugConsumptionsCompanion(
        id: Value(id),
        valueKwh: const Value(25.0),
      ));

      expect(updated, isTrue);

      final consumption = await dao.getConsumption(id);
      expect(consumption.valueKwh, 25.0);
    });

    test('deleteConsumption removes entry', () async {
      final id = await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 3, 1),
        valueKwh: 10.0,
      ));

      await dao.deleteConsumption(id);

      final consumptions = await dao.getConsumptionsForPlug(plugId);
      expect(consumptions, isEmpty);
    });

    test('getLatestConsumptionForPlug returns most recent entry', () async {
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 2, 1),
        valueKwh: 10.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 3, 1),
        valueKwh: 20.0,
      ));

      final latest = await dao.getLatestConsumptionForPlug(plugId);
      expect(latest, isNotNull);
      expect(latest!.valueKwh, 20.0);
    });

    test('getLatestConsumptionForPlug returns null when no entries', () async {
      final latest = await dao.getLatestConsumptionForPlug(plugId);
      expect(latest, isNull);
    });

    test('getConsumptionForMonth returns entry for given month', () async {
      final month = DateTime(2024, 3, 1);
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: month,
        valueKwh: 15.0,
      ));

      final result = await dao.getConsumptionForMonth(plugId, month);
      expect(result, isNotNull);
      expect(result!.valueKwh, 15.0);
    });

    test('getConsumptionForMonth returns null for non-existent month', () async {
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        month: DateTime(2024, 3, 1),
        valueKwh: 15.0,
      ));

      final result = await dao.getConsumptionForMonth(plugId, DateTime(2024, 4, 1));
      expect(result, isNull);
    });
  });

  group('SmartPlugDao - Aggregation Methods', () {
    late int plugId1;
    late int plugId2;
    late int room2Id;

    setUp(() async {
      plugId1 = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Plug 1',
      ));

      room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(householdId: householdId, name: 'Room 2'));

      plugId2 = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: room2Id,
        name: 'Plug 2',
      ));
    });

    test('getTotalConsumptionForPlug calculates sum in date range', () async {
      final march1 = DateTime(2024, 3, 1);
      final march15 = DateTime(2024, 3, 15);
      final april1 = DateTime(2024, 4, 1);

      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId1,
        month: march1,
        valueKwh: 10.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId1,
        month: march15,
        valueKwh: 15.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId1,
        month: april1,
        valueKwh: 20.0, // Outside range
      ));

      final total = await dao.getTotalConsumptionForPlug(
        plugId1,
        march1,
        april1,
      );
      expect(total, 25.0); // 10 + 15
    });

    test('getTotalConsumptionForRoom calculates sum for all plugs in room', () async {
      // Add another plug to the first room
      final plugId3 = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Plug 3',
      ));

      final march1 = DateTime(2024, 3, 1);
      final april1 = DateTime(2024, 4, 1);

      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId1,
        month: march1,
        valueKwh: 10.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId3,
        month: march1,
        valueKwh: 20.0,
      ));
      // Plug 2 is in a different room
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId2,
        month: march1,
        valueKwh: 100.0, // Should not be counted
      ));

      final total = await dao.getTotalConsumptionForRoom(
        roomId,
        march1,
        april1,
      );
      expect(total, 30.0); // 10 + 20
    });

    test('getTotalSmartPlugConsumption calculates sum for entire household', () async {
      final march1 = DateTime(2024, 3, 1);
      final april1 = DateTime(2024, 4, 1);

      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId1,
        month: march1,
        valueKwh: 10.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId2,
        month: march1,
        valueKwh: 20.0,
      ));

      final total = await dao.getTotalSmartPlugConsumption(
        householdId,
        march1,
        april1,
      );
      expect(total, 30.0); // 10 + 20
    });

    test('aggregation returns 0 when no consumption entries', () async {
      final total = await dao.getTotalConsumptionForPlug(
        plugId1,
        DateTime(2024, 1, 1),
        DateTime(2024, 12, 31),
      );
      expect(total, 0.0);
    });
  });
}
