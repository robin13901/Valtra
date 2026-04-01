import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/providers/electricity_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late ElectricityDao dao;
  late ElectricityProvider provider;
  late int householdId;

  setUp(() async {
    database = createTestDatabase();
    dao = ElectricityDao(database);
    provider = ElectricityProvider(dao);

    // Create a test household
    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('ElectricityProvider', () {
    test('readings stream updates when household changes', () async {
      // Insert a reading for the household
      await dao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now(),
        valueKwh: 1000.0,
      ));

      // Initially no readings (no household set)
      expect(provider.readings, isEmpty);

      // Set household and wait for stream
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.readings.length, 1);
      expect(provider.readings[0].valueKwh, 1000.0);
    });

    test('addReading creates record in database', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final timestamp = DateTime(2024, 3, 15, 10, 30);
      await provider.addReading(timestamp, 1234.5);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.readings.length, 1);
      expect(provider.readings[0].valueKwh, 1234.5);
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
      await dao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        valueKwh: 1000.0,
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
      await dao.insertReading(ElectricityReadingsCompanion.insert(
        householdId: householdId,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        valueKwh: 1000.0,
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
      await provider.addReading(now.subtract(const Duration(days: 2)), 1000.0);
      await provider.addReading(now.subtract(const Duration(days: 1)), 1100.0);
      await provider.addReading(now, 1250.0);
      await Future.delayed(const Duration(milliseconds: 100));

      final withDeltas = provider.readingsWithDeltas;
      expect(withDeltas.length, 3);

      // Newest first
      expect(withDeltas[0].reading.valueKwh, 1250.0);
      expect(withDeltas[0].deltaKwh, 150.0); // 1250 - 1100

      expect(withDeltas[1].reading.valueKwh, 1100.0);
      expect(withDeltas[1].deltaKwh, 100.0); // 1100 - 1000

      expect(withDeltas[2].reading.valueKwh, 1000.0);
      expect(withDeltas[2].deltaKwh, isNull); // First reading
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

      expect(provider.readings[0].valueKwh, 1500.0);
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

    test('showInterpolatedValues defaults to false', () {
      expect(provider.showInterpolatedValues, false);
    });

    test('toggleInterpolatedValues flips the state', () {
      expect(provider.showInterpolatedValues, false);
      provider.toggleInterpolatedValues();
      expect(provider.showInterpolatedValues, true);
      provider.toggleInterpolatedValues();
      expect(provider.showInterpolatedValues, false);
    });

    test('toggleInterpolatedValues notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.toggleInterpolatedValues();

      expect(notified, true);
    });

    test('displayItems returns real items when toggle is off', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();
      await provider.addReading(now.subtract(const Duration(days: 2)), 1000.0);
      await provider.addReading(now.subtract(const Duration(days: 1)), 1100.0);
      await Future.delayed(const Duration(milliseconds: 100));

      final items = provider.displayItems;
      expect(items.length, 2);
      expect(items.every((i) => !i.isInterpolated), true);
      expect(items.every((i) => i.readingId != null), true);
    });

    test('displayItems includes interpolated values when toggle is on', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      // Add readings spanning multiple months to generate interpolated boundaries
      await provider.addReading(DateTime(2024, 1, 15), 1000.0);
      await provider.addReading(DateTime(2024, 4, 15), 1300.0);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.toggleInterpolatedValues();
      final items = provider.displayItems;

      // Should have 2 real + some interpolated (Feb 1, Mar 1, Apr 1)
      expect(items.length, greaterThan(2));

      final interpolated = items.where((i) => i.isInterpolated).toList();
      expect(interpolated.isNotEmpty, true);

      // All interpolated items should be on 1st of month at 00:00
      for (final item in interpolated) {
        expect(item.timestamp.day, 1);
        expect(item.timestamp.hour, 0);
        expect(item.timestamp.minute, 0);
        expect(item.readingId, isNull);
      }

      // Items should be sorted newest first
      for (var i = 0; i < items.length - 1; i++) {
        expect(
          items[i].timestamp.isAfter(items[i + 1].timestamp) ||
              items[i].timestamp == items[i + 1].timestamp,
          true,
        );
      }
    });

    test('displayItems returns empty when no readings', () {
      provider.setHouseholdId(householdId);
      expect(provider.displayItems, isEmpty);
    });

    test('displayItems with toggle on but <2 readings shows real only', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime(2024, 1, 15), 1000.0);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.toggleInterpolatedValues();
      final items = provider.displayItems;

      expect(items.length, 1);
      expect(items.first.isInterpolated, false);
    });
  });
}
