---
phase: 28-home-nav-polish
plan: 02
subsystem: ui
tags: [flutter, liquid_glass, navigation, bottom_nav, fab, widget]

# Dependency graph
requires:
  - phase: 24-liquid-glass-nav
    provides: LiquidGlassBottomNav widget with left/right circular FABs
provides:
  - LiquidGlassBottomNav without dot indicator, inline right FAB inside pill
  - Simplified API: removed onLeftTap, leftVisibleForIndices, keepLeftPlaceholder
  - Updated all 5 meter screens to new API
  - Tests covering inline FAB, visibility toggle, no-dot indicator, dark mode
affects: [29-meter-screens, 30-settings-screens, 32-debt-cleanup, any screen using LiquidGlassBottomNav]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline FAB pattern: FAB rendered as last child inside nav pill Row, not floating externally"
    - "Row(Expanded(nav items) + fixed FAB) layout for nav pill with inline action button"

key-files:
  created:
    - test/widgets/liquid_glass_widgets_test.dart
  modified:
    - lib/widgets/liquid_glass_widgets.dart
    - lib/screens/electricity_screen.dart
    - lib/screens/gas_screen.dart
    - lib/screens/water_screen.dart
    - lib/screens/heating_screen.dart
    - lib/screens/smart_plugs_screen.dart
    - test/widgets/liquid_glass_widgets_coverage_test.dart

key-decisions:
  - "FAB integrated inline into pill as last Row child: Expanded(nav items) + fixed 48px FAB Container"
  - "Left FAB (onLeftTap, leftVisibleForIndices, keepLeftPlaceholder) removed entirely: was unused by all screens"
  - "Inline FAB uses primary.withValues(alpha: 0.15/0.20 dark) tinted circle, not LiquidGlassLayer, for visual weight distinction"
  - "No dot indicator: _buildNavColumn has no AnimatedContainer dot; active tab shown by color-only (white/black vs grey/black54)"

patterns-established:
  - "Inline FAB: place as last non-Expanded child inside the pill Row after Expanded(nav items)"
  - "Nav pill height stays 56px: 48px FAB circle fits with 4px symmetric margin"

# Metrics
duration: 11min
completed: 2026-04-01
---

# Phase 28 Plan 02: Nav Polish - Remove Dot & Inline FAB Summary

**LiquidGlassBottomNav redesigned: left FAB removed, right FAB integrated inline into the nav pill as the rightmost element with tinted circle style**

## Performance

- **Duration:** 11 min
- **Started:** 2026-04-01T10:26:11Z
- **Completed:** 2026-04-01T10:38:04Z
- **Tasks:** 2
- **Files modified:** 8 (1 created)

## Accomplishments
- Removed unused left FAB parameters (onLeftTap, leftVisibleForIndices, keepLeftPlaceholder) from LiquidGlassBottomNav, simplifying the API
- Integrated right FAB as inline element inside the navigation pill (rightmost fixed-width child after Expanded nav items)
- Updated all 5 meter screens (electricity, gas, water, heating, smart_plugs) to the new API
- Created test/widgets/liquid_glass_widgets_test.dart (was missing) and updated coverage test with new test cases covering inline FAB rendering, visibility toggle, dark mode, and no-dot verification

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove dot indicator and integrate FAB into navigation pill** - `f1b230e` (feat)
2. **Task 2: Update all meter screens, coverage test, and add tests** - `7596722` (feat)

**Plan metadata:** (next commit, docs)

## Files Created/Modified
- `lib/widgets/liquid_glass_widgets.dart` - LiquidGlassBottomNav: removed left FAB, inline right FAB in pill Row
- `lib/screens/electricity_screen.dart` - Removed onLeftTap/leftVisibleForIndices/keepLeftPlaceholder params
- `lib/screens/gas_screen.dart` - Same as above
- `lib/screens/water_screen.dart` - Same as above
- `lib/screens/heating_screen.dart` - Same as above
- `lib/screens/smart_plugs_screen.dart` - Same as above
- `test/widgets/liquid_glass_widgets_test.dart` - Created: full widget test suite for new API
- `test/widgets/liquid_glass_widgets_coverage_test.dart` - Updated: removed left FAB tests, added inline FAB tests

## Decisions Made
- **Left FAB completely removed**: All screens were passing `onLeftTap: null, leftVisibleForIndices: const {}` - the feature was never used. Clean removal simplifies the API.
- **Inline FAB uses tinted Container, not LiquidGlassLayer**: The FAB sits inside the LiquidGlass pill already, so adding another LiquidGlass layer would create nested glass effects. A tinted circle (`primary.withValues(alpha: 0.15/0.20)`) provides adequate visual distinction while blending with the glass aesthetic.
- **Layout: Row(Expanded(nav items) + fixed FAB)**: Keeps nav items evenly distributed (unchanged behavior) while adding a fixed 48px FAB at the right end. This is cleaner than wrapping everything in a single Expanded.
- **Pill height stays 56px**: The 48px FAB circle with 4px symmetric margin fits within 56px cleanly.

## Deviations from Plan

None - plan executed exactly as written. The "dot indicator" mentioned in the plan was already absent from the current codebase (no AnimatedContainer dot was present). The plan's verification criteria still pass since the new code has no such dot.

## Issues Encountered
- None. The pre-existing `migration_test.dart` failure (v2→v3 smart plug interval conversion) is unrelated to this plan and was pre-noted in STATE.md.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- LiquidGlassBottomNav API is cleaner (3 fewer parameters)
- All 5 meter screens use the new inline FAB style
- NAV-02 (no dot indicator) and NAV-03 (FAB inside pill) requirements satisfied
- Phase 28 plan 03 or other nav polish tasks can proceed

---
*Phase: 28-home-nav-polish*
*Completed: 2026-04-01*
