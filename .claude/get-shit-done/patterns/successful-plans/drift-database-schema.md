---
name: drift-database-schema
domain: db
tech: [dart, drift, sqlite]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-06
---

## Context
Use this pattern when setting up Drift database schema for Flutter apps. Particularly useful for apps with hierarchical entity relationships (parent → child → readings).

## Pattern

### Table Structure

1. **Define Enums First**
```dart
enum WaterMeterType { cold, hot, other }
enum ConsumptionInterval { daily, weekly, monthly, yearly }
```

2. **Use @DataClassName for Singular Names**
```dart
@DataClassName('Household')
class Households extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

3. **Foreign Keys with References**
```dart
IntColumn get householdId => integer().references(Households, #id)();
```

4. **Use intEnum for Enum Columns**
```dart
IntColumn get type => intEnum<WaterMeterType>()();
```

5. **Real Numbers for Measurements**
```dart
RealColumn get valueKwh => real()();
RealColumn get valueCubicMeters => real()();
```

### Hierarchy Pattern

For meter-reading systems:
```
Household (top level)
  ├── ElectricityReadings (direct child, single meter per household)
  ├── GasReadings (direct child, single meter per household)
  ├── WaterMeters (multiple per household)
  │     └── WaterReadings
  ├── HeatingMeters (multiple per household)
  │     └── HeatingReadings
  └── Rooms (multiple per household)
        └── SmartPlugs
              └── SmartPlugConsumptions
```

### Database Class Pattern

```dart
@DriftDatabase(tables: [
  Households,
  ElectricityReadings,
  GasReadings,
  WaterMeters,
  WaterReadings,
  HeatingMeters,
  HeatingReadings,
  Rooms,
  SmartPlugs,
  SmartPlugConsumptions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => await m.createAll(),
  );
}
```

### Test Database Factory

```dart
import 'package:drift/native.dart';

AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
```

### Key Decisions

1. **Single file for all tables** - Drift generates one .g.dart, easier FK management
2. **@DataClassName for singular** - `Households` table → `Household` entity
3. **autoIncrement for IDs** - Let SQLite handle ID generation
4. **real() for measurements** - More precision than integer for meter values
5. **withDefault for timestamps** - `currentDateAndTime` sets on insert

### Common Pitfalls

1. **Forgetting to run build_runner** - Always run after schema changes
2. **Using `RealColumn` vs `IntColumn`** - Use `real()` for any measurement that might have decimals
3. **Missing references** - Always use `.references()` for foreign keys
4. **Enum column type** - Use `intEnum<T>()` not `text()` for enums

### Build Commands

```bash
# Generate database code
dart run build_runner build

# Delete and regenerate (if conflicts)
dart run build_runner build --delete-conflicting-outputs
```
