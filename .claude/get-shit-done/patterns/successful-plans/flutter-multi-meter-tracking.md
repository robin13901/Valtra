---
name: flutter-multi-meter-tracking
domain: crud
tech: [flutter, drift, provider, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-06
---

## Context
Use this pattern when implementing meter tracking that supports **multiple meters per household** with types/categories. Examples: water meters (cold/hot/other), heating meters. Differs from single-meter pattern (electricity/gas) by having:
- Parent entity: Meter (belongs to Household)
- Child entity: Reading (belongs to Meter)
- Type categorization on meter (enum field)

## Pattern

### Tasks

| # | Task | File | Dependencies |
|---|------|------|--------------|
| 1 | Create DAO | `lib/database/daos/{meter}_dao.dart` | None |
| 2 | Register DAO | `lib/database/app_database.dart` | Task 1 |
| 3 | Create Provider | `lib/providers/{meter}_provider.dart` | Task 2 |
| 4 | Add Localization | `lib/l10n/app_*.arb` | None |
| 5 | Create Meter Form Dialog | `lib/widgets/dialogs/{meter}_meter_form_dialog.dart` | None |
| 6 | Create Reading Form Dialog | `lib/widgets/dialogs/{meter}_reading_form_dialog.dart` | None |
| 7 | Create Screen | `lib/screens/{meter}_screen.dart` | Task 3, 5, 6 |
| 8 | Integrate Provider | `lib/main.dart` | Task 3 |
| 9 | Add Navigation | `lib/main.dart` | Task 7, 8 |

### Wave Structure

```
Wave 1 (Parallel):  Task 1 (DAO), Task 4 (L10n), Task 5 (Meter Dialog), Task 6 (Reading Dialog)
Wave 2 (Sequential): Task 2 (Register DAO)
Wave 3 (Sequential): Task 3 (Provider)
Wave 4 (Sequential): Task 7 (Screen)
Wave 5 (Parallel):   Task 8 (Integration), Task 9 (Navigation)
```

### Key Components

#### Database Tables
```dart
@DataClassName('WaterMeter')
class WaterMeters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get type => intEnum<WaterMeterType>()();  // cold, hot, other
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('WaterReading')
class WaterReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get waterMeterId => integer().references(WaterMeters, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get valueCubicMeters => real()();
}
```

#### DAO Structure (Two-Level CRUD)
```dart
@DriftAccessor(tables: [WaterMeters, WaterReadings])
class WaterDao extends DatabaseAccessor<AppDatabase> with _$WaterDaoMixin {
  // METER OPERATIONS
  Future<int> insertMeter(WaterMetersCompanion entry);
  Future<WaterMeter> getMeter(int id);
  Future<List<WaterMeter>> getMetersForHousehold(int householdId);
  Stream<List<WaterMeter>> watchMetersForHousehold(int householdId);
  Future<bool> updateMeter(WaterMetersCompanion entry);
  Future<void> deleteMeter(int id);  // CASCADE: also deletes readings
  Future<int> getReadingCountForMeter(int meterId);

  // READING OPERATIONS
  Future<int> insertReading(WaterReadingsCompanion entry);
  Future<WaterReading> getReading(int id);
  Future<List<WaterReading>> getReadingsForMeter(int meterId);  // Scoped to meter
  Stream<List<WaterReading>> watchReadingsForMeter(int meterId);
  Future<bool> updateReading(WaterReadingsCompanion entry);
  Future<void> deleteReading(int id);
  Future<void> deleteReadingsForMeter(int meterId);
  Future<WaterReading?> getPreviousReading(int meterId, DateTime timestamp);
  Future<WaterReading?> getNextReading(int meterId, DateTime timestamp);
  Future<WaterReading?> getLatestReading(int meterId);
}
```

#### Cascade Delete Pattern
```dart
Future<void> deleteMeter(int id) async {
  await transaction(() async {
    // Delete all readings for this meter first
    await (delete(waterReadings)..where((r) => r.waterMeterId.equals(id))).go();
    // Then delete the meter
    await (delete(waterMeters)..where((m) => m.id.equals(id))).go();
  });
}
```

#### Provider with Multi-Subscription
```dart
class WaterProvider extends ChangeNotifier {
  List<WaterMeter> _meters = [];
  final Map<int, List<WaterReading>> _readingsByMeter = {};
  final Map<int, StreamSubscription<List<WaterReading>>> _readingSubscriptions = {};
  StreamSubscription<List<WaterMeter>>? _metersSubscription;

  void setHouseholdId(int? householdId) {
    // Cancel existing subscriptions
    _metersSubscription?.cancel();
    _cancelAllReadingSubscriptions();
    _readingsByMeter.clear();

    // Subscribe to meters, then subscribe to readings for each meter
    _metersSubscription = _dao.watchMetersForHousehold(householdId).listen((meters) {
      _meters = meters;
      for (final meter in meters) {
        _subscribeToReadings(meter.id);
      }
      notifyListeners();
    });
  }

  void _subscribeToReadings(int meterId) {
    if (_readingSubscriptions.containsKey(meterId)) return;
    _readingSubscriptions[meterId] = _dao.watchReadingsForMeter(meterId).listen((readings) {
      _readingsByMeter[meterId] = readings;
      notifyListeners();
    });
  }

  void _cancelAllReadingSubscriptions() {
    for (final subscription in _readingSubscriptions.values) {
      subscription.cancel();
    }
    _readingSubscriptions.clear();
  }

  @override
  void dispose() {
    _metersSubscription?.cancel();
    _cancelAllReadingSubscriptions();
    super.dispose();
  }
}
```

#### Delta Calculation (Per-Meter)
```dart
List<WaterReadingWithDelta> getReadingsWithDeltas(int meterId) {
  final readings = _readingsByMeter[meterId] ?? [];
  final result = <WaterReadingWithDelta>[];

  for (var i = 0; i < readings.length; i++) {
    final current = readings[i];
    final previous = i + 1 < readings.length ? readings[i + 1] : null;
    final delta = previous != null
        ? current.valueCubicMeters - previous.valueCubicMeters
        : null;
    result.add(WaterReadingWithDelta(reading: current, deltaCubicMeters: delta));
  }
  return result;
}
```

### Screen Structure (Expandable Cards)

```dart
class WaterScreen extends StatelessWidget {
  // Build: Scaffold with ListView of _WaterMeterCard widgets
  // Each card is expandable to show readings
  // FAB to add new meter
}

class _WaterMeterCard extends StatelessWidget {
  // Header: meter name, type badge (Cold/Hot/Other), latest reading
  // Expandable body: list of readings with deltas
  // PopupMenuButton: Edit meter, Delete meter
  // Add Reading button inside card
}
```

### Key Decisions

1. **Two-level hierarchy** - Household → Meters → Readings
2. **Per-meter subscriptions** - Each meter has its own reading stream subscription
3. **Cascade delete with transaction** - Delete readings first, then meter, in one transaction
4. **Type badge display** - Show meter type (Cold/Hot/Other) as colored chip/badge
5. **Expandable cards** - Cards expand to show readings, collapse to save space
6. **Reading count warning** - Show count of readings in delete confirmation dialog
7. **Subscription cleanup on delete** - Cancel reading subscription when meter is deleted

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| Memory leak from subscriptions | Use Map to track subscriptions per meter, cancel all in dispose() |
| Readings showing for wrong meter | Query readings by meterId, not householdId |
| Cascade delete inconsistency | Wrap delete operations in transaction() |
| Stale readings after meter delete | Remove from _readingsByMeter map before DAO delete |
| Type enum persistence | Use `intEnum<T>()` in table definition, not `textEnum()` |

### Localization Template

```json
{
  "{meter}Meters": "{Meter} Meters",
  "add{Meter}Meter": "Add {Meter} Meter",
  "edit{Meter}Meter": "Edit {Meter} Meter",
  "delete{Meter}Meter": "Delete {Meter} Meter",
  "{meter}MeterName": "Meter Name",
  "{meter}MeterType": "Meter Type",
  "coldWater": "Cold Water",
  "hotWater": "Hot Water",
  "other{Meter}": "Other",
  "no{Meter}Meters": "No {meter} meters yet. Add one to start tracking!",
  "{meter}MeterHasReadings": "This meter has {count} reading(s). They will also be deleted.",
  "{meter}Reading": "{Meter} Reading",
  "add{Meter}Reading": "Add Reading",
  "edit{Meter}Reading": "Edit Reading",
  "delete{Meter}Reading": "Delete Reading",
  "no{Meter}Readings": "No readings yet. Add your first meter reading!",
  "{meter}ConsumptionSince": "+{value} {unit} since previous"
}
```

### Test Coverage

| Component | Test Count | Coverage |
|-----------|------------|----------|
| DAO | 24 | Meter CRUD, Reading CRUD, cascade, queries |
| Provider | 16 | Meters, readings, deltas, validation |
| Meter Form Dialog | 6 | Create/edit mode, type selection, validation |
| Reading Form Dialog | 7 | Create/edit mode, value input, validation |
| Screen | 10 | Empty states, CRUD flows, delta display |

### UAT Criteria Template

1. **Create Meter** - Dialog shows type selector, meter appears in list
2. **Add Reading to Meter** - Reading scoped to correct meter
3. **Edit Meter** - Type and name update correctly
4. **Delete Meter** - Warning shows reading count, cascade deletes readings
5. **Consumption Deltas** - Per-meter delta calculation works correctly
6. **Localization** - All strings translated (EN/DE)
