---
phase: 14-ui-ux-polish
plan: 07
subsystem: settings, testing
tags: [language-toggle, locale-provider, test-fixes, glass-widgets, provider-injection]
dependency-graph:
  requires: [LocaleProvider (Plan 01), GlassCard/buildGlassAppBar (Plan 03), ValtraNumberFormat (Plan 04)]
  provides: [Language toggle UI, test helper MockLocaleProvider, all-green test suite]
  affects: [settings_screen.dart, 11 test files]
tech-stack:
  added: []
  patterns: [SegmentedButton<String> for language selection, shared mock provider helper]
key-files:
  created:
    - test/helpers/test_locale_provider.dart
  modified:
    - lib/screens/settings_screen.dart
    - test/screens/settings_screen_test.dart
    - test/screens/electricity_screen_test.dart
    - test/screens/gas_screen_test.dart
    - test/screens/water_screen_test.dart
    - test/screens/heating_screen_test.dart
    - test/screens/analytics_screen_test.dart
    - test/screens/monthly_analytics_screen_test.dart
    - test/screens/yearly_analytics_screen_test.dart
    - test/screens/smart_plug_analytics_screen_test.dart
    - test/phase6_uat_test.dart
    - test/widgets/charts/consumption_pie_chart_test.dart
decisions:
  - "MockLocaleProvider defaults to 'en' for consistent test expected values"
  - "Removed unit badge chip assertions (kWh/m3) since Plan 05 removed them"
  - "Pass locale='en' to chart widgets in tests for English number formatting"
metrics:
  duration: 20m
  completed: 2026-03-07
  tasks: 2/2
  tests-passing: 765
  analyze-issues: 0
---

# Phase 14 Plan 07: Language Toggle & Final Test Fixes Summary

Language toggle in settings screen using SegmentedButton (Deutsch/English) wired to LocaleProvider; all 81 pre-existing test failures fixed across 11 test files by injecting ThemeProvider + LocaleProvider and updating widget finders.

## Tasks Completed

### Task 1: Add language toggle to settings screen
- Imported `locale_provider.dart` into `settings_screen.dart`
- Added `_buildLanguageSection` method with `SegmentedButton<String>` (de/en segments)
- Inserted between theme section and meter settings section
- Wrapped in `GlassCard` for visual consistency
- Updated `settings_screen_test.dart` with `MockLocaleProvider` and 6 new tests (3 rendering + 3 toggle behavior)
- **Commit:** `5f9009d`

### Task 2: Fix all 81 failing tests
- Created `test/helpers/test_locale_provider.dart` as shared mock helper
- **Root causes of 81 failures:**
  1. **Missing ThemeProvider** (76 failures): GlassCard, buildGlassAppBar, buildGlassFAB all call `context.watch<ThemeProvider>()` -- added to 8 screen test files + phase6_uat_test
  2. **Missing LocaleProvider** (6 failures): Screens call `context.watch<LocaleProvider>()` for locale-aware formatting -- added to all screen test files
  3. **Card to GlassCard** (tapping): `find.byType(Card)` replaced with `find.byType(GlassCard)` in electricity, gas, heating, water screen tests
  4. **Removed unit chips** (1 failure): `find.text('m\u00b3')` assertion removed from phase6_uat_test (Plan 05 removed badges)
  5. **Filled water icons** (1 failure): `Icons.water_drop_outlined` changed to `Icons.water_drop` (Plan 05 change)
  6. **Number format locale** (1 failure): ConsumptionPieChart test now passes `locale: 'en'` for English format percentages
- **Commit:** `7b7288f`

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `flutter test --no-pub`: **765/765 tests pass** (0 failures)
- `flutter analyze --no-pub`: **0 issues**
- Settings screen language toggle renders correctly with Deutsch/English segments
- Switching language calls `LocaleProvider.setLocale()` which updates `MaterialApp.locale` immediately

## Phase 14 Completion Checklist

- [x] FR-12.1: Home screen GlassBottomNav, no FAB, no divider
- [x] FR-12.2: Locale-aware numbers, time with "Uhr", month names, umlauts fixed
- [x] FR-12.3: No badges, no info icons, no hints, styled pickers, no pre-selected room
- [x] FR-12.4: Dark mode text on accent is black, room subtitle readable
- [x] FR-12.5: Water filled icons, dropdown selector
- [x] FR-12.6: No daily view, no custom range, renamed tab, defaults to current month
- [x] FR-12.7: Language toggle in settings, persists via SharedPreferences, applies immediately
