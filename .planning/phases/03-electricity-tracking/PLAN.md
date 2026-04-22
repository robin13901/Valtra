# Phase 3: Electricity Tracking

## Goal
Implement complete electricity meter reading functionality including data layer (DAO), state management (Provider), and UI screens for managing readings, enabling users to log electricity meter readings and view consumption history with delta calculations.

## Requirements Coverage
- **FR-2.1**: Log electricity meter readings with date/time and value (kWh)
- **FR-2.2**: Each household has exactly one main electricity meter (implicit via householdId)
- **FR-2.3**: Display reading history with consumption deltas
- **FR-2.4**: Support editing and deleting historical readings

## Success Criteria
1. User can add a new electricity reading with date/time and kWh value
2. User can view list of all readings for current household sorted by timestamp (newest first)
3. Each reading shows the consumption delta from the previous reading
4. User can edit existing readings
5. User can delete readings (with confirmation)
6. Validation prevents readings less than previous (cumulative meter)
7. All CRUD operations have corresponding unit tests
8. UI screens have widget tests
9. All code passes `flutter analyze` with no issues

---

## Tasks

### Task 1: Create ElectricityDao
**File**: `lib/database/daos/electricity_dao.dart`
**Description**: Data access object for electricity reading CRUD operations using Drift DAO pattern
**Depends on**: None

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'electricity_dao.g.dart';

@DriftAccessor(tables: [ElectricityReadings])
class ElectricityDao extends DatabaseAccessor<AppDatabase>
    with _$ElectricityDaoMixin {
  ElectricityDao(super.db);

  // Key methods to implement:
  // - Future<int> insertReading(ElectricityReadingsCompanion entry)
  // - Future<ElectricityReading> getReading(int id)
  // - Future<List<ElectricityReading>> getReadingsForHousehold(int householdId)
  // - Stream<List<ElectricityReading>> watchReadingsForHousehold(int householdId)
  // - Future<bool> updateReading(ElectricityReadingsCompanion entry)
  // - Future<void> deleteReading(int id)
  // - Future<ElectricityReading?> getPreviousReading(int householdId, DateTime timestamp)
  // - Future<ElectricityReading?> getLatestReading(int householdId)
}
```

**Implementation Details**:
- Sort readings by timestamp descending (newest first)
- `getPreviousReading` finds the reading immediately before a given timestamp
- `getLatestReading` returns the most recent reading for validation

**Test file**: `test/database/electricity_dao_test.dart`
- Test insert and retrieve reading
- Test watch stream emits on changes
- Test update modifies existing record
- Test delete removes record
- Test getPreviousReading returns correct reading
- Test getLatestReading returns most recent
- Test readings filtered by householdId

---

### Task 2: Register ElectricityDao in AppDatabase
**File**: `lib/database/app_database.dart`
**Description**: Add ElectricityDao as accessor to AppDatabase
**Depends on**: Task 1

```dart
// Add import:
import 'daos/electricity_dao.dart';

// Add to AppDatabase:
ElectricityDao get electricityDao => ElectricityDao(this);
```

**Verification**: Run `dart run build_runner build` to regenerate database

---

### Task 3: Create ElectricityProvider
**File**: `lib/providers/electricity_provider.dart`
**Description**: State management for electricity readings
**Depends on**: Task 1, Task 2

```dart
// Key functionality:
// - Stream<List<ElectricityReading>> readings (filtered by current household)
// - List<ReadingWithDelta> readingsWithDeltas (calculated property)
// - Future<void> addReading(DateTime timestamp, double valueKwh)
// - Future<void> updateReading(int id, DateTime timestamp, double valueKwh)
// - Future<void> deleteReading(int id)
// - Future<String?> validateReading(double value, DateTime timestamp, {int? excludeId})
//   Returns error message if invalid, null if valid
// - void setHouseholdId(int householdId) - called when household changes
```

**ReadingWithDelta class**:
```dart
class ReadingWithDelta {
  final ElectricityReading reading;
  final double? deltaKwh;  // null for oldest reading

