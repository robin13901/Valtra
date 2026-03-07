# Phase 7: Heating Meter Tracking

## Goal
Implement complete heating meter tracking with support for multiple meters per household, each with a name and optional location (e.g., room name). Users can create heating meters, log readings with timestamps (unit-less consumption units), and view consumption history with delta calculations. Follows the multi-meter pattern established in Phase 5 (Water).

## Requirements Coverage
- **FR-6.1**: Create multiple heating consumption meters per household
- **FR-6.2**: Each meter has name and location (e.g., room name)
- **FR-6.3**: Log readings with date/time and value (unit-less consumption units)
- **FR-6.4**: Typical reading pattern: 1st of month, but arbitrary timestamps supported

## Dependencies
- Phase 1: Project setup (completed) — database tables already defined in `tables.dart`
- Phase 2: Household management (completed) — needed for household scoping
- HeatingMeters and HeatingReadings tables already exist in `tables.dart`

## Success Criteria
- [ ] User can create multiple heating meters per household with name and optional location
- [ ] User can add readings with date/time and value (unit-less consumption units)
- [ ] Readings are displayed per meter with consumption deltas
- [ ] User can edit and delete both meters and readings
- [ ] Cascade delete: deleting a meter also deletes its readings
- [ ] Validation prevents readings less than previous (cumulative meter)
- [ ] All UI strings are localized (EN/DE)
- [ ] All CRUD operations have corresponding unit tests
- [ ] UI screens have widget tests
- [ ] All code passes `flutter analyze` with no issues
- [ ] 100% statement coverage on new code

---

## Tasks

### Task 1: Create HeatingDao
**File**: `lib/database/daos/heating_dao.dart`
**Description**: Data access object for heating meter and reading CRUD operations using Drift DAO pattern (following WaterDao pattern for multi-meter support)
**Depends on**: None

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'heating_dao.g.dart';

@DriftAccessor(tables: [HeatingMeters, HeatingReadings])
class HeatingDao extends DatabaseAccessor<AppDatabase> with _$HeatingDaoMixin {
  HeatingDao(super.db);

  // METER OPERATIONS (mirror WaterDao meter methods):
  // - Future<int> insertMeter(HeatingMetersCompanion entry)
  // - Future<HeatingMeter> getMeter(int id)
  // - Future<List<HeatingMeter>> getMetersForHousehold(int householdId)
  // - Stream<List<HeatingMeter>> watchMetersForHousehold(int householdId)
  // - Future<bool> updateMeter(HeatingMetersCompanion entry)
  // - Future<void> deleteMeter(int id)  // CASCADE: also deletes readings
  // - Future<int> getReadingCountForMeter(int meterId)

  // READING OPERATIONS (mirror WaterDao reading methods):
  // - Future<int> insertReading(HeatingReadingsCompanion entry)
  // - Future<HeatingReading> getReading(int id)
  // - Future<List<HeatingReading>> getReadingsForMeter(int meterId)
  // - Stream<List<HeatingReading>> watchReadingsForMeter(int meterId)
  // - Future<bool> updateReading(HeatingReadingsCompanion entry)
  // - Future<void> deleteReading(int id)
  // - Future<void> deleteReadingsForMeter(int meterId)
  // - Future<HeatingReading?> getPreviousReading(int meterId, DateTime timestamp)
  // - Future<HeatingReading?> getLatestReading(int meterId)
  // - Future<HeatingReading?> getNextReading(int meterId, DateTime timestamp)
}
```

**Implementation Details**:
- Copy WaterDao structure, replace `waterMeters`/`waterReadings` with `heatingMeters`/`heatingReadings`
- Replace `WaterMeter`/`WaterReading` with `HeatingMeter`/`HeatingReading`
- Replace `waterMeterId` references with `heatingMeterId`
- HeatingMeter has `location` (nullable text) instead of `type` (intEnum)
- HeatingReading has `value` field (not `valueCubicMeters`)
- Sort readings by timestamp descending (newest first)
- Cascade delete: wrap meter deletion in transaction, delete readings first

**Test file**: `test/database/daos/heating_dao_test.dart`
- Test insert and retrieve meter
- Test get meters for household (filtered by householdId)
- Test update meter (name and location)
- Test delete meter cascades to readings
- Test getReadingCountForMeter
- Test insert and retrieve reading
- Test watch stream emits on changes
- Test update reading modifies existing record
- Test delete reading removes record
- Test deleteReadingsForMeter
- Test getPreviousReading returns correct reading
- Test getLatestReading returns most recent
- Test getNextReading returns correct reading
- Test readings filtered by meterId

---

### Task 2: Register HeatingDao in AppDatabase
**File**: `lib/database/app_database.dart`
**Description**: Add HeatingDao as accessor to AppDatabase
**Depends on**: Task 1

```dart
// Add import:
import 'daos/heating_dao.dart';

