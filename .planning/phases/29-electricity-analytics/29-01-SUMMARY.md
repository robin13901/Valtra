---
phase: 29
plan: 01
subsystem: analytics-provider
tags: [analytics, household-comparison, monthly-summary, l10n, provider]
requires: [27-01, 27-02, 27-03, 27-04]
provides: [household-comparison-data-loading, smart-plug-coverage-card-fields]
affects: [29-02, 29-03]
tech-stack:
  added: []
  patterns: [household-dao-injection-in-provider, extract-method-for-per-household-query]
key-files:
  created: []
  modified:
    - lib/providers/analytics_provider.dart
    - lib/main.dart
    - lib/widgets/charts/monthly_summary_card.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_de.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_de.dart
    - lib/l10n/app_localizations_en.dart
    - test/providers/analytics_provider_test.dart
    - test/providers/analytics_provider_yearly_test.dart
    - test/l10n/german_locale_coverage_test.dart
    - test/integration/reading_to_analytics_test.dart
    - test/phase6_uat_test.dart
    - test/screens/gas_screen_test.dart
    - test/screens/gas_screen_coverage_test.dart
    - test/screens/water_screen_test.dart
    - test/screens/heating_screen_test.dart
    - test/screens/electricity_screen_test.dart
    - test/screens/electricity_screen_coverage_test.dart
    - test/widgets/charts/monthly_summary_card_test.dart
decisions:
  - "HouseholdDao injected into AnalyticsProvider constructor (not fetched from context)"
  - "_getReadingsPerMeterForHousehold extracted to enable per-household data loading without changing selected household"
  - "householdComparisonData populated during _loadYearlyData (not _loadMonthlyData)"
  - "smartPlugCoverage coverage line requires BOTH kwh AND percent to be non-null"
metrics:
  duration: ~15 min
  completed: 2026-04-01
---

# Phase 29 Plan 01: AnalyticsProvider Household Comparison + MonthlySummaryCard Coverage Summary

**One-liner:** HouseholdDao injected into AnalyticsProvider enabling multi-household comparison data via `householdComparisonData` getter; MonthlySummaryCard extended with optional smart plug coverage line.

## What Was Built

### AnalyticsProvider — Household Comparison Data

`AnalyticsProvider` now accepts `HouseholdDao` as a required constructor parameter and exposes two new capabilities:

1. **`_getReadingsPerMeterForHousehold(householdId, type, rangeStart, rangeEnd)`** — extracted from `_getReadingsPerMeter`. Loads consumption data for any household ID, not just the currently selected one. The original `_getReadingsPerMeter` now delegates to this method.

2. **`_loadHouseholdComparison(type, rangeStart, rangeEnd)`** — called at the end of `_loadYearlyData`. Loads data for all households via `HouseholdDao.getAllHouseholds()`. Returns empty when only 1 household exists. Builds `List<HouseholdChartData>` with `pieChartColors[index]` color assignment.

3. **`householdComparisonData` getter** — exposes `List<HouseholdChartData>` for Plan 02's electricity screen to render in `HouseholdComparisonChart`.

`main.dart` updated to pass `HouseholdDao(database)` to `AnalyticsProvider(...)`.

### MonthlySummaryCard — Smart Plug Coverage Fields

Two optional fields added to `MonthlySummaryCard`:
- `final double? smartPlugKwh` — kWh tracked by smart plugs
- `final double? smartPlugPercent` — percentage of total consumption

When **both** are non-null, renders a coverage line below the change text:
```
⚡ Smart Plugs: 50.0 kWh (25.0%)
```
Using `Icons.power` in `AppColors.electricityColor` and the localized `l10n.smartPlugCoverage(kwh, percent)` method.

### l10n — smartPlugCoverage Key

Added to both `app_en.arb` and `app_de.arb`:
```json
"smartPlugCoverage": "Smart Plugs: {kwh} kWh ({percent}%)"
```
Both locales use the same format string. l10n files regenerated.

### Test Coverage

- **analytics_provider_test.dart**: Added `MockHouseholdDao`; 2 new tests for household comparison (empty when 1 household, populated for 2+ households)
- **analytics_provider_yearly_test.dart**: Added `MockHouseholdDao` with empty stub
- **monthly_summary_card_test.dart**: 3 new tests for smart plug coverage line visibility
- **10 other test files**: Constructor call sites updated with `householdDao:` parameter

## Tasks Completed

| Task | Description | Commit | Key Files |
|------|-------------|--------|-----------|
| 1 | Extend AnalyticsProvider with household comparison | ae16a4c | analytics_provider.dart, main.dart, analytics_provider_test.dart |
| 2 | Add smart plug coverage to MonthlySummaryCard + l10n | d592e4d | monthly_summary_card.dart, app_en.arb, app_de.arb |
| 3 | Fix all remaining test constructor call sites | e62e14e | 10 test files |

## Verification Results

- `flutter test test/providers/analytics_provider_test.dart` — 42/42 pass
- `flutter test test/widgets/charts/monthly_summary_card_test.dart` — 13/13 pass
- `flutter test` — 1217/1218 pass (1 pre-existing migration_test failure, unrelated)
- `flutter analyze` — 0 errors/warnings on modified files; 14 pre-existing info deprecations

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

Plan 02 (electricity screen redesign) can now:
- Consume `analyticsProvider.householdComparisonData` to render `HouseholdComparisonChart`
- Pass `smartPlugKwh` and `smartPlugPercent` to `MonthlySummaryCard` for smart plug coverage display
- All data plumbing is in place; Plan 02 focuses purely on screen composition
