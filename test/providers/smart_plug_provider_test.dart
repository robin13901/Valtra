import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/smart_plug_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/providers/smart_plug_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late SmartPlugDao dao;
  late SmartPlugProvider provider;
  late int householdId;
  late int roomId;

  setUp(() async {
    database = createTestDatabase();
    dao = SmartPlugDao(database);
    provider = SmartPlugProvider(dao);

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

    // Create a test room
    roomId = await database
        .into(database.rooms)
        .insert(RoomsCompanion.insert(householdId: householdId, name: 'Living Room'));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('SmartPlugProvider', () {
    test('plugs update when household changes', () async {
      // Add plugs
      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'TV Plug',
      ));

      // Set household ID
      provider.setHouseholdId(householdId);

      // Wait for stream to update
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.plugs.length, 1);
      expect(provider.plugs.first.plug.name, 'TV Plug');
      expect(provider.plugs.first.roomName, 'Living Room');
    });

    test('plugsByRoom groups correctly', () async {
      // Create another room
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(householdId: householdId, name: 'Kitchen'));

      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Living Room Plug',
      ));
      await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: room2Id,
        name: 'Kitchen Plug',
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      final byRoom = provider.plugsByRoom;
      expect(byRoom.keys.length, 2);
      expect(byRoom['Living Room']!.length, 1);
      expect(byRoom['Kitchen']!.length, 1);
    });

    test('addSmartPlug creates record', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final id = await provider.addSmartPlug('New Plug', roomId);

      expect(id, isPositive);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.plugs.length, 1);
      expect(provider.plugs.first.plug.name, 'New Plug');
    });

    test('updateSmartPlug modifies record', () async {
      final id = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Original',
      ));
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await provider.updateSmartPlug(id, 'Updated', roomId);

      expect(success, isTrue);
    });

    test('deleteSmartPlug removes record', () async {
      final id = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'To Delete',
      ));
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.deleteSmartPlug(id);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.plugs, isEmpty);
    });

    test('addConsumption creates record', () async {
      final plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Test Plug',
      ));

      final id = await provider.addConsumption(
        plugId,
        ConsumptionInterval.monthly,
        DateTime(2024, 3, 1),
        15.5,
      );

      expect(id, isPositive);

      final consumptions = await dao.getConsumptionsForPlug(plugId);
      expect(consumptions.length, 1);
      expect(consumptions.first.valueKwh, 15.5);
    });

    test('updateConsumption modifies record', () async {
      final plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Test Plug',
      ));
      final id = await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        intervalType: ConsumptionInterval.monthly,
        intervalStart: DateTime(2024, 3, 1),
        valueKwh: 10.0,
      ));

      final success = await provider.updateConsumption(
        id,
        ConsumptionInterval.daily,
        DateTime(2024, 3, 15),
        25.0,
      );

      expect(success, isTrue);

      final consumption = await dao.getConsumption(id);
      expect(consumption.valueKwh, 25.0);
      expect(consumption.intervalType, ConsumptionInterval.daily);
    });

    test('deleteConsumption removes record', () async {
      final plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Test Plug',
      ));
      final id = await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        intervalType: ConsumptionInterval.monthly,
        intervalStart: DateTime.now(),
        valueKwh: 10.0,
      ));

      await provider.deleteConsumption(id);

      final consumptions = await dao.getConsumptionsForPlug(plugId);
      expect(consumptions, isEmpty);
    });

    test('getLatestConsumptionForPlug returns most recent', () async {
      final plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Test Plug',
      ));

      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        intervalType: ConsumptionInterval.monthly,
        intervalStart: DateTime(2024, 3, 1),
        valueKwh: 10.0,
      ));
      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        intervalType: ConsumptionInterval.monthly,
        intervalStart: DateTime(2024, 4, 1),
        valueKwh: 20.0,
      ));

      final latest = await provider.getLatestConsumptionForPlug(plugId);

      expect(latest, isNotNull);
      expect(latest!.valueKwh, 20.0);
    });

    test('getConsumptionsForPlug with labels', () async {
      final plugId = await dao.insertSmartPlug(SmartPlugsCompanion.insert(
        roomId: roomId,
        name: 'Test Plug',
      ));

      await dao.insertConsumption(SmartPlugConsumptionsCompanion.insert(
        smartPlugId: plugId,
        intervalType: ConsumptionInterval.monthly,
        intervalStart: DateTime(2024, 3, 1),
        valueKwh: 15.0,
      ));

      String getIntervalName(ConsumptionInterval interval) {
        return interval.name;
      }

      final consumptions = await provider.getConsumptionsForPlug(
        plugId,
        getIntervalName,
      );

      expect(consumptions.length, 1);
      expect(consumptions.first.intervalLabel, contains('monthly'));
    });
  });
}
