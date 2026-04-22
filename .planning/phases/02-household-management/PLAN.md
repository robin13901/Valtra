# Phase 2: Household Management

## Goal
Implement complete household management functionality including data layer (DAO), state management (Provider), and UI screens for CRUD operations, enabling users to create, manage, and switch between multiple households.

## Requirements Coverage
- **FR-1.1**: Create, edit, and delete households
- **FR-1.2**: Each household has a name and optional description
- **FR-1.3**: All meters and data are scoped to a household
- **FR-1.4**: User can switch between households in the app
- **FR-1.5**: Default household selection persists across sessions

## Success Criteria
1. User can create a new household with name and optional description
2. User can view list of all households
3. User can edit existing household details
4. User can delete a household (with confirmation)
5. User can select/switch active household from dropdown
6. Selected household persists across app restarts (SharedPreferences)
7. All CRUD operations have corresponding unit tests
8. UI screens have widget tests
9. All code passes `flutter analyze` with no issues

---

## Tasks

### Task 1: Create HouseholdDao
**File**: `lib/database/daos/household_dao.dart`
**Description**: Data access object for household CRUD operations using Drift DAO pattern
**Depends on**: None

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'household_dao.g.dart';

@DriftAccessor(tables: [
  Households,
  ElectricityReadings,
  GasReadings,
  WaterMeters,
  HeatingMeters,
  Rooms,
])
class HouseholdDao extends DatabaseAccessor<AppDatabase>
    with _$HouseholdDaoMixin {
  HouseholdDao(super.db);

  // Key methods to implement:
  // - Future<int> insert(HouseholdsCompanion entry)
  // - Future<Household> getHousehold(int id)
  // - Future<List<Household>> getAllHouseholds()
  // - Stream<List<Household>> watchAllHouseholds()
  // - Future<bool> updateHousehold(HouseholdsCompanion entry)
  // - Future<void> deleteHousehold(int id)
  // - Future<bool> hasRelatedData(int householdId) - check for meters/readings
}
```

**Test file**: `test/database/household_dao_test.dart`
- Test insert and retrieve household
- Test watch stream emits on changes
- Test update modifies existing record
- Test delete removes record
- Test hasRelatedData returns true when readings exist

---

### Task 2: Register HouseholdDao in AppDatabase
**File**: `lib/database/app_database.dart`
**Description**: Add HouseholdDao as accessor to AppDatabase
**Depends on**: Task 1

```dart
// Add to AppDatabase:
// HouseholdDao get householdDao => HouseholdDao(this);
```

**Verification**: Run `dart run build_runner build` to regenerate database

---

### Task 3: Create HouseholdProvider
**File**: `lib/providers/household_provider.dart`
**Description**: State management for household selection and list
**Depends on**: Task 1, Task 2

```dart
// Key functionality:
// - Stream<List<Household>> households (from DAO watch)
// - Household? selectedHousehold
// - int? selectedHouseholdId (stored in SharedPreferences)
// - Future<void> init() - load persisted selection
// - Future<void> selectHousehold(int id)
// - Future<void> createHousehold(String name, String? description)
// - Future<void> updateHousehold(int id, String name, String? description)
// - Future<void> deleteHousehold(int id)
```

**Test file**: `test/providers/household_provider_test.dart`
- Test initial state loads persisted household ID
- Test selectHousehold persists to SharedPreferences
- Test createHousehold adds to database
- Test selectedHousehold updates when household list changes

---

### Task 4: Create Household List Screen
**File**: `lib/screens/households_screen.dart`
**Description**: Screen showing list of all households with add/edit/delete actions
**Depends on**: Task 3

**UI Components**:
- AppBar with title "Households"
- ListView.builder for household cards
- FloatingActionButton to add new household
- Long-press to delete (with confirmation dialog)
- Tap to edit household
- **Delete blocked with error dialog** if `hasRelatedData()` returns true

**Test file**: `test/screens/households_screen_test.dart`
- Test displays list of households
- Test FAB opens add dialog
- Test tap opens edit dialog
- Test long-press shows delete confirmation

---

### Task 5: Create Household Form Dialog
**File**: `lib/widgets/dialogs/household_form_dialog.dart`
**Description**: Reusable dialog for creating/editing households
**Depends on**: None

**UI Components**:
- TextFormField for name (required, max 100 chars)
- TextFormField for description (optional)
- Cancel and Save buttons
- Form validation

**Test file**: `test/widgets/household_form_dialog_test.dart`
- Test form validates empty name
- Test form submits with valid data
- Test cancel closes dialog without saving
- Test edit mode pre-fills fields

---

### Task 6: Create Household Selector Widget
**File**: `lib/widgets/household_selector.dart`
**Description**: Dropdown widget for selecting active household in app bar
**Depends on**: Task 3

**UI Components**:
- DropdownButton with current household name
- List of all households
- "Add Household" option at bottom
- Shows icon + name

**Test file**: `test/widgets/household_selector_test.dart`
- Test shows current selection
- Test dropdown opens with all households
- Test selection triggers provider change
- Test shows placeholder when no households

---

### Task 7: Integrate Household Selector in HomeScreen
**File**: `lib/main.dart`
**Description**: Add HouseholdSelector to app bar and HouseholdProvider to providers
**Depends on**: Task 3, Task 6

**Changes**:
- Add HouseholdProvider to MultiProvider
- Replace placeholder HomeScreen with proper navigation placeholder
- Add HouseholdSelector to AppBar actions

---

### Task 8: Add Localization Strings
**File**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Description**: Add missing household-related strings (some already exist from Phase 1)
**Depends on**: None

**Existing strings** (do not duplicate):
- households, selectHousehold, createHousehold, householdName

**New strings to add**:
- household (singular)
- editHousehold, deleteHousehold
- householdDescription
- deleteHouseholdConfirm
- noHouseholds
- householdRequired, householdNameTooLong
- cannotDeleteHousehold, householdHasRelatedData

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

## File Structure After Phase 2

```
lib/
├── database/
│   ├── daos/
│   │   └── household_dao.dart       # NEW
│   ├── app_database.dart            # MODIFIED
│   └── ...
├── providers/
│   ├── household_provider.dart      # NEW
│   └── ...
├── screens/
│   └── households_screen.dart       # NEW
├── widgets/
│   ├── dialogs/
│   │   └── household_form_dialog.dart  # NEW
│   └── household_selector.dart      # NEW
├── l10n/
│   ├── app_en.arb                   # MODIFIED
│   └── app_de.arb                   # MODIFIED
└── main.dart                        # MODIFIED

test/
├── database/
│   └── household_dao_test.dart      # NEW
├── providers/
│   └── household_provider_test.dart # NEW
├── screens/
│   └── households_screen_test.dart  # NEW
└── widgets/
    ├── household_form_dialog_test.dart  # NEW
    └── household_selector_test.dart     # NEW
```

## Execution Order

1. Task 8 (Localization) - No dependencies
2. Task 5 (Form Dialog) - No dependencies
3. Task 1 (DAO) - Core data layer
4. Task 2 (Register DAO) - Database integration
5. Task 3 (Provider) - State management
6. Task 6 (Selector Widget) - UI component
7. Task 4 (List Screen) - Full screen
8. Task 7 (Integration) - Wire everything together
9. Task 9 (Tests) - Verify
10. Task 10 (Analysis) - Final check

## Estimated Duration
2-3 hours
