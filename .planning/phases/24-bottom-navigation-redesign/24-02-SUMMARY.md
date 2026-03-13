---
phase: 24-bottom-navigation-redesign
plan: 02
subsystem: ui-screens
tags: [liquid-glass, bottom-nav, flutter, screens, smart-plugs, gas]

dependency-graph:
  requires:
    - phase: 24-01
      provides: LiquidGlassBottomNav widget, buildLiquidCircleButton, liquidGlassSettings
  provides:
    - SmartPlugsScreen migrated to LiquidGlassBottomNav with Stack+Positioned layout
    - GasScreen migrated to LiquidGlassBottomNav with Stack+Positioned layout
    - FAB (right button) visible only on Liste tab (index 1) on both screens
  affects:
    - "24-03: Water/Heating screen migration (same pattern)"
    - "Future: any test referencing FloatingActionButton on migrated screens must use Key('right_fab')"

tech-stack:
  added: []
  patterns:
    - Stack+Positioned layout for overlaying LiquidGlassBottomNav on IndexedStack body
    - rightVisibleForIndices: {1} for FAB visible only on Liste tab
    - bottom padding 100px on list/analyse ListViews to prevent nav overlap
    - Screen-specific nav keys (smart_plugs_nav_* and gas_nav_*) for test targeting

key-files:
  created: []
  modified:
    - lib/screens/smart_plugs_screen.dart
    - lib/screens/gas_screen.dart
    - test/screens/smart_plugs_screen_test.dart
    - test/screens/gas_screen_test.dart
    - test/phase6_uat_test.dart
    - lib/widgets/liquid_glass_widgets.dart

decisions:
  - id: D1
    choice: "Stack+Positioned overlay for nav bar in Scaffold.body"
    rationale: Keeps IndexedStack as primary content; nav floats above it without using Scaffold.bottomNavigationBar (which doesn't work with FAB on a pill nav)
  - id: D2
    choice: "bottom: 100px padding on all scrollable content"
    rationale: Prevents list items from being hidden behind the floating nav bar (which is ~88px tall including SafeArea padding)
  - id: D3
    choice: "rightVisibleForIndices: const {1} for FAB on Liste tab only"
    rationale: Consistent with plan spec; FAB only makes sense on the list view where adding items is relevant

metrics:
  duration: "10m 18s"
  completed: "2026-03-13"
---

# Phase 24 Plan 02: SmartPlugs and Gas Screen Migration Summary

**SmartPlugsScreen and GasScreen migrated from GlassBottomNav+floatingActionButton to LiquidGlassBottomNav with Stack+Positioned layout; FAB visible on Liste tab only; 1093 tests passing.**

## Performance

- **Duration:** 10m 18s
- **Started:** 2026-03-13T14:58:42Z
- **Completed:** 2026-03-13T15:09:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Migrated SmartPlugsScreen to use `LiquidGlassBottomNav` in a `Stack+Positioned` layout; removed `Scaffold.floatingActionButton` and `Scaffold.bottomNavigationBar`
- Migrated GasScreen with identical pattern; also added bottom padding to both `_buildListeTab` and `_buildAnalyseContent` ListViews
- Updated all affected tests (smart_plugs_screen_test, gas_screen_test, phase6_uat_test) to use `Key('right_fab')` instead of `FloatingActionButton` type finders
- Fixed pre-existing bug in `buildLiquidCircleButton` where key was silently dropped when `onTap == null`

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate SmartPlugs and Gas screens to LiquidGlassBottomNav** - `8d68b98` (feat)
2. **Task 2: Update SmartPlugs and Gas screen tests** - `9eb8b97` (test)

**Plan metadata:** to be committed after SUMMARY creation

## Files Created/Modified

- `lib/screens/smart_plugs_screen.dart` - Migrated to LiquidGlassBottomNav with Stack+Positioned; removed old GlassBottomNav + floatingActionButton; added 100px bottom padding to ListView
- `lib/screens/gas_screen.dart` - Same migration; both list and analyse ListViews get 100px bottom padding
- `test/screens/smart_plugs_screen_test.dart` - GlassBottomNav → LiquidGlassBottomNav; FloatingActionButton → Key('right_fab')
- `test/screens/gas_screen_test.dart` - Same test update pattern
- `test/phase6_uat_test.dart` - Updated 3 gas UAT tests using FloatingActionButton → Key('right_fab')
- `lib/widgets/liquid_glass_widgets.dart` - Fixed buildLiquidCircleButton key propagation when onTap is null

## Decisions Made

- Used `Stack+Positioned(bottom:0, left:0, right:0)` rather than `Scaffold.bottomNavigationBar` — pill nav must float above content
- `rightVisibleForIndices: const {1}` on both screens — FAB only on Liste tab (index 1)
- 100px bottom padding on all scrollable content — nav bar is ~88px tall with SafeArea
- Screen-specific nav keys: `smart_plugs_nav_analyse`, `smart_plugs_nav_liste`, `gas_nav_analyse`, `gas_nav_liste` for precise test targeting

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] buildLiquidCircleButton key not propagated when onTap is null**

- **Found during:** Task 2 (full test suite run showing 2 failures in liquid_glass_widgets_coverage_test)
- **Issue:** When `onTap == null`, `buildLiquidCircleButton` returns the `SizedBox` without the key; `GestureDetector` (which carries the key) is only created when `onTap != null`. Two tests expecting `Key('right_fab')` on a keyless button failed.
- **Fix:** Changed `SizedBox` construction to `SizedBox(key: onTap == null ? key : null, ...)` — key goes to SizedBox when no GestureDetector wraps it
- **Files modified:** `lib/widgets/liquid_glass_widgets.dart`
- **Verification:** `flutter test` — 1093/1093 passing
- **Committed in:** `9eb8b97` (Task 2 commit)

**2. [Rule 1 - Bug] phase6_uat_test.dart gas tests using FloatingActionButton**

- **Found during:** Task 2 (full test suite run showing 3 failures in phase6_uat_test)
- **Issue:** UAT tests for GasScreen (UAC-G1, UAC-G2, UAC-G6) tap/find `FloatingActionButton` which no longer exists on the migrated screen
- **Fix:** Updated 3 assertions/interactions to use `Key('right_fab')` — consistent with the pattern established in gas_screen_test.dart
- **Files modified:** `test/phase6_uat_test.dart`
- **Verification:** All 3 UAT tests passing
- **Committed in:** `9eb8b97` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both fixes necessary for correct test results. No scope creep. The buildLiquidCircleButton fix was actually documented as Decision D2 in 24-01-SUMMARY but the code wasn't updated before commit.

## Issues Encountered

- Worktree was branched from `origin/main` before plan 24-01 was merged. Required `git merge main` at start of execution to pull in LiquidGlassBottomNav widget from 24-01 commits.

## Next Phase Readiness

Plan 02 complete. SmartPlugs and Gas screens both use LiquidGlassBottomNav.

**Pre-conditions met for plan 03 (Water/Heating/Gas screens):**
- Migration pattern established and tested (Stack+Positioned, rightVisibleForIndices, 100px padding)
- All 1093 tests passing, zero analyze issues
- Gas screen already migrated (plan 03 focuses on Water and Heating only)

---
*Phase: 24-bottom-navigation-redesign*
*Completed: 2026-03-13*
