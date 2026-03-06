# Phase 4: Smart Plug & Room Management

## Goal
Implement complete room and smart plug management functionality including data layer (DAOs), state management (Providers), and UI screens for managing rooms, smart plugs, and interval-based consumption logging, enabling users to track electricity consumption at the device level organized by room.

## Requirements Coverage
- **FR-3.1**: Create smart plugs with name and assigned room
- **FR-3.2**: Create and manage rooms within a household
- **FR-3.3**: Log consumption values for smart plugs with interval type (day/week/month/year)
- **FR-3.4**: Store interval start date and consumption value (kWh)
- **FR-3.5**: Aggregate consumption by plug, by room, and total (foundation for Phase 11)
- **FR-3.6**: Calculate "Other" consumption (foundation for Phase 11)

## Success Criteria
1. User can create/edit/delete rooms within a household
2. User can create/edit/delete smart plugs assigned to rooms
3. User can log consumption entries with interval type and value
4. Consumption entries display with proper formatting and interval labels
5. User can view all smart plugs organized by room
6. All CRUD operations have comprehensive unit tests
7. UI screens have widget tests
8. All code passes `flutter analyze` with no issues

---

## Tasks

### Task 1: Create RoomDao
**File**: `lib/database/daos/room_dao.dart`
**Description**: Data access object for room CRUD operations using Drift DAO pattern
**Depends on**: None

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'room_dao.g.dart';

@DriftAccessor(tables: [Rooms, SmartPlugs, SmartPlugConsumptions])
class RoomDao extends DatabaseAccessor<AppDatabase> with _$RoomDaoMixin {
  RoomDao(super.db);

  // Key methods to implement:
  // - Future<int> insertRoom(RoomsCompanion entry)
  // - Future<Room> getRoom(int id)
  // - Future<List<Room>> getRoomsForHousehold(int householdId)
  // - Stream<List<Room>> watchRoomsForHousehold(int householdId)
  // - Future<bool> updateRoom(RoomsCompanion entry)
  // - Future<void> deleteRoom(int id) - cascade delete smart plugs
  // - Future<bool> roomHasSmartPlugs(int roomId)
}
```

**Implementation Details**:
- Sort rooms by name alphabetically
- Cascade delete: when room is deleted, delete all its smart plugs (and their consumption records)
- `roomHasSmartPlugs` checks if room can be safely deleted (for UI warning)

**Test file**: `test/database/room_dao_test.dart`
- Test insert and retrieve room
- Test watch stream emits on changes
- Test update modifies existing record
- Test delete removes room and cascades to smart plugs
- Test rooms filtered by householdId
- Test roomHasSmartPlugs returns correct boolean

---

### Task 2: Create SmartPlugDao
**File**: `lib/database/daos/smart_plug_dao.dart`
**Description**: Data access object for smart plug and consumption CRUD operations
**Depends on**: None

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'smart_plug_dao.g.dart';

@DriftAccessor(tables: [SmartPlugs, SmartPlugConsumptions, Rooms])
class SmartPlugDao extends DatabaseAccessor<AppDatabase>
    with _$SmartPlugDaoMixin {
  SmartPlugDao(super.db);

  // Smart Plug methods:
  // - Future<int> insertSmartPlug(SmartPlugsCompanion entry)
  // - Future<SmartPlug> getSmartPlug(int id)
  // - Future<List<SmartPlug>> getSmartPlugsForRoom(int roomId)
  // - Stream<List<SmartPlug>> watchSmartPlugsForRoom(int roomId)
  // - Future<List<SmartPlug>> getSmartPlugsForHousehold(int householdId)
  // - Stream<List<SmartPlug>> watchSmartPlugsForHousehold(int householdId)
  // - Future<bool> updateSmartPlug(SmartPlugsCompanion entry)
  // - Future<void> deleteSmartPlug(int id) - cascade delete consumption

  // Consumption methods:
  // - Future<int> insertConsumption(SmartPlugConsumptionsCompanion entry)
  // - Future<SmartPlugConsumption> getConsumption(int id)
  // - Future<List<SmartPlugConsumption>> getConsumptionsForPlug(int smartPlugId)
  // - Stream<List<SmartPlugConsumption>> watchConsumptionsForPlug(int smartPlugId)
  // - Future<bool> updateConsumption(SmartPlugConsumptionsCompanion entry)
  // - Future<void> deleteConsumption(int id)

  // Aggregation methods (for analytics - Phase 11):
  // - Future<double> getTotalConsumptionForPlug(int smartPlugId, DateTime from, DateTime to)
  // - Future<double> getTotalConsumptionForRoom(int roomId, DateTime from, DateTime to)
  // - Future<double> getTotalSmartPlugConsumption(int householdId, DateTime from, DateTime to)
}
```

