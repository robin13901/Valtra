# Phase 6: Gas Tracking

## Goal
Implement complete gas meter reading functionality including data layer (DAO), state management (Provider), and UI screens for managing readings, enabling users to log gas meter readings (in m³) and view consumption history with delta calculations. Follows the same single-meter-per-household pattern as Electricity (Phase 3).

## Requirements Coverage
- **FR-5.1**: Log gas meter readings with date/time and value (m³)
- **FR-5.2**: Each household has exactly one gas meter (implicit via householdId)
- **FR-5.3**: Optional: Display kWh equivalent (conversion factor configurable) - deferred to future enhancement
- **FR-5.4**: Display reading history with consumption deltas

## Dependencies
- Phase 1: Project setup (completed) - database tables already defined
- Phase 2: Household management (completed) - needed for household scoping
- GasReadings table already exists in `tables.dart`

## Success Criteria
- [ ] User can add a new gas reading with date/time and m³ value
- [ ] User can view list of all readings for current household sorted by timestamp (newest first)
- [ ] Each reading shows the consumption delta from the previous reading
- [ ] User can edit existing readings
- [ ] User can delete readings (with confirmation)
- [ ] Validation prevents readings less than previous (cumulative meter)
- [ ] All CRUD operations have corresponding unit tests
- [ ] UI screens have widget tests
- [ ] All code passes `flutter analyze` with no issues
- [ ] 100% statement coverage on new code

---

## Tasks

### Task 1: Create GasDao
**File**: `lib/database/daos/gas_dao.dart`
**Description**: Data access object for gas reading CRUD operations using Drift DAO pattern (following ElectricityDao pattern exactly)
**Depends on**: None

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'gas_dao.g.dart';

@DriftAccessor(tables: [GasReadings])
class GasDao extends DatabaseAccessor<AppDatabase> with _$GasDaoMixin {
  GasDao(super.db);

  // Key methods to implement (mirror ElectricityDao):
  // - Future<int> insertReading(GasReadingsCompanion entry)
  // - Future<GasReading> getReading(int id)
  // - Future<List<GasReading>> getReadingsForHousehold(int householdId)
  // - Stream<List<GasReading>> watchReadingsForHousehold(int householdId)
  // - Future<bool> updateReading(GasReadingsCompanion entry)
  // - Future<void> deleteReading(int id)
  // - Future<GasReading?> getPreviousReading(int householdId, DateTime timestamp)
  // - Future<GasReading?> getLatestReading(int householdId)
  // - Future<GasReading?> getNextReading(int householdId, DateTime timestamp)
}
```

**Implementation Details**:
- Copy ElectricityDao structure, replace `electricityReadings` with `gasReadings`
- Replace `ElectricityReading` with `GasReading`
- Replace `valueKwh` references with `valueCubicMeters`
- Sort readings by timestamp descending (newest first)

**Test file**: `test/database/daos/gas_dao_test.dart`
- Test insert and retrieve reading
- Test watch stream emits on changes
- Test update modifies existing record
- Test delete removes record
- Test getPreviousReading returns correct reading
- Test getLatestReading returns most recent
- Test getNextReading returns correct reading
- Test readings filtered by householdId

---

### Task 2: Register GasDao in AppDatabase
**File**: `lib/database/app_database.dart`
**Description**: Add GasDao as accessor to AppDatabase
**Depends on**: Task 1

```dart
// Add import:
import 'daos/gas_dao.dart';

// Add to @DriftDatabase daos list:
daos: [...existing..., GasDao]

// Add accessor:
@override
GasDao get gasDao => GasDao(this);
```

**Verification**: Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate database

---

### Task 3: Create GasProvider
**File**: `lib/providers/gas_provider.dart`
**Description**: State management for gas readings (following ElectricityProvider pattern)
**Depends on**: Task 1, Task 2

```dart
class GasReadingWithDelta {
  final GasReading reading;
  final double? deltaCubicMeters;  // null for oldest reading

  GasReadingWithDelta({required this.reading, this.deltaCubicMeters});
}

