---
phase: 28-home-nav-polish
plan: 01
subsystem: database
tags: [drift, sqlite, migration, schema, household, person-count, localization]

# Dependency graph
requires:
  - phase: 26
    provides: Households table at schema v3, HouseholdProvider, HouseholdFormDialog
provides:
  - Household data model with personCount integer column (schema v4)
  - DB migration v3→v4 adding person_count column with DEFAULT 1 for existing rows
  - HouseholdProvider.createHousehold accepts required int personCount
  - HouseholdProvider.updateHousehold accepts optional int? personCount
  - HouseholdFormDialog with person count input field (required, >= 1, digits only)
  - Localization keys: personCount, personCountHint, personCountRequired (EN + DE)
affects: [28-02, 28-03, plans using HouseholdProvider.createHousehold, home screen card display]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Required int field in DB: integer()() in Drift table = NOT NULL, no default in code, DEFAULT X in ALTER TABLE migration only"
    - "FilteringTextInputFormatter.digitsOnly for numeric-only text input without full number keyboard"
    - "BackupRestoreService.expectedSchemaVersion must be bumped alongside schemaVersion in app_database.dart"

key-files:
  created: []
  modified:
    - lib/database/tables.dart
    - lib/database/app_database.dart
    - lib/database/app_database.g.dart
    - lib/providers/household_provider.dart
    - lib/widgets/dialogs/household_form_dialog.dart
    - lib/screens/households_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_de.arb
    - lib/services/backup_restore_service.dart
    - test/providers/household_provider_test.dart
    - test/widgets/household_form_dialog_test.dart
    - test/screens/households_screen_coverage_test.dart
    - test/services/backup_restore_service_test.dart

key-decisions:
  - "personCount has no .withDefault() in Drift table definition -- the form enforces the value. The DEFAULT 1 in ALTER TABLE migration is only for existing rows."
  - "BackupRestoreService.expectedSchemaVersion must always match app_database.dart schemaVersion"
  - "FilteringTextInputFormatter.digitsOnly chosen over keyboardType: TextInputType.numberWithOptions for reliable digit-only enforcement"

patterns-established:
  - "Schema bump pattern: bump schemaVersion, add if (from < N) block in onUpgrade, bump expectedSchemaVersion in BackupRestoreService"
  - "Required form field pattern: FilteringTextInputFormatter.digitsOnly + validator requiring non-empty + parse >= 1"

# Metrics
duration: 35min
completed: 2026-04-01
---

# Phase 28 Plan 01: Person Count Storage for Households Summary

**Drift schema v4 with personCount integer column on Households, migration, form dialog input with validation, provider wiring, and EN/DE localization**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-01T10:20:00Z
- **Completed:** 2026-04-01T10:54:00Z
- **Tasks:** 2
- **Files modified:** 20+

## Accomplishments
- Added `personCount` integer column to Households table (required, no default)
- Created schema v4 migration (`ALTER TABLE households ADD COLUMN person_count INTEGER NOT NULL DEFAULT 1`)
- Updated `HouseholdProvider.createHousehold` to require `personCount` and `updateHousehold` to accept optional `personCount`
- Added person count `TextFormField` to `HouseholdFormDialog` with `FilteringTextInputFormatter.digitsOnly` and required >= 1 validation
- Updated `HouseholdFormData` to carry `personCount`
- Added localization keys in EN and DE (personCount, personCountHint, personCountRequired)
- Updated all 37+ test files that construct `HouseholdsCompanion.insert` or call `provider.createHousehold`
- Added new tests: personCount stored and retrievable, updateHousehold with personCount change, form validation tests

## Task Commits

Each task was committed atomically:

1. **Task 1: Add personCount to Households table and migrate to schema v4** - `266c5bc` (feat)
2. **Task 2: Update provider, form dialog, screens, and localization for person count** - `fdf78d6` (feat)

## Files Created/Modified
- `lib/database/tables.dart` - Added `IntColumn get personCount => integer()()`
- `lib/database/app_database.dart` - Bumped schemaVersion to 4, added migration block
- `lib/database/app_database.g.dart` - Regenerated with personCount field
- `lib/providers/household_provider.dart` - createHousehold/updateHousehold accept personCount
- `lib/widgets/dialogs/household_form_dialog.dart` - Person count field + HouseholdFormData.personCount
- `lib/screens/households_screen.dart` - Passes result.personCount to provider
- `lib/l10n/app_en.arb` - personCount, personCountHint, personCountRequired keys
- `lib/l10n/app_de.arb` - German translations for same keys
- `lib/services/backup_restore_service.dart` - expectedSchemaVersion bumped from 3 to 4
- Test files (37+) - Updated HouseholdsCompanion.insert and provider.createHousehold calls

## Decisions Made
- `personCount` has no `.withDefault()` in Drift table definition; the form enforces the value. The `DEFAULT 1` in the `ALTER TABLE` migration only assigns values to existing rows.
- `BackupRestoreService.expectedSchemaVersion` must be bumped alongside `schemaVersion` (discovered when backup tests failed with schema mismatch).
- Used `FilteringTextInputFormatter.digitsOnly` for reliable digit-only input (keyboard type alone doesn't prevent pasting non-digits).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] BackupRestoreService.expectedSchemaVersion not updated**
- **Found during:** Task 2 (running full test suite)
- **Issue:** `backup_restore_test.dart` and `backup_restore_service_test.dart` failed because service still validated against schema version 3 while DB was now v4
- **Fix:** Bumped `expectedSchemaVersion` from 3 to 4 in `lib/services/backup_restore_service.dart`; updated test helper calls from `schemaVersion: 3` to `schemaVersion: 4`
- **Files modified:** `lib/services/backup_restore_service.dart`, `test/services/backup_restore_service_test.dart`, `test/integration/backup_restore_test.dart`
- **Verification:** All backup tests pass
- **Committed in:** `fdf78d6` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug - missing schema version constant update)
**Impact on plan:** Essential correctness fix. No scope creep.

## Issues Encountered
- The automated Node.js script for bulk-replacing `HouseholdsCompanion.insert(...)` calls used a naive regex that mangled multi-line calls (nested parentheses). Had to revert and redo with targeted Edit tool calls for multiline cases.
- `build_runner` used cached outputs when first run after table change, requiring `dart run build_runner clean` then full rebuild to regenerate correct generated code.

## Next Phase Readiness
- personCount field is in DB, provider, and form - ready for Plan 03 (home screen card display)
- 1108 tests passing (1 pre-existing migration_test failure unrelated to this plan)
- Zero analyzer errors

---
*Phase: 28-home-nav-polish*
*Completed: 2026-04-01*