**Implementation Details**:
- Smart plugs queried via room join to filter by household
- Consumption entries sorted by intervalStart descending (newest first)
- Cascade delete: deleting plug removes all its consumption records
- Aggregation uses SUM with date range filtering

**Test file**: `test/database/smart_plug_dao_test.dart`
- Test all CRUD operations for smart plugs
- Test all CRUD operations for consumption entries
- Test cascade delete behavior
- Test aggregation calculations
- Test filtering by room and household

---

### Task 3: Register DAOs in AppDatabase
**File**: `lib/database/app_database.dart`
**Description**: Add RoomDao and SmartPlugDao as accessors to AppDatabase
**Depends on**: Task 1, Task 2

```dart
// Add imports:
import 'daos/room_dao.dart';
import 'daos/smart_plug_dao.dart';

// Add to @DriftDatabase daos list:
daos: [
  HouseholdDao,
  ElectricityDao,
  RoomDao,      // NEW
  SmartPlugDao, // NEW
]

// Add accessors:
@override
RoomDao get roomDao => RoomDao(this);

@override
SmartPlugDao get smartPlugDao => SmartPlugDao(this);
```

**Verification**: Run `dart run build_runner build` to regenerate database

---

### Task 4: Create RoomProvider
**File**: `lib/providers/room_provider.dart`
**Description**: State management for rooms
**Depends on**: Task 1, Task 3

```dart
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../database/daos/room_dao.dart';

class RoomProvider extends ChangeNotifier {
  final RoomDao _roomDao;
  int? _householdId;
  List<Room> _rooms = [];

  RoomProvider(this._roomDao);

  // Properties:
  List<Room> get rooms => _rooms;

  // Methods:
  void setHouseholdId(int? householdId);
  Future<void> addRoom(String name);
  Future<void> updateRoom(int id, String name);
  Future<void> deleteRoom(int id);
  Future<bool> canDeleteRoom(int id); // Check for smart plugs
}
```

**Test file**: `test/providers/room_provider_test.dart`
- Test rooms update when household changes
- Test addRoom creates record
- Test updateRoom modifies record
- Test deleteRoom removes record (and cascades)
- Test canDeleteRoom returns correct value

---

### Task 5: Create SmartPlugProvider
**File**: `lib/providers/smart_plug_provider.dart`
**Description**: State management for smart plugs and consumption
**Depends on**: Task 2, Task 3

```dart
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../database/daos/smart_plug_dao.dart';
import '../database/tables.dart';

/// Smart plug with its associated room name for display.
class SmartPlugWithRoom {
  final SmartPlug plug;
  final String roomName;

  SmartPlugWithRoom({required this.plug, required this.roomName});
}

/// Consumption entry with interval label for display.
class ConsumptionWithLabel {
  final SmartPlugConsumption consumption;
  final String intervalLabel; // e.g., "Daily - Mar 5, 2024"

  ConsumptionWithLabel({required this.consumption, required this.intervalLabel});
}

class SmartPlugProvider extends ChangeNotifier {
  final SmartPlugDao _smartPlugDao;
  int? _householdId;
  List<SmartPlugWithRoom> _plugs = [];

  SmartPlugProvider(this._smartPlugDao);

  // Properties:
  List<SmartPlugWithRoom> get plugs => _plugs;
  Map<String, List<SmartPlugWithRoom>> get plugsByRoom; // Grouped by room name

  // Smart Plug methods:
  void setHouseholdId(int? householdId);
  Future<void> addSmartPlug(String name, int roomId);
  Future<void> updateSmartPlug(int id, String name, int roomId);
  Future<void> deleteSmartPlug(int id);

  // Consumption methods:
  Future<List<ConsumptionWithLabel>> getConsumptionsForPlug(int plugId);
  Stream<List<ConsumptionWithLabel>> watchConsumptionsForPlug(int plugId);
  Future<void> addConsumption(int plugId, ConsumptionInterval interval, DateTime start, double kWh);
  Future<void> updateConsumption(int id, ConsumptionInterval interval, DateTime start, double kWh);
  Future<void> deleteConsumption(int id);
}
```

