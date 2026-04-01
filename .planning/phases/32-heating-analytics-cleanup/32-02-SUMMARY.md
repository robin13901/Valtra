---
phase: 32-heating-analytics-cleanup
plan: 02
subsystem: ui
tags: [flutter, liquid-glass, deprecated-widgets, dead-code-removal, tech-debt]

# Dependency graph
requires:
  - phase: 28-home-nav-polish
    provides: LiquidGlassBottomNav replacing GlassBottomNav
  - phase: 31-smart-plug-screen-overhaul
    provides: expandable cards replacing SmartPlugConsumptionScreen navigation
provides:
  - GlassBottomNav and buildGlassFAB fully removed from liquid_glass_widgets.dart
  - HouseholdsScreen and RoomsScreen using standard FloatingActionButton
  - SmartPlugConsumptionScreen deleted (dead code after Phase 31)
  - Zero deprecated annotations remaining in liquid_glass_widgets.dart
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Standard FloatingActionButton used for add actions in households and rooms screens"

key-files:
  created: []
  modified:
    - lib/widgets/liquid_glass_widgets.dart
    - lib/screens/households_screen.dart
    - lib/screens/rooms_screen.dart
    - test/widgets/liquid_glass_widgets_test.dart
    - test/widgets/liquid_glass_widgets_coverage_test.dart

key-decisions:
  - "Standard FloatingActionButton (not themed) replaces buildGlassFAB -- simplest correct migration with no behavioral regression"
  - "SmartPlugConsumptionScreen confirmed dead: zero Navigator.push/route refs after Phase 31 expandable cards"

patterns-established: []

# Metrics
duration: 5min
completed: 2026-04-01
---

# Phase 32 Plan 02: Deprecated Widget Removal Summary

**Removed GlassBottomNav class and buildGlassFAB function (deprecated since v0.5.0) plus deleted dead SmartPlugConsumptionScreen, eliminating DEBT-01 and 492 lines of dead code**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-01T16:12:39Z
- **Completed:** 2026-04-01T16:17:32Z
- **Tasks:** 2
- **Files modified:** 5 (+ 2 deleted)

## Accomplishments
- Removed GlassBottomNav class (50 lines) and buildGlassFAB function (36 lines) from liquid_glass_widgets.dart
- Migrated HouseholdsScreen and RoomsScreen FABs to standard FloatingActionButton
- Removed corresponding test groups (4 tests) from both liquid_glass_widgets_test.dart and liquid_glass_widgets_coverage_test.dart
- Deleted SmartPlugConsumptionScreen and its 7-test test file (confirmed dead since Phase 31)
- Zero @Deprecated annotations remain in liquid_glass_widgets.dart
- 1213 tests passing (down from 1229 due to deleted dead-code tests; pre-existing migration_test failure unchanged)

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove deprecated widgets and dead code** - `2f78745` (refactor)
2. **Task 2: Delete dead SmartPlugConsumptionScreen** - `37bc233` (refactor)

**Plan metadata:** (see final docs commit)

## Files Created/Modified
- `lib/widgets/liquid_glass_widgets.dart` - Removed GlassBottomNav class and buildGlassFAB function
- `lib/screens/households_screen.dart` - Replaced buildGlassFAB with FloatingActionButton
- `lib/screens/rooms_screen.dart` - Replaced buildGlassFAB with FloatingActionButton
- `test/widgets/liquid_glass_widgets_test.dart` - Removed GlassBottomNav and buildGlassFAB test groups
- `test/widgets/liquid_glass_widgets_coverage_test.dart` - Removed GlassBottomNav and buildGlassFAB test groups
- `lib/screens/smart_plug_consumption_screen.dart` - DELETED (dead code)
- `test/screens/smart_plug_consumption_screen_test.dart` - DELETED (test for dead code)

## Decisions Made
- Standard `FloatingActionButton` (no custom theming) chosen to replace `buildGlassFAB` callers -- minimal surface area, consistent with Material design, no behavioral regression
- SmartPlugConsumptionScreen deletion confirmed safe via grep showing zero navigation references in lib/ or test/ (outside the deleted files themselves)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. The pre-existing `migration_test.dart` failure (v2→v3 smart plug interval conversion, unscheduled tech debt) was present before this plan and remains unchanged.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- DEBT-01 fully resolved: no deprecated symbols remain in liquid_glass_widgets.dart
- Phase 32 is now complete (32-01 heating analytics + 32-02 deprecated widget removal)
- v0.6.0 milestone plans complete -- ready for milestone verification and tagging

---
*Phase: 32-heating-analytics-cleanup*
*Completed: 2026-04-01*
