# Phase 5: Water Tracking

## Goal
Implement complete water meter tracking with support for multiple meters per household (cold water, hot water, other). Users can create water meters with types, log readings with timestamps, and view consumption deltas.

## Requirements Coverage
- **FR-4.1**: Create multiple water meters per household (e.g., cold water, hot water, washing machine)
- **FR-4.2**: Each meter has name, type (cold/hot/other), and unit (m³)
- **FR-4.3**: Log readings with date/time and value
- **FR-4.4**: Display reading history per meter with consumption deltas

## Dependencies
- Phase 1 (database tables already defined in `tables.dart`)
- Phase 2 (household management for scoping)

## Success Criteria
- [ ] Water meters can be created with name and type (cold/hot/other)
- [ ] Water readings can be added with timestamp and value (m³)
- [ ] Readings are displayed per meter with consumption deltas
- [ ] Edit and delete operations work for both meters and readings
- [ ] All UI strings are localized (EN/DE)
- [ ] Tests achieve 100% statement coverage on new code

---

## Task Breakdown

### Task 1: Create WaterDao
**File**: `lib/database/daos/water_dao.dart`

Create the DAO for water meter and reading operations following the ElectricityDao pattern but adapted for the multi-meter relationship (WaterMeter → WaterReading).

```dart
// Key methods to implement:
// Meter operations:
// - insertMeter(WaterMetersCompanion) → Future<int>
// - getMeter(int id) → Future<WaterMeter>
// - getMetersForHousehold(int householdId) → Future<List<WaterMeter>>
// - watchMetersForHousehold(int householdId) → Stream<List<WaterMeter>>
// - updateMeter(WaterMetersCompanion) → Future<bool>
// - deleteMeter(int id) → Future<void>

// Reading operations:
// - insertReading(WaterReadingsCompanion) → Future<int>
// - getReading(int id) → Future<WaterReading>
// - getReadingsForMeter(int meterId) → Future<List<WaterReading>>
// - watchReadingsForMeter(int meterId) → Stream<List<WaterReading>>
// - updateReading(WaterReadingsCompanion) → Future<bool>
// - deleteReading(int id) → Future<void>
// - getPreviousReading(int meterId, DateTime) → Future<WaterReading?>
// - getLatestReading(int meterId) → Future<WaterReading?>
// - getNextReading(int meterId, DateTime) → Future<WaterReading?>
// - deleteReadingsForMeter(int meterId) → Future<void>
```

**Tests**: `test/database/daos/water_dao_test.dart`
- Test all CRUD operations for meters
- Test all CRUD operations for readings
- Test cascade: deleting meter also deletes readings
- Test getPreviousReading with various timestamps
- Test watchReadingsForMeter reactive updates

---

### Task 2: Register WaterDao in AppDatabase
**File**: `lib/database/app_database.dart`

Add WaterDao to the database accessors.

```dart
// Add to @DriftDatabase annotation:
@DriftDatabase(
  tables: [...existing..., WaterMeters, WaterReadings],
  daos: [...existing..., WaterDao],
)
```

Run code generation after: `flutter pub run build_runner build --delete-conflicting-outputs`

---

### Task 3: Create WaterProvider
**File**: `lib/providers/water_provider.dart`

Create provider managing water meter and reading state, following patterns from ElectricityProvider but adapted for multi-meter support.

```dart
class WaterReadingWithDelta {
  final WaterReading reading;
  final double? deltaCubicMeters;
}

class WaterProvider extends ChangeNotifier {
  // State:
  // - List<WaterMeter> _meters
  // - Map<int, List<WaterReading>> _readingsByMeter (or fetch on-demand)
  // - int? _householdId
  // - int? _selectedMeterId

  // Meter operations:
  // - setHouseholdId(int?)
  // - addMeter(name, type) → Future<int>
  // - updateMeter(id, name, type) → Future<bool>
  // - deleteMeter(id) → Future<void>

  // Reading operations:
  // - setSelectedMeterId(int?)
  // - addReading(meterId, timestamp, value) → Future<int>
  // - updateReading(id, timestamp, value) → Future<bool>
  // - deleteReading(id) → Future<void>
  // - validateReading(meterId, value, timestamp, {excludeId}) → Future<String?>

  // Computed:
  // - List<WaterMeter> get meters
  // - List<WaterReadingWithDelta> getReadingsWithDeltas(int meterId)
}
```

