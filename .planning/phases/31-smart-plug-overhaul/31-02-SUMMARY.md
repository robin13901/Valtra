---
phase: 31-smart-plug-overhaul
plan: 02
subsystem: ui
tags: [flutter, smart-plugs, expandable-cards, provider, analytics, stream-builder]

# Dependency graph
requires:
  - phase: 31-01
    provides: SmartPlugAnalyseTab redesign, smartPlugPieColors, MockAnalyticsProvider in test setup
provides:
  - _SmartPlugExpandableCard with inline consumption CRUD (add/edit/delete via form dialogs)
  - Flat plug list replacing room-grouped sections in Liste tab
  - SmartPlugsScreen initState wiring both AnalyticsProvider + SmartPlugAnalyticsProvider
  - Updated test file with expandable card tests and MeterType fallback registration
affects: [phase-32-cleanup, future-smart-plug-features]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "_HeatingMeterCard expandable pattern applied to smart plugs (GlassCard > InkWell header > if _isExpanded ... expanded section)"
    - "StreamBuilder inside expandable section for live consumption list"
    - "registerFallbackValue(MeterType.electricity) required in setUpAll for mocktail any() on enum types"
    - "300ms tearDown delay for async initState disposal safety"

key-files:
  created: []
  modified:
    - lib/screens/smart_plugs_screen.dart
    - test/screens/smart_plugs_screen_test.dart

key-decisions:
  - "l10n.addConsumption used as button label (not generic l10n.add) for clarity"
  - "registerFallbackValue(MeterType.electricity) required in setUpAll when using any() matcher on enum parameters in mocktail"
  - "_SmartPlugExpandableCard calls _loadLatestConsumption() after add/edit/delete so header stays in sync"

patterns-established:
  - "Expandable card pattern: StatefulWidget with _isExpanded bool, InkWell header, if (_isExpanded) [...Divider, content section]"
  - "StreamBuilder for inline list within expanded section: watchConsumptionsForPlug + shrinkWrap ListView.builder"

# Metrics
duration: 7min
completed: 2026-04-01
---

# Phase 31 Plan 02: Smart Plug Overhaul - Liste Tab Expandable Cards Summary

**Room-grouped smart plug list replaced with flat expandable cards featuring inline consumption CRUD via StreamBuilder, with SmartPlugsScreen initState wiring both AnalyticsProvider and SmartPlugAnalyticsProvider**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-01T15:27:30Z
- **Completed:** 2026-04-01T15:35:06Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced `_SmartPlugsList`/`_RoomSection`/`_SmartPlugCard` with single `_SmartPlugExpandableCard` StatefulWidget following the `_HeatingMeterCard` pattern
- Inline consumption management (add/edit/delete) via `SmartPlugConsumptionFormDialog` and `ConfirmDeleteDialog` - no navigation to separate screen
- SmartPlugsScreen initState now initializes `AnalyticsProvider` (MeterType.electricity) + `SmartPlugAnalyticsProvider` via `setSelectedMonth`
- 20 tests passing (4 new expandable card tests added)

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace SmartPlugsScreen Liste tab with expandable cards and update initState** - `f473f36` (feat)
2. **Task 2: Update smart_plugs_screen_test.dart for expandable cards and flat list** - `a5bb68e` (test)

**Plan metadata:** (see final commit below)

## Files Created/Modified
- `lib/screens/smart_plugs_screen.dart` - Replaced room-grouped classes with `_SmartPlugExpandableCard`; updated initState; removed `smart_plug_consumption_screen.dart` import
- `test/screens/smart_plugs_screen_test.dart` - Added MeterType fallback registration, new provider stubs, 300ms tearDown delay, 4 expandable card tests; removed room section icon test

## Decisions Made
- `l10n.addConsumption` used as button label (not a generic "Add") for explicit labeling in the expanded consumption section
- `registerFallbackValue(MeterType.electricity)` must be added to `setUpAll` when using `any()` on enum type parameters in mocktail stubs
- `_loadLatestConsumption()` called after each CRUD operation to keep the card header's "last entry" display in sync without requiring a StreamBuilder at the header level

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added `registerFallbackValue(MeterType.electricity)` to test setUpAll**
- **Found during:** Task 2 (test execution)
- **Issue:** mocktail `any()` matcher on `MeterType` enum parameter in `setSelectedMeterType(any())` stub requires a fallback value to be registered; tests failed with "Bad state: registerFallbackValue not called"
- **Fix:** Added `registerFallbackValue(MeterType.electricity)` to `setUpAll`, plus `analytics_models.dart` import in test file
- **Files modified:** `test/screens/smart_plugs_screen_test.dart`
- **Verification:** All 20 tests pass
- **Committed in:** a5bb68e (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical test infrastructure)
**Impact on plan:** Required for test correctness. No scope creep.

## Issues Encountered
None beyond the MeterType fallback deviation documented above.

## Next Phase Readiness
- Smart Plug screen overhaul (Phase 31) fully complete: Analyse tab redesigned (31-01), Liste tab expandable cards (31-02)
- Phase 32 (cleanup/debt) can now remove deprecated `GlassBottomNav`/`buildGlassFAB`
- `SmartPlugConsumptionScreen` still exists but is no longer navigated to from `smart_plugs_screen.dart`; can be removed in Phase 32 if confirmed unused elsewhere

---
*Phase: 31-smart-plug-overhaul*
*Completed: 2026-04-01*
