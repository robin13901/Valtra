---
phase: 32-heating-analytics-cleanup
plan: 01
subsystem: ui
tags: [flutter, heating, analytics, pie-chart, month-selector, shared-widgets]

# Dependency graph
requires:
  - phase: 27-shared-chart-infrastructure
    provides: MonthSelector, MonthlySummaryCard, MonthlyBarChart, YearComparisonChart, HouseholdComparisonChart widgets
  - phase: 31-smart-plug-overhaul
    provides: ConsumptionPieChart, PieSliceData, pieChartColors

provides:
  - Heating Analyse tab overhauled to month-based shared widget composition
  - Per-heater pie chart showing raw counter delta percentage distribution (HEAT-02)
  - Per-heater breakdown list with meter name, room, and percentage
  - initState fixed to call all three provider setters (setSelectedMeterType + setSelectedMonth + setSelectedYear)
  - Deprecated _YearNavigationHeader and _YearlySummaryCard removed from heating_screen.dart
  - SmartPlugConsumptionScreen deleted (unused, blocked by buildGlassFAB removal)
affects:
  - 32-02 (DEBT-01 deprecated widget removal - partially already covered here)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Heating Analyse tab: MonthSelector -> MonthlySummaryCard -> MonthlyBarChart -> YearComparisonChart -> HouseholdComparisonChart -> ConsumptionPieChart"
    - "Per-heater pie: raw reading deltas from HeatingProvider.getReadingsWithDeltas, pieChartColors (multi-hue)"
    - "showCosts: false always for heating (no cost profiles)"

key-files:
  created: []
  modified:
    - lib/screens/heating_screen.dart
    - test/screens/heating_screen_test.dart
  deleted:
    - lib/screens/smart_plug_consumption_screen.dart
    - test/screens/smart_plug_consumption_screen_test.dart

key-decisions:
  - "Per-heater pie uses raw reading deltas (not ratio-adjusted) per HEAT-02 requirement: unitless counter readings"
  - "Heater distribution section title uses l10n.consumptionByRoomTitle to avoid duplicate 'Monthly Breakdown' text"
  - "SmartPlugConsumptionScreen deleted (confirmed unused, buildGlassFAB already removed in 32-02 on main)"

patterns-established:
  - "Heating screen tearDown: await Future.delayed(300ms) before disposal (prevents async race with 3 initState setters)"
  - "initState for month-based screens: setSelectedMeterType -> setSelectedMonth -> setSelectedYear (all three required)"

# Metrics
duration: 18min
completed: 2026-04-01
---

# Phase 32 Plan 01: Heating Analyse Tab Overhaul Summary

**Month-based heating Analyse tab with MonthSelector, MonthlySummaryCard, MonthlyBarChart, YearComparisonChart, HouseholdComparisonChart, and per-heater ConsumptionPieChart showing raw counter delta percentages**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-01T16:13:49Z
- **Completed:** 2026-04-01T16:32:00Z
- **Tasks:** 1 (single large task)
- **Files modified:** 4 (2 modified, 2 deleted)

## Accomplishments
- Replaced old yearly-only heating Analyse tab with the shared widget composition pattern used by electricity/gas/water screens
- Fixed broken initState: added missing `setSelectedMonth` call (was causing monthlyData to never load)
- Added per-heater pie chart (HEAT-02) computing raw counter reading deltas per meter for the selected month
- Removed 160+ LOC of deprecated private classes (_YearNavigationHeader, _YearlySummaryCard)
- Added 8 new test cases: Analyse tab shared widgets, loading state, MonthSelector navigation, pie chart render/no-render, breakdown percentages
- Updated tearDown with 300ms delay to prevent async disposal races

## Task Commits

Each task was committed atomically:

1. **Task 1: Overhaul heating Analyse tab + per-heater pie chart** - `3230af6` (feat)

**Plan metadata:** (pending - this summary commit)

## Files Created/Modified
- `lib/screens/heating_screen.dart` - Replaced old yearly pattern with month-based composition + pie chart; removed _YearNavigationHeader, _YearlySummaryCard, old _buildAnalyseContent
- `test/screens/heating_screen_test.dart` - Fixed tearDown delay, added Analyse tab + pie chart tests (30 total tests, up from 23)
- `lib/screens/smart_plug_consumption_screen.dart` - DELETED (unused, buildGlassFAB already removed)
- `test/screens/smart_plug_consumption_screen_test.dart` - DELETED (alongside screen)

## Decisions Made
- Per-heater pie chart uses **raw reading deltas** (not ratio-adjusted) per HEAT-02 requirement: "unitless counter readings"
- Heater distribution section uses `consumptionByRoomTitle` ("Consumption by Room") to avoid duplicate "Monthly Breakdown" heading
- SmartPlugConsumptionScreen deleted immediately as it had a blocking compilation error (buildGlassFAB removed in phase 32-02 on main) and was confirmed unused

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Deleted SmartPlugConsumptionScreen causing compilation failure**
- **Found during:** Full test suite run
- **Issue:** `smart_plug_consumption_screen.dart` called `buildGlassFAB()` which was removed from `liquid_glass_widgets.dart` by phase 32-02 (merged to main before this worktree was set up). This caused a compilation error blocking the test suite.
- **Fix:** Deleted `lib/screens/smart_plug_consumption_screen.dart` and `test/screens/smart_plug_consumption_screen_test.dart`. The research confirmed these files are unused (no navigation to SmartPlugConsumptionScreen in `lib/`).
- **Files modified:** 2 files deleted
- **Verification:** `flutter test` completes without compilation error; only 1 failure remains (pre-existing migration_test issue documented in STATE.md)
- **Committed in:** `3230af6`

**2. [Rule 3 - Blocking] Worktree was missing phases 29-31 changes**
- **Found during:** Task 1 implementation - `householdComparisonData` getter not found on AnalyticsProvider
- **Issue:** Worktree HEAD was at phase 28 (pre-29-31 work). The analytics_provider.dart didn't have `householdComparisonData` getter.
- **Fix:** `git merge main` to fast-forward the worktree to include all phases 29-31+32-02 changes (62 commits ahead of origin/main)
- **Verification:** `analyticsProvider.householdComparisonData` compiles; heating screen has all 6 required shared widgets

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both auto-fixes necessary to unblock compilation and correct implementation. No scope creep.

## Issues Encountered
- Worktree was diverged from main and missing all phases 29-31 changes - resolved by merging main
- "Monthly Breakdown" text appeared twice (bar chart section + heater distribution) causing `findsOneWidget` test failure - resolved by using `consumptionByRoomTitle` for the heater section
- Pre-existing `migration_test.dart` failure remains (v2→v3 smart plug interval conversion - documented in STATE.md as unscheduled debt)

## Next Phase Readiness
- Heating Analyse tab fully aligned with electricity/gas/water patterns
- Phase 32-02 (DEBT-01: deprecated GlassBottomNav/buildGlassFAB removal) is the remaining plan in Phase 32
- SmartPlugConsumptionScreen already deleted here, so 32-02 only needs to clean up remaining deprecated symbols and migrate households_screen/rooms_screen FABs

---
*Phase: 32-heating-analytics-cleanup*
*Completed: 2026-04-01*
