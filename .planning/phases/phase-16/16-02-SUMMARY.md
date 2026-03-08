# Phase 16 Plan 02: Backup/Restore UI Integration Summary

## One-liner
BackupRestoreProvider with export/import state machine, settings screen section with loading indicators, file picker + confirmation dialog, EN/DE localization for 13 keys, wired into MultiProvider.

## Completed Tasks

| Task | Description | Status |
|------|-------------|--------|
| T1 | Create BackupRestoreProvider and add localization strings | Done |
| T2 | Add backup/restore section to SettingsScreen and wire into main.dart | Done |

## Changes Made

### Task 1: BackupRestoreProvider + Localization

**Provider (`lib/providers/backup_restore_provider.dart`):**
- `BackupRestoreState` enum: idle, exporting, importing, validating, success, error
- `BackupRestoreProvider` extends ChangeNotifier with constructor-injected BackupRestoreService
- `exportDatabase()`: sets exporting -> calls service.exportDatabase + shareBackup -> sets success/error
- `importDatabase(File)`: sets validating -> validates -> if invalid: sets error, returns false -> sets importing -> imports -> sets success, returns true
- `resetState()`: returns to idle, clears messages
- `isLoading` getter: true during exporting/importing states
- `onDatabaseReplaced` VoidCallback for app restart after import

**Localization (13 keys each in EN and DE):**
- Used `backupExportSuccess` instead of `exportSuccess` (already taken by CSV export)
- All keys: backupRestore, exportDatabase, importDatabase, exportInProgress, importInProgress, backupExportSuccess, importSuccess, importFailed, importConfirmTitle, importConfirmMessage, invalidBackupFile, backupCreated, validatingFile

**Tests (`test/providers/backup_restore_provider_test.dart`):**
- 16 tests with MockBackupRestoreService (mocktail)
- Covers: initial state, export success/error, import validation/success/error, isLoading states, resetState, onDatabaseReplaced callback

### Task 2: Settings Screen + main.dart Wiring

**Settings screen (`lib/screens/settings_screen.dart`):**
- Added `_buildBackupRestoreSection` between cost config and about sections
- Export tile: cloud_upload icon, loading spinner + "Exporting database..." subtitle during export
- Import tile: cloud_download icon, loading spinner during import/validation, subtitle text per state
- `_handleExport`: calls provider, shows SnackBar with success/error, resets state
- `_handleImport`: opens FilePicker (FileType.any), shows confirmation AlertDialog, calls provider.importDatabase, shows success/error SnackBar, calls onDatabaseReplaced on success
- Buttons disabled when isLoading is true

**main.dart wiring:**
- BackupRestoreService created with default constructor
- BackupRestoreProvider created with service injection
- Added to ValtraApp constructor and MultiProvider list

**Settings screen tests (`test/screens/settings_screen_test.dart`):**
- Added MockBackupRestoreProvider with idle state stubs
- 6 new tests: section header, export tile, import tile, exporting loading indicator, importing loading indicator, validating text
- Used `tester.drag` + `pump` for tests with CircularProgressIndicator (avoids pumpAndSettle timeout)

**German locale test fix (`test/l10n/german_locale_coverage_test.dart`):**
- Added BackupRestoreProvider mock to prevent ProviderNotFoundException
- Fixed pre-existing "Erscheinungsbild" -> "Darstellung" assertion

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] german_locale_coverage_test.dart missing BackupRestoreProvider**
- **Found during:** Task 2
- **Issue:** Adding BackupRestoreProvider to settings screen caused ProviderNotFoundException in german_locale_coverage_test.dart
- **Fix:** Added MockBackupRestoreProvider mock setup and registration to the test's SettingsScreen MultiProvider
- **Files modified:** test/l10n/german_locale_coverage_test.dart
- **Commit:** d873a53

**2. [Rule 1 - Bug] german_locale_coverage_test.dart wrong DE string assertion**
- **Found during:** Task 2 (exposed after fixing issue 1)
- **Issue:** Test expected "Erscheinungsbild" but actual DE l10n key for "appearance" is "Darstellung"
- **Fix:** Updated assertion to match actual DE string
- **Files modified:** test/l10n/german_locale_coverage_test.dart
- **Commit:** d873a53

**3. [Rule 2 - Missing] Localization key collision avoidance**
- **Found during:** Task 1
- **Issue:** `exportSuccess` key already exists for CSV export feature
- **Fix:** Used `backupExportSuccess` for backup-specific success message
- **Files modified:** lib/l10n/app_en.arb, lib/l10n/app_de.arb
- **Commit:** 8161b6c

## Decisions Made

1. **backupExportSuccess key name** -- Used `backupExportSuccess` instead of `exportSuccess` to avoid collision with existing CSV export localization key
2. **CircularProgressIndicator test approach** -- Used `tester.drag` + `pump` instead of `scrollUntilVisible` + `pumpAndSettle` for tests showing loading indicators, because CircularProgressIndicator animates indefinitely and prevents pumpAndSettle from completing
3. **Import = copy only, restart via callback** -- BackupRestoreProvider does not manage DB connection lifecycle; onDatabaseReplaced callback allows app layer to handle restart/reinitialize

## Test Results

| Test File | Tests | Status |
|-----------|-------|--------|
| test/providers/backup_restore_provider_test.dart | 16 | Pass |
| test/screens/settings_screen_test.dart | 30 | Pass |
| Full suite (excluding pre-existing failures) | 945+ | Pass |
| flutter analyze (our files) | 0 issues | Pass |

**New tests added:** 22 (16 provider + 6 settings screen)
**Pre-existing failures (not caused by this plan):** 11 in unrelated files + 1 timeout in german_locale_coverage HouseholdsScreen test

## Files Created/Modified

### Created
- `lib/providers/backup_restore_provider.dart` (107 lines)
- `test/providers/backup_restore_provider_test.dart` (184 lines)

### Modified
- `lib/screens/settings_screen.dart` (+120 lines: imports, backup/restore section, handlers)
- `lib/main.dart` (+10 lines: imports, service/provider init, constructor param, MultiProvider)
- `lib/l10n/app_en.arb` (+13 keys)
- `lib/l10n/app_de.arb` (+13 keys)
- `lib/l10n/app_localizations.dart` (auto-generated)
- `lib/l10n/app_localizations_en.dart` (auto-generated)
- `lib/l10n/app_localizations_de.dart` (auto-generated)
- `test/screens/settings_screen_test.dart` (+55 lines: mock, registration, 6 tests)
- `test/l10n/german_locale_coverage_test.dart` (+12 lines: mock, fix)

## Commits

| Hash | Message |
|------|---------|
| 8161b6c | feat(16-02): create BackupRestoreProvider with localization strings |
| d873a53 | feat(16-02): add backup/restore settings UI and wire into main.dart |
