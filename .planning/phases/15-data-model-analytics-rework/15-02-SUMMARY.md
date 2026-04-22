# Phase 15 Plan 02: Smart Plug Entry Rework -- Data Layer Summary

Removed ConsumptionInterval enum and intervalType/intervalStart columns, replaced with single month (DateTime) column for simplified monthly consumption entries.

## Changes Made

### T1: Table Definitions (tables.dart)
- Removed `ConsumptionInterval` enum (daily/weekly/monthly/yearly)
- Removed `intervalType` intEnum column from `SmartPlugConsumptions`
- Renamed `intervalStart` to `month` (DateTime, 1st of month 00:00)
- Regenerated Drift code via `build_runner build`

### T2: SmartPlugDao
- Updated `getConsumptionsForPlug()` -- order by `month` desc
- Updated `watchConsumptionsForPlug()` -- order by `month` desc
- Updated `getLatestConsumptionForPlug()` -- order by `month` desc
- Added `getConsumptionForMonth(plugId, month)` -- exact month lookup
- Updated all 3 aggregation methods to filter by `month` column

### T3: SmartPlugProvider
- Simplified `addConsumption(plugId, month, kWh)` -- no intervalType param
- Added duplicate month check (returns -1 if entry exists)
- Simplified `updateConsumption(id, month, kWh)` -- no intervalType param
- Updated `ConsumptionWithLabel.generateLabel()` to produce localized month/year string via `DateFormat.yMMMM(locale)`
- Changed `getConsumptionsForPlug()` and `watchConsumptionsForPlug()` to accept `locale` string instead of interval name function

### T4: SmartPlugAnalyticsProvider
- No changes needed -- already calls DAO via method names, not column accessors

### T5: Tests
- **DAO tests**: 20 tests (7 smart plug + 9 consumption including 2 new for getConsumptionForMonth + 4 aggregation)
- **Provider tests**: 12 tests (5 CRUD + duplicate month check + consumption with labels + latest)
- **Analytics tests**: 22 tests (unchanged, still pass)
- **Form dialog tests**: 6 tests (updated for month picker, removed interval type assertions)
- **Tables test**: 1 test updated (consumption insert without intervalType)
- **Room DAO test**: 1 test updated (cascade delete consumption without intervalType)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated form dialog and screens to compile**
- **Found during:** T1/T3
- **Issue:** Removing `ConsumptionInterval` from tables.dart broke the form dialog, consumption screen, and smart plugs screen
- **Fix:** Updated `SmartPlugConsumptionFormDialog` (removed interval dropdown, uses month picker), `SmartPlugConsumptionScreen` (passes locale instead of interval name function), `SmartPlugsScreen` (uses `DateFormat.yMMM` for lastEntry label)
- **Files modified:** `lib/widgets/dialogs/smart_plug_consumption_form_dialog.dart`, `lib/screens/smart_plug_consumption_screen.dart`, `lib/screens/smart_plugs_screen.dart`
- **Commit:** 5dd3e5e

**2. [Rule 1 - Bug] Added date formatting initialization in provider test**
- **Found during:** T5
- **Issue:** `ConsumptionWithLabel.generateLabel()` uses `DateFormat.yMMMM(locale)` which requires `initializeDateFormatting()` before use
- **Fix:** Added `setUpAll(() => initializeDateFormatting('en'))` in smart_plug_provider_test.dart
- **Files modified:** `test/providers/smart_plug_provider_test.dart`
- **Commit:** 5dd3e5e

## Verification

- [x] No `ConsumptionInterval` enum in codebase (except unused l10n keys)
- [x] SmartPlugConsumptions table has `month` column (no `intervalType`, no `intervalStart`)
- [x] DAO queries work with new column names
- [x] Provider correctly manages month-based consumption with duplicate check
- [x] All 788 tests pass
- [x] flutter analyze: 0 issues

## Commits

| Hash | Message |
|------|---------|
| 5dd3e5e | feat(15-02): smart plug data layer -- remove interval type, month-based schema |

## Key Files

### Modified
- `lib/database/daos/smart_plug_dao.dart` -- month ordering, getConsumptionForMonth
- `lib/providers/smart_plug_provider.dart` -- simplified API, locale-based labels
- `lib/screens/smart_plug_consumption_screen.dart` -- locale param, no interval names
- `lib/screens/smart_plugs_screen.dart` -- DateFormat for lastEntry label
- `lib/widgets/dialogs/smart_plug_consumption_form_dialog.dart` -- month picker, no interval dropdown
- `test/database/smart_plug_dao_test.dart` -- month-based tests + getConsumptionForMonth
- `test/providers/smart_plug_provider_test.dart` -- month-based CRUD + duplicate check
- `test/widgets/smart_plug_consumption_form_dialog_test.dart` -- month picker tests
- `test/database/tables_test.dart` -- consumption insert without intervalType
- `test/database/room_dao_test.dart` -- cascade delete without intervalType

## Metrics
- **Duration:** ~36 minutes
- **Tests:** 788 passing (17 net new: 2 DAO + 2 provider + removed some old interval-specific ones, rebalanced)
- **Completed:** 2026-03-07