// Add to @DriftDatabase daos list:
daos: [...existing..., HeatingDao]

// Add accessor:
@override
HeatingDao get heatingDao => HeatingDao(this);
```

**Verification**: Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate database

---

### Task 3: Create HeatingProvider
**File**: `lib/providers/heating_provider.dart`
**Description**: State management for heating meters and readings (following WaterProvider multi-meter pattern)
**Depends on**: Task 1, Task 2

```dart
class HeatingReadingWithDelta {
  final HeatingReading reading;
  final double? delta;  // null for oldest reading (unit-less)

  const HeatingReadingWithDelta({required this.reading, this.delta});
}

class HeatingProvider extends ChangeNotifier {
  final HeatingDao _dao;

  List<HeatingMeter> _meters = [];
  final Map<int, List<HeatingReading>> _readingsByMeter = {};
  final Map<int, StreamSubscription<List<HeatingReading>>> _readingSubscriptions = {};
  int? _householdId;
  int? _selectedMeterId;
  StreamSubscription<List<HeatingMeter>>? _metersSubscription;

  // Key functionality (mirror WaterProvider):
  // Getters: meters, householdId, selectedMeterId
  //
  // Household management:
  // - void setHouseholdId(int? householdId)
  // - void setSelectedMeterId(int? meterId)
  //
  // Meter operations:
  // - Future<int> addMeter(String name, String? location)
  // - Future<bool> updateMeter(int id, String name, String? location)
  // - Future<void> deleteMeter(int id)
  // - Future<int> getReadingCountForMeter(int meterId)
  //
  // Reading operations:
  // - Future<int> addReading(int meterId, DateTime timestamp, double value)
  // - Future<bool> updateReading(int id, DateTime timestamp, double value)
  // - Future<void> deleteReading(int id)
  // - List<HeatingReadingWithDelta> getReadingsWithDeltas(int meterId)
  //
  // Validation:
  // - Future<String?> validateReading(int meterId, double value, DateTime timestamp, {int? excludeId})
  //   Returns formatted previous value string if invalid, null if valid
}
```

**Provider Architecture Notes**:
- Stream subscription per household for meters
- Stream subscription per meter for readings (stored in Map)
- Clean up all subscriptions when householdId changes or on dispose()
- Delta is `current.value - previous.value` (unit-less)

**Test file**: `test/providers/heating_provider_test.dart`
- Test setHouseholdId triggers meter refresh and clears old subscriptions
- Test addMeter creates record in database
- Test updateMeter modifies existing meter
- Test deleteMeter removes meter and cancels reading subscription
- Test addReading creates record in database
- Test updateReading modifies record
- Test deleteReading removes record
- Test getReadingsWithDeltas calculates correct deltas
- Test validateReading returns error when value < previous reading
- Test validateReading returns null for valid readings
- Test setHouseholdId(null) clears all state
- Test getReadingCountForMeter returns correct count

---

### Task 4: Add Localization Strings
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Description**: Add heating-related localization strings (following water pattern)
**Depends on**: None

**New strings to add (EN)**:
```json
{
  "heatingMeters": "Heating Meters",
  "addHeatingMeter": "Add Heating Meter",
  "editHeatingMeter": "Edit Heating Meter",
  "deleteHeatingMeter": "Delete Heating Meter",
  "heatingMeterName": "Meter Name",
  "heatingMeterNameHint": "Enter meter name",
  "heatingMeterLocation": "Location",
  "heatingMeterLocationHint": "e.g. Living Room (optional)",
  "noHeatingMeters": "No heating meters yet. Add one to start tracking heating consumption!",
  "heatingMeterNameRequired": "Meter name is required",
  "deleteHeatingMeterConfirm": "Are you sure you want to delete this heating meter?",
  "heatingMeterHasReadings": "This meter has {count} reading(s). They will also be deleted.",
  "@heatingMeterHasReadings": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "heatingReading": "Heating Reading",
  "heatingReadings": "Heating Readings",
  "addHeatingReading": "Add Reading",
  "editHeatingReading": "Edit Reading",
  "deleteHeatingReading": "Delete Reading",
  "deleteHeatingReadingConfirm": "Are you sure you want to delete this reading?",
  "noHeatingReadings": "No readings yet. Add your first meter reading!",
  "heatingConsumptionSince": "+{value} units since previous",
  "@heatingConsumptionSince": {
    "placeholders": {
      "value": {"type": "String"}
    }
  },
  "heatingReadingMustBeGreaterOrEqual": "Value must be >= {previousValue}",
  "@heatingReadingMustBeGreaterOrEqual": {
    "placeholders": {
      "previousValue": {"type": "String"}
    }
  }
}
```

**German translations (DE)**:
```json
{
  "heatingMeters": "Heizungszähler",
  "addHeatingMeter": "Heizungszähler hinzufügen",
  "editHeatingMeter": "Heizungszähler bearbeiten",
  "deleteHeatingMeter": "Heizungszähler löschen",
  "heatingMeterName": "Zählername",
  "heatingMeterNameHint": "Zählernamen eingeben",
  "heatingMeterLocation": "Standort",
  "heatingMeterLocationHint": "z.B. Wohnzimmer (optional)",
  "noHeatingMeters": "Noch keine Heizungszähler. Fügen Sie einen hinzu, um den Heizverbrauch zu verfolgen!",
  "heatingMeterNameRequired": "Zählername ist erforderlich",
  "deleteHeatingMeterConfirm": "Möchten Sie diesen Heizungszähler wirklich löschen?",
  "heatingMeterHasReadings": "Dieser Zähler hat {count} Ablesung(en). Diese werden ebenfalls gelöscht.",
  "heatingReading": "Heizungsablesung",
  "heatingReadings": "Heizungsablesungen",
  "addHeatingReading": "Ablesung hinzufügen",
  "editHeatingReading": "Ablesung bearbeiten",
  "deleteHeatingReading": "Ablesung löschen",
  "deleteHeatingReadingConfirm": "Möchten Sie diese Ablesung wirklich löschen?",
  "noHeatingReadings": "Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!",
  "heatingConsumptionSince": "+{value} Einheiten seit letzter Ablesung",
  "heatingReadingMustBeGreaterOrEqual": "Der Wert muss >= {previousValue} sein"
}
```

**Verification**: Run `flutter gen-l10n` to generate localization classes

---

### Task 5: Create Heating Meter Form Dialog
**File**: `lib/widgets/dialogs/heating_meter_form_dialog.dart`
**Description**: Dialog for creating/editing heating meters with name and optional location (following WaterMeterFormDialog pattern but with location instead of type)
**Depends on**: Task 4

```dart
class HeatingMeterFormDialog extends StatefulWidget {
  final HeatingMeter? meter;  // null for create, non-null for edit

