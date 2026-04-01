import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/tables.dart';

/// Creates an in-memory v2 database with pre-populated data, then opens it
/// through AppDatabase to trigger the v2->v3 migration.
///
/// The [populateV2] callback receives the raw sqlite3 database handle
/// (via NativeDatabase's setup callback) to insert v2 test data.
AppDatabase _createMigratingDatabase({
  required void Function(void Function(String sql, [List<Object?>? params]) execute)
      populateV2,
}) {
  return AppDatabase(NativeDatabase.memory(
    setup: (rawDb) {
      // Drop all tables that Drift would auto-create (we want the v2 schema)
      // Drift hasn't created anything yet at this point; the setup callback
      // runs before Drift interacts with the database. But since this is a
      // memory database, it's empty.
      //
      // We need to create the v2 schema BEFORE Drift's migration runs.
      // However, Drift's migration is triggered on first access, not in setup.
      // The setup callback runs on the raw sqlite3 database before Drift
      // applies any schema management.
      //
      // Strategy: Create v2 tables in setup, set user_version = 2.
      // When Drift opens, it sees version 2, knows current is 3,
      // and runs onUpgrade(m, 2, 3).

      // Create v2 schema tables
      rawDb.execute('''
        CREATE TABLE households (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');
      rawDb.execute('''
        CREATE TABLE electricity_readings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          household_id INTEGER NOT NULL REFERENCES households(id),
          timestamp INTEGER NOT NULL,
          value_kwh REAL NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE gas_readings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          household_id INTEGER NOT NULL REFERENCES households(id),
          timestamp INTEGER NOT NULL,
          value_cubic_meters REAL NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE water_meters (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          household_id INTEGER NOT NULL REFERENCES households(id),
          name TEXT NOT NULL,
          type INTEGER NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE water_readings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          water_meter_id INTEGER NOT NULL REFERENCES water_meters(id),
          timestamp INTEGER NOT NULL,
          value_cubic_meters REAL NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE heating_meters (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          household_id INTEGER NOT NULL REFERENCES households(id),
          name TEXT NOT NULL,
          location TEXT
        )
      ''');
      rawDb.execute('''
        CREATE TABLE heating_readings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          heating_meter_id INTEGER NOT NULL REFERENCES heating_meters(id),
          timestamp INTEGER NOT NULL,
          value REAL NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE rooms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          household_id INTEGER NOT NULL REFERENCES households(id),
          name TEXT NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE smart_plugs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          room_id INTEGER NOT NULL REFERENCES rooms(id),
          name TEXT NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE smart_plug_consumptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          smart_plug_id INTEGER NOT NULL REFERENCES smart_plugs(id),
          interval_type INTEGER NOT NULL,
          interval_start INTEGER NOT NULL,
          value_kwh REAL NOT NULL
        )
      ''');
      rawDb.execute('''
        CREATE TABLE cost_configs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          household_id INTEGER NOT NULL REFERENCES households(id),
          meter_type INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          standing_charge REAL NOT NULL DEFAULT 0.0,
          price_tiers TEXT,
          currency_symbol TEXT NOT NULL DEFAULT '\u20AC',
          valid_from INTEGER NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Set version to 2 so Drift triggers onUpgrade(m, 2, 3)
      rawDb.execute('PRAGMA user_version = 2');

      // Populate v2 data using the callback
      populateV2((sql, [params]) {
        rawDb.execute(sql, params ?? []);
      });
    },
  ));
}

/// Returns the unix epoch (seconds) for a DateTime.
int _epoch(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

void main() {
  group('Migration v2 to v3', () {
    group('Heating meters: location to room conversion', () {
      test('meters with location are assigned to matching rooms', () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Test Home'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Bedroom Radiator', 'Bedroom'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [2, 1, 'Kitchen Radiator', 'Kitchen'],
            );
          },
        );

        // Trigger migration by accessing the database
        final meters = await (db.select(db.heatingMeters)
              ..orderBy([(m) => OrderingTerm.asc(m.id)]))
            .get();

        expect(meters.length, 2);
        expect(meters[0].name, 'Bedroom Radiator');
        expect(meters[1].name, 'Kitchen Radiator');

        // Verify rooms were created
        final rooms = await db.select(db.rooms).get();
        expect(rooms.length, 2);

        final roomNames = rooms.map((r) => r.name).toSet();
        expect(roomNames, containsAll(['Bedroom', 'Kitchen']));

        // Verify room assignment
        final bedroomRoom =
            rooms.firstWhere((r) => r.name == 'Bedroom');
        final kitchenRoom =
            rooms.firstWhere((r) => r.name == 'Kitchen');
        expect(meters[0].roomId, bedroomRoom.id);
        expect(meters[1].roomId, kitchenRoom.id);

        await db.close();
      });

      test('meters without location get "Standard" room', () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Test Home'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Radiator A', null],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [2, 1, 'Radiator B', null],
            );
          },
        );

        final meters = await (db.select(db.heatingMeters)
              ..orderBy([(m) => OrderingTerm.asc(m.id)]))
            .get();
        expect(meters.length, 2);

        // Both should share the same "Standard" room
        expect(meters[0].roomId, meters[1].roomId);

        final rooms = await db.select(db.rooms).get();
        expect(rooms.length, 1);
        expect(rooms.first.name, 'Standard');
        expect(rooms.first.householdId, 1);

        await db.close();
      });

      test('duplicate location names in same household share one room',
          () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Radiator 1', 'Living Room'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [2, 1, 'Radiator 2', 'Living Room'],
            );
          },
        );

        final meters = await (db.select(db.heatingMeters)
              ..orderBy([(m) => OrderingTerm.asc(m.id)]))
            .get();
        expect(meters.length, 2);

        // Both share the same room
        expect(meters[0].roomId, meters[1].roomId);

        final rooms = await db.select(db.rooms).get();
        expect(rooms.length, 1);
        expect(rooms.first.name, 'Living Room');

        await db.close();
      });

      test('heating readings preserved after table recreation', () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Test Meter', 'Room A'],
            );
            final ts1 = _epoch(DateTime(2024, 1, 15));
            final ts2 = _epoch(DateTime(2024, 2, 15));
            exec(
              'INSERT INTO heating_readings (id, heating_meter_id, timestamp, value) VALUES (?, ?, ?, ?)',
              [1, 1, ts1, 100.0],
            );
            exec(
              'INSERT INTO heating_readings (id, heating_meter_id, timestamp, value) VALUES (?, ?, ?, ?)',
              [2, 1, ts2, 150.0],
            );
          },
        );

        // Verify readings still exist and reference the correct meter
        final readings = await (db.select(db.heatingReadings)
              ..orderBy([(r) => OrderingTerm.asc(r.id)]))
            .get();
        expect(readings.length, 2);
        expect(readings[0].heatingMeterId, 1);
        expect(readings[0].value, 100.0);
        expect(readings[1].heatingMeterId, 1);
        expect(readings[1].value, 150.0);

        await db.close();
      });

      test('new heating_type defaults to ownMeter (0) after migration',
          () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Meter', 'Room'],
            );
          },
        );

        final meters = await db.select(db.heatingMeters).get();
        expect(meters.length, 1);
        expect(meters.first.heatingType, HeatingType.ownMeter);
        expect(meters.first.heatingRatio, isNull);

        await db.close();
      });

      test('empty string location treated as null (gets Standard room)',
          () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Meter A', ''],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [2, 1, 'Meter B', '  '],
            );
          },
        );

        final rooms = await db.select(db.rooms).get();
        expect(rooms.length, 1);
        expect(rooms.first.name, 'Standard');

        final meters = await db.select(db.heatingMeters).get();
        expect(meters.length, 2);
        expect(meters[0].roomId, rooms.first.id);
        expect(meters[1].roomId, rooms.first.id);

        await db.close();
      });

      test('multiple households create separate rooms per household',
          () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home A'],
            );
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [2, 'Home B'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Meter A', 'Kitchen'],
            );
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [2, 2, 'Meter B', 'Kitchen'],
            );
          },
        );

        final rooms = await (db.select(db.rooms)
              ..orderBy([(r) => OrderingTerm.asc(r.id)]))
            .get();
        // Each household gets its own "Kitchen" room
        expect(rooms.length, 2);
        expect(rooms[0].householdId, 1);
        expect(rooms[0].name, 'Kitchen');
        expect(rooms[1].householdId, 2);
        expect(rooms[1].name, 'Kitchen');

        final meters = await (db.select(db.heatingMeters)
              ..orderBy([(m) => OrderingTerm.asc(m.id)]))
            .get();
        expect(meters[0].roomId, rooms[0].id);
        expect(meters[1].roomId, rooms[1].id);

        await db.close();
      });
    });

    group('Smart plug consumptions: interval to month conversion', () {
      test('consumptions merged by month with SUM', () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            exec(
              'INSERT INTO rooms (id, household_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Office'],
            );
            exec(
              'INSERT INTO smart_plugs (id, room_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Desk Lamp'],
            );
            // Two entries for the same plug and month (Jan 2024),
            // different interval types and start dates
            final jan1 = _epoch(DateTime(2024, 1, 1));
            final jan15 = _epoch(DateTime(2024, 1, 15));
            final feb1 = _epoch(DateTime(2024, 2, 1));
            exec(
              'INSERT INTO smart_plug_consumptions (smart_plug_id, interval_type, interval_start, value_kwh) VALUES (?, ?, ?, ?)',
              [1, 2, jan1, 10.0], // monthly, Jan 1
            );
            exec(
              'INSERT INTO smart_plug_consumptions (smart_plug_id, interval_type, interval_start, value_kwh) VALUES (?, ?, ?, ?)',
              [1, 0, jan15, 5.0], // daily, Jan 15 (still Jan)
            );
            exec(
              'INSERT INTO smart_plug_consumptions (smart_plug_id, interval_type, interval_start, value_kwh) VALUES (?, ?, ?, ?)',
              [1, 2, feb1, 8.0], // monthly, Feb 1
            );
          },
        );

        final consumptions = await (db.select(db.smartPlugConsumptions)
              ..orderBy([(c) => OrderingTerm.asc(c.month)]))
            .get();

        expect(consumptions.length, 2);

        // January: 10.0 + 5.0 = 15.0
        expect(consumptions[0].smartPlugId, 1);
        expect(consumptions[0].valueKwh, 15.0);
        // Verify month is set to first of month
        expect(consumptions[0].month.month, 1);
        expect(consumptions[0].month.day, 1);

        // February: 8.0
        expect(consumptions[1].smartPlugId, 1);
        expect(consumptions[1].valueKwh, 8.0);
        expect(consumptions[1].month.month, 2);
        expect(consumptions[1].month.day, 1);

        await db.close();
      });

      test('different plugs with same month are kept separate', () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            exec(
              'INSERT INTO rooms (id, household_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Office'],
            );
            exec(
              'INSERT INTO smart_plugs (id, room_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Plug A'],
            );
            exec(
              'INSERT INTO smart_plugs (id, room_id, name) VALUES (?, ?, ?)',
              [2, 1, 'Plug B'],
            );
            final jan1 = _epoch(DateTime(2024, 1, 1));
            exec(
              'INSERT INTO smart_plug_consumptions (smart_plug_id, interval_type, interval_start, value_kwh) VALUES (?, ?, ?, ?)',
              [1, 2, jan1, 10.0],
            );
            exec(
              'INSERT INTO smart_plug_consumptions (smart_plug_id, interval_type, interval_start, value_kwh) VALUES (?, ?, ?, ?)',
              [2, 2, jan1, 20.0],
            );
          },
        );

        final consumptions = await db.select(db.smartPlugConsumptions).get();
        expect(consumptions.length, 2);

        final plugAConsumption =
            consumptions.firstWhere((c) => c.smartPlugId == 1);
        final plugBConsumption =
            consumptions.firstWhere((c) => c.smartPlugId == 2);

        expect(plugAConsumption.valueKwh, 10.0);
        expect(plugBConsumption.valueKwh, 20.0);

        await db.close();
      });

      test('interval_type column removed after migration', () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            exec(
              'INSERT INTO rooms (id, household_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Room'],
            );
            exec(
              'INSERT INTO smart_plugs (id, room_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Plug'],
            );
          },
        );

        // Verify the new table has no interval_type column
        final result = await db.customSelect(
          "PRAGMA table_info(smart_plug_consumptions)",
        ).get();

        final columnNames = result.map((r) => r.read<String>('name')).toList();
        expect(columnNames, contains('id'));
        expect(columnNames, contains('smart_plug_id'));
        expect(columnNames, contains('month'));
        expect(columnNames, contains('value_kwh'));
        expect(columnNames, isNot(contains('interval_type')));
        expect(columnNames, isNot(contains('interval_start')));

        await db.close();
      });
    });

    group('Combined migration scenarios', () {
      test('migration with no heating meters or consumptions succeeds',
          () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Empty Home'],
            );
          },
        );

        // Verify database is accessible after migration
        final households = await db.select(db.households).get();
        expect(households.length, 1);
        expect(households.first.name, 'Empty Home');

        final meters = await db.select(db.heatingMeters).get();
        expect(meters, isEmpty);

        final consumptions = await db.select(db.smartPlugConsumptions).get();
        expect(consumptions, isEmpty);

        await db.close();
      });

      test('existing rooms preserved during migration', () async {
        final db = _createMigratingDatabase(
          populateV2: (exec) {
            exec(
              'INSERT INTO households (id, name) VALUES (?, ?)',
              [1, 'Home'],
            );
            // Pre-existing room (for smart plugs in v2)
            exec(
              'INSERT INTO rooms (id, household_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Office'],
            );
            exec(
              'INSERT INTO smart_plugs (id, room_id, name) VALUES (?, ?, ?)',
              [1, 1, 'Desk Plug'],
            );
            // Heating meter with location matching existing room name
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [1, 1, 'Office Heater', 'Office'],
            );
            // Heating meter with different location
            exec(
              'INSERT INTO heating_meters (id, household_id, name, location) VALUES (?, ?, ?, ?)',
              [2, 1, 'Bedroom Heater', 'Bedroom'],
            );
          },
        );

        final rooms = await (db.select(db.rooms)
              ..orderBy([(r) => OrderingTerm.asc(r.id)]))
            .get();

        // Should have: Office (pre-existing), Bedroom (new from migration)
        // The INSERT OR IGNORE should not duplicate Office
        final roomNames = rooms.map((r) => r.name).toList();
        expect(roomNames, contains('Office'));
        expect(roomNames, contains('Bedroom'));

        // Office room should only exist once
        final officeRooms = rooms.where((r) => r.name == 'Office').toList();
        expect(officeRooms.length, 1);

        // Smart plug should still reference the Office room
        final plugs = await db.select(db.smartPlugs).get();
        expect(plugs.length, 1);
        expect(plugs.first.roomId, officeRooms.first.id);

        // Heating meter with Office location should use existing Office room
        final meters = await (db.select(db.heatingMeters)
              ..orderBy([(m) => OrderingTerm.asc(m.id)]))
            .get();
        expect(meters[0].roomId, officeRooms.first.id);

        await db.close();
      });
    });

    group('Fresh install at v3', () {
      test('fresh database creates all tables without migration', () async {
        final db = AppDatabase(NativeDatabase.memory());

        // Verify we can insert and query data with the v3 schema
        final householdId = await db.into(db.households).insert(
              HouseholdsCompanion.insert(name: 'Fresh Home', personCount: 1),
            );
        final roomId = await db.into(db.rooms).insert(
              RoomsCompanion.insert(
                householdId: householdId,
                name: 'Living Room',
              ),
            );
        final meterId = await db.into(db.heatingMeters).insert(
              HeatingMetersCompanion.insert(
                householdId: householdId,
                roomId: roomId,
                name: 'Radiator',
              ),
            );

        final meter = await (db.select(db.heatingMeters)
              ..where((m) => m.id.equals(meterId)))
            .getSingle();
        expect(meter.roomId, roomId);
        expect(meter.heatingType, HeatingType.ownMeter);
        expect(meter.heatingRatio, isNull);

        // Verify smart plug consumption uses month (not interval)
        final plugId = await db.into(db.smartPlugs).insert(
              SmartPlugsCompanion.insert(
                roomId: roomId,
                name: 'TV Plug',
              ),
            );
        final consumptionId = await db.into(db.smartPlugConsumptions).insert(
              SmartPlugConsumptionsCompanion.insert(
                smartPlugId: plugId,
                month: DateTime(2024, 3, 1),
                valueKwh: 5.5,
              ),
            );

        final consumption = await (db.select(db.smartPlugConsumptions)
              ..where((c) => c.id.equals(consumptionId)))
            .getSingle();
        expect(consumption.month.month, 3);
        expect(consumption.valueKwh, 5.5);

        await db.close();
      });
    });
  });
}
