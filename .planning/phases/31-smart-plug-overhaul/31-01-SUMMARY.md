---
phase: 31-smart-plug-overhaul
plan: 01
subsystem: ui
tags: [flutter, smart-plug, analytics, pie-chart, shared-widgets, provider, mock]

# Dependency graph
requires:
  - phase: 27-shared-chart-infrastructure
    provides: MonthSelector, MonthlySummaryCard, MonthlyBarChart, YearComparisonChart, HouseholdComparisonChart, ConsumptionPieChart, ChartLegend
  - phase: 29-electricity-analytics
    provides: reference _buildAnalyseTab composition pattern and AnalyticsProvider integration
provides:
  - smartPlugPieColors constant (10 single-hue yellow shades) in analytics_models.dart
  - Redesigned SmartPlugAnalyseTab using all 5 shared chart widgets from Phase 27
  - Per-plug pie chart with single-hue yellow color scheme (SPLG-02)
  - Room sections removed from Analyse tab (SPLG-04 analytics side)
  - AnalyticsProvider in SmartPlugsScreen test provider tree
affects:
  - 31-02-PLAN.md (SmartPlugsScreen initState must now initialize AnalyticsProvider)
  - Any test file using SmartPlugsScreen (needs MockAnalyticsProvider)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - SmartPlugAnalyseTab follows Phase 29 reference composition pattern exactly
    - MockAnalyticsProvider pattern for SmartPlugsScreen widget tests
    - smartPlugPieColors alternates dark/light shades for adjacent pie slice distinction

key-files:
  created:
    - test/screens/smart_plug_analytics_screen_test.dart (rewritten)
  modified:
    - lib/services/analytics/analytics_models.dart
    - lib/providers/smart_plug_analytics_provider.dart
    - lib/screens/smart_plug_analytics_screen.dart
    - test/providers/smart_plug_analytics_provider_test.dart
    - test/screens/smart_plugs_screen_test.dart

key-decisions:
  - "SmartPlugAnalyseTab watches both AnalyticsProvider and SmartPlugAnalyticsProvider; syncs both in onMonthChanged with year boundary detection"
  - "MonthlySummaryCard shows no smartPlugKwh/smartPlugPercent -- would be redundant on a screen that is entirely about smart plugs"
  - "Per-plug pie chart uses totalSmartPlug as denominator (not totalSmartPlug + otherConsumption) to show proportions within smart plug total"
  - "showCosts: false for MonthlyBarChart and YearComparisonChart -- smart plugs have no cost profiles"
  - "smart_plugs_screen_test.dart needs MockAnalyticsProvider because SmartPlugAnalyseTab is inside IndexedStack and watches AnalyticsProvider"

patterns-established:
  - "Pattern: MockAnalyticsProvider added to all test files using SmartPlugsScreen"
  - "Pattern: smartPlugPieColors used for all per-plug pie slices; pieChartColors retained only for byRoom"

# Metrics
duration: 22min
completed: 2026-04-01
---

# Phase 31 Plan 01: Smart Plug Overhaul - Analytics Redesign Summary

**SmartPlugAnalyseTab redesigned with 5 shared chart widgets, single-hue yellow smartPlugPieColors, and room sections removed -- satisfying SPLG-01, SPLG-02, SPLG-03, SPLG-04 (Analyse side)**

## Performance

- **Duration:** 22 min
- **Started:** 2026-04-01T14:59:15Z
- **Completed:** 2026-04-01T15:21:30Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added `smartPlugPieColors` constant (10 alternating dark/light yellow shades) to `analytics_models.dart`
- Updated `SmartPlugAnalyticsProvider` to assign `smartPlugPieColors` for `byPlug` entries (SPLG-02)
- Rewrote `SmartPlugAnalyseTab` to follow Phase 29 reference composition: MonthSelector → MonthlySummaryCard → MonthlyBarChart → YearComparisonChart → HouseholdComparisonChart → per-plug pie + list
- Removed room-based sections entirely from the Analyse tab (SPLG-04 analytics side)
- Updated 4 test files: replaced 9 old tests with 14 new tests, fixed color expectation, added `MockAnalyticsProvider` to `smart_plugs_screen_test.dart`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add smartPlugPieColors constant and update provider color assignment** - `423e454` (feat)
2. **Task 2: Redesign SmartPlugAnalyseTab with shared widget composition** - `4eccbdf` (feat)

