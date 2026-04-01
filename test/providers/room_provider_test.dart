import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/room_dao.dart';
import 'package:valtra/providers/room_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late RoomDao dao;
  late RoomProvider provider;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = RoomDao(database);
    provider = RoomProvider(dao);

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('RoomProvider', () {
    test('rooms update when household changes', () async {
      // Initially no household
      expect(provider.rooms, isEmpty);

      // Add rooms to the household
      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Living Room',
      ));
      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Kitchen',
      ));

      // Set household ID
      provider.setHouseholdId(householdId);

      // Wait for stream to update
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.rooms.length, 2);
    });

    test('rooms cleared when household set to null', () async {
      // Add room and set household
      await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Test Room',
      ));
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.rooms.length, 1);

      // Clear household
      provider.setHouseholdId(null);

      expect(provider.rooms, isEmpty);
    });

    test('addRoom creates record', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final id = await provider.addRoom('New Room');

      expect(id, isPositive);

      // Wait for stream update
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.rooms.length, 1);
      expect(provider.rooms.first.name, 'New Room');
    });

    test('addRoom throws when no household selected', () async {
      expect(() => provider.addRoom('Test'), throwsStateError);
    });

    test('updateRoom modifies record', () async {
      provider.setHouseholdId(householdId);
      final id = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Original',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await provider.updateRoom(id, 'Updated');

      expect(success, isTrue);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.rooms.first.name, 'Updated');
    });

    test('deleteRoom removes record', () async {
      provider.setHouseholdId(householdId);
      final id = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'To Delete',
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.rooms.length, 1);

      await provider.deleteRoom(id);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.rooms, isEmpty);
    });

    test('canDeleteRoom returns true when no plugs', () async {
      final id = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Empty Room',
      ));

      final canDelete = await provider.canDeleteRoom(id);
      expect(canDelete, isTrue);
    });

    test('canDeleteRoom returns false when has plugs', () async {
      final id = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Room with Plugs',
      ));

      await database.into(database.smartPlugs).insert(
            SmartPlugsCompanion.insert(roomId: id, name: 'Test Plug'),
          );

      final canDelete = await provider.canDeleteRoom(id);
      expect(canDelete, isFalse);
    });

    test('getSmartPlugCount returns correct count', () async {
      final id = await dao.insertRoom(RoomsCompanion.insert(
        householdId: householdId,
        name: 'Test Room',
      ));

      expect(await provider.getSmartPlugCount(id), 0);

      await database.into(database.smartPlugs).insert(
            SmartPlugsCompanion.insert(roomId: id, name: 'Plug 1'),
          );

      expect(await provider.getSmartPlugCount(id), 1);
    });
  });
}
