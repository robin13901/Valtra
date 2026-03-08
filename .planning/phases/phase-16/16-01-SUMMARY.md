# Phase 16 Plan 01: BackupRestoreService (TDD) Summary

## One-liner
BackupRestoreService with constructor-injected directory providers: timestamped export, SQLite validation (table + schema version), safety backup, and import with pre-validation.

## Completed Tasks

| Task | Description | Status |
|------|-------------|--------|
| T1 | Add file_picker dependency, write failing tests (RED), implement service (GREEN), refactor | Done |

## Changes Made

### Step 0: Dependency Addition
- Added `file_picker: ^8.0.0` to pubspec.yaml under `# Export` section
- Ran `flutter pub get` successfully

### Step 1 (RED): Failing Tests
- Created `test/services/backup_restore_service_test.dart` with 19 tests covering all 5 public methods
- Tests structured in 4 groups: exportDatabase (4), validateBackupFile (7), createSafetyBackup (4), importDatabase (4)
- Used real temp directories with `Directory.systemTemp.createTempSync` for isolation
- Used `sqlite3` package directly to create valid/invalid test databases
- Helper function `_createValidValtraDb` for consistent test DB creation

### Step 2 (GREEN): Implementation
- Created `lib/services/backup_restore_service.dart` with 5 public methods
- Constructor injection: `Future<Directory> Function()` for both DB and temp directory (defaults to path_provider functions)
- `exportDatabase()`: copies DB to temp with `valtra_backup_YYYYMMDD_HHmmss.sqlite` name
- `validateBackupFile()`: checks existence, non-empty, opens with sqlite3, verifies `households` table, checks `PRAGMA user_version == 3`
- `createSafetyBackup()`: copies DB to temp with `safety_backup_YYYYMMDD_HHmmss.sqlite` name
- `importDatabase()`: validates source, creates safety backup, copies source over DB file; throws `ArgumentError` on invalid file
- `shareBackup()`: wraps `Share.shareXFiles` with `application/x-sqlite3` MIME type

### Step 3 (REFACTOR): Documentation
- Added comprehensive doc comments on all public methods and the class itself
- Added `expectedSchemaVersion` constant (3) to avoid magic numbers

## Key Files Created
- `lib/services/backup_restore_service.dart` (121 lines) - Core service implementation
- `test/services/backup_restore_service_test.dart` (192 lines) - Full unit test coverage

## Key Files Modified
- `pubspec.yaml` - Added file_picker dependency
- `pubspec.lock` - Updated lock file

## Key Decisions
1. **Constructor injection over mock** - Used `Future<Directory> Function()` parameters instead of mocking path_provider, making tests fast and deterministic
2. **ArgumentError for invalid imports** - Throws `ArgumentError` (not a custom exception) for invalid backup files during import, keeping error handling simple
3. **Service does NOT manage DB connections** - Import only copies the file; DB close/reconnect is the provider layer's responsibility (Plan 16-02)
4. **sqlite3 package for validation** - Uses the existing sqlite3 dependency to open and query the database file directly, avoiding Drift overhead
5. **Schema version check via PRAGMA user_version** - Drift stores schema version in SQLite's user_version pragma; validation checks for exact match (version 3)

## Deviations from Plan
None - plan executed exactly as written.

## Verification Results
- [x] BackupRestoreService exists with 5 public methods (export, share, validate, safety backup, import)
- [x] Constructor injection allows testing without platform channels
- [x] Validation correctly distinguishes valid Valtra DBs from invalid files
- [x] Export produces correctly named timestamped files
- [x] Safety backup creates timestamped copy in temp directory
- [x] Import validates, creates safety backup, then replaces DB file
- [x] 19 new tests pass (4 export + 7 validation + 4 safety backup + 4 import)
- [x] All 874 tests pass (855 existing + 19 new)
- [x] flutter analyze: zero issues in new files (28 pre-existing issues in other files logged to deferred-items.md)

## Commit
`33dcbcf` feat(16-01): BackupRestoreService with TDD -- export, import, validation, sharing
