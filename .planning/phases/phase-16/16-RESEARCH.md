# Phase 16 Research: Backup, Testing & Documentation

## Requirements Covered
- **FR-14**: Backup & Restore (FR-14.1 Database Export, FR-14.2 Database Import)
- **NFR-10**: Testing (80%+ statement coverage, integration tests)
- **NFR-9.2/9.3**: Performance (export <5s, import+restart <10s)
- **NFR-12.2/12.3**: Data Integrity (complete backup, schema validation)

## UACs Covered
- **UAC-M3-7**: Database backup via settings → share .sqlite file
- **UAC-M3-8**: Database import via settings → replace + restart
- **UAC-M3-10**: 80%+ statement coverage with all tests passing

---

## Existing Codebase Context

### Database Layer
- **File**: `lib/database/app_database.dart` — Schema version 3, 11 tables
- **Connection**: `lib/database/connection/native.dart` — `valtra.sqlite` in app documents dir
- **Path**: `getApplicationDocumentsDirectory() / valtra.sqlite`
- **Drift ORM** with LazyDatabase pattern

### Settings Screen
- **File**: `lib/screens/settings_screen.dart`
- **Sections**: Appearance, Language, Meter Settings, Cost Configuration, About
- **Pattern**: `_buildSection*()` methods returning GlassCard widgets

### Share Service (export pattern to follow)
- **File**: `lib/services/share_service.dart`
- **Pattern**: Write to temp dir → `Share.shareXFiles([XFile(path)])` → cleanup
- **Already handles**: CSV export with MIME type

### Provider Pattern
- ChangeNotifier with async `init()`, DAO injection
- All providers initialized in `main()` before `runApp()`
- `MultiProvider` wrapping in `ValtraApp`
- Household selection triggers provider reloads

### Localization
- **EN**: `lib/l10n/app_en.arb` (~430 lines)
- **DE**: `lib/l10n/app_de.arb` (matching)
- Auto-generated `app_localizations.dart`

### Test Infrastructure
- **66 test files** across `test/database/`, `test/providers/`, `test/screens/`, `test/services/`, `test/widgets/`
- **Helpers**: `test/helpers/test_database.dart` (in-memory DB), `test/helpers/test_utils.dart` (widget wrappers)
- **CI**: `.github/workflows/flutter-tests.yml` — runs analyze + test + coverage upload
- **Coverage exclusions**: `.g.dart`, `app_theme.dart`, `tables.dart`, `l10n/*`
- **Current count**: 855 tests passing

### Dependencies Already Available
- `drift: ^2.19.0`, `sqlite3_flutter_libs: ^0.5.24`
- `path_provider: ^2.1.3`, `path: ^1.9.0`
- `share_plus: ^10.0.0`
- `provider: ^6.1.2`

### Dependencies to Add
- `file_picker: ^5.7.0` — for import file selection dialog

---

## Reference Implementation: XFin

**File**: `C:\SAPDevelop\Privat\XFin\lib\utils\db_backup.dart` (96 lines)

### Export Flow
1. Get DB file path from `getApplicationDocumentsDirectory()`
2. Copy DB to temp dir with timestamped name
3. Share via `Share.shareXFiles()` or save via `FileSaver`
4. Show success/failure toast

### Import Flow
1. Open file picker with `.sqlite` extension filter
2. Read selected file
3. Validate it's a valid SQLite database
4. Show confirmation dialog (current data will be replaced)
5. Auto-backup current DB before replacing
6. Close current database
7. Copy imported file to DB path
8. Recreate AppDatabase instance
9. Reinitialize providers
10. Show success toast

### DB Replacement Strategy
```
close old DB → copy source to temp → delete old DB → rename temp to DB path → reconnect
```

### Testing Pattern (XFin)
- `test/utils/db_backup_test.dart` (234 lines)
- Mocks platform channels (file_picker, path_provider)
- Tests success/failure paths for both export and import
- Uses in-memory DB for validation tests

---

## Architecture Decisions

### 1. Service Layer
- `BackupRestoreService` — stateless service handling file I/O, DB copy, validation
- Separate from provider for testability (pure business logic)

### 2. Provider Layer
- `BackupRestoreProvider` — wraps service, manages loading/error state, notifies UI
- Receives `AppDatabase` reference for close/reconnect

### 3. DB Reconnection Strategy
- After import: close DB → replace file → recreate LazyDatabase → reinitialize all providers
- Use Navigator to push replacement route (forces widget tree rebuild)
- Alternative: trigger app restart via `SystemNavigator.pop()` or `Phoenix` pattern

### 4. File Format
- Export as `.sqlite` with timestamp: `valtra_backup_YYYYMMDD_HHmmss.sqlite`
- No compression needed (SQLite is already compact)
- MIME type: `application/x-sqlite3`

### 5. Validation
- Check file exists and is non-empty
- Open as SQLite DB and verify expected tables exist (households, etc.)
- Check schema version matches current (v3)

### 6. Plan Breakdown
- **Plan 01**: BackupRestoreService + unit tests (export, import, validation logic)
- **Plan 02**: UI integration (SettingsScreen section, dialogs, provider, localization)
- **Plan 03**: Coverage analysis + test gap filling across codebase
- **Plan 04**: Integration tests + final verification + project state update
