import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/gas_dao.dart';
import 'package:valtra/providers/gas_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late GasDao dao;
  late GasProvider provider;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = GasDao(database);
    provider = GasProvider(dao);

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('GasProvider', () {
    test('readings stream updates when household changes', () async {
      // Insert a reading for the household
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now(),
        valueCubicMeters: 1000.0,
      ));

      // Initially no readings (no household set)
      expect(provider.readings, isEmpty);

      // Set household and wait for stream
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.readings.length, 1);
      expect(provider.readings[0].valueCubicMeters, 1000.0);
    });

    test('addReading creates record in database', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final timestamp = DateTime(2024, 3, 15, 10, 30);
      await provider.addReading(timestamp, 1234.5);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.readings.length, 1);
      expect(provider.readings[0].valueCubicMeters, 1234.5);
      expect(provider.readings[0].timestamp, timestamp);
    });

    test('addReading throws when no household selected', () async {
      expect(
        () => provider.addReading(DateTime.now(), 1000.0),
        throwsA(isA<StateError>()),
      );
    });

    test('validateReading returns error when value < previous reading',
        () async {
      provider.setHouseholdId(householdId);

      // Add initial reading
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        valueCubicMeters: 1000.0,
      ));

      // Try to validate a smaller value
      final error = await provider.validateReading(
        900.0,
        DateTime.now(),
      );

      expect(error, isNotNull);
      expect(error, 1000.0);
    });

    test('validateReading returns null for valid readings', () async {
      provider.setHouseholdId(householdId);

      // Add initial reading
      await dao.insertReading(GasReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        valueCubicMeters: 1000.0,
      ));

      // Validate a larger value
      final error = await provider.validateReading(
        1100.0,
        DateTime.now(),
      );

      expect(error, isNull);
    });

    test('readingsWithDeltas calculates correct deltas', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();

      // Add readings in order
      await provider.addReading(
          now.subtract(const Duration(days: 2)), 1000.0);
      await provider.addReading(
          now.subtract(const Duration(days: 1)), 1100.0);
      await provider.addReading(now, 1250.0);
      await Future.delayed(const Duration(milliseconds: 100));

      final withDeltas = provider.readingsWithDeltas;
      expect(withDeltas.length, 3);

      // Newest first
      expect(withDeltas[0].reading.valueCubicMeters, 1250.0);
      expect(withDeltas[0].deltaCubicMeters, 150.0); // 1250 - 1100

      expect(withDeltas[1].reading.valueCubicMeters, 1100.0);
      expect(withDeltas[1].deltaCubicMeters, 100.0); // 1100 - 1000

      expect(withDeltas[2].reading.valueCubicMeters, 1000.0);
      expect(withDeltas[2].deltaCubicMeters, isNull); // First reading
    });

    test('deleteReading removes record', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime.now(), 1000.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final readingId = provider.readings[0].id;
      await provider.deleteReading(readingId);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.readings, isEmpty);
    });

    test('updateReading modifies record', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime.now(), 1000.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final readingId = provider.readings[0].id;
      final newTimestamp = DateTime(2024, 4, 1);

      await provider.updateReading(readingId, newTimestamp, 1500.0);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.readings[0].valueCubicMeters, 1500.0);
      expect(provider.readings[0].timestamp, newTimestamp);
    });

    test('setHouseholdId clears readings when set to null', () async {
      provider.setHouseholdId(householdId);
      await provider.addReading(DateTime.now(), 1000.0);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.readings.length, 1);

      provider.setHouseholdId(null);
      expect(provider.readings, isEmpty);
    });

    test('householdId getter returns current household', () async {
      expect(provider.householdId, isNull);

      provider.setHouseholdId(householdId);
      expect(provider.householdId, householdId);
    });
  });
}
