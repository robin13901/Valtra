# Phase 1: Project Setup & Architecture

## Phase Goal
Establish the complete project foundation including dependencies, database schema, theming, localization, and test infrastructure so all subsequent phases can build on a solid base.

## Requirements Addressed
- **NFR-1**: Localization (EN/DE ARB files)
- **NFR-2**: Data Persistence (Drift/SQLite setup)
- **NFR-3**: Quality & Testing (test infrastructure, CI/CD)
- **NFR-4**: UI/UX (theme with Ultra Violet/Lemon Chiffon)

## Success Criteria
- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` passes with zero issues
- [ ] `flutter test` runs (even if no tests yet)
- [ ] Database code generates via `dart run build_runner build`
- [ ] App launches with themed splash screen
- [ ] Localization strings resolve in both EN and DE

---

## Tasks

### Task 1.1: Configure Dependencies (pubspec.yaml)
**File**: `pubspec.yaml`

**Dependencies to add**:
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  # Database
  drift: ^2.19.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0
  # State Management
  provider: ^6.1.2
  # UI
  liquid_glass_renderer: ^0.2.0-dev.4
  fl_chart: ^0.68.0
  # Utils
  intl: ^0.20.2
  shared_preferences: ^2.2.3

dev_dependencies:
  drift_dev: ^2.19.0
  build_runner: ^2.4.10
  flutter_lints: ^6.0.0
  test: ^1.25.2
  sqlite3: ^2.4.4
  remove_from_coverage: ^2.0.0
  mocktail: ^0.3.0
```

**Add flutter generate flag**:
```yaml
flutter:
  uses-material-design: true
  generate: true
```

**Acceptance**: `flutter pub get` succeeds

---

### Task 1.2: Setup Localization Infrastructure
**Files**: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`

**l10n.yaml**:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

**app_en.arb** (initial strings):
```json
{
  "@@locale": "en",
  "appTitle": "Valtra",
  "electricity": "Electricity",
  "gas": "Gas",
  "water": "Water",
  "heating": "Heating",
  "analysis": "Analysis",
  "settings": "Settings",
  "households": "Households",
  "addReading": "Add Reading",
  "save": "Save",
  "cancel": "Cancel",
  "delete": "Delete",
  "edit": "Edit",
  "date": "Date",
  "time": "Time",
  "value": "Value",
  "consumption": "Consumption",
  "meter": "Meter",
  "room": "Room",
  "smartPlug": "Smart Plug",
  "kWh": "kWh",
  "cubicMeters": "m³",
  "noData": "No data available",
  "selectHousehold": "Select Household",
  "createHousehold": "Create Household",
  "householdName": "Household Name"
}
```

**app_de.arb** (German translations):
```json
{
  "@@locale": "de",
  "appTitle": "Valtra",
  "electricity": "Strom",
  "gas": "Gas",
  "water": "Wasser",
  "heating": "Heizung",
  "analysis": "Analyse",
  "settings": "Einstellungen",
  "households": "Haushalte",
  "addReading": "Ablesung hinzufügen",
  "save": "Speichern",
  "cancel": "Abbrechen",
  "delete": "Löschen",
  "edit": "Bearbeiten",
  "date": "Datum",
  "time": "Uhrzeit",
  "value": "Wert",
  "consumption": "Verbrauch",
  "meter": "Zähler",
  "room": "Raum",
  "smartPlug": "Smarte Steckdose",
  "kWh": "kWh",
  "cubicMeters": "m³",
  "noData": "Keine Daten vorhanden",
  "selectHousehold": "Haushalt auswählen",
  "createHousehold": "Haushalt erstellen",
  "householdName": "Haushaltsname"
}
```

**Acceptance**: `flutter gen-l10n` generates localization files

---

### Task 1.3: Create App Theme
**File**: `lib/app_theme.dart`

**Color Scheme**:
- Primary: Ultra Violet `#5F4A8B`
- Accent/Secondary: Lemon Chiffon `#FEFACD`
- Light/Dark variants derived from these

**Structure** (following XFin pattern):
```dart
class AppColors {
  // Brand colors
  static const ultraViolet = Color(0xFF5F4A8B);
  static const lemonChiffon = Color(0xFFFEFACD);

  // Light theme
  static const lightBackground = Color(0xFFF8F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1A1A2E);

  // Dark theme
  static const darkBackground = Color(0xFF1A1A2E);
  static const darkSurface = Color(0xFF2D2D44);
  static const darkOnSurface = Color(0xFFF8F7FA);
}

class AppTheme {
  static ThemeData get lightTheme => ...
  static ThemeData get darkTheme => ...
}
```