**Test file**: `test/providers/smart_plug_provider_test.dart`
- Test plugs update when household changes
- Test plugsByRoom groups correctly
- Test all CRUD operations for plugs
- Test all CRUD operations for consumption
- Test consumption label formatting

---

### Task 6: Create Room Management Screen
**File**: `lib/screens/rooms_screen.dart`
**Description**: Screen for managing rooms within a household
**Depends on**: Task 4

**UI Components**:
- AppBar with title "Rooms"
- ListView.builder for room cards
- Each card shows: room name, smart plug count badge
- FloatingActionButton to add new room
- Tap on card to edit room name
- Long-press or menu to delete (with confirmation if plugs exist)
- Empty state when no rooms

**Card Layout**:
```
┌──────────────────────────────────────┐
│  🏠 Living Room                    ⋮  │
│  3 smart plugs                       │
└──────────────────────────────────────┘
```

**Test file**: `test/screens/rooms_screen_test.dart`
- Test displays list of rooms
- Test FAB opens add dialog
- Test tap opens edit dialog
- Test shows empty state when no rooms
- Test shows smart plug count

---

### Task 7: Create Smart Plug Management Screen
**File**: `lib/screens/smart_plugs_screen.dart`
**Description**: Screen displaying smart plugs organized by room with consumption management
**Depends on**: Task 5

**UI Components**:
- AppBar with title "Smart Plugs"
- Show unit (kWh) in app bar chip
- Grouped ListView: sections by room, items are smart plugs
- Each plug card shows: name, room, recent consumption summary
- FloatingActionButton to add new plug
- Tap on card to view/add consumption entries
- Edit/delete via popup menu
- Empty state when no plugs

**Card Layout**:
```
┌──────────────────────────────────────┐
│  📱 TV Stand Plug                  ⋮  │
│  Living Room                         │
│  Last entry: 15.3 kWh (Monthly)      │
└──────────────────────────────────────┘
```

**Test file**: `test/screens/smart_plugs_screen_test.dart`
- Test displays list of smart plugs grouped by room
- Test FAB opens add dialog
- Test tap navigates to consumption screen
- Test shows empty state when no plugs

---

### Task 8: Create Smart Plug Consumption Screen
**File**: `lib/screens/smart_plug_consumption_screen.dart`
**Description**: Screen showing consumption history for a specific smart plug
**Depends on**: Task 5

**UI Components**:
- AppBar with plug name as title
- Room name as subtitle
- ListView.builder for consumption cards
- Each card shows: interval type, start date, kWh value
- FloatingActionButton to add new consumption entry
- Edit/delete via tap and popup menu
- Empty state when no consumption entries

**Card Layout**:
```
┌──────────────────────────────────────┐
│  📊 Monthly                        ⋮  │
│  Mar 1, 2024                         │
│  ─────────────────────────────────── │
│  15.3 kWh                            │
└──────────────────────────────────────┘
```

**Test file**: `test/screens/smart_plug_consumption_screen_test.dart`
- Test displays consumption entries
- Test FAB opens add dialog
- Test shows interval type labels correctly
- Test shows empty state when no entries

---

### Task 9: Create Room Form Dialog
**File**: `lib/widgets/dialogs/room_form_dialog.dart`
**Description**: Dialog for creating/editing rooms
**Depends on**: None

```dart
class RoomFormDialog extends StatefulWidget {
  final Room? room;  // null for create, non-null for edit

  static Future<RoomFormData?> show(BuildContext context, {Room? room});
}

class RoomFormData {
  final String name;
}
```

**UI Components**:
- TextFormField for room name
- Validation: name required, max 100 chars
- Cancel and Save buttons

