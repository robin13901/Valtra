---
phase: 25-chart-localization-labels
plan: 01
subsystem: ui
tags: [flutter, fl_chart, intl, DateFormat, localization, charts]

# Dependency graph
requires:
  - phase: 24-bottom-nav-redesign
    provides: LiquidGlassBottomNav with locale/unit/costUnit already passed to chart widgets from all screens
provides:
  - Locale-aware DateFormat.MMM(locale) on MonthlyBarChart X-axis and tooltip
  - Locale-aware DateFormat.MMM(locale) on YearComparisonChart X-axis and tooltip
  - Y-axis axisNameWidget showing displayUnit (kWh, m3, EUR) on both chart widgets
affects: [26-home-cost-fixes]

# Tech tracking
tech-stack:
  added: [intl/date_symbol_data_local.dart (test initializeDateFormatting)]
  patterns:
    - DateFormat locale parameter always passed explicitly (never locale-less)
    - displayUnit computed as: showCosts && costUnit != null ? costUnit! : unit
    - axisNameWidget on AxisTitles leftTitles for Y-axis unit label

key-files:
  created: []
  modified:
    - lib/widgets/charts/monthly_bar_chart.dart
    - lib/widgets/charts/year_comparison_chart.dart
    - test/widgets/charts/monthly_bar_chart_test.dart
    - test/widgets/charts/year_comparison_chart_test.dart

key-decisions:
  - "DateFormat locale in _buildTitles() - displayUnit computed independently in _buildTitles() rather than passed as parameter to avoid signature changes"
  - "Test noData test uses locale=en - buildTestWidget default changed to 'de', so noData empty-state test passes locale=en to match English 'No data available' assertion"

patterns-established:
  - "Locale-aware chart labels: Always pass locale string from widget field to DateFormat factory (DateFormat.MMM(locale), DateFormat.yMMM(locale))"
  - "Chart Y-axis unit: axisNameWidget: Text(displayUnit) + axisNameSize: 18 on leftTitles AxisTitles"
  - "Test locale init: setUpAll(() async { await initializeDateFormatting('de'); await initializeDateFormatting('en'); }) for deterministic locale tests"

# Metrics
duration: 9min
completed: 2026-03-13
---

# Phase 25 Plan 01: Chart Localization & Labels Summary

**DateFormat.MMM(locale) and axisNameWidget(displayUnit) added to MonthlyBarChart and YearComparisonChart; German produces Jan/Feb/Mrz, English produces Jan/Feb/Mar; Y-axis shows kWh/m3/EUR**

## Performance

- **Duration:** 9 min
- **Started:** 2026-03-13T15:58:34Z
- **Completed:** 2026-03-13T16:07:47Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Both chart widgets now use `DateFormat.MMM(locale)` on X-axis bottom titles and tooltips (was locale-less, always used system locale)
- Y-axis `axisNameWidget` added to both charts displaying `displayUnit` (kWh, m³, or EUR depending on `showCosts`/`costUnit`)
- 10 new tests added (5 per chart): German/English month abbreviation assertions, unit/costUnit/null-fallback Y-axis label assertions

## Task Commits

Each task was committed atomically:

1. **Task 1: Localize MonthlyBarChart X-axis + tooltips and add Y-axis unit label** - `177a78f` (feat)
2. **Task 2: Localize YearComparisonChart X-axis + tooltips and add Y-axis unit label** - `c6ba267` (feat)

**Plan metadata:** `[TBD]` (docs: complete chart localization plan)

## Files Created/Modified
- `lib/widgets/charts/monthly_bar_chart.dart` - DateFormat.yMMM(locale) tooltip, DateFormat.MMM(locale) X-axis, axisNameWidget on leftTitles
- `lib/widgets/charts/year_comparison_chart.dart` - DateFormat.MMM(locale) tooltip + X-axis, displayUnit computed in _buildTitles(), axisNameWidget on leftTitles
- `test/widgets/charts/monthly_bar_chart_test.dart` - locale param on buildTestWidget + MaterialApp; setUpAll date init; 5 new locale/Y-axis tests
- `test/widgets/charts/year_comparison_chart_test.dart` - locale param on _wrap; setUpAll date init; 5 new locale/Y-axis tests

## Decisions Made

1. **displayUnit computed in `_buildTitles()`** - In `YearComparisonChart`, `displayUnit` was already computed in `_buildData()`. Rather than refactoring to pass it as a parameter (which would break the method signature), `_buildTitles()` also computes it independently via `showCosts && costUnit != null ? costUnit! : unit`. Consistent with how `MonthlyBarChart` handles it.

2. **Test noData assertion uses locale='en'** - `buildTestWidget` now defaults to `locale='de'`, which changes the empty-state text to German. The existing "shows noData text when periods list is empty" test was updated to explicitly pass `locale: 'en'` to keep the English assertion intact without changing test semantics.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The `shows noData text when periods list is empty` test failed on first run because changing `buildTestWidget`'s default locale from `'de'` (via MonthlyBarChart's widget default) to explicitly `'de'` in MaterialApp caused the localization to resolve to "Keine Daten vorhanden" instead of "No data available". Fixed by explicitly passing `locale: 'en'` to that single test. This was a minor test adjustment, not a code issue.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- CHART-01, CHART-02, CHART-03 requirements fulfilled
- All screens (electricity, gas, water, heating) already pass `locale`, `unit`, `showCosts`, `costUnit` to chart widgets - no screen changes needed
- 1104 tests passing, zero regressions
- Ready for Phase 26: Home & Cost Fixes

---
*Phase: 25-chart-localization-labels*
*Completed: 2026-03-13*
