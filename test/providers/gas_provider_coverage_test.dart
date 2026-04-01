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

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household', personCount: 1));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('GasProvider - displayItems', () {
    test('displayItems returns empty list when no readings', () {
      provider.setHouseholdId(householdId);
      expect(provider.displayItems, isEmpty);
    });

    test('displayItems returns real items without interpolation by default',
        () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime(2024, 1, 15), 1000.0);
      await provider.addReading(DateTime(2024, 3, 15), 1200.0);
      await Future.delayed(const Duration(milliseconds: 100));

      final items = provider.displayItems;
      expect(items.length, 2);
      expect(items[0].isInterpolated, false);
      expect(items[1].isInterpolated, false);
    });

    test('displayItems includes interpolated values when toggled', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime(2024, 1, 15), 1000.0);
      await provider.addReading(DateTime(2024, 3, 15), 1200.0);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.toggleInterpolatedValues();
      expect(provider.showInterpolatedValues, true);

      final items = provider.displayItems;
      expect(items.length, greaterThan(2));

      final interpolatedItems =
          items.where((item) => item.isInterpolated).toList();
      expect(interpolatedItems, isNotEmpty);
    });

    test('displayItems does not include interpolated with fewer than 2 readings',
        () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime(2024, 1, 15), 1000.0);
      await Future.delayed(const Duration(milliseconds: 100));

      provider.toggleInterpolatedValues();
      expect(provider.showInterpolatedValues, true);

      final items = provider.displayItems;
      expect(items.length, 1);
      expect(items[0].isInterpolated, false);
    });

    test('displayItems delta calculation is correct', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime(2024, 1, 15), 1000.0);
      await provider.addReading(DateTime(2024, 2, 15), 1100.0);
      await Future.delayed(const Duration(milliseconds: 100));

      final items = provider.displayItems;
      // Newest first
      expect(items[0].delta, 100.0);
      expect(items[1].delta, isNull); // First reading
    });

    test('toggleInterpolatedValues toggles state', () {
      expect(provider.showInterpolatedValues, false);
      provider.toggleInterpolatedValues();
      expect(provider.showInterpolatedValues, true);
      provider.toggleInterpolatedValues();
      expect(provider.showInterpolatedValues, false);
    });
  });

  group('GasProvider - validation edge cases', () {
    test('validateReading returns null when no household set', () async {
      final result = await provider.validateReading(100.0, DateTime.now());
      expect(result, isNull);
    });

    test('validateReading with excludeId checks next reading', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      // Add two readings
      await provider.addReading(DateTime(2024, 1, 1), 100.0);
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.addReading(DateTime(2024, 3, 1), 300.0);
      await Future.delayed(const Duration(milliseconds: 50));

      // Validate editing the first reading with a value > next reading
      final reading1 = provider.readings.last; // oldest
      final error = await provider.validateReading(
        400.0, // Greater than next reading (300)
        DateTime(2024, 1, 1),
        excludeId: reading1.id,
      );

      expect(error, isNotNull);
    });

    test('getLatestReading returns null when no household', () async {
      final result = await provider.getLatestReading();
      expect(result, isNull);
    });

    test('getLatestReading returns reading when exists', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.addReading(DateTime(2024, 1, 15), 1000.0);
      await Future.delayed(const Duration(milliseconds: 50));

      final latest = await provider.getLatestReading();
      expect(latest, isNotNull);
      expect(latest!.valueCubicMeters, 1000.0);
    });

    test('readingsWithDeltas returns empty for no readings', () {
      provider.setHouseholdId(householdId);
      expect(provider.readingsWithDeltas, isEmpty);
    });

    test('setHouseholdId with same ID does nothing', () async {
      provider.setHouseholdId(householdId);
      await Future.delayed(const Duration(milliseconds: 50));

      // Set same ID again - should not restart subscription
      provider.setHouseholdId(householdId);
      // No error or change expected
      expect(provider.householdId, householdId);
    });
  });
}