**Test file**: `test/widgets/room_form_dialog_test.dart`
- Test form validates empty name
- Test form validates name length
- Test form submits with valid data
- Test cancel closes without saving
- Test edit mode pre-fills name

---

### Task 10: Create Smart Plug Form Dialog
**File**: `lib/widgets/dialogs/smart_plug_form_dialog.dart`
**Description**: Dialog for creating/editing smart plugs
**Depends on**: Task 4 (needs rooms list)

```dart
class SmartPlugFormDialog extends StatefulWidget {
  final SmartPlug? plug;  // null for create, non-null for edit
  final List<Room> rooms;
  final int? initialRoomId;

  static Future<SmartPlugFormData?> show(
    BuildContext context, {
    SmartPlug? plug,
    required List<Room> rooms,
    int? initialRoomId,
  });
}

class SmartPlugFormData {
  final String name;
  final int roomId;
}
```

**UI Components**:
- TextFormField for plug name
- DropdownButtonFormField for room selection
- Validation: name required, room required
- Cancel and Save buttons

**Test file**: `test/widgets/smart_plug_form_dialog_test.dart`
- Test form validates empty name
- Test form validates room selection
- Test form submits with valid data
- Test edit mode pre-fills fields
- Test dropdown shows all rooms

---

### Task 11: Create Smart Plug Consumption Form Dialog
**File**: `lib/widgets/dialogs/smart_plug_consumption_form_dialog.dart`
**Description**: Dialog for creating/editing consumption entries
**Depends on**: None

```dart
class SmartPlugConsumptionFormDialog extends StatefulWidget {
  final SmartPlugConsumption? consumption;  // null for create, non-null for edit

  static Future<SmartPlugConsumptionFormData?> show(
    BuildContext context, {
    SmartPlugConsumption? consumption,
  });
}

class SmartPlugConsumptionFormData {
  final ConsumptionInterval intervalType;
  final DateTime intervalStart;
  final double valueKwh;
}
```

**UI Components**:
- DropdownButtonFormField for interval type (Daily/Weekly/Monthly/Yearly)
- DatePicker for interval start date
- TextFormField for kWh value (numeric with decimals)
- Validation: value must be positive
- Cancel and Save buttons

**Test file**: `test/widgets/smart_plug_consumption_form_dialog_test.dart`
- Test form validates empty value
- Test form validates positive value
- Test interval type dropdown works
- Test date picker works
- Test edit mode pre-fills fields

---

### Task 12: Add Localization Strings
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Description**: Add room and smart plug related strings
**Depends on**: None

**New strings to add** (EN):
```json
{
  "rooms": "Rooms",
  "addRoom": "Add Room",
  "editRoom": "Edit Room",
  "deleteRoom": "Delete Room",
  "roomName": "Room Name",
  "roomNameHint": "Enter room name",
  "noRooms": "No rooms yet. Create one to organize your smart plugs!",
  "roomNameRequired": "Room name is required",
  "roomNameTooLong": "Room name must be 100 characters or less",
  "deleteRoomConfirm": "Are you sure you want to delete this room?",
  "roomHasSmartPlugs": "This room has {count} smart plug(s). They will also be deleted.",
  "@roomHasSmartPlugs": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "smartPlugs": "Smart Plugs",
  "addSmartPlug": "Add Smart Plug",
  "editSmartPlug": "Edit Smart Plug",
  "deleteSmartPlug": "Delete Smart Plug",
  "smartPlugName": "Plug Name",
  "smartPlugNameHint": "Enter smart plug name",
  "noSmartPlugs": "No smart plugs yet. Add one to start tracking device consumption!",
  "smartPlugNameRequired": "Plug name is required",
  "deleteSmartPlugConfirm": "Are you sure you want to delete this smart plug?",
  "selectRoom": "Select Room",
  "roomRequired": "Please select a room",
  "consumption": "Consumption",
  "addConsumption": "Add Consumption",
  "editConsumption": "Edit Consumption",
  "deleteConsumption": "Delete Consumption",
  "noConsumption": "No consumption entries yet.",
  "deleteConsumptionConfirm": "Are you sure you want to delete this entry?",
  "intervalType": "Interval Type",
  "intervalStart": "Start Date",
  "daily": "Daily",
  "weekly": "Weekly",
  "monthly": "Monthly",
  "yearly": "Yearly",
  "smartPlugCount": "{count, plural, =0{No smart plugs} =1{1 smart plug} other{{count} smart plugs}}",
  "@smartPlugCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "lastEntry": "Last: {value} kWh ({interval})",
  "@lastEntry": {
    "placeholders": {
      "value": {"type": "String"},
      "interval": {"type": "String"}
    }
  }
}
```

