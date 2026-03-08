import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/smart_plug_dao.dart';
import 'package:valtra/providers/smart_plug_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late SmartPlugDao dao;
  late SmartPlugProvider provider;
  late int householdId;
  late int roomId;

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  setUp(() async {
    database = createTestDatabase();
    dao = SmartPlugDao(database);
    provider = SmartPlugProvider(dao);

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

    roomId = await database.into(database.rooms).insert(
        RoomsCompanion.insert(householdId: householdId, name: 'Living Room'));
  });

  tearDown(() async {
    provider.setHouseholdId(null);
    await Future.delayed(const Duration(milliseconds: 50));
    provider.dispose();
    await database.close();
  });

  group('SmartPlugProvider - coverage gaps', () {
    test('plugsByRoom groups plugs by room name', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addSmartPlug('Plug A', roomId);
      await provider.addSmartPlug('Plug B', roomId);

      final room2Id = await database.into(database.rooms).insert(
          RoomsCompanion.insert(householdId: householdId, name: 'Kitchen'));
      await provider.addSmartPlug('Plug C', room2Id);
      await Future.delayed(const Duration(milliseconds: 200));

      final byRoom = provider.plugsByRoom;
      expect(byRoom.keys, contains('Living Room'));
      expect(byRoom.keys, contains('Kitchen'));
      expect(byRoom['Living Room']!.length, 2);
      expect(byRoom['Kitchen']!.length, 1);
    });

    test('setHouseholdId null clears plugs', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addSmartPlug('Test', roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.plugs, isNotEmpty);

      provider.setHouseholdId(null);
      expect(provider.plugs, isEmpty);
    });

    test('setHouseholdId with same ID does nothing', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setHouseholdId(householdId);
      expect(provider.householdId, householdId);
    });

    test('getConsumptionsForPlug returns labeled entries', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);
      await provider.addConsumption(plugId, DateTime(2024, 3, 1), 45.5);
      await Future.delayed(const Duration(milliseconds: 50));

      final consumptions =
          await provider.getConsumptionsForPlug(plugId, 'en');
      expect(consumptions.length, 1);
      expect(consumptions[0].intervalLabel, contains('March'));
      expect(consumptions[0].consumption.valueKwh, 45.5);
    });

    test('addConsumption returns -1 for duplicate month', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);
      await provider.addConsumption(plugId, DateTime(2024, 3, 1), 45.5);

      final result =
          await provider.addConsumption(plugId, DateTime(2024, 3, 1), 50.0);
      expect(result, -1);
    });

    test('updateConsumption modifies entry', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);
      final consumptionId =
          await provider.addConsumption(plugId, DateTime(2024, 3, 1), 45.5);
      expect(consumptionId, greaterThan(0));

      final success = await provider.updateConsumption(
          consumptionId, DateTime(2024, 4, 1), 55.0);
      expect(success, true);
    });

    test('deleteConsumption removes entry', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);
      final consumptionId =
          await provider.addConsumption(plugId, DateTime(2024, 3, 1), 45.5);

      await provider.deleteConsumption(consumptionId);

      final remaining =
          await provider.getConsumptionsForPlug(plugId, 'en');
      expect(remaining, isEmpty);
    });

    test('getConsumptionForMonth returns null when no match', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);

      final result =
          await provider.getConsumptionForMonth(plugId, DateTime(2024, 3, 1));
      expect(result, isNull);
    });

    test('getConsumptionForMonth returns match', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);
      await provider.addConsumption(plugId, DateTime(2024, 3, 1), 45.5);

      final result =
          await provider.getConsumptionForMonth(plugId, DateTime(2024, 3, 1));
      expect(result, isNotNull);
      expect(result!.valueKwh, 45.5);
    });

    test('getLatestConsumptionForPlug returns latest entry', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);
      await provider.addConsumption(plugId, DateTime(2024, 3, 1), 45.5);
      await provider.addConsumption(plugId, DateTime(2024, 4, 1), 55.0);

      final latest = await provider.getLatestConsumptionForPlug(plugId);
      expect(latest, isNotNull);
      expect(latest!.valueKwh, 55.0);
    });

    test('getLatestConsumptionForPlug returns null for empty plug', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('Empty', roomId);

      final latest = await provider.getLatestConsumptionForPlug(plugId);
      expect(latest, isNull);
    });

    test('updateSmartPlug modifies plug', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('OldName', roomId);

      final success = await provider.updateSmartPlug(plugId, 'NewName', roomId);
      expect(success, true);
    });

    test('deleteSmartPlug removes plug', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('DeleteMe', roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.plugs, isNotEmpty);

      await provider.deleteSmartPlug(plugId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.plugs, isEmpty);
    });

    test('getSmartPlug returns plug by id', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('FindMe', roomId);
      final plug = await provider.getSmartPlug(plugId);

      expect(plug.name, 'FindMe');
    });

    test('getRoomForSmartPlug returns room', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final plugId = await provider.addSmartPlug('TV', roomId);
      final room = await provider.getRoomForSmartPlug(plugId);

      expect(room.name, 'Living Room');
    });

    test('ConsumptionWithLabel.generateLabel works correctly', () {
      final label =
          ConsumptionWithLabel.generateLabel(DateTime(2024, 3, 1), 'en');
      expect(label, contains('March'));
      expect(label, contains('2024'));
    });
  });
}