**Plan metadata:** (next commit)

## Files Created/Modified
- `lib/services/analytics/analytics_models.dart` - Added `smartPlugPieColors` list with 10 yellow shades after `pieChartColors`
- `lib/providers/smart_plug_analytics_provider.dart` - Changed byPlug color assignment from `pieChartColors` to `smartPlugPieColors`
- `lib/screens/smart_plug_analytics_screen.dart` - Complete rewrite: shared widget composition, room sections removed, single-hue colors
- `test/screens/smart_plug_analytics_screen_test.dart` - Rewritten: 14 new tests covering shared widgets, per-plug breakdown, empty/loading states
- `test/providers/smart_plug_analytics_provider_test.dart` - Updated color expectation from `pieChartColors` to `smartPlugPieColors`
- `test/screens/smart_plugs_screen_test.dart` - Added `MockAnalyticsProvider` to provider tree (required for IndexedStack SmartPlugAnalyseTab)

## Decisions Made
- `SmartPlugAnalyseTab` watches both `AnalyticsProvider` and `SmartPlugAnalyticsProvider`; both synced in `onMonthChanged`, with year boundary detection before calling `setSelectedYear`
- `MonthlySummaryCard` does NOT receive `smartPlugKwh/smartPlugPercent` -- displaying smart plug coverage on the dedicated smart plugs screen is redundant
- Per-plug pie chart uses `totalSmartPlug` as denominator (not `totalSmartPlug + otherConsumption`) to show the breakdown within the smart plug portion only
- `showCosts: false` passed to `MonthlyBarChart` and `YearComparisonChart` -- smart plugs have no cost profiles
- `smart_plugs_screen_test.dart` requires `MockAnalyticsProvider` because `SmartPlugAnalyseTab` lives inside `SmartPlugsScreen`'s IndexedStack and calls `context.watch<AnalyticsProvider>()`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated smart_plug_analytics_provider_test.dart color expectation**
- **Found during:** Task 2 verification (full `flutter test` run)
- **Issue:** `smart_plug_analytics_provider_test.dart` expected `pieChartColors[0]` for byPlug but provider now correctly assigns `smartPlugPieColors[0]`
- **Fix:** Updated test to assert `smartPlugPieColors` for byPlug, `pieChartColors` for byRoom
- **Files modified:** `test/providers/smart_plug_analytics_provider_test.dart`
- **Verification:** `flutter test test/providers/smart_plug_analytics_provider_test.dart` - all 16 tests pass
- **Committed in:** `4eccbdf` (part of Task 2 commit)

**2. [Rule 3 - Blocking] Added MockAnalyticsProvider to smart_plugs_screen_test.dart**
- **Found during:** Task 2 verification (full `flutter test` run)
- **Issue:** `smart_plugs_screen_test.dart` had no `AnalyticsProvider` in its provider tree; `SmartPlugAnalyseTab` inside IndexedStack called `context.watch<AnalyticsProvider>()` causing "deactivated widget ancestor" errors
- **Fix:** Added `MockAnalyticsProvider` class and wired it into `wrapWithProviders()` with sensible stubs
- **Files modified:** `test/screens/smart_plugs_screen_test.dart`
- **Verification:** All 16 `smart_plugs_screen_test.dart` tests pass
- **Committed in:** `4eccbdf` (part of Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both auto-fixes necessary for correctness. No scope creep.

## Issues Encountered
None - implementation proceeded as planned. Deviations were test-only fixes required by the provider tree change.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 31-01 complete: analytics screen redesigned with shared widgets and single-hue colors
- Plan 31-02 (`SmartPlugsScreen` initState + heating screen) can proceed:
  - `SmartPlugsScreen.initState` must be updated to initialize `AnalyticsProvider` (setSelectedMeterType + setSelectedMonth + setSelectedYear) alongside `SmartPlugAnalyticsProvider`
  - `AnalyticsProvider` must be added to the `SmartPlugsScreen` provider tree in `main.dart` or wherever screens are wired up
- Room data (`byRoom`) is still computed in the provider and stored in `SmartPlugAnalyticsData` -- this is fine as it's used by other parts of the app (Plan 31-02 may use it for the Liste tab grouping)

---
*Phase: 31-smart-plug-overhaul*
*Completed: 2026-04-01*
