# Phase 24: Bottom Navigation Redesign - Research

**Researched:** 2026-03-13
**Domain:** Flutter bottom navigation, LiquidGlass widgets, screen layout migration
**Confidence:** HIGH

---

## Summary

All 5 meter screens (Electricity, Gas, Water, Smart Plugs, Heating) currently use an identical bottom navigation pattern:
`Scaffold.bottomNavigationBar: GlassBottomNav` with a separate `Scaffold.floatingActionButton: buildGlassFAB` that is conditionally null on Analyse tab. The current `GlassBottomNav` is a custom Container+ClipRRect wrapper around Flutter's built-in `BottomNavigationBar` — it does NOT use `liquid_glass_renderer`.

The XFin reference project provides a `LiquidGlassBottomNav` widget in its own `liquid_glass_widgets.dart` that uses `liquid_glass_renderer` (already in Valtra's `pubspec.yaml`). Valtra's `pubspec.yaml` already declares `liquid_glass_renderer: ^0.2.0-dev.4` but Valtra's `liquid_glass_widgets.dart` never imports or uses it — this is the core migration gap.

The key architectural change is from `Scaffold.bottomNavigationBar` (docked at bottom) to a `Stack + Positioned` overlay layout that floats the pill nav bar above the content. The FAB is NOT separate; it is built into `LiquidGlassBottomNav` via `rightIcon`/`onRightTap` and `rightVisibleForIndices`.

**Primary recommendation:** Copy `LiquidGlassBottomNav` and `buildCircleButton` (plus related imports) from XFin into Valtra's `liquid_glass_widgets.dart`, adapting the `ThemeProvider.isDark()` static call to match Valtra's instance-based `isDark(BuildContext)` API. Then migrate each screen's `Scaffold` body to `Stack + Positioned` overlay layout.

---

## Current Implementation Analysis

### All 5 Screens — Identical Nav Pattern

Confirmed by reading source: all five screens use the exact same structure.

```
Scaffold(
  appBar: buildGlassAppBar(...),
  body: IndexedStack(index: _currentTab, children: [...]),
  floatingActionButton: _currentTab == 1 ? buildGlassFAB(...) : null,
  bottomNavigationBar: GlassBottomNav(
    currentIndex: _currentTab,
    onTap: (index) => setState(() => _currentTab = index),
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.analytics), label: l10n.analysis),
      BottomNavigationBarItem(icon: Icon(Icons.list),      label: l10n.list),
    ],
  ),
)
```

| Screen | File | Tab 0 | Tab 1 | FAB Action | Cost Toggle |
|--------|------|-------|-------|------------|-------------|
| Electricity | `electricity_screen.dart` | Analyse | Liste | `_addReading` | Yes (on Analyse) |
| Gas | `gas_screen.dart` | Analyse | Liste | `_addReading` | Yes (on Analyse) |
| Water | `water_screen.dart` | Analyse | Liste | `_addMeter` | Yes (on Analyse) |
| Smart Plugs | `smart_plugs_screen.dart` | Analyse | Liste | `_addSmartPlug` | No |
| Heating | `heating_screen.dart` | Analyse | Liste | `_addMeter` | Yes (on Analyse, note: unitless heating) |

**Tab index:** All screens use `0=Analyse, 1=Liste` (default `_currentTab = 1`).

### Current GlassBottomNav Widget

- Location: `lib/widgets/liquid_glass_widgets.dart`
- Implementation: `Container` with `BoxDecoration` (borderRadius, color, boxShadow) wrapping a `ClipRRect` + Flutter's `BottomNavigationBar`
- Does NOT use `liquid_glass_renderer` — pure Flutter widgets with color-based glass simulation
- Signature: `GlassBottomNav({currentIndex, onTap, items: List<BottomNavigationBarItem>})`

### Current buildGlassFAB

- Also in `lib/widgets/liquid_glass_widgets.dart`
- Implementation: `Container` with `BoxDecoration` (circle shape, color, boxShadow) wrapping `FloatingActionButton`
- Does NOT use `liquid_glass_renderer`
- Signature: `buildGlassFAB({BuildContext context, IconData icon, VoidCallback onPressed, String? tooltip})`

---

## XFin Reference Implementation

### LiquidGlassBottomNav Widget (HIGH confidence — read source directly)

**Location:** `/c/SAPDevelop/Privat/XFin/lib/widgets/liquid_glass_widgets.dart`

**Key structural properties:**

```dart
class LiquidGlassBottomNav extends StatelessWidget {
  final List<IconData> icons;
  final List<String> labels;
  final List<Key> keys;           // required — one Key per tab item
  final int currentIndex;
  final ValueChanged<int> onTap;

  // LEFT circular button (optional)
  final VoidCallback? onLeftTap;
  final Set<int> leftVisibleForIndices;

  // RIGHT circular button (FAB equivalent)
  final IconData rightIcon;        // default: Icons.more_horiz
  final VoidCallback? onRightTap;
  final Set<int>? rightVisibleForIndices;  // null = always visible

  final bool keepLeftPlaceholder;  // preserves spacing when left button hidden
  final double height;             // default: 56.0
  final double horizontalPadding;  // default: 16.0
}
```

**Layout:** `SafeArea > Padding > SizedBox > Row` with:
- Optional LEFT circle button (`buildCircleButton`, 64x64)
- Expanded center pill (`LiquidGlassLayer > LiquidGlass.grouped(LiquidRoundedSuperellipse)`)
- RIGHT circle button (always rendered as `SizedBox` placeholder when hidden)

**Pill shape:** `LiquidRoundedSuperellipse(borderRadius: 32.0)` — borderRadius = circleSize/2 = 64/2

**FAB visibility:** `rightVisibleForIndices: const {1}` makes the FAB visible only on tab index 1 (Liste tab). When hidden, a `SizedBox(width: 64, height: 64)` placeholder preserves layout.

**Placement in XFin screens:** The nav is placed as a `Stack > Positioned(bottom: 16, left: 8, right: 8, ...)` overlay — NOT as `Scaffold.bottomNavigationBar`. The `IndexedStack` body fills the full screen and the nav floats on top.

### buildCircleButton Function (HIGH confidence)

```dart
Widget buildCircleButton({
  required Widget child,
  required double size,
  required LiquidGlassSettings settings,
  VoidCallback? onTap,
  Key? key,
})
```

Uses `LiquidGlassLayer > LiquidGlass.grouped(LiquidRoundedSuperellipse(borderRadius: 100))`. No `BuildContext` required — takes a `Widget child` directly.

### LiquidGlassSettings

```dart
LiquidGlassSettings get liquidGlassSettings => LiquidGlassSettings(
  thickness: 30,
  blur: 1.4,
  glassColor: ThemeProvider.isDark()
      ? const Color(0x33000000)
      : const Color(0x18E1E1E1),
);
```

Uses `ThemeProvider.isDark()` as a **static method** (XFin's ThemeProvider uses singleton pattern with `ThemeProvider.instance`).

### Dark/Light Mode Handling in XFin

XFin's `_buildNavColumn` computes:
```dart
final Color selectedColor   = ThemeProvider.isDark() ? Colors.white : Colors.black;
final Color unselectedColor = ThemeProvider.isDark() ? Colors.grey  : Colors.black54;
```

The glass background color is also driven by `ThemeProvider.isDark()`.

### XFin Screen Layout Pattern

```dart
Scaffold(
  body: Stack(
    children: [
      IndexedStack(index: _tab, children: [...]),
      buildLiquidGlassAppBar(context, title: ...),   // overlay appbar
      Positioned(
        bottom: 16, left: 8, right: 8,
        child: LiquidGlassBottomNav(
          icons: [...],
          labels: [...],
          keys: [...],
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          rightIcon: Icons.add,
          rightVisibleForIndices: const {1},   // FAB on Liste only
          onRightTap: () => _handleAdd(),
          onLeftTap: null,
          leftVisibleForIndices: const {},
          keepLeftPlaceholder: true,
        ),
      ),
    ],
  ),
)
```

Note: Valtra's screens currently use `buildGlassAppBar` (returns `PreferredSizeWidget`) not `buildLiquidGlassAppBar` (returns a `Positioned` overlay). The appbar is a separate migration concern — for this phase the decision is whether to keep `buildGlassAppBar` as `Scaffold.appBar` or also migrate to the overlay appbar. The requirements do NOT mention appbar changes, only the bottom nav. Keep `buildGlassAppBar` for now.

---

## Gap Analysis

### Gap 1: ThemeProvider.isDark() API Mismatch (HIGH impact)

XFin uses: `ThemeProvider.isDark()` — **static** method via singleton `ThemeProvider.instance`

Valtra uses: `provider.isDark(BuildContext context)` — **instance** method requiring context

`LiquidGlassBottomNav` calls `ThemeProvider.isDark()` in `_buildNavColumn` and `liquidGlassSettings` calls it at top-level.

**Resolution options:**
1. Add a static `isDark()` convenience method to Valtra's `ThemeProvider` (uses `WidgetsBinding.instance.platformDispatcher.platformBrightness` for system mode). This is what XFin does and is the cleanest approach.
2. Adapt the ported widget to use `Theme.of(context).brightness` instead. This is self-contained and avoids ThemeProvider coupling.

**Recommendation:** Use `Theme.of(context).brightness == Brightness.dark` inside the widget (no static needed). This is simpler and works correctly with Flutter's theme system.

### Gap 2: Scaffold Layout Change (MEDIUM impact)

Current: `Scaffold.bottomNavigationBar: GlassBottomNav` (docked, pushes body up)
Target: `Stack > Positioned` overlay nav (body fills full height, nav floats above)

This means body content will scroll under the nav bar. Each screen's `ListView` / content needs bottom padding equal to nav height + safe area to prevent content being hidden under the nav.

**Estimated nav height:** SafeArea + Padding (8+8) + max(64 circle, 56 pill) = 64 + 16 + bottom_safe_area ≈ ~80-100dp total. Use `MediaQuery.of(context).padding.bottom + 88` as ListView bottom padding.

### Gap 3: keepLeftPlaceholder / Left Button Not Needed (LOW impact)

Valtra has no left circular button concept. Use `onLeftTap: null`, `leftVisibleForIndices: const {}`, `keepLeftPlaceholder: false`. The right button is the FAB.

### Gap 4: Required `keys` Parameter (LOW impact)

`LiquidGlassBottomNav` requires `List<Key> keys` (one per tab). Use `Key('nav_analyse')` and `Key('nav_liste')` per screen (or screen-specific names for test isolation).

### Gap 5: Test Updates (MEDIUM impact)

All 5 screen tests currently assert `find.byType(GlassBottomNav)`. After migration this changes to `find.byType(LiquidGlassBottomNav)`. The widget tests in `liquid_glass_widgets_coverage_test.dart` test `GlassBottomNav` — these need new tests for `LiquidGlassBottomNav`.

The `buildGlassFAB` tests also need updating since the FAB is now built into the nav (no standalone `FloatingActionButton` in the tree).

---

## Implementation Strategy Notes

### Approach: Add LiquidGlassBottomNav to Valtra's widget file

Do NOT delete `GlassBottomNav` immediately — deprecate in place after migration. Add `LiquidGlassBottomNav` and `buildCircleButton` (new XFin signature) alongside existing widgets.

The XFin `buildCircleButton` has a different signature than Valtra's:
- XFin: `buildCircleButton({Widget child, double size, LiquidGlassSettings settings, VoidCallback? onTap, Key? key})`
- Valtra: `buildCircleButton({BuildContext context, IconData icon, VoidCallback onPressed, double size})`

Rename Valtra's old function or use the XFin signature (preferred). Keep old one temporarily for backward compatibility with any callers.

### Screen Migration Sequence

Recommended order (lowest risk first):
1. Smart Plugs (simplest — no cost toggle, no interpolation toggle during migration)
2. Gas (standard)
3. Water (standard)
4. Electricity (has cost toggle + visibility toggle appbar actions)
5. Heating (most complex — has rooms button in appbar + unitless meters)

Each screen migration is independent and can be verified in isolation.

### Body Padding for Overlay Nav

When the nav becomes an overlay, content can scroll behind it. Add `padding: EdgeInsets.only(bottom: 88 + MediaQuery.of(context).padding.bottom)` to each screen's `ListView` / list padding. 88dp = 64 (circle height) + 16 (top/bottom Padding insets in widget) + 8 (extra clearance).

---

## Files Inventory

### Files to Modify

| File | Change Type | Details |
|------|-------------|---------|
| `lib/widgets/liquid_glass_widgets.dart` | ADD new widgets | Add `LiquidGlassBottomNav`, new `buildCircleButton`, `liquidGlassSettings`. Add `import 'package:liquid_glass_renderer/liquid_glass_renderer.dart'` |
| `lib/screens/electricity_screen.dart` | MIGRATE nav | `Scaffold.body` → `Stack`, add Positioned nav, remove `bottomNavigationBar` and `floatingActionButton`, add list bottom padding |
| `lib/screens/gas_screen.dart` | MIGRATE nav | Same as electricity |
| `lib/screens/water_screen.dart` | MIGRATE nav | Same as electricity |
| `lib/screens/smart_plugs_screen.dart` | MIGRATE nav | Same pattern, no cost toggle |
| `lib/screens/heating_screen.dart` | MIGRATE nav | Same pattern, keep rooms/visibility actions in appbar |

### Test Files to Update

| File | Change Type | Details |
|------|-------------|---------|
| `test/widgets/liquid_glass_widgets_coverage_test.dart` | ADD tests | Add `LiquidGlassBottomNav` test group (renders, onTap, FAB visibility, dark mode) |
| `test/screens/electricity_screen_test.dart` | UPDATE | Change `GlassBottomNav` → `LiquidGlassBottomNav`; remove `FloatingActionButton` assertions |
| `test/screens/gas_screen_test.dart` | UPDATE | Same |
| `test/screens/water_screen_test.dart` | UPDATE | Same |
| `test/screens/smart_plugs_screen_test.dart` | UPDATE | Same |
| `test/screens/heating_screen_test.dart` | UPDATE | Same |

### XFin Reference Files (read-only)

| File | Used For |
|------|---------|
| `/c/SAPDevelop/Privat/XFin/lib/widgets/liquid_glass_widgets.dart` | Copy `LiquidGlassBottomNav`, `buildCircleButton`, `liquidGlassSettings` |
| `/c/SAPDevelop/Privat/XFin/lib/screens/assets_screen.dart` | Reference for `Stack + Positioned` layout pattern |
| `/c/SAPDevelop/Privat/XFin/lib/screens/standing_orders_screen.dart` | Reference for `LiquidGlassBottomNav` with FAB on specific tabs |

---

## Common Pitfalls

### Pitfall 1: Content Hidden Under Floating Nav
**What goes wrong:** ListView content is scrollable to the end but the last items are hidden behind the floating nav bar.
**Why it happens:** `Scaffold.bottomNavigationBar` auto-adds bottom padding to the body; `Stack > Positioned` overlay does not.
**How to avoid:** Add explicit `padding: EdgeInsets.only(bottom: 88 + MediaQuery.of(context).padding.bottom)` to every ListView that scrolls.
**Warning signs:** Last list item not reachable by scrolling.

### Pitfall 2: ThemeProvider.isDark() Static Method Missing in Valtra
**What goes wrong:** Compile error when copying `liquidGlassSettings` getter from XFin — calls `ThemeProvider.isDark()` which doesn't exist as static in Valtra.
**How to avoid:** Replace `ThemeProvider.isDark()` with `Theme.of(context).brightness == Brightness.dark` inside the widget, or compute inside `build()` via `Theme.of(context)`.
**Warning signs:** Compile error referencing `ThemeProvider.isDark`.

### Pitfall 3: Key Collision in Tests
**What goes wrong:** Multiple screens each add `Key('fab')` to their nav; tests that pump multiple screens simultaneously may find multiple widgets with the same key.
**How to avoid:** Use screen-specific keys: `Key('electricity_nav_analyse')`, `Key('electricity_nav_liste')`, etc.
**Warning signs:** Test finds more than one widget for a key.

### Pitfall 4: SafeArea Double-Application
**What goes wrong:** `LiquidGlassBottomNav` already includes a `SafeArea(bottom: true)` wrapper. If the `Positioned` parent or Scaffold also applies bottom safe area, the nav will be pushed up too far.
**How to avoid:** Place the `Positioned` at `bottom: 16` without additional SafeArea — the widget handles it internally.
**Warning signs:** Nav bar appears too high on devices with home indicator.

### Pitfall 5: liquid_glass_renderer Not Imported in Valtra widgets file
**What goes wrong:** `LiquidGlass`, `LiquidGlassLayer`, `LiquidRoundedSuperellipse`, `LiquidGlassSettings` all come from `liquid_glass_renderer`. Valtra's `liquid_glass_widgets.dart` currently does NOT import this package despite it being in `pubspec.yaml`.
**How to avoid:** Add `import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';` to the top of `liquid_glass_widgets.dart`.
**Warning signs:** Undefined class errors for `LiquidGlass`, `LiquidGlassLayer`.

---

## Architecture Patterns

### Pattern 1: Stack + Positioned Overlay Nav (XFin pattern)
```dart
// Source: XFin lib/screens/assets_screen.dart
return Scaffold(
  body: Stack(
    children: [
      // Full-screen body with bottom padding for nav clearance
      IndexedStack(
        index: _currentTab,
        children: [tabAnalyse, tabListe],
      ),
      // AppBar stays as Scaffold.appBar (Valtra decision — not migrating appbar)
      Positioned(
        bottom: 16,
        left: 8,
        right: 8,
        child: LiquidGlassBottomNav(
          icons: const [Icons.analytics, Icons.list],
          labels: [l10n.analysis, l10n.list],
          keys: const [Key('nav_analyse'), Key('nav_liste')],
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          onLeftTap: null,
          leftVisibleForIndices: const {},
          keepLeftPlaceholder: false,
          rightIcon: Icons.add,
          rightVisibleForIndices: const {1},  // FAB only on Liste tab
          onRightTap: () => _handleAdd(context),
        ),
      ),
    ],
  ),
);
```

### Pattern 2: ListView Padding for Overlay Nav
```dart
// In _buildListeTab and _buildAnalyseTab
return ListView(
  padding: EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: 16 + 64 + 16 + MediaQuery.of(context).padding.bottom,
    // ^^^    Positioned bottom  ^^^  circle height  ^^^  SafeArea
  ),
  children: [...],
);
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `Scaffold.bottomNavigationBar` (Flutter standard) | `Stack + Positioned` overlay (XFin LiquidGlass pattern) | Body no longer auto-padded; must handle bottom padding manually |
| `FloatingActionButton` (separate widget) | FAB built into `LiquidGlassBottomNav` via `rightIcon`/`rightVisibleForIndices` | Unified glass effect; single widget controls both nav and FAB |
| CSS-style glass (BoxDecoration+blur simulation) | `liquid_glass_renderer` (native renderer) | True iOS-style liquid glass with refraction/blur |

---

## Open Questions

1. **Appbar migration:** Valtra uses `buildGlassAppBar` (PreferredSizeWidget, normal Scaffold appBar). XFin uses `buildLiquidGlassAppBar` (Positioned overlay). The requirements for Phase 24 only mention bottom nav — leave appbar as-is. Confirm: do NOT migrate appbar in this phase.

2. **Heating screen cost toggle:** `_showCosts` is mentioned in the heating screen (`bool _showCosts = false`), but heating meters are unitless (Zentralheizung proportional counters per project memory). The cost toggle in heating appbar is present in code. No change needed for Phase 24 — leave this logic untouched, only migrate the nav widget.

3. **NavBarController (visibility hiding):** XFin uses `NavBarController` + `ValueListenableBuilder` to hide the nav when keyboards/filters appear. Valtra's simpler screens likely don't need this. Omit for this phase.

---

## Sources

### Primary (HIGH confidence)
- `XFin/lib/widgets/liquid_glass_widgets.dart` — `LiquidGlassBottomNav` widget full source read
- `XFin/lib/screens/assets_screen.dart` — Stack+Positioned layout pattern, `rightVisibleForIndices` usage
- `XFin/lib/screens/standing_orders_screen.dart` — second usage reference
- `Valtra/lib/widgets/liquid_glass_widgets.dart` — current GlassBottomNav implementation read
- `Valtra/lib/screens/electricity_screen.dart` — read in full
- `Valtra/lib/screens/gas_screen.dart` — read in full
- `Valtra/lib/screens/water_screen.dart` — read in full
- `Valtra/lib/screens/smart_plugs_screen.dart` — read in full
- `Valtra/lib/screens/heating_screen.dart` — read in full (bottom nav section confirmed at lines 85-113)
- `Valtra/pubspec.yaml` — confirmed `liquid_glass_renderer: ^0.2.0-dev.4` present
- `Valtra/lib/providers/theme_provider.dart` — confirmed instance method `isDark(BuildContext)`
- `XFin/lib/providers/theme_provider.dart` — confirmed static method `isDark()`

### Secondary (MEDIUM confidence)
- `Valtra/test/screens/*.dart` — all 5 screen tests reference `GlassBottomNav` (grep verified)
- `Valtra/test/widgets/liquid_glass_widgets_coverage_test.dart` — test coverage for current widgets

---

## Metadata

**Confidence breakdown:**
- Current implementation: HIGH — read all 5 screen sources directly
- XFin reference widget: HIGH — read source directly
- Gap analysis: HIGH — compared both sources directly
- Implementation strategy: HIGH — based on direct source reading

**Research date:** 2026-03-13
**Valid until:** 2026-04-13 (stable domain — Flutter widget migration)
