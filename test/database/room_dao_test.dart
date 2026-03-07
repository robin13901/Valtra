import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/room_dao.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late RoomDao dao;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = RoomDao(database);

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));
  });

  tearDown(() async {
    await database.close();
  });

  group('RoomDao', () {
    test('insert and retrieve room', () async {
      final id = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Living Room',
      ));

      expect(id, isPositive);

      final room = await dao.getRoom(id);
      expect(room.householdId, householdId);
      expect(room.name, 'Living Room');
    });

    test('getRoomsForHousehold returns rooms ordered by name', () async {
      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Kitchen',
      ));
      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Bedroom',
      ));
      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Living Room',
      ));

      final rooms = await dao.getRoomsForHousehold(householdId);
      expect(rooms.length, 3);
      expect(rooms[0].name, 'Bedroom'); // Alphabetical order
      expect(rooms[1].name, 'Kitchen');
      expect(rooms[2].name, 'Living Room');
    });

    test('watchRoomsForHousehold emits on changes', () async {
      final stream = dao.watchRoomsForHousehold(householdId);

      final expectation = expectLater(
        stream,
        emitsInOrder([
          [], // Initial empty state
          hasLength(1), // After insert
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'New Room',
      ));

      await expectation;
    });

    test('updateRoom modifies existing record', () async {
      final id = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Original',
      ));

      final updated = await dao.updateRoom(RoomsCompanion(
        id: Value(id),
        name: const Value('Updated'),
      ));

      expect(updated, isTrue);

      final room = await dao.getRoom(id);
      expect(room.name, 'Updated');
    });

    test('updateRoom returns false for non-existent id', () async {
      final updated = await dao.updateRoom(const RoomsCompanion(
        id: Value(9999),
        name: Value('Nonexistent'),
      ));

      expect(updated, isFalse);
    });

    test('deleteRoom removes room and cascades to smart plugs', () async {
      // Create a room
      final roomId = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'To Delete',
      ));

      // Create smart plugs in the room
      final plugId1 = await database.into(database.smartPlugs).insert(
            SmartPlugsCompanion.insert(roomId: roomId, name: 'Plug 1'),
          );
      final plugId2 = await database.into(database.smartPlugs).insert(
            SmartPlugsCompanion.insert(roomId: roomId, name: 'Plug 2'),
          );

      // Create consumption entries
      await database.into(database.smartPlugConsumptions).insert(
            SmartPlugConsumptionsCompanion.insert(
              smartPlugId: plugId1,
              month: DateTime.now(),
              valueKwh: 10.0,
            ),
          );
      await database.into(database.smartPlugConsumptions).insert(
            SmartPlugConsumptionsCompanion.insert(
              smartPlugId: plugId2,
              month: DateTime.now(),
              valueKwh: 20.0,
            ),
          );

      // Delete the room (should cascade)
      await dao.deleteRoom(roomId);

      // Verify room is deleted
      final rooms = await dao.getRoomsForHousehold(householdId);
      expect(rooms, isEmpty);

      // Verify smart plugs are deleted
      final plugs = await database.select(database.smartPlugs).get();
      expect(plugs, isEmpty);

      // Verify consumption entries are deleted
      final consumptions =
          await database.select(database.smartPlugConsumptions).get();
      expect(consumptions, isEmpty);
    });

    test('rooms filtered by householdId', () async {
      // Create another household
      final otherHouseholdId = await database
          .into(database.households)
          .insert(HouseholdsCompanion.insert(name: 'Other Household'));

      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'My Room',
      ));
      await dao.insertRoom(RoomsCompanion.insert(
        householdId: otherHouseholdId,
        name: 'Other Room',
      ));

      final rooms = await dao.getRoomsForHousehold(householdId);
      expect(rooms.length, 1);
      expect(rooms[0].name, 'My Room');
    });

    test('roomHasSmartPlugs returns correct boolean', () async {
      final roomId = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Test Room',
      ));

      // Initially no plugs
      expect(await dao.roomHasSmartPlugs(roomId), isFalse);

      // Add a smart plug
      await database.into(database.smartPlugs).insert(
            SmartPlugsCompanion.insert(roomId: roomId, name: 'Test Plug'),
          );

      expect(await dao.roomHasSmartPlugs(roomId), isTrue);
    });

    test('getSmartPlugCount returns correct count', () async {
      final roomId = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Test Room',
      ));

      expect(await dao.getSmartPlugCount(roomId), 0);

      await database.into(database.smartPlugs).insert(
            SmartPlugsCompanion.insert(roomId: roomId, name: 'Plug 1'),
          );
      expect(await dao.getSmartPlugCount(roomId), 1);

      await database.into(database.smartPlugs).insert(
            SmartPlugsCompanion.insert(roomId: roomId, name: 'Plug 2'),
          );
      expect(await dao.getSmartPlugCount(roomId), 2);
    });
  });
}