**German translations**:
```json
{
  "rooms": "Räume",
  "addRoom": "Raum hinzufügen",
  "editRoom": "Raum bearbeiten",
  "deleteRoom": "Raum löschen",
  "roomName": "Raumname",
  "roomNameHint": "Raumnamen eingeben",
  "noRooms": "Noch keine Räume. Erstellen Sie einen, um Ihre Smart Plugs zu organisieren!",
  "roomNameRequired": "Raumname ist erforderlich",
  "roomNameTooLong": "Raumname darf maximal 100 Zeichen lang sein",
  "deleteRoomConfirm": "Möchten Sie diesen Raum wirklich löschen?",
  "roomHasSmartPlugs": "Dieser Raum hat {count} Smart Plug(s). Diese werden ebenfalls gelöscht.",
  "smartPlugs": "Smart Plugs",
  "addSmartPlug": "Smart Plug hinzufügen",
  "editSmartPlug": "Smart Plug bearbeiten",
  "deleteSmartPlug": "Smart Plug löschen",
  "smartPlugName": "Plug-Name",
  "smartPlugNameHint": "Smart Plug Namen eingeben",
  "noSmartPlugs": "Noch keine Smart Plugs. Fügen Sie einen hinzu, um den Geräteverbrauch zu verfolgen!",
  "smartPlugNameRequired": "Plug-Name ist erforderlich",
  "deleteSmartPlugConfirm": "Möchten Sie diesen Smart Plug wirklich löschen?",
  "selectRoom": "Raum auswählen",
  "roomRequired": "Bitte wählen Sie einen Raum",
  "addConsumption": "Verbrauch hinzufügen",
  "editConsumption": "Verbrauch bearbeiten",
  "deleteConsumption": "Verbrauch löschen",
  "noConsumption": "Noch keine Verbrauchseinträge.",
  "deleteConsumptionConfirm": "Möchten Sie diesen Eintrag wirklich löschen?",
  "intervalType": "Intervalltyp",
  "intervalStart": "Startdatum",
  "daily": "Täglich",
  "weekly": "Wöchentlich",
  "monthly": "Monatlich",
  "yearly": "Jährlich",
  "smartPlugCount": "{count, plural, =0{Keine Smart Plugs} =1{1 Smart Plug} other{{count} Smart Plugs}}",
  "lastEntry": "Zuletzt: {value} kWh ({interval})"
}
```

---

### Task 13: Integrate Providers in main.dart
**File**: `lib/main.dart`
**Description**: Add RoomProvider and SmartPlugProvider to MultiProvider
**Depends on**: Task 4, Task 5

**Changes**:
```dart
// Add imports:
import 'providers/room_provider.dart';
import 'providers/smart_plug_provider.dart';
import 'database/daos/room_dao.dart';
import 'database/daos/smart_plug_dao.dart';

// Create providers:
final roomProvider = RoomProvider(RoomDao(database));
final smartPlugProvider = SmartPlugProvider(SmartPlugDao(database));

// Add to MultiProvider:
ChangeNotifierProvider<RoomProvider>.value(value: roomProvider),
ChangeNotifierProvider<SmartPlugProvider>.value(value: smartPlugProvider),

// Listen to household changes:
// When selectedHouseholdId changes, call:
// roomProvider.setHouseholdId(id);
// smartPlugProvider.setHouseholdId(id);
```

---

### Task 14: Add Navigation to Smart Plug Screens
**File**: `lib/main.dart` or navigation widget
**Description**: Enable navigation from home screen to room and smart plug screens
**Depends on**: Task 6, Task 7, Task 13

