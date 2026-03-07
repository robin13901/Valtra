---
phase: 14-ui-ux-polish
plan: 02
subsystem: navigation, localization, home-screen
tags: [glass-bottom-nav, glass-card, locale-provider, home-screen, bottom-navigation, consumer2]
dependency-graph:
  requires: [LocaleProvider from 14-01, GlassBottomNav from liquid_glass_widgets, ThemeProvider, HouseholdProvider]
  provides: [Tabbed HomeScreen with GlassBottomNav, LocaleProvider wired to MaterialApp.locale]
  affects: [lib/main.dart, test/widget_test.dart, app_de.arb, app_en.arb, generated l10n files]
tech-stack:
  added: []
  patterns: [Option B shortcut bar pattern (bottom nav pushes screens, resets to home), Consumer2 for dual provider consumption, GridView.count for category cards]
key-files:
  created: []
  modified:
    - lib/main.dart
    - lib/l10n/app_de.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_de.dart
    - lib/l10n/app_localizations_en.dart
    - test/widget_test.dart
decisions:
  - "Option B shortcut bar: bottom nav items 1-4 push screens via Navigator.push, index resets to 0 after return"
  - "Home hub uses 2-column GridView of GlassCards for all 6 categories (no IndexedStack, no nested Scaffolds)"
  - "Consumer2<ThemeProvider, LocaleProvider> wraps MaterialApp for dual reactive binding"
  - "'home' l10n key added: DE 'Start', EN 'Home'"
metrics:
  duration: "~16 minutes"
  completed: "2026-03-07"
  tasks: 2/2
  tests-added: 18
  total-tests: 693
  analyze-issues: 0
---

# Phase 14 Plan 02: Home Screen Rewrite Summary

Rewrite HomeScreen from StatelessWidget with Chips to StatefulWidget with GlassBottomNav (5-item shortcut bar) and 6-category GlassCard grid; wire LocaleProvider into MaterialApp.locale via Consumer2; remove Divider before Analytics and FAB per FR-12.1.1/FR-12.1.2.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Wire LocaleProvider and rewrite HomeScreen with GlassBottomNav | 07b1151 | lib/main.dart, app_de.arb, app_en.arb, generated l10n files |
| 2 | Update home screen widget tests | 58dc0fc | test/widget_test.dart |

## What Was Built

### LocaleProvider Wiring (lib/main.dart)
- LocaleProvider created and initialized in `main()` after ThemeProvider
- Passed to ValtraApp constructor as new required field
- Added `ChangeNotifierProvider<LocaleProvider>.value` to MultiProvider
- MaterialApp now wrapped in `Consumer2<ThemeProvider, LocaleProvider>` (was `Consumer<ThemeProvider>`)
- `locale: localeProvider.locale` set on MaterialApp for reactive locale switching

### HomeScreen Rewrite (lib/main.dart)
- Converted from `StatelessWidget` to `StatefulWidget` with `_HomeScreenState`
- **GlassBottomNav** with 5 items: Home, Electricity, Gas, Water, Analytics
- **Option B shortcut bar pattern**: tapping items 1-4 pushes the corresponding screen via `Navigator.push` and resets `_currentIndex` to 0 on return
- Home tab shows the hub view with:
  - App icon (electric_bolt) and title
  - Current household info
  - **2-column GridView** of 6 GlassCard navigation tiles: Electricity, Smart Plugs, Gas, Water, Heating, Analytics
- **Removed**: `Divider` before Analytics (FR-12.1.1)
- **Removed**: `FloatingActionButton` (FR-12.1.2)
- **Replaced**: `buildGlassAppBar` for AppBar with glassmorphism styling
- Settings gear icon and HouseholdSelector remain in AppBar actions
- All 6 navigation methods preserved with household validation

### New Localization Key
- `home`: DE "Start", EN "Home" (used as bottom nav label for index 0)

## Test Coverage

### New Tests (18 total in test/widget_test.dart)
**HomeScreen group (14 tests):**
- GlassBottomNav rendered, has 5 items, shows correct labels
- No Divider widget, no FloatingActionButton
- 6 GlassCard navigation items present with all category labels
- Settings gear icon in AppBar
- HouseholdSelector in AppBar
- No Chip widgets (replaced by GlassCard)
- App title "Valtra" in AppBar
- Category icons present (electric_bolt, power, local_fire_department, water_drop, thermostat, analytics)
- Home nav icon present
- Bottom nav shows snackbar when no household selected

**LocaleProvider group (4 tests):**
- Default locale null (follow device)
- Default localeString is 'de'
- setLocale updates locale
- init loads persisted locale from SharedPreferences

### Test Results
- `flutter test test/widget_test.dart`: 25/25 passed
- Non-screen tests (providers, database, services, widgets): 668/668 passed
- `flutter analyze`: 0 issues

## Deviations from Plan

None -- plan executed exactly as written.

## Pre-existing Issues (Not Caused by This Plan)

82 screen test failures exist in the working directory due to Plan 14-01's uncommitted glass widget conversions (`buildGlassAppBar`/`buildGlassFAB`) applied to all screen files without updating their test `wrapWithProviders` to include `ThemeProvider`. These failures are documented in `.planning/phases/14-ui-ux-polish/deferred-items.md`.

## Verification Results

- `flutter test test/widget_test.dart --no-pub`: 25/25 passed
- `flutter test test/widget_test.dart test/providers/ test/database/ test/services/ test/widgets/ --no-pub`: 668/668 passed
- `flutter analyze --no-pub`: 0 issues

## Self-Check: PASSED

All created/modified files exist and all commits verified (07b1151, 58dc0fc).