  ReadingWithDelta({required this.reading, this.deltaKwh});
}
```

**Test file**: `test/providers/electricity_provider_test.dart`
- Test readings stream updates when household changes
- Test addReading creates record in database
- Test validateReading returns error when value < previous reading
- Test validateReading returns null for valid readings
- Test readingsWithDeltas calculates correct deltas
- Test deleteReading removes record

---

### Task 4: Create Electricity Screen
**File**: `lib/screens/electricity_screen.dart`
**Description**: Screen showing list of electricity readings with add/edit/delete actions
**Depends on**: Task 3

**UI Components**:
- AppBar with title "Electricity"
- Show unit (kWh) in app bar subtitle or chip
- ListView.builder for reading cards
- Each card shows: timestamp, value (kWh), delta from previous
- FloatingActionButton to add new reading
- Tap on card to edit
- Long-press or menu to delete (with confirmation)
- Empty state when no readings

**Card Layout**:
```
┌──────────────────────────────────────┐
│  📅 2024-03-15 10:30              ⋮  │
│  ────────────────────────────────────│
│  12,345.6 kWh                        │
│  +156.4 kWh since previous           │
└──────────────────────────────────────┘
```

**Test file**: `test/screens/electricity_screen_test.dart`
- Test displays list of readings
- Test FAB opens add dialog
- Test tap opens edit dialog
- Test shows empty state when no readings
- Test shows delta values correctly

---

### Task 5: Create Electricity Reading Form Dialog
**File**: `lib/widgets/dialogs/electricity_reading_form_dialog.dart`
**Description**: Reusable dialog for creating/editing electricity readings
**Depends on**: None

**UI Components**:
- DateTimePicker for timestamp (defaults to now)
- TextFormField for value (kWh) - numeric input with decimals
- Cancel and Save buttons
- Form validation:
  - Value must be positive
  - Value must be >= previous reading (validation via provider)
- Shows error message from validation inline

**Dialog Pattern** (following HouseholdFormDialog):
```dart
class ElectricityReadingFormDialog extends StatefulWidget {
  final ElectricityReading? reading;  // null for create, non-null for edit

  static Future<ElectricityReadingFormData?> show(
    BuildContext context, {
    ElectricityReading? reading,
  });
}

class ElectricityReadingFormData {
  final DateTime timestamp;
  final double valueKwh;
}
```

**Test file**: `test/widgets/electricity_reading_form_dialog_test.dart`
- Test form validates empty value
- Test form validates non-numeric input
- Test form submits with valid data
- Test cancel closes dialog without saving
- Test edit mode pre-fills fields
- Test date/time picker works

---

### Task 6: Add Localization Strings
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Description**: Add electricity-related strings
**Depends on**: None

**New strings to add** (EN):
```json
{
  "electricityReading": "Electricity Reading",
  "electricityReadings": "Electricity Readings",
  "addElectricityReading": "Add Reading",
  "editElectricityReading": "Edit Reading",
  "deleteElectricityReading": "Delete Reading",
  "deleteReadingConfirm": "Are you sure you want to delete this reading?",
  "noElectricityReadings": "No readings yet. Add your first meter reading!",
  "meterValue": "Meter Value",
  "meterValueHint": "Enter current meter value",
  "consumptionSince": "+{value} kWh since previous",
  "@consumptionSince": {
    "placeholders": {
      "value": {"type": "String"}
    }
  },
  "firstReading": "First reading",
  "readingMustBePositive": "Value must be positive",
  "readingMustBeGreaterOrEqual": "Value must be greater than or equal to previous reading ({previousValue} kWh)",
  "@readingMustBeGreaterOrEqual": {
    "placeholders": {
      "previousValue": {"type": "String"}
    }
  },
  "dateAndTime": "Date & Time"
}
```

**German translations**:
```json
{
  "electricityReading": "Stromablesung",
  "electricityReadings": "Stromablesungen",
  "addElectricityReading": "Ablesung hinzufügen",
  "editElectricityReading": "Ablesung bearbeiten",
  "deleteElectricityReading": "Ablesung löschen",
  "deleteReadingConfirm": "Möchten Sie diese Ablesung wirklich löschen?",
  "noElectricityReadings": "Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!",
  "meterValue": "Zählerstand",
  "meterValueHint": "Aktuellen Zählerstand eingeben",
  "consumptionSince": "+{value} kWh seit letzter Ablesung",
  "firstReading": "Erste Ablesung",
  "readingMustBePositive": "Der Wert muss positiv sein",
  "readingMustBeGreaterOrEqual": "Der Wert muss größer oder gleich der vorherigen Ablesung sein ({previousValue} kWh)",
  "dateAndTime": "Datum & Uhrzeit"
}
```

---

### Task 7: Integrate ElectricityProvider in main.dart
**File**: `lib/main.dart`
**Description**: Add ElectricityProvider to MultiProvider and connect to household changes
**Depends on**: Task 3

**Changes**:
- Create and initialize ElectricityProvider with ElectricityDao
- Add to MultiProvider
- Listen to HouseholdProvider changes to update electricity readings

```dart
// Add to main():
final electricityProvider = ElectricityProvider(ElectricityDao(database));

// In ValtraApp constructor, add:
required this.electricityProvider,

// In MultiProvider:
ChangeNotifierProvider<ElectricityProvider>.value(value: electricityProvider),

