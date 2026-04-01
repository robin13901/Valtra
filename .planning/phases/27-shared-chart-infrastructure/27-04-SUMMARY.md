---
phase: 27-shared-chart-infrastructure
plan: "04"
subsystem: ui
tags: [flutter, fl_chart, line-chart, household-comparison, analytics, charts]

# Dependency graph
requires:
  - phase: 27-01
    provides: ChartAxisStyle (borderData, gridData, leftTitles, hiddenTitles) for AXIS-01/02 compliance
provides:
  - HouseholdComparisonChart widget: multi-line chart comparing consumption across households
  - HouseholdChartData model: data class pairing household name + PeriodConsumption list + color
affects:
  - phases 28-32 (analytics screens integrating household comparison charts)
  - any provider building HouseholdChartData lists from DB

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "HouseholdChartData as typed data transfer object from provider to chart widget"
    - "Actual vs interpolated split using FlSpot.nullSpot to create line gaps (not separate lists)"
    - "X-axis = (month-1) + (yearOffset*12) for multi-year data, simplifies to 0-11 for single year"
    - "Dashed line for interpolated/extrapolated: dashArray [8,4], alpha 0.5"
    - "Open dot via FlDotCirclePainter(color: surface, strokeColor: lineColor)"

key-files:
  created:
    - lib/widgets/charts/household_comparison_chart.dart
    - test/widgets/charts/household_comparison_chart_test.dart
  modified: []

key-decisions:
  - "HouseholdChartData.color is caller-assigned: provider assigns pieChartColors[index], widget is color-agnostic"
  - "interpolated/extrapolated unified: both render as dashed line + open dots"
  - "No belowBarData fill on any line: comparison chart uses clean lines without gradient fills"
  - "locale defaults 'de' matching existing chart widget convention"

patterns-established:
  - "Multi-household line chart: each household is 2 optional bars (actual solid + interpolated dashed)"
  - "FlSpot.nullSpot creates gaps in lines for the opposing series type"

# Metrics
duration: 12min
completed: 2026-04-01
---

# Phase 27 Plan 04: New HouseholdComparisonChart Widget Summary

**Multi-line fl_chart LineChart comparing PeriodConsumption across households with actual (solid+filled dot) vs interpolated/extrapolated (dashed+open dot) visual distinction using ChartAxisStyle for AXIS-01/02 compliance**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-01T09:06:40Z
- **Completed:** 2026-04-01T09:19:37Z
- **Tasks:** 2
- **Files modified:** 2 (both new)

## Accomplishments
- Created `HouseholdChartData` model (name + PeriodConsumption list + Color) as typed DTO for provider→chart data transfer
- Implemented `HouseholdComparisonChart` StatelessWidget with multi-year X-axis, actual/interpolated visual split, ChartAxisStyle integration, and locale-aware tooltips
- 14 widget tests covering empty data, single/multiple households, HCMP-01 color assignment, HCMP-02 solid/dashed distinction, AXIS-01/02 border and grid style, and edge cases

## Task Commits

Each task was committed atomically:

1. **Task 1: Create HouseholdComparisonChart widget** - `32d6680` (feat)
2. **Task 2: Create HouseholdComparisonChart tests** - `2f15dc4` (test)

**Plan metadata:** `[pending]` (docs: complete plan)

## Files Created/Modified
- `lib/widgets/charts/household_comparison_chart.dart` - HouseholdChartData model + HouseholdComparisonChart widget
- `test/widgets/charts/household_comparison_chart_test.dart` - 14 widget tests

## Decisions Made
- Removed the `analytics_models.dart` import from the widget: the widget itself doesn't reference `pieChartColors` directly — callers assign colors when constructing `HouseholdChartData`. This keeps the widget color-agnostic and avoids an unused import warning.
- `interpolated` flag check unifies `startInterpolated || endInterpolated || isExtrapolated` into a single branch — any uncertainty about a period renders it dashed, matching conservative visual policy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `analytics_models.dart` import**
- **Found during:** Task 1 (flutter analyze check)
- **Issue:** Plan specified importing `analytics_models.dart` for `pieChartColors`, but the widget uses `Color` directly (caller assigns colors). `flutter analyze` reported `unused_import` warning.
- **Fix:** Removed the import. The test file correctly imports `analytics_models.dart` since it uses `pieChartColors` directly to construct test data.
- **Files modified:** `lib/widgets/charts/household_comparison_chart.dart`
- **Verification:** `flutter analyze` reports no issues
- **Committed in:** `32d6680` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - unused import removed)
**Impact on plan:** Minor. Widget design unchanged; caller assigns colors as originally designed. No scope creep.

## Issues Encountered
- Pre-existing failure in `test/database/migration_test.dart` ("consumptions merged by month with SUM" expects 1, gets 12). Verified this failure existed before this plan's changes via `git stash`. Not introduced by this plan.

## Next Phase Readiness
- `HouseholdComparisonChart` + `HouseholdChartData` ready for integration into analytics screens in phases 28-32
- Callers should build `HouseholdChartData` lists using `pieChartColors[index]` for color assignment
- Widget handles empty households gracefully (shows `noData`), skips empty-period households silently

---
*Phase: 27-shared-chart-infrastructure*
*Completed: 2026-04-01*
