---
phase: 27-shared-chart-infrastructure
plan: "02"
subsystem: ui
tags: [flutter, fl_chart, bar_chart, scrolling, animation, chart_axis_style]

# Dependency graph
requires:
  - phase: 27-01
    provides: ChartAxisStyle with borderData, gridData, leftTitles, hiddenTitles

provides:
  - MonthlyBarChart as StatefulWidget with horizontal scrolling (BAR-01)
  - Glow effect on current month bar via BackgroundBarChartRodData (BAR-02)
  - Past bars opaque (0.85 alpha), future/extrapolated transparent (0.3 alpha) (BAR-03)
  - Fixed Y-axis column stays stationary while chart scrolls (AXIS-03)
  - ChartAxisStyle fully integrated into MonthlyBarChart (AXIS-01/02)

affects:
  - 28-electricity-screen
  - 28-gas-screen
  - 28-water-screen
  - 28-heating-screen
  - 29-32 (all meter screens that use MonthlyBarChart)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Row(fixed-Y-axis-column + Expanded(SingleChildScrollView)) for AXIS-03 pattern"
    - "BackgroundBarChartRodData for glow behind highlighted bar"
    - "WidgetsBinding.instance.addPostFrameCallback for auto-scroll to highlight"

key-files:
  created: []
  modified:
    - lib/widgets/charts/monthly_bar_chart.dart
    - test/widgets/charts/monthly_bar_chart_test.dart

key-decisions:
  - "visibleBars defaults to 12 -- matches 12-month view requirement, controls scroll threshold"
  - "Fixed Y-axis uses dummy transparent BarChart with same maxY to keep label alignment"
  - "Alpha 0.85 for past (not 0.6 as before), 0.3 for future/extrapolated, 1.0 for highlighted"
  - "Y-axis labels updated: ChartAxisStyle embeds unit in getTitlesWidget text, not axisNameWidget"

patterns-established:
  - "BAR-01: periods.length <= visibleBars -> simple BarChart; > visibleBars -> Row(fixed + scroll)"
  - "BAR-02: isHighlighted -> BackgroundBarChartRodData(show: true) with alpha 0.3 behind main rod"
  - "BAR-03: isFuture || isExtrapolated -> alpha 0.3; normal past -> alpha 0.85; highlighted -> 1.0"

# Metrics
duration: 18min
completed: 2026-04-01
---

# Phase 27 Plan 02: Refactor MonthlyBarChart - Scrolling, Glow, Opacity, Axis Style Summary

**MonthlyBarChart refactored from StatelessWidget to StatefulWidget with horizontal scrolling, glow highlighting, opacity semantics, and full ChartAxisStyle integration across all 5 meter screens**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-01T09:17:00Z
- **Completed:** 2026-04-01T09:35:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- MonthlyBarChart is now a StatefulWidget with ScrollController lifecycle management
- BAR-01: Horizontal scrolling kicks in when periods exceed visibleBars (default 12); fixed Y-axis stays stationary
- BAR-02: Highlighted month bar has glow effect via BackgroundBarChartRodData (translucent color behind main bar)
- BAR-03: Past bars 0.85 alpha, future/extrapolated bars 0.3 alpha, highlighted bar 1.0 alpha
- AXIS-01/02/03: Full ChartAxisStyle integration (no left border, dashed grid, translucent label text)
- 27 tests pass (13 new + 14 existing updated for new conventions)

## Task Commits

Each task was committed atomically:

1. **Task 1: Refactor MonthlyBarChart implementation** - `212f749` (feat)
2. **Task 2: Update MonthlyBarChart tests** - `deeb1d9` (test)

**Plan metadata:** see docs commit below

## Files Created/Modified
- `lib/widgets/charts/monthly_bar_chart.dart` - Refactored to StatefulWidget with scroll, glow, opacity, ChartAxisStyle
- `test/widgets/charts/monthly_bar_chart_test.dart` - Updated and expanded: 27 tests total

## Decisions Made
- `visibleBars` defaults to 12 (12-month view requirement); scroll layout only activates above this threshold
- Fixed Y-axis column is a transparent dummy BarChart with the same `maxY` to keep label alignment pixel-perfect
- Alpha changed from old scheme (0.6 normal, 1.0 highlighted) to new scheme (0.85 past, 0.3 extrapolated/future, 1.0 highlighted) matching BAR-03 spec
- ChartAxisStyle.leftTitles embeds the unit in the label text (`"{value} {unit}"` format) via `getTitlesWidget`, not via `axisNameWidget` - existing tests for `axisNameWidget` updated to check `getTitlesWidget` output instead

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `chart_axis_style.dart` import from test file**
- **Found during:** Task 2 (test update)
- **Issue:** Plan specified adding the import, but no direct static method was called in tests (assertions go through BarChart data, not ChartAxisStyle directly); `flutter analyze` flagged `unused_import`
- **Fix:** Removed the import from the test file
- **Files modified:** test/widgets/charts/monthly_bar_chart_test.dart
- **Verification:** `flutter analyze` reports no issues
- **Committed in:** deeb1d9 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug - unused import)
**Impact on plan:** Trivial fix required by analyzer; no scope change.

## Issues Encountered
- Existing Y-axis tests checked `data.titlesData.leftTitles.axisNameWidget` for the unit label. ChartAxisStyle uses `sideTitles.getTitlesWidget` with inline unit text, so `axisNameWidget` is null in the new implementation. Tests were updated to verify `getTitlesWidget` returns a `SideTitleWidget` with `Text` containing the unit string instead.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- MonthlyBarChart is production-ready for all 5 meter screens (electricity, gas, water, heating, smart plug)
- Scrolling, glow, opacity, and shared axis style all functional
- No blockers for phases 28-32 that integrate MonthlyBarChart

---
*Phase: 27-shared-chart-infrastructure*
*Completed: 2026-04-01*
