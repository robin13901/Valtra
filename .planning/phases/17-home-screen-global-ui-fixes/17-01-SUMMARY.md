---
phase: 17
plan: 1
subsystem: widgets/household-selector
tags: [ui-fix, theme, dark-mode]
dependency-graph:
  requires: []
  provides: [theme-aware-household-dropdown]
  affects: [home-screen]
tech-stack:
  added: []
  patterns: [Theme.of(context).colorScheme.onSurface for theme-adaptive text/icon colors]
key-files:
  created: []
  modified:
    - lib/widgets/household_selector.dart
    - test/widgets/household_selector_coverage_test.dart
decisions: []
metrics:
  duration: 92s
  completed: 2026-03-09T07:36:42Z
---

# Phase 17 Plan 1: Fix Household Dropdown Text Color Summary

Explicit onSurface color applied to household selector trigger button text and icons for light/dark theme readability.

## What Was Done

### Task 1: Fix Household Dropdown Text Color

- Changed trigger button `Text` style from `const TextStyle(fontWeight: FontWeight.w500)` to `TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)`
- Added explicit `color: Theme.of(context).colorScheme.onSurface` to the `Icons.home` icon in the trigger row
- Added explicit `color: Theme.of(context).colorScheme.onSurface` to the `Icons.arrow_drop_down` icon in the trigger row
- Did NOT change popup menu item styling (only the trigger button row)

### Tests Added

Replaced the placeholder coverage test file with 5 substantive tests:

1. **text color uses onSurface in light theme** - Verifies Text widget has AppTheme.lightTheme.colorScheme.onSurface color
2. **text color uses onSurface in dark theme** - Verifies Text widget has AppTheme.darkTheme.colorScheme.onSurface color
3. **home icon color uses onSurface in light theme** - Verifies both home and arrow_drop_down icons have light onSurface color
4. **home icon color uses onSurface in dark theme** - Verifies both icons have dark onSurface color
5. **light and dark theme produce different onSurface colors** - Sanity check that the fix is meaningful

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- All 6 tests pass (1 existing + 5 new)
- `flutter analyze` reports zero issues on `lib/widgets/household_selector.dart`

## Commits

| Commit | Message | Files |
|--------|---------|-------|
| 6df78ea | fix(17): household dropdown text color respects light/dark theme | household_selector.dart, household_selector_coverage_test.dart |