// In HomeScreen or navigation, listen to household changes:
// When selectedHouseholdId changes, call electricityProvider.setHouseholdId(id)
```

---

### Task 8: Add Navigation to Electricity Screen
**File**: `lib/main.dart` (or create navigation widget)
**Description**: Enable navigation from home screen to electricity screen
**Depends on**: Task 4, Task 7

**Changes**:
- Make electricity category chip tappable
- Navigate to ElectricityScreen on tap
- Ensure back navigation works correctly

---

### Task 9: Verify All Tests Pass
**Command**: `flutter test`
**Description**: Run full test suite and ensure 100% pass rate
**Depends on**: All previous tasks

---

### Task 10: Run Static Analysis
**Command**: `flutter analyze`
**Description**: Fix any lint warnings or errors
**Depends on**: Task 9

---

## File Structure After Phase 3

```
lib/
├── database/
│   ├── daos/
│   │   ├── household_dao.dart
│   │   └── electricity_dao.dart       # NEW
│   ├── app_database.dart              # MODIFIED
│   └── ...
├── providers/
│   ├── household_provider.dart
│   ├── electricity_provider.dart      # NEW
│   └── ...
├── screens/
│   ├── households_screen.dart
│   └── electricity_screen.dart        # NEW
├── widgets/
│   ├── dialogs/
│   │   ├── household_form_dialog.dart
│   │   └── electricity_reading_form_dialog.dart  # NEW
│   └── ...
├── l10n/
│   ├── app_en.arb                     # MODIFIED
│   └── app_de.arb                     # MODIFIED
└── main.dart                          # MODIFIED

test/
├── database/
│   ├── household_dao_test.dart
│   └── electricity_dao_test.dart      # NEW
├── providers/
│   ├── household_provider_test.dart
│   └── electricity_provider_test.dart # NEW
├── screens/
│   ├── households_screen_test.dart
│   └── electricity_screen_test.dart   # NEW
└── widgets/
    ├── household_form_dialog_test.dart
    └── electricity_reading_form_dialog_test.dart  # NEW
```

## Execution Order

**Wave 1 (Parallel)**:
- Task 1 (DAO) - Core data layer
- Task 5 (Form Dialog) - UI component (no dependencies)
- Task 6 (Localization) - No dependencies

**Wave 2 (Sequential)**:
- Task 2 (Register DAO) - After Task 1

**Wave 3 (Sequential)**:
- Task 3 (Provider) - After Task 2

**Wave 4 (Sequential)**:
- Task 4 (Screen) - After Task 3

**Wave 5 (Parallel after Task 3)**:
- Task 7 (Integration) - Wire providers
- Task 8 (Navigation) - After Task 4

**Wave 6 (Final)**:
- Task 9 (Tests) - After all implementation
- Task 10 (Analysis) - After tests pass

```
Wave 1:  Task 1 ─────┐
         Task 5      │
         Task 6      │
                     ▼
Wave 2:  Task 2 ────►
                     │
Wave 3:  Task 3 ◄───┘
                     │
Wave 4:  Task 4 ◄───┘
                     │
Wave 5:  Task 7, Task 8
                     │
Wave 6:  Task 9 ──► Task 10
```

## Estimated Duration
3-4 hours

## Dependencies
- Phase 1: Project setup (completed)
- Phase 2: Household management (completed) - needed for household scoping
- ElectricityReadings table (exists in schema)

## Technical Notes

### Delta Calculation
The delta (consumption since previous reading) is calculated as:
```dart
delta = currentReading.valueKwh - previousReading.valueKwh
```

Where `previousReading` is the reading with the closest timestamp BEFORE the current reading.

### Validation Logic
When adding/editing a reading:
1. Find the reading immediately BEFORE the timestamp being entered
2. Ensure value >= previousReading.valueKwh
3. Find the reading immediately AFTER (if editing)
4. If editing, ensure the new value doesn't create an invalid gap with the next reading

### DateTime Picker
Use Flutter's `showDatePicker` + `showTimePicker` or a combined datetime picker widget. Default to current date/time when creating new readings.

### Number Formatting
Use `NumberFormat` from `intl` package for consistent kWh display:
```dart
final formatter = NumberFormat('#,##0.0', 'en');
formatter.format(12345.67);  // "12,345.7"
```

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Delta calculation edge cases | Thorough unit tests for boundary cases |
| Validation for edit mode | Test editing middle readings carefully |
| Timestamp picker UX | Consider combined date/time picker package |
| Stream subscription leaks | Proper disposal in provider |

## UAT Criteria

### UAC-E1: Add First Reading
- Given I have a household selected
- When I tap "+" on electricity screen
- And I enter 1000 kWh
- Then the reading appears in the list as "First reading"

### UAC-E2: Add Subsequent Reading
- Given I have a reading of 1000 kWh
- When I add a new reading of 1150 kWh
- Then it shows "+150 kWh since previous"

### UAC-E3: Edit Reading
- Given I have readings 1000, 1100, 1200
- When I edit 1100 to 1150
- Then deltas update: (none), +150, +50

### UAC-E4: Delete Reading
- Given I have readings 1000, 1100, 1200
- When I delete 1100
- Then readings show: 1000 (none), 1200 (+200)

### UAC-E5: Validation Error
- Given I have a reading of 1000 kWh
- When I try to add 900 kWh
- Then I see error "Value must be >= 1000 kWh"
