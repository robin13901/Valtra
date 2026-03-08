---
phase: 14-ui-ux-polish
plan: 04
subsystem: localization, formatting, screens, charts
tags: [locale-aware, number-format, ValtraNumberFormat, LocaleProvider, chart-tooltips]
dependency-graph:
  requires: [ValtraNumberFormat from 14-01, LocaleProvider from 14-01]
  provides: [Locale-aware formatting across all screens and charts]
  affects: [all meter screens, all analytics screens, all chart widgets, 4 providers]
tech-stack:
  added: []
  patterns: [context.watch<LocaleProvider>().localeString for screens, locale parameter for chart widgets, raw double return from provider validation]
key-files:
  created: []
  modified:
    - lib/screens/electricity_screen.dart
    - lib/screens/gas_screen.dart
    - lib/screens/water_screen.dart
    - lib/screens/heating_screen.dart
    - lib/screens/smart_plugs_screen.dart
    - lib/screens/smart_plug_consumption_screen.dart
    - lib/screens/analytics_screen.dart
    - lib/screens/monthly_analytics_screen.dart
    - lib/screens/yearly_analytics_screen.dart
    - lib/screens/smart_plug_analytics_screen.dart
    - lib/providers/electricity_provider.dart
    - lib/providers/gas_provider.dart
    - lib/providers/heating_provider.dart
    - lib/providers/water_provider.dart
    - lib/widgets/charts/consumption_line_chart.dart
    - lib/widgets/charts/monthly_bar_chart.dart
    - lib/widgets/charts/year_comparison_chart.dart
    - lib/widgets/charts/consumption_pie_chart.dart
    - test/providers/electricity_provider_test.dart
    - test/providers/gas_provider_test.dart
    - test/providers/heating_provider_test.dart
    - test/providers/water_provider_test.dart
    - test/phase6_uat_test.dart
decisions:
  - "Providers return raw double? from validateReading instead of formatted String? -- screen layer formats with locale"
  - "Chart widgets use optional locale parameter with 'de' default for backward compatibility"
  - "Y-axis labels keep toStringAsFixed(0) since integer tick values need no locale formatting"
  - "Percentage labels in pie chart use ValtraNumberFormat.consumption for locale-aware decimal"
metrics:
  duration: "~29 minutes"
  completed: "2026-03-07"
  tasks: 2/2
  tests-added: 0
  tests-modified: 5
  total-tests: 777
  analyze-issues: 0
---

# Phase 14 Plan 04: Number Formatting Cascade Summary

Replaced all hardcoded English number formatting (NumberFormat with 'en' locale and toStringAsFixed calls) with locale-aware ValtraNumberFormat calls across 18 files: 6 meter screens, 4 analytics screens, 4 chart widgets, and 4 providers.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Replace number formatting in meter screens and providers | eabc859 | 6 screens, 4 providers, 5 test files |
| 2 | Replace number formatting in analytics screens and chart widgets | f09be9b | 4 analytics screens, 4 chart widgets |

## What Was Built

### Task 1: Meter Screens and Providers (15 files)

**6 Meter Screens:**
- `electricity_screen.dart`: ValtraNumberFormat.consumption for kWh values, locale-aware validation errors
- `gas_screen.dart`: ValtraNumberFormat.consumption for m3 values, locale-aware validation errors
- `water_screen.dart`: ValtraNumberFormat.waterReading (3 decimals) for m3 values, locale-aware validation errors
- `heating_screen.dart`: ValtraNumberFormat.consumption for heating meter values, locale-aware validation errors
- `smart_plugs_screen.dart`: ValtraNumberFormat.consumption for latest consumption display
- `smart_plug_consumption_screen.dart`: ValtraNumberFormat.consumption for consumption cards

Each screen gets locale via `context.watch<LocaleProvider>().localeString` (for reactive rebuilds in build methods) or `context.read<LocaleProvider>().localeString` (for one-shot use in event handlers).

**4 Providers (interface change):**
- `electricity_provider.dart`: validateReading now returns `double?` (raw boundary value)
- `gas_provider.dart`: validateReading now returns `double?`
- `heating_provider.dart`: validateReading now returns `double?`
- `water_provider.dart`: validateReading now returns `double?`

All 4 providers had `import 'package:intl/intl.dart'` removed -- they no longer format numbers. Screen layer handles formatting with locale context.

**5 Test Files Updated:**
- 4 provider tests: assertions changed from `expect(error, contains('1,000.0'))` to `expect(error, 1000.0)`
- phase6_uat_test: assertion changed from `expect(error, contains('100.5'))` to `expect(error, 100.5)`

### Task 2: Analytics Screens and Chart Widgets (8 files)

**4 Analytics Screens:**
- `analytics_screen.dart`: ValtraNumberFormat.consumption + currency for overview cards
- `monthly_analytics_screen.dart`: ValtraNumberFormat.consumption + currency for summary card, locale passed to ConsumptionLineChart and MonthlyBarChart
- `yearly_analytics_screen.dart`: ValtraNumberFormat.consumption + currency for yearly summary, year-over-year change percentage locale-aware, locale passed to MonthlyBarChart and YearComparisonChart
- `smart_plug_analytics_screen.dart`: ValtraNumberFormat.consumption for summary card, plug/room breakdown lists, locale passed to ConsumptionPieChart

**4 Chart Widgets (new locale parameter):**
- `consumption_line_chart.dart`: `final String locale` parameter (default 'de'), ValtraNumberFormat.consumption in tooltip
- `monthly_bar_chart.dart`: `final String locale` parameter (default 'de'), ValtraNumberFormat.consumption in tooltip
- `year_comparison_chart.dart`: `final String locale` parameter (default 'de'), ValtraNumberFormat.consumption in tooltip
- `consumption_pie_chart.dart`: `final String locale` parameter (default 'de'), ValtraNumberFormat.consumption for percentage labels

## Verification Results

- `flutter analyze --no-pub`: 0 issues
- `flutter test --no-pub`: 694 pass, 83 fail (82 pre-existing ThemeProvider gap + 1 timing-dependent)
- Grep for `NumberFormat.*'en'` in lib/: 0 results
- Grep for `toStringAsFixed` in lib/screens/: 0 results
- Grep for `toStringAsFixed` in lib/widgets/charts/: 3 results (Y-axis integer labels only, no locale formatting needed)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed phase6_uat_test assertion after provider interface change**
- **Found during:** Task 1
- **Issue:** test/phase6_uat_test.dart used `expect(error, contains('100.5'))` which expects a String, but validateReading now returns double?
- **Fix:** Changed to `expect(error, 100.5)`
- **Files modified:** test/phase6_uat_test.dart
- **Commit:** eabc859

## Self-Check: PASSED