**Acceptance**: Theme compiles and applies to MaterialApp

---

### Task 1.4: Create Database Schema (tables.dart)
**File**: `lib/database/tables.dart`

**Enums**:
```dart
enum WaterMeterType { cold, hot, other }
enum ConsumptionInterval { daily, weekly, monthly, yearly }
```

**Tables** (with proper Drift annotations):
1. `Households` - id, name, description, createdAt
2. `ElectricityReadings` - id, householdId, timestamp, valueKwh
3. `GasReadings` - id, householdId, timestamp, valueCubicMeters
4. `WaterMeters` - id, householdId, name, type
5. `WaterReadings` - id, waterMeterId, timestamp, valueCubicMeters
6. `HeatingMeters` - id, householdId, name, location
7. `HeatingReadings` - id, heatingMeterId, timestamp, value
8. `Rooms` - id, householdId, name
9. `SmartPlugs` - id, roomId, name
10. `SmartPlugConsumptions` - id, smartPlugId, intervalType, intervalStart, valueKwh

**Acceptance**: No syntax errors, follows Drift conventions

---

### Task 1.5: Create Database Class (app_database.dart)
**File**: `lib/database/app_database.dart`

**Structure**:
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

**Acceptance**: `dart run build_runner build` generates .g.dart file

---

### Task 1.6: Create Database Connection (native.dart / web.dart)
**Files**: `lib/database/connection/native.dart`, `lib/database/connection/shared.dart`

**Pattern**: Follow XFin's platform-specific connection pattern
- Native: Uses `sqlite3_flutter_libs` + `path_provider`
- Shared: Common interface for both platforms

**Acceptance**: Database opens successfully on Android/iOS

---

### Task 1.7: Create Theme Provider
**File**: `lib/providers/theme_provider.dart`

**Features**:
- Store theme mode (system/light/dark) in SharedPreferences
- Provide `isDark()` helper for LiquidGlass widgets
- ChangeNotifier for reactive updates

**Acceptance**: Theme switches persist across app restarts

---

### Task 1.8: Update main.dart with App Shell
**File**: `lib/main.dart`

**Structure**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase(openConnection());
  runApp(ValtraApp(database: database));
}

class ValtraApp extends StatelessWidget {
  // MultiProvider setup
  // MaterialApp with localization delegates
  // Theme from AppTheme
  // Home: placeholder screen
}
```

**Acceptance**: App launches with themed UI and correct localization

---

### Task 1.9: Setup Test Infrastructure
**Files**:
- `test/helpers/test_database.dart` - In-memory database for tests
- `test/helpers/test_utils.dart` - Common test utilities
- `test/database/tables_test.dart` - Basic schema validation

**test_database.dart**:
```dart
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
```

**Acceptance**: `flutter test` runs without errors

---

### Task 1.10: Copy LiquidGlass Widgets
**File**: `lib/widgets/liquid_glass_widgets.dart`

**Action**: Adapt from XFin reference with Valtra theme colors
- `LiquidGlassBottomNav`
- `buildCircleButton`
- `buildFAB`
- `buildLiquidGlassAppBar`

**Acceptance**: Widgets compile and reference ThemeProvider

---

## Execution Order

```
1.1 (pubspec) ──► 1.2 (l10n) ──► 1.3 (theme) ──┐
                                               │
1.4 (tables) ──► 1.5 (database) ──► 1.6 (connection) ──► 1.8 (main.dart)
                                               │              │
                                    1.7 (theme provider) ─────┘
                                               │
1.9 (test infra) ◄────────────────────────────┘
                                               │
1.10 (liquid glass) ◄─────────────────────────┘
```

**Parallelizable**: 1.1-1.3 can run parallel to 1.4-1.6

---

## Verification Checklist

After completion, verify:
- [ ] `flutter pub get` - no errors
- [ ] `dart run build_runner build` - generates database code
- [ ] `flutter gen-l10n` - generates localization code
- [ ] `flutter analyze` - zero issues
- [ ] `flutter test` - passes (even with minimal tests)
- [ ] `flutter run` - app launches on emulator
- [ ] Theme colors visible in UI
- [ ] Can switch locale and see German strings

---

## Estimated Duration
4-6 hours

## Dependencies
- XFin reference project for patterns
- Flutter SDK (stable channel)
- Android Studio / emulator for testing

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Drift version incompatibility | Pin exact versions from XFin |
| LiquidGlass package issues | Use exact version from XFin (0.2.0-dev.4) |
| l10n generation fails | Ensure `generate: true` in pubspec |
