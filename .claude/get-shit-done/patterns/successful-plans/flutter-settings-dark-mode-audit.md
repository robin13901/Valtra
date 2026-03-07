---
name: flutter-settings-dark-mode-audit
domain: ui, settings
tech: [flutter, provider, shared_preferences, package_info_plus, material3]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-07
---

## Context
Use this pattern when adding a dedicated settings screen to a Flutter app that already has a ThemeProvider and configuration providers using SharedPreferences. Also applies when performing a dark mode audit across an existing codebase.

## Pattern

### Tasks
1. **Add package_info_plus dependency** — For dynamic app version display
2. **Localization keys** — Add all new settings labels in EN + DE ARB files
3. **SettingsScreen UI** — StatelessWidget with scrollable sections:
   - Appearance: `SegmentedButton<ThemeMode>` (Material 3) for Light/Dark/System
   - Configuration: Numeric inputs + dropdowns reading/writing existing providers
   - About: `FutureBuilder<PackageInfo>` for version display
4. **Wire navigation** — Replace inline AppBar toggles with gear icon → SettingsScreen
5. **Dark mode audit** — Systematic grep for hardcoded colors, replace with theme-aware values
6. **Tests** — Screen render tests, provider unit tests, navigation tests

### Key Decisions
1. **No new provider** — SettingsScreen is purely UI over existing ThemeProvider + InterpolationSettingsProvider
2. **SegmentedButton over Switch** — Material 3 `SegmentedButton<ThemeMode>` for 3-way choice (Light/Dark/System). More discoverable than toggle. Requires wrapping value in `{value}` Set.
3. **Remove inline toggle** — Centralize theme control in settings, remove AppBar toggle to declutter
4. **Stateful inner widget for TextFormField** — Gas factor uses `_GasConversionField` (StatefulWidget) to manage `TextEditingController` lifecycle and avoid losing cursor position on provider rebuilds
5. **onSubmitted not onChanged** — Persist numeric settings on submit/editingComplete, not every keystroke (debounce without timer)
6. **FutureBuilder for PackageInfo** — `PackageInfo.fromPlatform()` is async, wrap in FutureBuilder with `...` loading placeholder
7. **Centralized AppColors** — Add `otherColor` and `successColor` to AppColors rather than inline

### Dark Mode Audit Pattern
1. **Search targets**: `Colors.white`, `Colors.black`, `Colors.grey`, `Colors.redAccent`, `Colors.red`, `Colors.green`, `Color(0x`, `Colors.white70`, `Colors.black54`
2. **Replacement mapping**:
   - `Colors.white` (backgrounds/dots) → `Theme.of(context).colorScheme.surface`
   - `Colors.white` (text on colored bg) → `Theme.of(context).colorScheme.surface`
   - `Colors.black` → `Theme.of(context).colorScheme.onSurface`
   - `Colors.grey` → `AppColors.otherColor` or `colorScheme.onSurfaceVariant`
   - `Colors.red`/`Colors.redAccent` → `colorScheme.error` or `AppColors.heatingColor`
   - `Colors.green` → `AppColors.successColor`
   - `Colors.white70`/`Colors.black54` → `colorScheme.onSurfaceVariant`
   - Inline `Color(0xFF...)` → named constant in `AppColors`
3. **Safe to skip**: `Colors.transparent`, colors inside `AppTheme` definitions, colors inside `AppColors` definitions

### Common Pitfalls
| Issue | Solution |
|-------|----------|
| SegmentedButton requires Set for selection | Wrap value: `selected: {themeMode}`, extract: `onSelectionChanged: (s) => set(s.first)` |
| PackageInfo fails in widget tests | FutureBuilder shows `...` placeholder; tests check for `Version` label not specific version string |
| About section scrolled off-screen in tests | Use `tester.drag(find.byType(ListView), Offset(0, -500))` to scroll down |
| `scrollUntilVisible` fails with "Too many elements" | Multiple Scrollable widgets exist; use `drag` on specific `ListView` instead |
| TextField loses cursor on provider rebuild | Extract to StatefulWidget with own TextEditingController lifecycle |
| SegmentedButton icons not findable via `find.byIcon` | ButtonSegment renders icons differently; test via `find.byType(SegmentedButton<ThemeMode>)` |
| fl_chart dot colors hardcoded white | `getDotPainter` closure captures `context` from enclosing `_buildData(context)` method |
| Theme-dependent chart colors in closures | Chart `_buildData(BuildContext context)` pattern passes context through for `Theme.of(context)` access |

### Wave Structure
```
Wave 1 (Parallel): Dependency + Localization
Wave 2: Settings screen UI
Wave 3 (Parallel): Navigation wiring + Dark mode audit
Wave 4: Tests + flutter test + flutter analyze
```
