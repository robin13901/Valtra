import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/tables.dart';

import '../helpers/test_database.dart';

void main() {
  group('Database Schema', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('creates database without errors', () async {
      expect(db, isNotNull);
    });

    test('can insert and retrieve household', () async {
      final id = await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              name: 'Test Household',
            ),
          );
      expect(id, greaterThan(0));

      final household = await (db.select(db.households)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingle();
      expect(household.name, 'Test Household');
    });

    test('can insert electricity reading', () async {
      // First create a household
      final householdId = await db.into(db.households).insert(
            HouseholdsCompanion.insert(name: 'Test Home'),
          );

      // Then create a reading
      final readingId = await db.into(db.electricityReadings).insert(
            ElectricityReadingsCompanion.insert(
              householdId: householdId,
              timestamp: DateTime.now(),
              valueKwh: 1234.5,
            ),
          );
      expect(readingId, greaterThan(0));
    });

    test('can insert water meter with type', () async {
      final householdId = await db.into(db.households).insert(
            HouseholdsCompanion.insert(name: 'Test Home'),
          );

      final meterId = await db.into(db.waterMeters).insert(
            WaterMetersCompanion.insert(
              householdId: householdId,
              name: 'Kitchen Cold Water',
              type: WaterMeterType.cold,
            ),
          );
      expect(meterId, greaterThan(0));

      final meter = await (db.select(db.waterMeters)
            ..where((tbl) => tbl.id.equals(meterId)))
          .getSingle();
      expect(meter.type, WaterMeterType.cold);
    });

    test('can insert smart plug consumption', () async {
      // Create hierarchy: Household -> Room -> SmartPlug
      final householdId = await db.into(db.households).insert(
            HouseholdsCompanion.insert(name: 'Test Home'),
          );

      final roomId = await db.into(db.rooms).insert(
            RoomsCompanion.insert(
              householdId: householdId,
              name: 'Living Room',
            ),
          );

      final plugId = await db.into(db.smartPlugs).insert(
            SmartPlugsCompanion.insert(
              roomId: roomId,
              name: 'TV Plug',
            ),
          );

      final consumptionId = await db.into(db.smartPlugConsumptions).insert(
            SmartPlugConsumptionsCompanion.insert(
              smartPlugId: plugId,
              intervalType: ConsumptionInterval.daily,
              intervalStart: DateTime(2026, 3, 1),
              valueKwh: 2.5,
            ),
          );
      expect(consumptionId, greaterThan(0));
    });
  });
}