**Changes**:
- Add "Smart Plugs" category chip on home screen (if not exists)
- Navigate to SmartPlugsScreen on tap
- Add navigation from SmartPlugsScreen to RoomsScreen (via app bar action)
- Add navigation from plug card to SmartPlugConsumptionScreen

---

### Task 15: Verify All Tests Pass
**Command**: `flutter test`
**Description**: Run full test suite and ensure 100% pass rate
**Depends on**: All previous tasks

---

### Task 16: Run Static Analysis
**Command**: `flutter analyze`
**Description**: Fix any lint warnings or errors
**Depends on**: Task 15

---

## File Structure After Phase 4

```
lib/
├── database/
│   ├── daos/
│   │   ├── household_dao.dart
│   │   ├── electricity_dao.dart
│   │   ├── room_dao.dart                    # NEW
│   │   └── smart_plug_dao.dart              # NEW
│   ├── app_database.dart                    # MODIFIED
│   └── ...
├── providers/
│   ├── household_provider.dart
│   ├── electricity_provider.dart
│   ├── room_provider.dart                   # NEW
│   └── smart_plug_provider.dart             # NEW
├── screens/
│   ├── households_screen.dart
│   ├── electricity_screen.dart
│   ├── rooms_screen.dart                    # NEW
│   ├── smart_plugs_screen.dart              # NEW
│   └── smart_plug_consumption_screen.dart   # NEW
├── widgets/
│   ├── dialogs/
│   │   ├── household_form_dialog.dart
│   │   ├── electricity_reading_form_dialog.dart
│   │   ├── room_form_dialog.dart            # NEW
│   │   ├── smart_plug_form_dialog.dart      # NEW
│   │   └── smart_plug_consumption_form_dialog.dart  # NEW
│   └── ...
├── l10n/
│   ├── app_en.arb                           # MODIFIED
│   └── app_de.arb                           # MODIFIED
└── main.dart                                # MODIFIED

test/
├── database/
│   ├── household_dao_test.dart
│   ├── electricity_dao_test.dart
│   ├── room_dao_test.dart                   # NEW
│   └── smart_plug_dao_test.dart             # NEW
├── providers/
│   ├── household_provider_test.dart
│   ├── electricity_provider_test.dart
│   ├── room_provider_test.dart              # NEW
│   └── smart_plug_provider_test.dart        # NEW
├── screens/
│   ├── households_screen_test.dart
│   ├── electricity_screen_test.dart
│   ├── rooms_screen_test.dart               # NEW
│   ├── smart_plugs_screen_test.dart         # NEW
│   └── smart_plug_consumption_screen_test.dart  # NEW
└── widgets/
    ├── household_form_dialog_test.dart
    ├── electricity_reading_form_dialog_test.dart
    ├── room_form_dialog_test.dart           # NEW
    ├── smart_plug_form_dialog_test.dart     # NEW
    └── smart_plug_consumption_form_dialog_test.dart  # NEW
```

## Execution Order

**Wave 1 (Parallel - Data Layer)**:
- Task 1 (RoomDao) - Room data operations
- Task 2 (SmartPlugDao) - Smart plug and consumption operations
- Task 9 (Room Form Dialog) - No dependencies
- Task 11 (Consumption Form Dialog) - No dependencies
- Task 12 (Localization) - No dependencies

**Wave 2 (Sequential - Database Integration)**:
- Task 3 (Register DAOs) - After Task 1, Task 2

**Wave 3 (Parallel - Providers)**:
- Task 4 (RoomProvider) - After Task 3
- Task 5 (SmartPlugProvider) - After Task 3

**Wave 4 (Parallel - Screens)**:
- Task 6 (Rooms Screen) - After Task 4
- Task 7 (Smart Plugs Screen) - After Task 5
- Task 10 (Smart Plug Form Dialog) - After Task 4 (needs rooms list)

**Wave 5 (Sequential)**:
- Task 8 (Consumption Screen) - After Task 5

**Wave 6 (Parallel - Integration)**:
- Task 13 (Provider Integration) - After Task 4, Task 5
- Task 14 (Navigation) - After Task 6, Task 7, Task 8

**Wave 7 (Final)**:
- Task 15 (Tests) - After all implementation
- Task 16 (Analysis) - After tests pass