  static Future<HeatingMeterFormData?> show(
    BuildContext context, {
    HeatingMeter? meter,
  });
}

class HeatingMeterFormData {
  final String name;
  final String? location;  // optional room/zone name
}
```

**UI Components**:
- TextFormField for name (required, max 100 chars)
- TextFormField for location (optional, max 100 chars, hint: "e.g. Living Room")
- Cancel and Save buttons
- Form validation: name is required

**Key Difference from Water**: No type enum/SegmentedButton. Instead, a simple optional text field for location.

**Test file**: `test/widgets/dialogs/heating_meter_form_dialog_test.dart`
- Test create mode shows empty fields
- Test edit mode pre-fills name and location
- Test validation (name required, location optional)
- Test save returns form data with name and location
- Test save returns form data with name only (no location)
- Test cancel returns null

---

### Task 6: Create Heating Reading Form Dialog
**File**: `lib/widgets/dialogs/heating_reading_form_dialog.dart`
**Description**: Dialog for creating/editing heating readings (following WaterReadingFormDialog pattern but with unit-less value)
**Depends on**: Task 4

```dart
class HeatingReadingFormDialog extends StatefulWidget {
  final HeatingReading? reading;  // null for create, non-null for edit

  static Future<HeatingReadingFormData?> show(
    BuildContext context, {
    HeatingReading? reading,
  });
}

