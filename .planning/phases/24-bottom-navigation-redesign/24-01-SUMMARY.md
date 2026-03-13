---
phase: 24
plan: 01
subsystem: ui-widgets
tags: [liquid-glass, bottom-nav, flutter, widgets]

dependency-graph:
  requires: []
  provides:
    - LiquidGlassBottomNav widget
    - buildLiquidCircleButton function
    - liquidGlassSettings context-aware function
  affects:
    - "24-02: Electricity screen migration"
    - "24-03: Water/Heating/Gas screen migration"

tech-stack:
  added: []
  patterns:
    - LiquidGlassLayer + LiquidGlass.grouped for pill-shaped nav bar
    - LiquidRoundedSuperellipse shape for squircle circles
    - Context-aware glass settings (liquidGlassSettings takes BuildContext)
    - LayoutBuilder with clamp-based item width for responsive pill nav

key-files:
  created: []
  modified:
    - lib/widgets/liquid_glass_widgets.dart
    - test/widgets/liquid_glass_widgets_coverage_test.dart

decisions:
  - id: D1
    choice: "Named buildLiquidCircleButton (not buildCircleButton) to avoid collision with existing widget"
    rationale: Old buildCircleButton remains for current screens; new function uses liquid_glass_renderer
  - id: D2
    choice: "Key placement fix: SizedBox gets key when onTap is null in buildLiquidCircleButton"
    rationale: GestureDetector is absent when no onTap; key must propagate to inner SizedBox for testability
  - id: D3
    choice: "liquidGlassSettings takes BuildContext (function, not getter)"
    rationale: Valtra uses MaterialApp theming not CupertinoTheme; brightness from Theme.of(context)

metrics:
  duration: "5m 31s"
  completed: "2026-03-13"
---

# Phase 24 Plan 01: LiquidGlassBottomNav Widget Summary

**One-liner:** LiquidGlassBottomNav pill nav + buildLiquidCircleButton + liquidGlassSettings using liquid_glass_renderer 0.2.0-dev.4, adapted from XFin.

## What Was Built

Created the shared `LiquidGlassBottomNav` widget that all 5 meter screens (electricity, gas, water, heating, smart plugs) will depend on in subsequent plans. The widget uses real `liquid_glass_renderer` effects (LiquidGlassLayer + LiquidGlass.grouped) rather than the old CSS-style glassmorphism.

### Components Added

**`liquidGlassSettings(BuildContext)`** - Context-aware glass settings factory. Returns `LiquidGlassSettings(thickness: 30, blur: 1.4)` with dark/light color variants derived from `Theme.of(context).brightness`.

**`buildLiquidCircleButton`** - Circular button using `LiquidGlassLayer` + `LiquidRoundedSuperellipse(borderRadius: 100)`. Key is placed on `SizedBox` when `onTap` is null (no `GestureDetector` wrapper in that case).

**`LiquidGlassBottomNav`** - Pill nav bar with:
- Optional left circular FAB (shown per `leftVisibleForIndices`)
- Expanded center pill with responsive LayoutBuilder (spaceEvenly when fits, Expanded fallback)
- Right circular FAB (shown per `rightVisibleForIndices`, null = always visible)
- `keepLeftPlaceholder` for layout stability when left button is hidden

### Preserved
All existing widgets (`GlassBottomNav`, `buildGlassFAB`, `buildCircleButton`, `buildGlassAppBar`, `GlassCard`) remain intact and unchanged. Migration of screens to `LiquidGlassBottomNav` happens in plans 02-03.

## Tests

14 new tests added to `test/widgets/liquid_glass_widgets_coverage_test.dart`:

| Group | Count | Coverage |
|-------|-------|---------|
| `liquidGlassSettings` | 2 | light mode, dark mode glass color |
| `buildLiquidCircleButton` | 3 | renders, onTap callback, no-onTap path |
| `LiquidGlassBottomNav` | 9 | icons/labels, onTap, right visible, right hidden, right always, left show, left hide, placeholder, dark mode |

Total project tests: **1093** (was 1079, +14).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Key not placed on widget when onTap is null in buildLiquidCircleButton**

- **Found during:** Task 2 (tests failing)
- **Issue:** Plan spec put key only on `GestureDetector`, but when `onTap == null` no `GestureDetector` exists and the key was silently dropped
- **Fix:** Pass `key` to `SizedBox` when `onTap == null`, otherwise pass to `GestureDetector`
- **Files modified:** `lib/widgets/liquid_glass_widgets.dart`
- **Commit:** 5cb16da

## Next Phase Readiness

Plan 01 complete. The shared `LiquidGlassBottomNav` widget is ready. Plans 02 and 03 can now migrate the 5 meter screens.

**Pre-conditions met for plan 02:**
- `LiquidGlassBottomNav` class exists in `lib/widgets/liquid_glass_widgets.dart`
- `buildLiquidCircleButton` available for per-screen FABs
- All 1093 tests passing, zero analyze issues