class GasProvider extends ChangeNotifier {
  final GasDao _dao;
  int? _householdId;
  List<GasReading> _readings = [];
  StreamSubscription<List<GasReading>>? _subscription;

  // Key functionality (mirror ElectricityProvider):
  // - Stream<List<GasReading>> readings (filtered by current household)
  // - List<GasReadingWithDelta> get readingsWithDeltas (calculated property)
  // - Future<void> addReading(DateTime timestamp, double valueCubicMeters)
  // - Future<void> updateReading(int id, DateTime timestamp, double valueCubicMeters)
  // - Future<void> deleteReading(int id)
  // - Future<String?> validateReading(double value, DateTime timestamp, {int? excludeId})
  //   Returns error message if invalid, null if valid
  // - void setHouseholdId(int? householdId) - called when household changes
}
```

**Test file**: `test/providers/gas_provider_test.dart`
- Test readings stream updates when household changes
- Test addReading creates record in database
- Test validateReading returns error when value < previous reading
- Test validateReading returns null for valid readings
- Test readingsWithDeltas calculates correct deltas
- Test deleteReading removes record
- Test updateReading modifies record
- Test setHouseholdId clears readings when null

---

### Task 4: Add Localization Strings
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Description**: Add gas-related strings (following electricity pattern)
**Depends on**: None

**New strings to add (EN)**:
```json
{
  "gasReading": "Gas Reading",
  "gasReadings": "Gas Readings",
  "addGasReading": "Add Reading",
  "editGasReading": "Edit Reading",
  "deleteGasReading": "Delete Reading",
  "deleteGasReadingConfirm": "Are you sure you want to delete this reading?",
  "noGasReadings": "No readings yet. Add your first meter reading!",
  "gasConsumptionSince": "+{value} m³ since previous",
  "@gasConsumptionSince": {
    "placeholders": {
      "value": {"type": "String"}
    }
  },
  "gasReadingMustBeGreaterOrEqual": "Value must be >= {previousValue} m³",
  "@gasReadingMustBeGreaterOrEqual": {
    "placeholders": {
      "previousValue": {"type": "String"}
    }
  }
}
```

**German translations (DE)**:
```json
{
  "gasReading": "Gasablesung",
  "gasReadings": "Gasablesungen",
  "addGasReading": "Ablesung hinzufügen",
  "editGasReading": "Ablesung bearbeiten",
  "deleteGasReading": "Ablesung löschen",
  "deleteGasReadingConfirm": "Möchten Sie diese Ablesung wirklich löschen?",
  "noGasReadings": "Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!",
  "gasConsumptionSince": "+{value} m³ seit letzter Ablesung",
  "gasReadingMustBeGreaterOrEqual": "Der Wert muss >= {previousValue} m³ sein"
}
```

**Verification**: Run `flutter gen-l10n` to generate localization classes

---

### Task 5: Create Gas Reading Form Dialog
**File**: `lib/widgets/dialogs/gas_reading_form_dialog.dart`
**Description**: Reusable dialog for creating/editing gas readings (following ElectricityReadingFormDialog pattern)
**Depends on**: Task 4

**UI Components**:
- DateTimePicker for timestamp (defaults to now)
- TextFormField for value (m³) - numeric input with decimals
- Unit display: m³
- Cancel and Save buttons
- Form validation:
  - Value must be positive
  - Value must be >= previous reading (validation via provider)
- Shows error message from validation inline

**Dialog Pattern** (following existing form dialogs):
```dart
class GasReadingFormDialog extends StatefulWidget {
  final GasReading? reading;  // null for create, non-null for edit

  static Future<GasReadingFormData?> show(
    BuildContext context, {
    GasReading? reading,
  });
}