```
Wave 1:  Task 1 (RoomDao) ──────────────┐
         Task 2 (SmartPlugDao) ─────────┤
         Task 9 (Room Dialog)           │
         Task 11 (Consumption Dialog)   │
         Task 12 (Localization)         │
                                        ▼
Wave 2:  Task 3 (Register DAOs) ───────►
                                        │
Wave 3:  Task 4 (RoomProvider) ◄───────┬┤
         Task 5 (SmartPlugProvider) ◄──┘│
                                        │
Wave 4:  Task 6 (Rooms Screen) ◄───────┬┤
         Task 7 (Smart Plugs Screen) ◄─┤│
         Task 10 (Plug Dialog) ◄───────┘│
                                        │
Wave 5:  Task 8 (Consumption Screen) ◄──┘
                                        │
Wave 6:  Task 13 (Integration)          │
         Task 14 (Navigation)           │
                                        ▼
Wave 7:  Task 15 (Tests) ──► Task 16 (Analysis)
```

## Estimated Duration
5-6 hours

## Dependencies
- Phase 1: Project setup (completed)
- Phase 2: Household management (completed) - needed for household scoping
- Phase 3: Electricity tracking (completed) - pattern reference
- Rooms, SmartPlugs, SmartPlugConsumptions tables (exist in schema)
- ConsumptionInterval enum (exists in tables.dart)

## Technical Notes

### Cascade Delete Strategy
When deleting a room:
1. Find all smart plugs in the room
2. Delete all consumption entries for each plug
3. Delete all smart plugs
4. Delete the room

This is handled in RoomDao.deleteRoom using a transaction.

### Smart Plug Querying
To get smart plugs for a household (not directly linked):
```dart
// Join through Rooms table
final query = select(smartPlugs).join([
  innerJoin(rooms, rooms.id.equalsExp(smartPlugs.roomId)),
]);
query.where(rooms.householdId.equals(householdId));
```

### Interval Type Display
Map ConsumptionInterval enum to localized strings:
```dart
String getIntervalLabel(ConsumptionInterval interval, AppLocalizations l10n) {
  switch (interval) {
    case ConsumptionInterval.daily: return l10n.daily;
    case ConsumptionInterval.weekly: return l10n.weekly;
    case ConsumptionInterval.monthly: return l10n.monthly;
    case ConsumptionInterval.yearly: return l10n.yearly;
  }
}
```

### Aggregation for Analytics
The aggregation methods in SmartPlugDao prepare for Phase 11 (Smart Plug Analytics):
- Total consumption per plug in time range
- Total consumption per room in time range
- Total smart plug consumption for household (for "Other" calculation)

These use SQL SUM with WHERE clauses for date filtering.

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Cascade delete complexity | Use database transactions, thorough tests |
| Join queries for household filter | Test with multiple households/rooms |
| Form dialog state management | Follow established patterns from Phase 3 |
| Date picker for interval start | Use simple DatePicker, not DateTime |
| Screen navigation complexity | Clear navigation stack management |

## UAT Criteria

### UAC-SP1: Create Room
- Given I have a household selected
- When I tap "+" on rooms screen
- And I enter "Living Room"
- Then the room appears in the list

### UAC-SP2: Create Smart Plug
- Given I have a room "Living Room"
- When I tap "+" on smart plugs screen
- And I enter "TV Plug" and select "Living Room"
- Then the plug appears grouped under "Living Room"

### UAC-SP3: Log Consumption
- Given I have a smart plug "TV Plug"
- When I tap the plug and then "+" on consumption screen
- And I select "Monthly", "Mar 1, 2024", and enter 15.3 kWh
- Then the entry appears in the consumption list

### UAC-SP4: Delete Room with Plugs
- Given I have "Living Room" with 2 smart plugs
- When I try to delete "Living Room"
- Then I see warning "This room has 2 smart plug(s). They will also be deleted."
- And when I confirm, the room and its plugs are deleted

### UAC-SP5: View Plugs by Room
- Given I have "Living Room" with 2 plugs and "Kitchen" with 1 plug
- When I view the smart plugs screen
- Then I see plugs grouped under room headers
