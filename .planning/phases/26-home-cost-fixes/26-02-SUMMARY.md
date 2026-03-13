---
phase: 26-home-cost-fixes
plan: 02
subsystem: ui
tags: [flutter, dart, cost-profiles, heating, analytics, enum]

# Dependency graph
requires:
  - phase: 26-01
    provides: cost settings screen with badge removed, hardcoded German currency
provides:
  - CostMeterType enum with exactly 3 values (electricity, gas, water) -- no heating
  - Heating screen without cost toggle (consumption-only display)
  - AnalyticsProvider returning null for MeterType.heating cost type
affects: [cost-config-provider, analytics-provider, heating-screen, household-cost-settings-screen]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Heating as consumption-only: all heating chart widgets receive showCosts=false, periodCosts=null, costUnit=null"
    - "null-safe cost lookup: _toCostMeterType returns null for heating, cascades safely through calculateCost guard"

key-files:
  created: []
  modified:
    - lib/database/tables.dart
    - lib/screens/household_cost_settings_screen.dart
    - lib/widgets/dialogs/cost_profile_form_dialog.dart
    - lib/providers/analytics_provider.dart
    - lib/screens/heating_screen.dart
    - test/screens/household_cost_settings_screen_test.dart
    - test/screens/heating_screen_test.dart

key-decisions:
  - "CostMeterType.heating removed permanently (ordinal 3) -- DB-safe because no CostConfig rows with meterType=3 exist in production"
  - "Heating screen imports: cost_config_provider.dart removed as unused after _buildCostToggle deletion"
  - "Test count: 3 Cost Toggle tests deleted, 1 existing updated, 1 new no-toggle assertion added (net -2, total 1103)"

patterns-established:
  - "Consumption-only meter type: remove enum value, remove switch cases, return null from cost mapper, hardcode showCosts=false in screen"

# Metrics
duration: 8min
completed: 2026-03-13
---

# Phase 26 Plan 02: Remove CostMeterType.heating Summary

**CostMeterType enum reduced to 3 values (electricity/gas/water); heating screen made consumption-only by removing _showCosts state and _buildCostToggle method**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-13T17:03:24Z
- **Completed:** 2026-03-13T17:04:14Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- CostMeterType enum has exactly 3 values: `{ electricity, gas, water }` -- heating permanently removed
- All switch statements exhaustive without heating (zero compile errors)
- Heating screen is consumption-only: no `_showCosts` state, no `_buildCostToggle` method, no cost toggle in app bar
- `_toCostMeterType(MeterType.heating)` returns `null` -- no cost calculation attempted for heating anywhere
- Cost settings screen renders exactly 3 cards (Electricity, Gas, Water)

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove CostMeterType.heating from enum and all switch cases** - `0aca6d9` (feat)
2. **Task 2: Remove cost toggle and showCosts from heating screen** - `8fda0fd` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `lib/database/tables.dart` - CostMeterType enum: removed `heating` value
- `lib/screens/household_cost_settings_screen.dart` - Removed `CostMeterType.heating` cases from `_meterTypeLabel` and `_meterTypeIcon`
- `lib/widgets/dialogs/cost_profile_form_dialog.dart` - Removed `CostMeterType.heating` fall-through in `_unitSuffix`
- `lib/providers/analytics_provider.dart` - `_toCostMeterType` returns `null` for `MeterType.heating`
- `lib/screens/heating_screen.dart` - Removed `_showCosts`, `_buildCostToggle`, cost toggle from app bar, `CostConfigProvider` import; hardcoded `showCosts: false`
- `test/screens/household_cost_settings_screen_test.dart` - Updated 5 assertions: Heating->findsNothing, thermostat->findsNothing, count 4->3 in 4 places
- `test/screens/heating_screen_test.dart` - Removed 3 Cost Toggle tests; updated 1 existing test; added `no cost toggle visible on Analyse tab` assertion

## Decisions Made
- DB-safe to remove `CostMeterType.heating` (ordinal 3): Drift appended it at end of enum. No production data has `meterType=3` in CostConfig table. No migration needed.
- Test net change: -3 removed (Cost Toggle group) + 1 new assertion = 1103 total tests (down from 1105).

## Deviations from Plan

None - plan executed exactly as written.

The only notable execution detail: Task 1 changes introduced compile errors in `heating_screen.dart` (which referenced `CostMeterType.heating` in `_buildCostToggle`). Task 2 resolved them immediately as part of the same execution wave. Both tasks passed `flutter analyze` together before their respective commits.

## Issues Encountered
None - all switch statements became exhaustive with 3 enum values and Dart's exhaustiveness checker confirmed zero compile errors.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- COST-04 and COST-05 complete
- Phase 26 plan 02 done; phase 26 now complete (all 5 fixes: HOME-01, COST-01 through COST-05)
- Ready for phase 27 or milestone v0.5.0 wrap-up

---
*Phase: 26-home-cost-fixes*
*Completed: 2026-03-13*
