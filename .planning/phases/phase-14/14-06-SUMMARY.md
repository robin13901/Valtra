---
phase: 14-ui-ux-polish
plan: 06
subsystem: analytics
tags: [analytics, cleanup, ux-simplification]
dependency_graph:
  requires: [14-03]
  provides: [simplified-analytics-screens, no-custom-date-range, no-daily-view]
  affects: [analytics-provider, smart-plug-analytics-provider, analytics-models]
tech_stack:
  patterns: [enum-reduction, dead-code-removal, l10n-cleanup]
key_files:
  created: []
  modified:
    - lib/screens/monthly_analytics_screen.dart
    - lib/screens/smart_plug_analytics_screen.dart
    - lib/providers/analytics_provider.dart
    - lib/providers/smart_plug_analytics_provider.dart
    - lib/services/analytics/analytics_models.dart
    - lib/l10n/app_de.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_de.dart
    - lib/l10n/app_localizations_en.dart
    - test/providers/analytics_provider_test.dart
    - test/providers/smart_plug_analytics_provider_test.dart
    - test/screens/monthly_analytics_screen_test.dart
    - test/screens/smart_plug_analytics_screen_test.dart
    - test/screens/analytics_screen_test.dart
    - test/screens/yearly_analytics_screen_test.dart
decisions:
  - "Removed dailyTrends, monthlyComparison, customDateRange, periodCustom l10n keys since no longer referenced anywhere"
  - "Kept ChartLegend and ConsumptionLineChart widget files since they are still used by yearly_analytics_screen"
  - "Kept dailyValues field in MonthlyAnalyticsData model since provider still populates it (used by data export)"
metrics:
  duration: "8m 28s"
  completed: "2026-03-07"
  tasks_completed: 2
  tasks_total: 2
  tests_removed: 10
  tests_passing: 681
  pre_existing_failures: 81
---

# Phase 14 Plan 06: Analytics Cleanup Summary

Removed daily trends view, custom date range feature, and "Benutzerdefiniert" tab from analytics screens. Renamed "Monatsvergleich" to "Monatsverlauf". AnalyticsPeriod enum reduced to {monthly, yearly}. 4 unused l10n keys removed, 10 obsolete tests removed, 16 files modified.

## Changes Made

### Task 1: Remove daily view and custom date range from analytics screens
- **monthly_analytics_screen.dart**: Removed ConsumptionLineChart and ChartLegend imports. Removed custom date range IconButton from app bar. Removed entire daily trends section (line chart + legend). Changed `l10n.monthlyComparison` to `l10n.monthlyProgress`. Removed `_pickDateRange()` method. Removed `customRange` from `_MonthNavigationHeader` (field, constructor param, display logic, and next-button guard).
- **smart_plug_analytics_screen.dart**: Removed custom date range IconButton from app bar actions (including the `AnalyticsPeriod.custom` condition). Removed `AnalyticsPeriod.custom` ButtonSegment from `_PeriodSelector`. Removed `AnalyticsPeriod.custom` case from `_PeriodNavigationHeader` switch. Removed `_CustomRangeDisplay` widget class. Removed `_pickDateRange()` method.
- **Commit**: c6a451b

### Task 2: Clean up providers, models, and ARB files
- **analytics_models.dart**: Changed `enum AnalyticsPeriod { monthly, yearly, custom }` to `{ monthly, yearly }`.
- **analytics_provider.dart**: Removed `_customRange` field, `customRange` getter, `setCustomRange()` method. Removed `_customRange = null` from `setSelectedMonth` and `navigateMonth`. Simplified `_loadMonthlyData` to use fixed month range instead of conditional custom range. Removed custom range total consumption aggregation branch.
- **smart_plug_analytics_provider.dart**: Removed `_customRange` field, `customRange` getter, `setCustomRange()` method. Removed `_customRange = null` from `setSelectedMonth` and `navigateMonth`. Removed `AnalyticsPeriod.custom` switch case from `loadData()`.
- **ARB files**: Removed `dailyTrends`, `monthlyComparison`, `customDateRange`, `periodCustom` keys from both app_en.arb and app_de.arb. Regenerated l10n files.
- **Tests updated**: Removed `customRange` mock stubs from 4 screen test files. Removed `setCustomRange` group (3 tests) and `customRange` initial state test from analytics_provider_test. Removed custom range clearing tests from setSelectedMonth and navigateMonth groups. Removed `customRange` initial state test and `setPeriod(custom)` test from smart_plug_analytics_provider_test. Updated monthly_analytics_screen_test to expect "Monthly Progress" instead of daily trends and date range picker. Updated smart_plug_analytics_screen_test to expect 2 segments instead of 3. Removed unused `flutter/material.dart` imports from both provider test files.
- **Commit**: 50d2d97

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `flutter analyze --no-pub` -- zero issues
- `flutter test --no-pub` -- 681 passing, 81 pre-existing screen test failures (ThemeProvider gap, documented in deferred-items.md)
- Grep for `_customRange|setCustomRange` in lib/ -- zero results
- Grep for `AnalyticsPeriod.custom` in lib/ -- zero results
- Grep for `dailyTrends|Tagesverlauf|ConsumptionLineChart` in monthly_analytics_screen.dart -- zero results

## Self-Check: PASSED