class HeatingReadingFormData {
  final DateTime timestamp;
  final double value;  // unit-less consumption units
}
```

**UI Components**:
- DateTimePicker for timestamp (defaults to now)
- TextFormField for value — numeric input with decimals
- No unit suffix (unit-less consumption units)
- Cancel and Save buttons
- Form validation: value must be positive

**Test file**: `test/widgets/dialogs/heating_reading_form_dialog_test.dart`
- Test create mode shows empty value and current time
- Test edit mode pre-fills timestamp and value
- Test validation (positive number required)
- Test save returns form data
- Test cancel returns null
- Test date/time picker works

---

### Task 7: Create Heating Screen
**File**: `lib/screens/heating_screen.dart`
**Description**: Screen showing heating meters with expandable reading lists (following WaterScreen pattern)
**Depends on**: Task 3, Task 4, Task 5, Task 6

**UI Structure**:
- AppBar with title from `l10n.heating`
- If no meters: empty state with icon (Icons.thermostat) and "Add meter" prompt
- If meters exist: ListView of expandable `_HeatingMeterCard` widgets
- FAB to add new meter

**_HeatingMeterCard Layout**:
```
┌──────────────────────────────────────┐
│  🌡️ Bedroom Radiator            ⋮  │
│  📍 Bedroom                         │
│  ────────────────────────────────────│
│  ▼ Readings (3)                      │
│  ┌────────────────────────────────┐  │
│  │ 📅 2024-03-15 10:30           │  │
│  │ 1,234.5                       │  │
│  │ +12.3 units since previous    │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ 📅 2024-02-01 00:00           │  │
│  │ 1,222.2                       │  │
│  │ First reading                 │  │
│  └────────────────────────────────┘  │
│  [+ Add Reading]                     │
└──────────────────────────────────────┘
```

**Card Features**:
- Header: meter name, location (if set) as subtitle, latest reading value
- Icon: `Icons.thermostat`, color: `AppColors.heatingColor` (#FF6B6B)
- Expandable body: list of readings with deltas
- PopupMenuButton: Edit meter, Delete meter (with confirmation + reading count warning)
- "Add Reading" button inside expanded card
- Per-reading PopupMenuButton: Edit reading, Delete reading

**Test file**: `test/screens/heating_screen_test.dart`
- Test empty state when no meters
- Test meter list displays correctly
- Test meter shows location subtitle when set
- Test meter hides location when null
- Test add meter flow (FAB → dialog → meter appears)
- Test edit meter flow
- Test delete meter with confirmation (shows reading count)
- Test add reading flow
- Test shows delta values correctly
- Test shows "First reading" for oldest reading

---

### Task 8: Register HeatingProvider in main.dart
**File**: `lib/main.dart`
**Description**: Add HeatingProvider to MultiProvider and connect to household changes
**Depends on**: Task 2, Task 3

**Changes**:
```dart
// Add imports:
import 'database/daos/heating_dao.dart';
import 'providers/heating_provider.dart';

// In main():
final heatingProvider = HeatingProvider(HeatingDao(database));

// Connect to initial household:
if (householdProvider.selectedHouseholdId != null) {
  // ...existing providers...
  heatingProvider.setHouseholdId(householdProvider.selectedHouseholdId);
}

