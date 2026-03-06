---
name: flutter-meter-reading-crud
domain: crud
tech: [flutter, drift, provider, intl]
success_rate: 100%
times_used: 2
source_project: valtra
captured_at: 2026-03-06
validated_phases: [3-electricity, 6-gas]
---

## Context
Use this pattern when implementing meter reading functionality with:
- Timestamped cumulative readings (electricity, gas, water, heating)
- Delta/consumption calculation between readings
- Validation that readings must be >= previous (cumulative meters)
- Household/parent entity scoping

## Pattern

### Tasks

| # | Task | File | Dependencies |
|---|------|------|--------------|
| 1 | Create DAO | `lib/database/daos/{meter}_dao.dart` | None |
| 2 | Register DAO | `lib/database/app_database.dart` | Task 1 |
| 3 | Create Provider | `lib/providers/{meter}_provider.dart` | Task 2 |
| 4 | Create Screen | `lib/screens/{meter}_screen.dart` | Task 3 |
| 5 | Create Form Dialog | `lib/widgets/dialogs/{meter}_reading_form_dialog.dart` | None |
| 6 | Add Localization | `lib/l10n/app_*.arb` | None |
| 7 | Integrate Provider | `lib/main.dart` | Task 3 |
| 8 | Add Navigation | `lib/main.dart` | Task 4, 7 |
| 9 | Run Tests | `flutter test` | All |
| 10 | Static Analysis | `flutter analyze` | Task 9 |

### Wave Structure

```
Wave 1 (Parallel):  Task 1 (DAO), Task 5 (Dialog), Task 6 (L10n)
Wave 2 (Sequential): Task 2 (Register DAO)
Wave 3 (Sequential): Task 3 (Provider)
Wave 4 (Sequential): Task 4 (Screen)
Wave 5 (Parallel):   Task 7 (Integration), Task 8 (Navigation)
Wave 6 (Sequential): Task 9 (Tests) → Task 10 (Analyze)
```

### Key Components

#### DAO Methods
```dart
@DriftAccessor(tables: [MeterReadings])
class MeterDao extends DatabaseAccessor<AppDatabase> with _$MeterDaoMixin {
  Future<int> insertReading(MeterReadingsCompanion entry);
  Future<MeterReading> getReading(int id);
  Future<List<MeterReading>> getReadingsForHousehold(int householdId);
  Stream<List<MeterReading>> watchReadingsForHousehold(int householdId);
  Future<bool> updateReading(MeterReadingsCompanion entry);
  Future<void> deleteReading(int id);
  Future<MeterReading?> getPreviousReading(int householdId, DateTime timestamp);
  Future<MeterReading?> getNextReading(int householdId, DateTime timestamp);
  Future<MeterReading?> getLatestReading(int householdId);
}
```

#### Provider with Delta Calculation
```dart
class ReadingWithDelta {
  final MeterReading reading;
  final double? delta;  // null for oldest reading
}

class MeterProvider extends ChangeNotifier {
  List<ReadingWithDelta> get readingsWithDeltas {
    // Readings sorted newest first
    for (var i = 0; i < _readings.length; i++) {
      final current = _readings[i];
      final previous = i + 1 < _readings.length ? _readings[i + 1] : null;
      final delta = previous != null ? current.value - previous.value : null;
      result.add(ReadingWithDelta(reading: current, delta: delta));
    }
  }

  Future<String?> validateReading(double value, DateTime timestamp, {int? excludeId}) async {
    final previous = await _dao.getPreviousReading(_householdId!, timestamp);
    if (previous != null && previous.id != excludeId && value < previous.value) {
      return NumberFormat('#,##0.0').format(previous.value);
    }
    return null;
  }
}
```

#### Household Connection
```dart
// In ValtraApp State:
void _onHouseholdChanged() {
  widget.meterProvider.setHouseholdId(widget.householdProvider.selectedHouseholdId);
}
```

### Key Decisions
1. **Newest-first ordering** - Readings displayed newest first for easy recent access
2. **Delta on adjacent readings** - Delta calculated from list position, not database query
3. **Validation before save** - Provider validates against previous reading before DAO insert
4. **Edit validation** - Check both previous AND next readings when editing middle values
5. **Stream subscription** - Provider listens to DAO stream for automatic UI updates

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| `isSmallerThan(timestamp)` compilation error | Use `isSmallerThanValue(timestamp)` for DateTime comparison in Drift |
| Missing `Value` import in provider | Add `import 'package:drift/drift.dart'` |
| Widget tests timeout with Drift streams | Use `tester.runAsync()` and `await tester.pumpWidget(Container())` at end |
| `isNotNull`/`isNull` import conflict | Add `hide isNotNull, isNull` to drift import in tests |

### Test Coverage

| Component | Test Count | Coverage |
|-----------|------------|----------|
| DAO | 13 | CRUD, getPrevious/Next/Latest, filtering |
| Provider | 10 | Delta calculation, validation, CRUD |
| Screen | 6 | Empty state, list, FAB, edit, delete |
| Dialog | 6 | Validation, submit, cancel, edit mode |

### Localization Template

```json
{
  "{meter}Reading": "{Meter} Reading",
  "add{Meter}Reading": "Add Reading",
  "edit{Meter}Reading": "Edit Reading",
  "delete{Meter}Reading": "Delete Reading",
  "deleteReadingConfirm": "Are you sure you want to delete this reading?",
  "no{Meter}Readings": "No readings yet. Add your first meter reading!",
  "meterValue": "Meter Value",
  "consumptionSince": "+{value} {unit} since previous",
  "firstReading": "First reading",
  "readingMustBePositive": "Value must be positive",
  "readingMustBeGreaterOrEqual": "Value must be >= {previousValue} {unit}"
}
```

### UAT Criteria Template

1. **Add First Reading** - Shows "First reading" label
2. **Add Subsequent Reading** - Shows delta from previous
3. **Edit Reading** - Deltas recalculate correctly
4. **Delete Reading** - Adjacent readings' deltas update
5. **Validation Error** - Prevents value < previous reading
6. **Navigation** - Home screen chip navigates to meter screen

### Validated Implementations

| Phase | Meter | Unit | Value Field | Color |
|-------|-------|------|-------------|-------|
| 3 | Electricity | kWh | `valueKwh` | electricityColor (#FFD93D) |
| 6 | Gas | m³ | `valueCubicMeters` | gasColor (#FF8C42) |

### Adaptation Notes
- Copy DAO/Provider/Screen from previous meter type and replace:
  - Table name (`electricityReadings` → `gasReadings`)
  - Entity name (`ElectricityReading` → `GasReading`)
  - Value field (`valueKwh` → `valueCubicMeters`)
  - Unit display (`kWh` → `m³`)
  - Color (`electricityColor` → `gasColor`)
  - Icon (`Icons.electric_bolt` → `Icons.local_fire_department`)
  - Localization keys (prefix with meter type)
