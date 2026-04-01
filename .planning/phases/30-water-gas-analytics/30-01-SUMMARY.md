---
phase: 30-water-gas-analytics
plan: 01
subsystem: ui
tags: [water, analytics, month-selector, monthly-summary-card, monthly-bar-chart, household-comparison, flutter, provider]

requires:
  - phase: 29-02
    provides: reference composition pattern (MonthSelector -> MonthlySummaryCard -> MonthlyBarChart -> YearComparisonChart -> HouseholdComparisonChart)
  - phase: 27-01
    provides: MonthSelector, MonthlySummaryCard, MonthlyBarChart shared widgets
  - phase: 27-02
    provides: YearComparisonChart, ChartLegend shared widgets
  - phase: 27-03
    provides: HouseholdComparisonChart shared widget

provides:
  - water-screen-month-based-analyse-tab
  - dead-code-removal-YearNavigationHeader-YearlySummaryCard-water

affects: [31-gas-analytics, 32-heating-analytics]

tech-stack:
  added: []
  patterns:
    - month-based-analyse-tab-composition-pattern-water

key-files:
  created: []
  modified:
    - lib/screens/water_screen.dart
    - test/screens/water_screen_test.dart

key-decisions:
  - "No SmartPlugAnalyticsProvider in water screen (water-only, no smart plug integration)"
  - "setSelectedMonth + setSelectedYear both called in initState; only 2 async ops (no SP sync) so 300ms tearDown sufficient"
  - "analytics_models.dart added as explicit import for MeterType (not transitive from analytics_provider.dart)"
  - "app_database.dart kept as import (WaterMeter/WaterReading generated classes used in Liste tab widgets)"
  - "Existing 'shows year navigation' test renamed/updated to check MonthSelector and MonthlySummaryCard instead of year text"

patterns-established:
  - "Water Analyse tab uses identical composition to electricity minus SmartPlugAnalyticsProvider"
  - "tearDown 300ms delay: 2 async initState ops for non-SP screens (setSelectedMonth + setSelectedYear)"

duration: ~11min
completed: 2026-04-01
---

# Phase 30 Plan 01: Water Analytics Analyse Tab Redesign Summary

**Water Analyse tab redesigned with MonthSelector, MonthlySummaryCard (blue water color), MonthlyBarChart (with highlightMonth), conditional YearComparisonChart, and conditional HouseholdComparisonChart — mirroring the electricity screen pattern without SmartPlug integration.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-04-01T13:56:29Z
- **Completed:** 2026-04-01T14:07:44Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced yearly-based `_buildAnalyseContent` / `_YearNavigationHeader` / `_YearlySummaryCard` with the unified month-based design using all Phase 27 shared widgets
- Added `setSelectedMonth(DateTime.now())` in `initState` so `monthlyData` is populated on screen entry
- `previousMonthTotal` computed inline from `monthlyData.recentMonths` (same pattern as electricity)
- Removed `_YearNavigationHeader` and `_YearlySummaryCard` dead code classes entirely (-228 lines, +70 lines net -158)
- Updated test file: 300ms tearDown delay, 3 new Analyse tab tests, existing test updated for month-based assertions
- Test count: 1221 passing (pre-existing migration_test.dart failure unchanged)

## Task Commits

1. **Task 1: Redesign water screen Analyse tab with shared widgets** - `14e6dfa` (feat)
2. **Task 2: Update water screen tests for month-based Analyse tab** - `5b84d19` (test)

## Files Created/Modified

- `lib/screens/water_screen.dart` - Redesigned Analyse tab; dead code removed (_YearNavigationHeader, _YearlySummaryCard, _buildAnalyseContent); new imports for MonthSelector, MonthlySummaryCard, HouseholdComparisonChart, analytics_models
- `test/screens/water_screen_test.dart` - 300ms tearDown delay; new 'Analyse Tab (month-based)' test group; updated existing Analyse test; imports for MonthSelector, MonthlySummaryCard, MonthlyBarChart

## Decisions Made

- No `SmartPlugAnalyticsProvider` in water screen -- water has no smart plug integration, omit entirely
- `analytics_models.dart` must be imported explicitly for `MeterType` -- it is not exported transitively from `analytics_provider.dart`
- `app_database.dart` kept as import because `WaterMeter` and `WaterReading` generated classes are used in the Liste tab's `_WaterMeterCard` widget
- `setSelectedYear` called conditionally (only on year boundary crossing) consistent with the electricity screen pattern

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Re-added app_database.dart import**

- **Found during:** Task 1 verification (flutter analyze)
- **Issue:** Plan spec said "remove app_database.dart if no longer needed after dead code removal" -- but `_WaterMeterCard` in the Liste tab still uses `WaterMeter` and `WaterReading` generated data classes from `app_database.g.dart`, which is only accessible via `app_database.dart`
- **Fix:** Kept `app_database.dart` import; removed only the `analytics_models.dart`-provides-YearlyAnalyticsData dependency
- **Files modified:** `lib/screens/water_screen.dart`
- **Verification:** `flutter analyze lib/screens/water_screen.dart` - no issues
- **Committed in:** `14e6dfa` (Task 1 commit)

**2. [Rule 2 - Missing Critical] Added analytics_models.dart import for MeterType**

- **Found during:** Task 1 verification (flutter analyze)
- **Issue:** `MeterType` enum comes from `analytics_models.dart`, not from `tables.dart` or transitively through `analytics_provider.dart` -- required explicit import
- **Fix:** Added `import '../services/analytics/analytics_models.dart';`
- **Files modified:** `lib/screens/water_screen.dart`
- **Verification:** `flutter analyze lib/screens/water_screen.dart` - no issues
- **Committed in:** `14e6dfa` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 missing critical)
**Impact on plan:** Both fixes directly required for compilation correctness. No scope creep.

## Issues Encountered

None beyond the auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Water Analyse tab uses same month-based pattern as electricity
- Plan 30-02 (Gas Analytics) can follow the same pattern: MonthSelector → MonthlySummaryCard → MonthlyBarChart → conditional YearComparisonChart → conditional HouseholdComparisonChart
- Gas has no SmartPlugAnalyticsProvider, same as water
- Dead code (_YearNavigationHeader, _YearlySummaryCard) remains in gas_screen.dart and heating_screen.dart — scheduled for Plans 31-32

---
*Phase: 30-water-gas-analytics*
*Completed: 2026-04-01*