// Add to ValtraApp constructor:
required this.heatingProvider,

// In _ValtraAppState._onHouseholdChanged():
widget.heatingProvider.setHouseholdId(householdId);

// Add to MultiProvider:
ChangeNotifierProvider<HeatingProvider>.value(value: widget.heatingProvider),
```

---

### Task 9: Add Navigation to Heating Screen
**File**: `lib/main.dart`
**Description**: Enable navigation from home screen heating chip to HeatingScreen
**Depends on**: Task 7, Task 8

**Changes**:
```dart
// Import:
import 'screens/heating_screen.dart';

// Update heating chip to add onTap:
_buildCategoryChip(
  context,
  Icons.thermostat,
  l10n.heating,
  AppColors.heatingColor,
  onTap: () => _navigateToHeating(context),
),

// Add navigation method:
void _navigateToHeating(BuildContext context) {
  final householdProvider = context.read<HouseholdProvider>();
  if (householdProvider.selectedHousehold == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.selectHousehold),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const HeatingScreen()),
  );
}
```

---

### Task 10: Verify All Tests Pass
**Command**: `flutter test`
**Description**: Run full test suite and ensure 100% pass rate
**Depends on**: All previous tasks

---

### Task 11: Run Static Analysis
**Command**: `flutter analyze`
**Description**: Fix any lint warnings or errors
**Depends on**: Task 10

---

## File Structure After Phase 7

```
lib/
├── database/
│   ├── daos/
│   │   ├── electricity_dao.dart
│   │   ├── gas_dao.dart
│   │   ├── heating_dao.dart             # NEW
│   │   ├── household_dao.dart
│   │   ├── room_dao.dart
│   │   ├── smart_plug_dao.dart
│   │   └── water_dao.dart
│   ├── app_database.dart                # MODIFIED (add HeatingDao)
│   └── tables.dart                      # UNCHANGED (tables already exist)
├── providers/
│   ├── electricity_provider.dart
│   ├── gas_provider.dart
│   ├── heating_provider.dart            # NEW
│   ├── household_provider.dart
│   ├── room_provider.dart
│   ├── smart_plug_provider.dart
│   └── water_provider.dart
├── screens/
│   ├── electricity_screen.dart
│   ├── gas_screen.dart
│   ├── heating_screen.dart              # NEW
│   ├── smart_plugs_screen.dart
│   └── water_screen.dart
├── widgets/
│   ├── dialogs/
│   │   ├── electricity_reading_form_dialog.dart
│   │   ├── gas_reading_form_dialog.dart
│   │   ├── heating_meter_form_dialog.dart       # NEW
│   │   ├── heating_reading_form_dialog.dart     # NEW
│   │   ├── household_form_dialog.dart
│   │   ├── water_meter_form_dialog.dart
│   │   └── water_reading_form_dialog.dart
│   └── ...
├── l10n/
│   ├── app_en.arb                       # MODIFIED (add heating strings)
│   └── app_de.arb                       # MODIFIED (add heating strings)
└── main.dart                            # MODIFIED (provider + navigation)

test/
├── database/
│   ├── daos/
│   │   ├── heating_dao_test.dart        # NEW
│   │   └── ...
├── providers/
│   ├── heating_provider_test.dart       # NEW
│   └── ...
├── screens/
│   ├── heating_screen_test.dart         # NEW
│   └── ...
└── widgets/
    ├── dialogs/
    │   ├── heating_meter_form_dialog_test.dart   # NEW
    │   ├── heating_reading_form_dialog_test.dart # NEW
    │   └── ...
