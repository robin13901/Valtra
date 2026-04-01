import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/providers/household_provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late HouseholdDao dao;
  late HouseholdProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = createTestDatabase();
    dao = HouseholdDao(database);
    provider = HouseholdProvider(dao);
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('HouseholdProvider', () {
    test('initial state has no households', () async {
      await provider.init();

      expect(provider.isInitialized, isTrue);
      expect(provider.households, isEmpty);
      expect(provider.selectedHousehold, isNull);
      expect(provider.selectedHouseholdId, isNull);
    });

    test('loads persisted household ID on init', () async {
      // Create a household directly in DB
      final id = await dao.insert(HouseholdsCompanion.insert(name: 'Test', personCount: 1));

      // Set the persisted ID
      SharedPreferences.setMockInitialValues(
          {'selected_household_id': id});

      // Recreate provider to simulate fresh start
      provider = HouseholdProvider(dao);
      await provider.init();

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedHouseholdId, id);
      expect(provider.selectedHousehold?.name, 'Test');
    });

    test('selectHousehold persists to SharedPreferences', () async {
      await provider.init();

      // Create households
      await dao.insert(HouseholdsCompanion.insert(name: 'First', personCount: 1));
      final id2 = await dao.insert(HouseholdsCompanion.insert(name: 'Second', personCount: 1));

      // Wait for stream to update
      await Future.delayed(const Duration(milliseconds: 100));

      // Select second household
      await provider.selectHousehold(id2);

      expect(provider.selectedHouseholdId, id2);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('selected_household_id'), id2);
    });

    test('createHousehold adds to database and selects by default', () async {
      await provider.init();

      final id = await provider.createHousehold(
        'New Household',
        description: 'A description',
        personCount: 2,
      );

      // Wait for stream to update
      await Future.delayed(const Duration(milliseconds: 100));

      expect(id, isPositive);
      expect(provider.selectedHouseholdId, id);
      expect(provider.selectedHousehold?.name, 'New Household');
      expect(provider.selectedHousehold?.description, 'A description');
    });

    test('createHousehold respects selectAfterCreate=false', () async {
      await provider.init();

      // Create first household
      final firstId = await provider.createHousehold('First', personCount: 1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Create second without selecting
      await provider.createHousehold('Second', personCount: 1, selectAfterCreate: false);
      await Future.delayed(const Duration(milliseconds: 100));

      // Should still have first selected
      expect(provider.selectedHouseholdId, firstId);
    });

    test('updateHousehold modifies existing household', () async {
      await provider.init();

      final id = await provider.createHousehold('Original', personCount: 1);
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.updateHousehold(id, 'Updated', description: 'New desc');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedHousehold?.name, 'Updated');
      expect(provider.selectedHousehold?.description, 'New desc');
    });

    test('deleteHousehold removes household', () async {
      await provider.init();

      final id = await provider.createHousehold('ToDelete', personCount: 1);
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await provider.deleteHousehold(id);

      expect(result, isTrue);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.households, isEmpty);
      expect(provider.selectedHouseholdId, isNull);
    });

    test('deleteHousehold returns false when household has related data',
        () async {
      await provider.init();

      final id = await provider.createHousehold('WithData', personCount: 1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Add related data
      await database.into(database.electricityReadings).insert(
          ElectricityReadingsCompanion.insert(
              householdId: id, timestamp: DateTime.now(), valueKwh: 100.0));

      final result = await provider.deleteHousehold(id);

      expect(result, isFalse);
      expect(provider.households.length, 1);
    });

    test('selectedHousehold updates when household list changes', () async {
      await provider.init();

      final id = await provider.createHousehold('Selected', personCount: 1);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedHousehold?.name, 'Selected');

      // Update household directly via DAO
      await dao.updateHousehold(HouseholdsCompanion(
        id: Value(id),
        name: const Value('Changed Name'),
      ));

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedHousehold?.name, 'Changed Name');
    });

    test('auto-selects first household if none selected', () async {
      // Create household before init (no selection persisted)
      final id = await dao.insert(HouseholdsCompanion.insert(name: 'Auto', personCount: 1));

      await provider.init();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedHouseholdId, id);
    });

    test('clears selection if selected household is deleted externally',
        () async {
      await provider.init();

      final id = await provider.createHousehold('Will be deleted', personCount: 1);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedHouseholdId, id);

      // Delete directly via DAO (simulating external deletion)
      await dao.deleteHousehold(id);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.selectedHouseholdId, isNull);
      expect(provider.selectedHousehold, isNull);
    });
  });
}