class GasReadingFormData {
  final DateTime timestamp;
  final double valueCubicMeters;
}
```

**Test file**: `test/widgets/dialogs/gas_reading_form_dialog_test.dart`
- Test form validates empty value
- Test form validates non-numeric input
- Test form submits with valid data
- Test cancel closes dialog without saving
- Test edit mode pre-fills fields
- Test date/time picker works
- Test shows m³ unit suffix

---

### Task 6: Create Gas Screen
**File**: `lib/screens/gas_screen.dart`
**Description**: Screen showing list of gas readings with add/edit/delete actions (following ElectricityScreen pattern)
**Depends on**: Task 3, Task 4, Task 5

**UI Components**:
- AppBar with title "Gas"
- Show unit (m³) in app bar chip
- ListView.builder for reading cards
- Each card shows: timestamp, value (m³), delta from previous
- FloatingActionButton to add new reading
- Tap on card to edit
- Long-press or menu to delete (with confirmation)
- Empty state when no readings

**Card Layout** (same as ElectricityScreen):
```
┌──────────────────────────────────────┐
│  📅 2024-03-15 10:30              ⋮  │
│  ────────────────────────────────────│
│  1,234.5 m³                          │
│  +12.3 m³ since previous             │
└──────────────────────────────────────┘
```

**Test file**: `test/screens/gas_screen_test.dart`
- Test displays list of readings
- Test FAB opens add dialog
- Test tap opens edit dialog
- Test shows empty state when no readings
- Test shows delta values correctly
- Test delete confirmation works
- Test popup menu for edit/delete

---

### Task 7: Register GasProvider in main.dart
**File**: `lib/main.dart`
**Description**: Add GasProvider to MultiProvider and connect to household changes
**Depends on**: Task 2, Task 3

**Changes**:
```dart
// Add imports:
import 'database/daos/gas_dao.dart';
import 'providers/gas_provider.dart';

// In main():
final gasProvider = GasProvider(GasDao(database));

// Add to household init connection:
if (householdProvider.selectedHouseholdId != null) {
  // ...existing providers...
  gasProvider.setHouseholdId(householdProvider.selectedHouseholdId);
}

// Add to ValtraApp constructor:
required this.gasProvider,

// Add to _ValtraAppState._onHouseholdChanged():
widget.gasProvider.setHouseholdId(householdId);

// Add to MultiProvider:
ChangeNotifierProvider<GasProvider>.value(value: widget.gasProvider),
```

---

### Task 8: Add Navigation to Gas Screen
**File**: `lib/main.dart`
**Description**: Enable navigation from home screen to gas screen
**Depends on**: Task 6, Task 7

**Changes**:
```dart
// Import:
import 'screens/gas_screen.dart';

// Update gas chip to add onTap:
_buildCategoryChip(
  context,
  Icons.local_fire_department,
  l10n.gas,
  AppColors.gasColor,
  onTap: () => _navigateToGas(context),
),

// Add navigation method:
void _navigateToGas(BuildContext context) {
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
    MaterialPageRoute(builder: (context) => const GasScreen()),
  );
}
```

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

## File Structure After Phase 6

```
lib/
├── database/
│   ├── daos/
│   │   ├── electricity_dao.dart
│   │   ├── gas_dao.dart              # NEW
│   │   ├── household_dao.dart
│   │   ├── room_dao.dart
│   │   ├── smart_plug_dao.dart
│   │   └── water_dao.dart
│   ├── app_database.dart             # MODIFIED
│   └── ...
├── providers/
│   ├── electricity_provider.dart
│   ├── gas_provider.dart             # NEW
│   ├── household_provider.dart
│   ├── room_provider.dart
│   ├── smart_plug_provider.dart
│   └── water_provider.dart
├── screens/
│   ├── electricity_screen.dart
│   ├── gas_screen.dart               # NEW
│   ├── smart_plugs_screen.dart
│   └── water_screen.dart
├── widgets/
│   ├── dialogs/
│   │   ├── electricity_reading_form_dialog.dart
│   │   ├── gas_reading_form_dialog.dart      # NEW
│   │   ├── household_form_dialog.dart
│   │   ├── water_meter_form_dialog.dart
│   │   └── water_reading_form_dialog.dart
│   └── ...
├── l10n/
│   ├── app_en.arb                    # MODIFIED
│   └── app_de.arb                    # MODIFIED
└── main.dart                         # MODIFIED