```

## Execution Order

**Wave 1 (Parallel)**:
- Task 1 (HeatingDao) — Core data layer
- Task 4 (Localization) — No dependencies
- Task 5 (Meter Form Dialog) — UI component
- Task 6 (Reading Form Dialog) — UI component

**Wave 2 (Sequential)**:
- Task 2 (Register DAO + code gen) — After Task 1

**Wave 3 (Sequential)**:
- Task 3 (Provider) — After Task 2

**Wave 4 (Sequential)**:
- Task 7 (Screen) — After Task 3, Task 4, Task 5, Task 6

**Wave 5 (Parallel)**:
- Task 8 (Provider Integration) — After Task 3
- Task 9 (Navigation) — After Task 7, Task 8

**Wave 6 (Final)**:
- Task 10 (Tests) — After all implementation
- Task 11 (Analysis) — After tests pass

```
Wave 1:  Task 1 ─────┐
         Task 4       │
         Task 5       │
         Task 6       │
                      ▼
Wave 2:  Task 2 ─────►
                      │
Wave 3:  Task 3 ◄────┘
                      │
Wave 4:  Task 7 ◄────┘
                      │
Wave 5:  Task 8, Task 9
                      │
Wave 6:  Task 10 ──► Task 11
```

## Estimated Duration
3-4 hours (Medium complexity — mirrors Water implementation with minor adaptations)

## Technical Notes

### Key Differences from Water (Phase 5)
| Aspect | Water | Heating |
|--------|-------|---------|
| Meter categorization | `type` (IntEnum: cold/hot/other) | `location` (nullable Text) |
| Reading value field | `valueCubicMeters` | `value` |
| Unit display | m³ | (none — unit-less consumption units) |
| Meter form | Name + SegmentedButton for type | Name + TextFormField for location |
| Icon | `Icons.water_drop` | `Icons.thermostat` |
| Color | `AppColors.waterColor` (#6BC5F8) | `AppColors.heatingColor` (#FF6B6B) |

### Delta Calculation
```dart
delta = currentReading.value - previousReading.value
```
Where `previousReading` is the reading with the closest timestamp BEFORE the current reading, scoped to the same meter.

### Validation Logic
When adding/editing a reading:
1. Find the reading immediately BEFORE the timestamp (for the same meterId)
2. Ensure value >= previousReading.value
3. If editing, also check value doesn't invalidate the next reading

### Number Formatting
Use `NumberFormat` from `intl` package:
```dart
final formatter = NumberFormat('#,##0.0');
formatter.format(1234.56);  // "1,234.6"
```
No unit suffix displayed (unit-less consumption units per FR-6.3).

### Cascade Delete
```dart
Future<void> deleteMeter(int id) async {
  await transaction(() async {
    await (delete(heatingReadings)..where((r) => r.heatingMeterId.equals(id))).go();
    await (delete(heatingMeters)..where((m) => m.id.equals(id))).go();
  });
}
```

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Multi-meter subscription leaks | Copy proven WaterProvider pattern with Map-based subscription tracking |
| Location field null handling | Test both with and without location in all layers |
| Unit-less display confusion | Use "units" in localization strings for clarity |
| Code duplication from Water | Acceptable — keeps code explicit and simple |

## UAT Criteria

### UAC-H1: Create Heating Meter
- Given I have a household selected
- When I tap FAB on heating screen and enter name "Bedroom Radiator" with location "Bedroom"
- Then the meter appears in the list with name and location

### UAC-H2: Create Meter Without Location
- Given I have a household selected
- When I create a meter with name "Hall Radiator" and leave location empty
- Then the meter appears without a location subtitle

### UAC-H3: Add First Reading
- Given I have a heating meter
- When I tap "Add Reading" and enter 1000.0
- Then the reading appears as "First reading"

### UAC-H4: Add Subsequent Reading
- Given I have a reading of 1000.0
- When I add a new reading of 1050.5
- Then it shows "+50.5 units since previous"

### UAC-H5: Delete Meter Cascade
- Given I have a meter with 3 readings
- When I delete the meter and confirm
- Then the confirmation shows "3 reading(s) will also be deleted"
- And both the meter and all readings are removed

### UAC-H6: Validation Error
- Given I have a reading of 1000.0
- When I try to add 950.0
- Then I see error "Value must be >= 1,000.0"

### UAC-H7: Navigation
- Given I am on the home screen with a household selected
- When I tap the "Heating" chip
- Then I navigate to the Heating screen