**Tests**: `test/providers/water_provider_test.dart`
- Test setHouseholdId triggers meter refresh
- Test CRUD operations for meters
- Test CRUD operations for readings
- Test delta calculation for readings
- Test validation against previous reading

---

### Task 4: Add Localization Strings
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`

Add water-specific localization strings:

**English (app_en.arb)**:
```json
"waterMeters": "Water Meters",
"addWaterMeter": "Add Water Meter",
"editWaterMeter": "Edit Water Meter",
"deleteWaterMeter": "Delete Water Meter",
"waterMeterName": "Meter Name",
"waterMeterNameHint": "Enter meter name",
"waterMeterType": "Meter Type",
"coldWater": "Cold Water",
"hotWater": "Hot Water",
"otherWater": "Other",
"noWaterMeters": "No water meters yet. Add one to start tracking water consumption!",
"waterMeterNameRequired": "Meter name is required",
"deleteWaterMeterConfirm": "Are you sure you want to delete this water meter?",
"waterMeterHasReadings": "This meter has {count} reading(s). They will also be deleted.",
"waterReading": "Water Reading",
"waterReadings": "Water Readings",
"addWaterReading": "Add Reading",
"editWaterReading": "Edit Reading",
"deleteWaterReading": "Delete Reading",
"noWaterReadings": "No readings yet. Add your first meter reading!",
"waterConsumptionSince": "+{value} m³ since previous",
"waterReadingMustBeGreaterOrEqual": "Value must be >= {previousValue} m³"
```

**German (app_de.arb)**:
```json
"waterMeters": "Wasserzähler",
"addWaterMeter": "Wasserzähler hinzufügen",
"editWaterMeter": "Wasserzähler bearbeiten",
"deleteWaterMeter": "Wasserzähler löschen",
"waterMeterName": "Zählername",
"waterMeterNameHint": "Zählernamen eingeben",
"waterMeterType": "Zählertyp",
"coldWater": "Kaltwasser",
"hotWater": "Warmwasser",
"otherWater": "Sonstiges",
"noWaterMeters": "Noch keine Wasserzähler. Fügen Sie einen hinzu, um den Wasserverbrauch zu verfolgen!",
"waterMeterNameRequired": "Zählername ist erforderlich",
"deleteWaterMeterConfirm": "Möchten Sie diesen Wasserzähler wirklich löschen?",
"waterMeterHasReadings": "Dieser Zähler hat {count} Ablesung(en). Diese werden ebenfalls gelöscht.",
"waterReading": "Wasserablesung",
"waterReadings": "Wasserablesungen",
"addWaterReading": "Ablesung hinzufügen",
"editWaterReading": "Ablesung bearbeiten",
"deleteWaterReading": "Ablesung löschen",
"noWaterReadings": "Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!",
"waterConsumptionSince": "+{value} m³ seit letzter Ablesung",
"waterReadingMustBeGreaterOrEqual": "Der Wert muss >= {previousValue} m³ sein"
```

Run generation: `flutter gen-l10n`

---

### Task 5: Create WaterMeterFormDialog
**File**: `lib/widgets/dialogs/water_meter_form_dialog.dart`

Dialog for creating/editing water meters with name and type selection.

```dart
class WaterMeterFormDialog extends StatefulWidget {
  final WaterMeter? meter; // null = create mode, non-null = edit mode

  static Future<WaterMeterFormData?> show(BuildContext context, {WaterMeter? meter});
}

class WaterMeterFormData {
  final String name;
  final WaterMeterType type;
}
```

UI Components:
- TextFormField for name (required, max 100 chars)
- SegmentedButton or DropdownButton for type (cold/hot/other)
- Cancel and Save buttons

**Tests**: `test/widgets/dialogs/water_meter_form_dialog_test.dart`
- Test create mode shows empty fields
- Test edit mode pre-fills values
- Test validation (required name)
- Test save returns form data
- Test cancel returns null

---

### Task 6: Create WaterReadingFormDialog
**File**: `lib/widgets/dialogs/water_reading_form_dialog.dart`

Dialog for creating/editing water readings, similar to ElectricityReadingFormDialog but with m³ unit.

```dart
class WaterReadingFormDialog extends StatefulWidget {
  final WaterReading? reading;

  static Future<WaterReadingFormData?> show(BuildContext context, {WaterReading? reading});
}

