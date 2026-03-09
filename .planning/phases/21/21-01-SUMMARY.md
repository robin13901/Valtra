---
phase: 21-smart-plug-screen-overhaul
plan: 01
subsystem: smart-plug-ui
tags: [bottom-nav, analytics, l10n, refactor]
dependency_graph:
  requires: [phase-19-electricity-screen, phase-20-gas-screen]
  provides: [smart-plug-bottom-nav, smart-plug-inline-analysis]
  affects: [smart-plugs-screen, smart-plug-analytics-screen, smart-plug-analytics-provider]
tech_stack:
  added: []
  patterns: [bottom-nav-indexed-stack, inline-analyse-tab, monthly-only-provider]
key_files:
  created: []
  modified:
    - lib/screens/smart_plugs_screen.dart
    - lib/screens/smart_plug_analytics_screen.dart
    - lib/providers/smart_plug_analytics_provider.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_de.arb
    - test/screens/smart_plugs_screen_test.dart
    - test/screens/smart_plug_analytics_screen_test.dart
    - test/providers/smart_plug_analytics_provider_test.dart
decisions:
  - "SmartPlugAnalyseTab replaces SmartPlugAnalyticsScreen as inline tab (no standalone navigation)"
  - "Provider simplified to monthly-only -- period/year fields and methods removed"
  - "AnalyticsPeriod enum kept in analytics_models.dart for backward compatibility"
  - "Room breakdown percentages calculated as room.consumption / totalSmartPlug * 100"
  - "Old l10n keys (totalTracked, totalElectricity, otherConsumption) retained for backward compat"
metrics:
  duration: "~12 minutes"
  completed: "2026-03-09"
  tasks_completed: 3
  tasks_total: 3
  tests_total: 1070
  tests_added: 17
---

# Phase 21 Plan 01: Smart Plug Screen Overhaul Summary

Smart plug screen refactored with GlassBottomNav (Analyse|Liste), IndexedStack, monthly-only analytics as inline tab, renamed stats (Gesamtverbrauch/Davon erfasst/Nicht erfasst), room breakdown with kWh + percentage display.

## What Was Done

### Task 1: L10n keys, monthly-only provider, bottom nav refactor, inline Analyse tab
- Added 6 new l10n keys: `totalConsumptionLabel`, `trackedByPlugs`, `notTracked`, `consumptionByRoomTitle`, `consumptionByPlugTitle`, `consumptionWithPercent`
- Simplified `SmartPlugAnalyticsProvider` to monthly-only: removed `_period`, `period`, `setPeriod()`, `_selectedYear`, `selectedYear`, `setSelectedYear()`, `navigateYear()` fields/methods
- Converted `SmartPlugsScreen` from `StatelessWidget` to `StatefulWidget` with `_currentTab = 1` (default Liste)
- Added `GlassBottomNav` with Analyse (analytics icon) and Liste (list icon) tabs
- Added `IndexedStack` for tab content (preserves state when switching)
- Conditional FAB: visible on Liste tab only, hidden on Analyse tab
- Removed `pie_chart` IconButton from app bar; kept `meeting_room` IconButton
- Preloads analytics data via `addPostFrameCallback` in `initState`
- Refactored `SmartPlugAnalyticsScreen` into `SmartPlugAnalyseTab` (plain StatelessWidget, no Scaffold/AppBar)
- Removed `_PeriodSelector`, `_PeriodNavigationHeader`, `_YearNavigation` widgets (monthly-only)
- Kept `_MonthNavigation` widget for month arrows
- Reordered UI: month nav > stats card > "Verbrauch nach Raum" (title + pie + list with %) > "Verbrauch nach Steckdose" (title + pie + list)
- Updated `_SummaryCard` to use new l10n keys: `totalConsumptionLabel` for totalElectricity, `trackedByPlugs` for totalSmartPlug, `notTracked` for otherConsumption
- Updated `_RoomBreakdownItem` to show percentage: `consumptionWithPercent(kWh, percent)`
- Applied `dense: true` and `VisualDensity.compact` to all breakdown `ListTile` widgets
- Updated provider tests: removed period/year-related tests (3 groups removed)
- **Commit:** bd07ae3

### Task 2: Comprehensive tests
- Added `MockSmartPlugAnalyticsProvider` to smart_plugs_screen_test.dart
- Added "Bottom Navigation" test group with 8 tests: renders, default Liste, tab switching, FAB visibility, no pie_chart, rooms button, IndexedStack state preservation
- Updated smart_plug_analytics_screen_test.dart for `SmartPlugAnalyseTab` (removed AppBar/SegmentedButton/yearly tests)
- Added tests: no SegmentedButton, month nav arrows, renamed stats labels, old labels absent, new section titles, room breakdown percentages, UI order, dense list items
- **Commit:** c219fc8

### Task 3: Full test suite validation
- `flutter test`: 1070 tests pass (baseline was 1069, net +1 from removing 6 old tests and adding 17 new tests -- some were renaming/restructuring)
- `flutter analyze`: zero issues

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

1. **SmartPlugAnalyseTab replaces SmartPlugAnalyticsScreen** - The standalone screen with its own Scaffold/AppBar is replaced by an inline tab widget suitable as an IndexedStack child.
2. **Provider simplified to monthly-only** - `period`, `selectedYear`, and associated methods removed. Only `selectedMonth` and `navigateMonth` remain.
3. **AnalyticsPeriod enum retained** - Left in analytics_models.dart since removing it could break other imports. Can be cleaned up in a future phase if desired.
4. **Room breakdown percentage formula** - `(room.consumption / totalSmartPlug) * 100`, displayed as integer (toStringAsFixed(0)).
5. **Old l10n keys retained** - `totalTracked`, `totalElectricity`, `otherConsumption` kept in ARB files for backward compatibility but no longer used in smart plug screens.

## Self-Check

Verifying claims...

- All 8 source/test files: FOUND
- Commit bd07ae3 (Task 1): FOUND
- Commit c219fc8 (Task 2): FOUND
- SUMMARY.md: FOUND
- flutter test: 1070 pass, 0 fail
- flutter analyze: 0 issues

## Self-Check: PASSED
