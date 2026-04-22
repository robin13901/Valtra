import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/heating_dao.dart';
import 'package:valtra/providers/heating_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late HeatingDao dao;
  late HeatingProvider provider;
  late int householdId;
  late int roomId;

  setUp(() async {
    database = createTestDatabase();
    dao = HeatingDao(database);
    provider = HeatingProvider(dao);

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
    provider.dispose();
    await database.close();
  });

  group('HeatingProvider - Household Management', () {
    test('meters update when household changes', () async {
      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      expect(provider.meters, isEmpty);

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.meters.length, 1);
      expect(provider.meters.first.roomId, roomId);
    });

    test('setHouseholdId clears meters when set to null', () async {
      await dao.insertMeter(HeatingMetersCompanion.insert(
        householdId: householdId,
        roomId: roomId,
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.meters.length, 1);

      provider.setHouseholdId(null);
      expect(provider.meters, isEmpty);
    });

    test('setting same household id does nothing', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.householdId, householdId);
    });
  });

  group('HeatingProvider - Meter Operations', () {
    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('addMeter creates record with roomId', () async {
      final id = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(id, greaterThan(0));
      expect(provider.meters.length, 1);
      expect(provider.meters.first.roomId, roomId);
    });

    test('addMeter throws when no household selected', () async {
      provider.setHouseholdId(null);

      expect(
        () => provider.addMeter(roomId),
        throwsA(isA<StateError>()),
      );
    });

    test('updateMeter modifies record', () async {
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(
            householdId: householdId,
            name: 'Kitchen',
          ));

      final id = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.updateMeter(id, room2Id);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.meters.first.roomId, room2Id);
    });

    test('deleteMeter removes record and clears selected', () async {
      final id = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.setSelectedMeterId(id);
      expect(provider.selectedMeterId, id);

      await provider.deleteMeter(id);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.meters, isEmpty);
      expect(provider.selectedMeterId, isNull);
    });

    test('getReadingCountForMeter returns correct count', () async {
      final meterId = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(await provider.getReadingCountForMeter(meterId), 0);

      await provider.addReading(meterId, DateTime.now(), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(await provider.getReadingCountForMeter(meterId), 1);
    });
  });

  group('HeatingProvider - Room-based Grouping', () {
    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('metersWithRooms returns HeatingMeterWithRoom objects', () async {
      await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      final metersWithRooms = provider.metersWithRooms;
      expect(metersWithRooms.length, 1);
      expect(metersWithRooms.first.roomName, 'Living Room');
    });

    test('metersByRoom groups meters by room name', () async {
      final room2Id = await database
          .into(database.rooms)
          .insert(RoomsCompanion.insert(
            householdId: householdId,
            name: 'Kitchen',
          ));

      await provider.addMeter(roomId);
      await provider.addMeter(room2Id);
      await Future.delayed(const Duration(milliseconds: 100));

      final grouped = provider.metersByRoom;
      expect(grouped.keys.length, 2);
      expect(grouped['Living Room']!.length, 1);
      expect(grouped['Kitchen']!.length, 1);
    });

    test('multiple meters in same room grouped together', () async {
      await provider.addMeter(roomId);
      await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      final grouped = provider.metersByRoom;
      expect(grouped.keys.length, 1);
      expect(grouped['Living Room']!.length, 2);
    });
  });

  group('HeatingProvider - Reading Operations', () {
    late int meterId;

    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      meterId = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('addReading creates record', () async {
      final timestamp = DateTime(2024, 1, 15);
      final id = await provider.addReading(meterId, timestamp, 1000.5);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(id, greaterThan(0));
      final readings = provider.getReadingsWithDeltas(meterId);
      expect(readings.length, 1);
      expect(readings.first.reading.value, 1000.5);
    });

    test('updateReading modifies record', () async {
      final id = await provider.addReading(meterId, DateTime.now(), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateReading(id, DateTime.now(), 200.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final readings = provider.getReadingsWithDeltas(meterId);
      expect(readings.first.reading.value, 200.0);
    });

    test('deleteReading removes record', () async {
      final id = await provider.addReading(meterId, DateTime.now(), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.getReadingsWithDeltas(meterId).length, 1);

      await provider.deleteReading(id);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.getReadingsWithDeltas(meterId), isEmpty);
    });
  });

  group('HeatingProvider - Delta Calculations', () {
    late int meterId;

    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      meterId = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('getReadingsWithDeltas calculates correct deltas', () async {
      await provider.addReading(meterId, DateTime(2024, 1, 1), 1000.0);
      await provider.addReading(meterId, DateTime(2024, 2, 1), 1050.0);
      await provider.addReading(meterId, DateTime(2024, 3, 1), 1125.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final readings = provider.getReadingsWithDeltas(meterId);

      expect(readings.length, 3);
      expect(readings[0].reading.value, 1125.0);
      expect(readings[0].delta, 75.0);
      expect(readings[1].reading.value, 1050.0);
      expect(readings[1].delta, 50.0);
      expect(readings[2].reading.value, 1000.0);
      expect(readings[2].delta, isNull);
    });

    test('getReadingsWithDeltas returns empty for unknown meter', () async {
      final readings = provider.getReadingsWithDeltas(999);
      expect(readings, isEmpty);
    });
  });

  group('HeatingProvider - Validation', () {
    late int meterId;

    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      meterId = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.addReading(meterId, DateTime(2024, 1, 1), 1000.0);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('validateReading returns null for valid value', () async {
      final error = await provider.validateReading(
        meterId,
        1050.0,
        DateTime(2024, 2, 1),
      );

      expect(error, isNull);
    });

    test('validateReading returns error for value less than previous',
        () async {
      final error = await provider.validateReading(
        meterId,
        950.0,
        DateTime(2024, 2, 1),
      );

      expect(error, isNotNull);
      expect(error, 1000.0);
    });

    test('validateReading handles excludeId for editing', () async {
      final readingId = await provider.addReading(
        meterId,
        DateTime(2024, 2, 1),
        1050.0,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final error = await provider.validateReading(
        meterId,
        1020.0,
        DateTime(2024, 2, 1),
        excludeId: readingId,
      );

      expect(error, isNull);
    });

    test('validateReading checks next reading when editing', () async {
      await provider.addReading(meterId, DateTime(2024, 3, 1), 1200.0);
      final middleId = await provider.addReading(
        meterId,
        DateTime(2024, 2, 1),
        1100.0,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final error = await provider.validateReading(
        meterId,
        1300.0,
        DateTime(2024, 2, 1),
        excludeId: middleId,
      );

      expect(error, isNotNull);
      expect(error, 1200.0);
    });
  });

  group('HeatingProvider - Selected Meter', () {
    test('setSelectedMeterId updates selected meter', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final meterId = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedMeterId, isNull);

      provider.setSelectedMeterId(meterId);
      expect(provider.selectedMeterId, meterId);

      provider.setSelectedMeterId(null);
      expect(provider.selectedMeterId, isNull);
    });

    test('setting same selectedMeterId does nothing', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final meterId = await provider.addMeter(roomId);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.setSelectedMeterId(meterId);
      provider.setSelectedMeterId(meterId);

      expect(provider.selectedMeterId, meterId);
    });
  });
}