class WaterReadingFormData {
  final DateTime timestamp;
  final double valueCubicMeters;
}
```

UI Components:
- Date/Time picker (defaults to now)
- TextFormField for value (decimal input, required, >= 0)
- Unit suffix: m³
- Cancel and Save buttons

**Tests**: `test/widgets/dialogs/water_reading_form_dialog_test.dart`
- Test create mode shows empty fields and current time
- Test edit mode pre-fills values
- Test validation (positive number required)
- Test save returns form data
- Test cancel returns null

---

### Task 7: Create WaterScreen
**File**: `lib/screens/water_screen.dart`

Main screen showing water meters with their readings, similar to SmartPlugsScreen pattern.

Structure:
- AppBar with "Water" title and m³ unit chip
- If no meters: empty state with "Add meter" prompt
- If meters exist:
  - List of WaterMeterCard widgets
  - Each card shows meter name, type badge, latest reading, and consumption delta
  - Tap to expand/navigate to readings for that meter
- FAB to add new meter

```dart
class WaterScreen extends StatelessWidget {
  // Build method returns Scaffold with:
  // - AppBar with title and unit chip
  // - Body: empty state or ListView of WaterMeterCard
  // - FAB for adding meter
}

class _WaterMeterCard extends StatelessWidget {
  final WaterMeter meter;
  final List<WaterReadingWithDelta> readings;
  // Shows meter info, expandable list of readings
  // Edit/delete meter via popup menu
  // Add reading button
}
```

**Tests**: `test/screens/water_screen_test.dart`
- Test empty state when no meters
- Test meter list displays correctly
- Test add meter flow
- Test edit meter flow
- Test delete meter with confirmation
- Test add reading flow
- Test edit reading flow
- Test delete reading with confirmation
- Test consumption delta display

---

### Task 8: Register WaterProvider in main.dart
**File**: `lib/main.dart`

1. Import WaterDao and WaterProvider
2. Initialize WaterProvider in main()
3. Connect to household changes
4. Add to MultiProvider

```dart
// In main():
final waterProvider = WaterProvider(WaterDao(database));

// In _onHouseholdChanged:
widget.waterProvider.setHouseholdId(householdId);

// In MultiProvider:
ChangeNotifierProvider<WaterProvider>.value(value: widget.waterProvider),
```

---

### Task 9: Add Navigation to WaterScreen
**File**: `lib/main.dart`

Add navigation handler for the Water chip in HomeScreen.

```dart
_buildCategoryChip(
  context,
  Icons.water_drop,
  l10n.water,
  AppColors.waterColor,
  onTap: () => _navigateToWater(context),
),

void _navigateToWater(BuildContext context) {
  // Check household selected
  // Navigate to WaterScreen
}
```

---

## Implementation Order

1. **Task 1**: WaterDao (foundation)
2. **Task 2**: Register DAO in AppDatabase + code gen
3. **Task 3**: WaterProvider (state management)
4. **Task 4**: Localization strings (needed for UI)
5. **Task 5**: WaterMeterFormDialog
6. **Task 6**: WaterReadingFormDialog
7. **Task 7**: WaterScreen
8. **Task 8**: Register provider in main.dart
9. **Task 9**: Add navigation

## Testing Strategy

Each task includes corresponding test files:
- DAO tests: Mock database, test queries
- Provider tests: Mock DAO, test state management
- Widget tests: Use test helpers, pump widgets with providers

Run after each task:
```bash
flutter test
flutter analyze
```

## Files to Create
- `lib/database/daos/water_dao.dart`
- `lib/providers/water_provider.dart`
- `lib/widgets/dialogs/water_meter_form_dialog.dart`
- `lib/widgets/dialogs/water_reading_form_dialog.dart`
- `lib/screens/water_screen.dart`
- `test/database/daos/water_dao_test.dart`
- `test/providers/water_provider_test.dart`
- `test/widgets/dialogs/water_meter_form_dialog_test.dart`
- `test/widgets/dialogs/water_reading_form_dialog_test.dart`
- `test/screens/water_screen_test.dart`

## Files to Modify
- `lib/database/app_database.dart` (add DAO)
- `lib/l10n/app_en.arb` (add strings)
- `lib/l10n/app_de.arb` (add strings)
- `lib/main.dart` (register provider, add navigation)
