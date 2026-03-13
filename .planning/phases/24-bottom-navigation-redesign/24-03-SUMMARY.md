---
phase: 24-bottom-navigation-redesign
plan: 03
subsystem: ui
tags: [flutter, liquid-glass, bottom-nav, navigation, IndexedStack, Stack, Positioned, dark-mode, deprecation]

# Dependency graph
requires:
  - phase: 24-01
    provides: LiquidGlassBottomNav widget in liquid_glass_widgets.dart
provides:
  - Electricity, Water, Heating screens migrated from GlassBottomNav to LiquidGlassBottomNav
  - FAB conditional visibility via rightVisibleForIndices={1} on all three screens
  - Deprecated GlassBottomNav and buildGlassFAB with @Deprecated annotations
  - Dark mode test for LiquidGlassBottomNav in screen context
  - Bug fix: buildLiquidCircleButton now applies key to SizedBox when onTap is null
affects: [24-02, future-phases-using-LiquidGlassBottomNav]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Stack+Positioned overlay for LiquidGlassBottomNav at bottom of screen body
    - rightVisibleForIndices const {1} for FAB only on Liste tab
    - EdgeInsets.fromLTRB(16, 16, 16, 100) bottom padding to avoid nav overlap

key-files:
  created: []
  modified:
    - lib/screens/electricity_screen.dart
    - lib/screens/water_screen.dart
    - lib/screens/heating_screen.dart
    - lib/widgets/liquid_glass_widgets.dart
    - test/screens/electricity_screen_test.dart
    - test/screens/water_screen_test.dart
    - test/screens/heating_screen_test.dart
    - test/widget_test.dart

key-decisions:
  - "Stack+Positioned pattern: LiquidGlassBottomNav overlays body content via Stack, same as gas/smart_plug screens"
  - "Bottom padding 100px on ListViews prevents content hidden under nav bar"
  - "@Deprecated annotations on GlassBottomNav and buildGlassFAB with v0.6.0 removal note"
  - "Key applied to SizedBox (not GestureDetector) when onTap is null for consistent key findability"

patterns-established:
  - "LiquidGlassBottomNav migration pattern: replace bottomNavigationBar+floatingActionButton with Stack+Positioned overlay"
  - "Screen nav keys: {screen}_nav_{tab} naming (electricity_nav_analyse, water_nav_liste, etc.)"

# Metrics
duration: 16min
completed: 2026-03-13
---

# Phase 24 Plan 03: Electricity/Water/Heating LiquidGlass Nav Migration Summary

**Electricity, Water, and Heating screens migrated from GlassBottomNav+FAB to LiquidGlassBottomNav Stack overlay; old widgets deprecated; 1094 tests passing**

## Performance

- **Duration:** 16 min
- **Started:** 2026-03-13T14:59:02Z
- **Completed:** 2026-03-13T15:15:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- All three screens (electricity, water, heating) now use `LiquidGlassBottomNav` with Stack+Positioned layout
- FAB conditional visibility via `rightVisibleForIndices: const {1}` - add button only on Liste tab
- Screen-specific navigation keys: `electricity_nav_analyse/liste`, `water_nav_*`, `heating_nav_*`
- Old `GlassBottomNav` and `buildGlassFAB` marked `@Deprecated('...Will be removed in v0.6.0.')`
- Dark mode rendering test added to `electricity_screen_test.dart`
- Bug fix: `buildLiquidCircleButton` now assigns key to `SizedBox` when `onTap` is null

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate Electricity, Water, Heating screens to LiquidGlassBottomNav** - `82200db` (feat)
2. **Task 2: Update tests, deprecate old widgets, add dark mode test** - `9735fb5` (test/fix)

**Plan metadata:** (to be created)

## Files Created/Modified
- `lib/screens/electricity_screen.dart` - Migrated to LiquidGlassBottomNav Stack+Positioned layout
- `lib/screens/water_screen.dart` - Migrated to LiquidGlassBottomNav Stack+Positioned layout
- `lib/screens/heating_screen.dart` - Migrated to LiquidGlassBottomNav Stack+Positioned layout
- `lib/widgets/liquid_glass_widgets.dart` - Added @Deprecated on GlassBottomNav/buildGlassFAB; fixed key propagation in buildLiquidCircleButton
- `test/screens/electricity_screen_test.dart` - Updated to LiquidGlassBottomNav/right_fab key; added dark mode test
- `test/screens/water_screen_test.dart` - Updated to LiquidGlassBottomNav/right_fab key
- `test/screens/heating_screen_test.dart` - Updated to LiquidGlassBottomNav/right_fab key
- `test/widget_test.dart` - Updated GlassBottomNav check to LiquidGlassBottomNav

## Decisions Made
- Same Stack+Positioned pattern as used in 24-02 (gas/smart_plug screens)
- Bottom padding `EdgeInsets.fromLTRB(16, 16, 16, 100)` consistent with other migrated screens
- `@Deprecated` annotation rather than deletion allows other screens (gas, smart_plugs, households, rooms) to continue using old widgets until they are migrated in later plans

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed key propagation in buildLiquidCircleButton when onTap is null**
- **Found during:** Task 2 (running full test suite after test updates)
- **Issue:** `buildLiquidCircleButton` only assigned the `key` parameter to the `GestureDetector` wrapper, but when `onTap` is null the wrapper is skipped and the key was dropped entirely. Tests in `liquid_glass_widgets_coverage_test.dart` looking for `Key('right_fab')` failed because the `SizedBox` had no key.
- **Fix:** Added `key: onTap == null ? key : null` to the `SizedBox` constructor, so the key is always on the outermost widget.
- **Files modified:** `lib/widgets/liquid_glass_widgets.dart`
- **Verification:** `liquid_glass_widgets_coverage_test.dart` all 27 tests pass; full suite 1094 tests pass
- **Committed in:** `9735fb5` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Bug fix was necessary for correct test key resolution. No scope creep.

## Issues Encountered
- Worktree was behind `main` branch (missing 24-01 commits). Merged `main` into worktree branch before execution. No conflicts.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 3 of 5 meter screens migrated to LiquidGlassBottomNav (electricity, water, heating + gas + smart_plug from 24-02)
- All 5 meter screens are now on LiquidGlassBottomNav if plan 24-02 is also complete
- `GlassBottomNav` and `buildGlassFAB` remain in codebase with @Deprecated annotations
- Ready for final deprecation cleanup plan (24-04) or v0.6.0 removal

---
*Phase: 24-bottom-navigation-redesign*
*Completed: 2026-03-13*