test/
├── database/
│   ├── daos/
│   │   ├── electricity_dao_test.dart
│   │   ├── gas_dao_test.dart         # NEW
│   │   └── ...
├── providers/
│   ├── electricity_provider_test.dart
│   ├── gas_provider_test.dart        # NEW
│   └── ...
├── screens/
│   ├── electricity_screen_test.dart
│   ├── gas_screen_test.dart          # NEW
│   └── ...
└── widgets/
    ├── dialogs/
    │   ├── electricity_reading_form_dialog_test.dart
    │   ├── gas_reading_form_dialog_test.dart  # NEW
    │   └── ...
```

## Execution Order

**Wave 1 (Parallel)**:
- Task 1 (GasDao) - Core data layer
- Task 4 (Localization) - No dependencies
- Task 5 (Form Dialog) - UI component (no dependencies)

**Wave 2 (Sequential)**:
- Task 2 (Register DAO + code gen) - After Task 1

**Wave 3 (Sequential)**:
- Task 3 (Provider) - After Task 2

**Wave 4 (Sequential)**:
- Task 6 (Screen) - After Task 3, Task 4, Task 5

**Wave 5 (Sequential)**:
- Task 7 (Provider Integration) - After Task 3
- Task 8 (Navigation) - After Task 6

**Wave 6 (Final)**:
- Task 9 (Tests) - After all implementation
- Task 10 (Analysis) - After tests pass

```
Wave 1:  Task 1 ─────┐
         Task 4      │
         Task 5      │
                     ▼
Wave 2:  Task 2 ────►
                     │
Wave 3:  Task 3 ◄───┘
                     │
Wave 4:  Task 6 ◄───┘
                     │
Wave 5:  Task 7, Task 8
                     │
Wave 6:  Task 9 ──► Task 10
```

## Estimated Duration
2-3 hours (Low complexity - mirrors existing Electricity implementation)

## Technical Notes

### Delta Calculation
The delta (consumption since previous reading) is calculated as:
```dart
delta = currentReading.valueCubicMeters - previousReading.valueCubicMeters
```

Where `previousReading` is the reading with the closest timestamp BEFORE the current reading.

### Validation Logic
When adding/editing a reading:
1. Find the reading immediately BEFORE the timestamp being entered
2. Ensure value >= previousReading.valueCubicMeters
3. Find the reading immediately AFTER (if editing)
4. If editing, ensure the new value doesn't create an invalid gap with the next reading

### Number Formatting
Use `NumberFormat` from `intl` package for consistent m³ display:
```dart
final formatter = NumberFormat('#,##0.0', 'en');
formatter.format(1234.56);  // "1,234.6"
```

### kWh Conversion (Optional Enhancement)
FR-5.3 mentions optional kWh equivalent display. This is deferred but noted here for future implementation:
- Typical conversion: 1 m³ gas ≈ 10-11 kWh (varies by gas quality)
- Would require a configurable conversion factor per household
- Can be added as a future enhancement to the GasReading card

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Code duplication from Electricity | Acceptable - keeps code explicit and simple |
| Forgot to copy all methods | Follow checklist, compare with ElectricityDao |
| Stream subscription leaks | Copy proven pattern from ElectricityProvider |

## UAT Criteria

### UAC-G1: Add First Gas Reading
- Given I have a household selected
- When I tap "+" on gas screen
- And I enter 100.5 m³
- Then the reading appears in the list as "First reading"

### UAC-G2: Add Subsequent Reading
- Given I have a reading of 100.5 m³
- When I add a new reading of 115.2 m³
- Then it shows "+14.7 m³ since previous"

### UAC-G3: Edit Reading
- Given I have readings 100, 110, 120 m³
- When I edit 110 to 115
- Then deltas update: (none), +15, +5

### UAC-G4: Delete Reading
- Given I have readings 100, 110, 120 m³
- When I delete 110
- Then readings show: 100 (none), 120 (+20)

### UAC-G5: Validation Error
- Given I have a reading of 100.5 m³
- When I try to add 95.0 m³
- Then I see error "Value must be >= 100.5 m³"

### UAC-G6: Navigation
- Given I am on the home screen with a household selected
- When I tap the "Gas" chip
- Then I navigate to the Gas screen
