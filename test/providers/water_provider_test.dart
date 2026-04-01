import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/water_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/providers/water_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late WaterDao dao;
  late WaterProvider provider;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = WaterDao(database);
    provider = WaterProvider(dao);

    // Create a household for testing
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('WaterProvider - Household Management', () {
    test('meters update when household changes', () async {
      // Add meter directly to database
      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Test Meter',
        type: WaterMeterType.cold,
      ));

      expect(provider.meters, isEmpty);

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.meters.length, 1);
      expect(provider.meters.first.name, 'Test Meter');
    });

    test('setHouseholdId clears meters when set to null', () async {
      await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Test Meter',
        type: WaterMeterType.cold,
      ));

      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.meters.length, 1);

      provider.setHouseholdId(null);
      expect(provider.meters, isEmpty);
    });

    test('setting same household id does nothing', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      // Should not trigger any change
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.householdId, householdId);
    });
  });

  group('WaterProvider - Meter Operations', () {
    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('addMeter creates record', () async {
      final id = await provider.addMeter('Cold Water', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(id, greaterThan(0));
      expect(provider.meters.length, 1);
      expect(provider.meters.first.name, 'Cold Water');
      expect(provider.meters.first.type, WaterMeterType.cold);
    });

    test('addMeter throws when no household selected', () async {
      provider.setHouseholdId(null);

      expect(
        () => provider.addMeter('Test', WaterMeterType.cold),
        throwsA(isA<StateError>()),
      );
    });

    test('updateMeter modifies record', () async {
      final id = await provider.addMeter('Original', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateMeter(id, 'Updated', WaterMeterType.hot);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.meters.first.name, 'Updated');
      expect(provider.meters.first.type, WaterMeterType.hot);
    });

    test('deleteMeter removes record and clears selected', () async {
      final id = await provider.addMeter('To Delete', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterId(id);
      expect(provider.selectedMeterId, id);

      await provider.deleteMeter(id);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.meters, isEmpty);
      expect(provider.selectedMeterId, isNull);
    });

    test('getReadingCountForMeter returns correct count', () async {
      final meterId = await provider.addMeter('Test', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(await provider.getReadingCountForMeter(meterId), 0);

      await provider.addReading(meterId, DateTime.now(), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(await provider.getReadingCountForMeter(meterId), 1);
    });
  });

  group('WaterProvider - Reading Operations', () {
    late int meterId;

    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      meterId = await provider.addMeter('Test Meter', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('addReading creates record', () async {
      final timestamp = DateTime(2024, 1, 15);
      final id = await provider.addReading(meterId, timestamp, 100.5);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(id, greaterThan(0));
      final readings = provider.getReadingsWithDeltas(meterId);
      expect(readings.length, 1);
      expect(readings.first.reading.valueCubicMeters, 100.5);
    });

    test('updateReading modifies record', () async {
      final id = await provider.addReading(meterId, DateTime.now(), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.updateReading(id, DateTime.now(), 200.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final readings = provider.getReadingsWithDeltas(meterId);
      expect(readings.first.reading.valueCubicMeters, 200.0);
    });

    test('deleteReading removes record', () async {
      final id = await provider.addReading(meterId, DateTime.now(), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.getReadingsWithDeltas(meterId).length, 1);

      await provider.deleteReading(id);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.getReadingsWithDeltas(meterId), isEmpty);
    });

    test('getLatestReading returns most recent', () async {
      await provider.addReading(meterId, DateTime(2024, 1, 1), 100.0);
      await provider.addReading(meterId, DateTime(2024, 2, 1), 150.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final latest = await provider.getLatestReading(meterId);

      expect(latest, isNotNull);
      expect(latest!.valueCubicMeters, 150.0);
    });
  });

  group('WaterProvider - Delta Calculations', () {
    late int meterId;

    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      meterId = await provider.addMeter('Test Meter', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('getReadingsWithDeltas calculates correct deltas', () async {
      await provider.addReading(meterId, DateTime(2024, 1, 1), 100.0);
      await provider.addReading(meterId, DateTime(2024, 2, 1), 150.0);
      await provider.addReading(meterId, DateTime(2024, 3, 1), 225.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final readings = provider.getReadingsWithDeltas(meterId);

      expect(readings.length, 3);
      // Readings are sorted newest first
      expect(readings[0].reading.valueCubicMeters, 225.0);
      expect(readings[0].deltaCubicMeters, 75.0); // 225 - 150
      expect(readings[1].reading.valueCubicMeters, 150.0);
      expect(readings[1].deltaCubicMeters, 50.0); // 150 - 100
      expect(readings[2].reading.valueCubicMeters, 100.0);
      expect(readings[2].deltaCubicMeters, isNull); // First reading, no previous
    });

    test('getReadingsWithDeltas returns empty for unknown meter', () async {
      final readings = provider.getReadingsWithDeltas(999);
      expect(readings, isEmpty);
    });
  });

  group('WaterProvider - Validation', () {
    late int meterId;

    setUp(() async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      meterId = await provider.addMeter('Test Meter', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));

      // Add a baseline reading
      await provider.addReading(meterId, DateTime(2024, 1, 1), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('validateReading returns null for valid value', () async {
      final error = await provider.validateReading(
        meterId,
        150.0,
        DateTime(2024, 2, 1),
      );

      expect(error, isNull);
    });

    test('validateReading returns error for value less than previous', () async {
      final error = await provider.validateReading(
        meterId,
        50.0, // Less than 100.0
        DateTime(2024, 2, 1),
      );

      expect(error, isNotNull);
      expect(error, 100.0);
    });

    test('validateReading handles excludeId for editing', () async {
      final readingId = await provider.addReading(
        meterId,
        DateTime(2024, 2, 1),
        150.0,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Edit the reading to a value between baseline and current
      final error = await provider.validateReading(
        meterId,
        120.0, // Valid because we're editing
        DateTime(2024, 2, 1),
        excludeId: readingId,
      );

      expect(error, isNull);
    });

    test('validateReading checks next reading when editing', () async {
      // Add a later reading
      await provider.addReading(meterId, DateTime(2024, 3, 1), 200.0);
      final middleId = await provider.addReading(
        meterId,
        DateTime(2024, 2, 1),
        150.0,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Try to edit middle reading to exceed the later one
      final error = await provider.validateReading(
        meterId,
        250.0, // More than 200.0
        DateTime(2024, 2, 1),
        excludeId: middleId,
      );

      expect(error, isNotNull);
      expect(error, 200.0);
    });
  });

  group('WaterProvider - Selected Meter', () {
    test('setSelectedMeterId updates selected meter', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final meterId = await provider.addMeter('Test', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.selectedMeterId, isNull);

      provider.setSelectedMeterId(meterId);
      expect(provider.selectedMeterId, meterId);

      provider.setSelectedMeterId(null);
      expect(provider.selectedMeterId, isNull);
    });

    test('setting same selectedMeterId does nothing', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final meterId = await provider.addMeter('Test', WaterMeterType.cold);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterId(meterId);
      provider.setSelectedMeterId(meterId); // Should not trigger another notification

      expect(provider.selectedMeterId, meterId);
    });
  });
}
