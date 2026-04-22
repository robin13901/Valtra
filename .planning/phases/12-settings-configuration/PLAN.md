# Phase 12 Plan — Settings & Configuration

**Phase**: 12 of 15
**Milestone**: 3 — Polish & Enhancement (v0.3.0)
**Requirements**: FR-10 (Settings & Theme), NFR-8 (Theme Consistency)
**Goal**: Build a dedicated SettingsScreen with 3-way theme toggle (Light/Dark/System), consolidate gas kWh conversion and interpolation method settings into it, add app info section, wire navigation from home screen, and audit all screens for dark mode compatibility.

---

## Architecture Overview

```
HomeScreen AppBar
  └── Settings gear icon ──► SettingsScreen

SettingsScreen (StatelessWidget)
  ├── Section: Appearance
  │   └── 3-way theme toggle (Light / Dark / System) with icons + immediate preview
  ├── Section: Meter Settings
  │   ├── Gas kWh conversion factor (numeric input with default hint)
  │   └── Interpolation method per meter type (dropdown per type)
  ├── Section: About
  │   ├── App version (package_info_plus)
  │   └── "Made with ♥ for Valtra" footer
  └── (Future placeholder: Cost Configuration, Backup/Restore)

ThemeProvider (existing — no changes needed)
  ├── themeMode: ThemeMode (light/dark/system)
  ├── setThemeMode(ThemeMode) → persists to SharedPreferences
  ├── toggleTheme() → cycle light↔dark
  └── isDark(BuildContext) → resolves system mode

InterpolationSettingsProvider (existing — no changes needed)
  ├── getMethodForMeterType(String) → InterpolationMethod
  ├── setMethodForMeterType(String, InterpolationMethod)
  ├── gasKwhFactor → double
  └── setGasKwhFactor(double)
```

---

## Key Decisions

1. **No new provider needed** — ThemeProvider and InterpolationSettingsProvider already handle all state. The SettingsScreen is purely a UI layer that reads/writes through existing providers.
2. **3-way toggle, not simple switch** — Use `SegmentedButton<ThemeMode>` (Material 3) for Light/Dark/System selection. More discoverable than the current AppBar toggle button, which will be removed.
3. **Remove AppBar theme toggle from HomeScreen** — The settings gear icon replaces it. This declutters the AppBar and centralizes all settings.
4. **Add `package_info_plus`** — Required for displaying app version dynamically (rather than hardcoding). Already widely used in Flutter ecosystem, minimal footprint.
5. **Dark mode audit as dedicated task** — Systematically review all screens and widgets for hardcoded colors. AppColors already defines dark variants, but some widgets may use raw color values.
6. **Keep SettingsScreen simple** — No deep navigation. All settings are on a single scrollable page with expandable sections. This sets up the foundation for Phase 13 (cost config) and Phase 15 (backup/restore) to add their sections.
7. **Interpolation settings per meter type** — Show a dropdown for each of the 5 meter types (electricity, smart plugs, gas, water, heating). Default is linear for all.

---

## Task Breakdown

### Task 1: Add package_info_plus dependency
**File**: `pubspec.yaml`
**Dependencies**: None
**Effort**: Small

Add `package_info_plus: ^8.0.0` to dependencies. Run `flutter pub get`.

**Acceptance**: Dependency resolves, no conflicts.

### Task 2: Localization (EN + DE)
**File**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Dependencies**: None
**Effort**: Small

New keys:

| Key | EN | DE |
|-----|----|----|
| `settingsTitle` | `"Settings"` | `"Einstellungen"` |
| `appearance` | `"Appearance"` | `"Darstellung"` |
| `themeMode` | `"Theme"` | `"Design"` |
| `themeLight` | `"Light"` | `"Hell"` |
| `themeDark` | `"Dark"` | `"Dunkel"` |
| `themeSystem` | `"System"` | `"System"` |
| `meterSettings` | `"Meter Settings"` | `"Zählereinstellungen"` |
| `gasKwhConversionFactor` | `"Gas kWh Conversion Factor"` | `"Gas kWh-Umrechnungsfaktor"` |
| `gasKwhConversionHint` | `"Default: 10.3 kWh/m³"` | `"Standard: 10,3 kWh/m³"` |
| `interpolationMethodLabel` | `"Interpolation Method"` | `"Interpolationsmethode"` |
| `aboutSection` | `"About"` | `"Über"` |
| `appVersion` | `"Version"` | `"Version"` |
| `settingsUpdated` | `"Settings updated"` | `"Einstellungen aktualisiert"` |
| `invalidNumber` | `"Please enter a valid number"` | `"Bitte gültige Zahl eingeben"` |

Check existing keys first — `settings`, `interpolation`, `interpolationMethod`, `linear`, `step`, `gasKwhConversion`, `gasConversionFactor` already exist. Only add truly new keys. Note: `settings` already exists as a key — reuse it for the AppBar tooltip instead of adding `settingsTitle` if the existing translation fits (it does: "Settings"/"Einstellungen").

Run `flutter gen-l10n` after editing.

**Acceptance**: All new strings in both ARB files, `flutter gen-l10n` succeeds.

### Task 3: Settings screen UI
**File**: `lib/screens/settings_screen.dart` (new)
**Dependencies**: Task 1 (package_info_plus), Task 2 (l10n keys)
**Effort**: Large

Build `SettingsScreen` as `StatelessWidget`:

```dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<InterpolationSettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _buildThemeSection(context, l10n, themeProvider),
          _buildMeterSettingsSection(context, l10n, settingsProvider),
          _buildAboutSection(context, l10n),
        ],
      ),
    );
  }
}
```

**Theme Section**:
- Section header: "Appearance"
- `SegmentedButton<ThemeMode>` with 3 segments:
  - Light (Icons.light_mode)
  - Dark (Icons.dark_mode)
  - System (Icons.brightness_auto)
- Selected value from `themeProvider.themeMode`
- `onSelectionChanged` → `themeProvider.setThemeMode(mode)`
- Immediate visual feedback (app theme changes instantly)

**Meter Settings Section**:
- Section header: "Meter Settings"
- **Gas kWh conversion factor**: `ListTile` with trailing `TextFormField` (numeric, width-constrained). Current value from `settingsProvider.gasKwhFactor`. On change → `settingsProvider.setGasKwhFactor(value)`. Show hint text "Default: 10.3 kWh/m³".
- **Interpolation methods**: One `ListTile` per meter type (Electricity, Smart Plugs, Gas, Water, Heating) with trailing `DropdownButton<InterpolationMethod>` (Linear / Step). Current value from `settingsProvider.getMethodForMeterType(type)`. On change → `settingsProvider.setMethodForMeterType(type, method)`.

**About Section**:
- Section header: "About"
- App version: `ListTile(title: "Version", subtitle: "x.y.z")` via `PackageInfo.fromPlatform()`
- Use `FutureBuilder<PackageInfo>` to load version asynchronously

**Acceptance**: SettingsScreen renders with all 3 sections, theme toggles work immediately, settings persist across restarts.

### Task 4: Wire navigation from HomeScreen
**File**: `lib/main.dart`
**Dependencies**: Task 3 (SettingsScreen exists)
**Effort**: Small

Changes to `HomeScreen`:
1. **Replace** the theme toggle `IconButton` in AppBar actions with a settings gear icon:
   ```dart
   IconButton(
     icon: const Icon(Icons.settings),
     onPressed: () => Navigator.of(context).push(
       MaterialPageRoute(builder: (context) => const SettingsScreen()),
     ),
     tooltip: l10n.settingsTitle,
   ),
   ```
2. **Remove** the `isDark` variable and theme toggle logic from HomeScreen (no longer needed — theme is managed in SettingsScreen).
3. **Add import** for `screens/settings_screen.dart`.

**Acceptance**: Gear icon in AppBar navigates to SettingsScreen. Theme toggle no longer in HomeScreen AppBar.

### Task 5: Dark mode audit & fixes
**File**: Multiple files across `lib/`
**Dependencies**: Task 3 (theme toggle works for testing)
**Effort**: Medium

Systematic audit of all screens and widgets:

1. **Search for hardcoded colors**: `Colors.white`, `Colors.black`, `Color(0x...)`, `withOpacity`, any raw color that should use `Theme.of(context).colorScheme.*` or `AppColors.*`
2. **Check each screen file** (8 screens):
   - `electricity_screen.dart`
   - `smart_plugs_screen.dart`
   - `gas_screen.dart`
   - `water_screen.dart`
   - `heating_screen.dart`
   - `analytics_screen.dart`
   - `monthly_analytics_screen.dart`
   - `yearly_analytics_screen.dart`
3. **Check remaining screen files** (4 more):
   - `smart_plug_analytics_screen.dart` — known hardcoded `Color(0xFF9E9E9E)` on lines 160/182
   - `smart_plug_consumption_screen.dart`
   - `rooms_screen.dart`
   - `households_screen.dart`
4. **Check widget files**:
   - `liquid_glass_widgets.dart` — verify glass effects in dark mode
   - All chart widgets — verify axis labels, grid lines, tooltip colors
   - `household_selector.dart`
   - All form dialogs
4. **Check main.dart** HomeScreen — verify category chips use theme colors
5. **Fix pattern**: Replace `Colors.white` → `Theme.of(context).colorScheme.surface`, `Colors.black` → `Theme.of(context).colorScheme.onSurface`, etc.

**Acceptance**: No hardcoded colors remain. All screens look correct in light, dark, and system modes.

### Task 6: Comprehensive tests
**File**: Multiple test files (new + modified)
**Dependencies**: Tasks 1-5
**Effort**: Large

Test files and focus:

| Test File | Focus | Est. Tests |
|-----------|-------|------------|
| `test/screens/settings_screen_test.dart` | Render all sections, theme toggle interaction, gas factor input, interpolation dropdowns, version display, navigation | ~20 |
| `test/providers/theme_provider_test.dart` | New file — init, setThemeMode for all 3 modes, persistence round-trip, toggleTheme cycling, isDark with system mode | ~15 |
| `test/providers/interpolation_settings_provider_test.dart` | Already exists — add tests for gas factor edge cases | ~3 (additions) |
| **Total** | | **~38** |

**Settings screen test details**:
- Renders AppBar with "Settings" title
- Renders theme section with 3 segments (Light, Dark, System)
- Tapping Light/Dark/System calls `themeProvider.setThemeMode()` correctly
- Renders gas conversion factor input with current value
- Editing gas factor calls `settingsProvider.setGasKwhFactor()`
- Invalid gas factor shows validation error
- Renders 5 interpolation method dropdowns (one per meter type)
- Changing dropdown calls `settingsProvider.setMethodForMeterType()`
- Renders About section with version info
- Settings gear icon on HomeScreen navigates to SettingsScreen

**Mock pattern**: Follow existing `mocktail` pattern. Mock `ThemeProvider` and `InterpolationSettingsProvider`. Use `wrapWithProviders()` from test_utils.dart.

**Acceptance**: All tests pass, `flutter test` green, `flutter analyze` clean.

---

## Wave Execution Plan

```
Wave 1 (Parallel — no deps):
  ├── Task 1: Add package_info_plus (pubspec.yaml)
  └── Task 2: Localization (EN + DE ARB files)

Wave 2 (Depends on Wave 1):
  └── Task 3: Settings screen UI

Wave 3 (Depends on Task 3):
  ├── Task 4: Wire navigation from HomeScreen
  └── Task 5: Dark mode audit & fixes

Wave 4 (Depends on all):
  └── Task 6: Tests + flutter test + flutter analyze
```

---

## Common Pitfalls

| Issue | Solution |
|-------|----------|
| `SegmentedButton` requires `Set<T>` for selection | Wrap `themeMode` in `{themeMode}` set. Use `onSelectionChanged: (set) => setThemeMode(set.first)` |
| Gas factor TextFormField needs debounce | Don't persist on every keystroke. Use `onFieldSubmitted` or `onEditingComplete` to trigger save |
| `PackageInfo.fromPlatform()` is async | Use `FutureBuilder<PackageInfo>` in About section with loading placeholder |
| `package_info_plus` fails in tests | Mock `PackageInfo` or use `PackageInfo(appName: 'Valtra', version: '0.3.0', ...)` constructor in test setup |
| InterpolationMethod enum display names | Map to l10n: `InterpolationMethod.linear` → `l10n.linear`, `.step` → `l10n.step` |
| Removing theme toggle breaks existing tests | Update `widget_test.dart` and any test that expects the theme toggle IconButton in HomeScreen AppBar |
| Drift stream-based screens fail in widget tests | Follow existing pattern: test provider logic separately, keep screen tests focused on rendering |
| Hardcoded tooltip strings in HomeScreen | Replace `'Switch to Light Mode'` / `'Switch to Dark Mode'` with l10n strings or remove (settings icon has simpler tooltip) |
| Dark mode on charts: fl_chart default axis colors | Override `titlesData` styling with theme-aware colors in all chart widgets |

## Requirements Traceability

| Requirement | Task(s) | Verification |
|-------------|---------|--------------|
| FR-10.1.1 (3-way theme toggle) | 3 | SegmentedButton with Light/Dark/System |
| FR-10.1.2 (Persist theme selection) | — (existing) | ThemeProvider already persists to SharedPreferences |
| FR-10.1.3 (Dark theme palette) | 5 | Audit confirms AppColors dark variants used everywhere |
| FR-10.1.4 (All screens correct in both modes) | 5 | Dark mode audit fixes hardcoded colors |
| FR-10.1.5 (Theme changes apply immediately) | 3 | SegmentedButton calls setThemeMode → notifyListeners → rebuild |
| FR-10.2.1 (Settings screen accessible) | 4 | Gear icon in HomeScreen AppBar |
| FR-10.2.2 (Theme toggle with preview) | 3 | Theme section with immediate visual feedback |
| FR-10.2.3 (Gas kWh conversion in settings) | 3 | Gas factor input in Meter Settings section |
| FR-10.2.4 (Interpolation method config) | 3 | Dropdown per meter type |
| FR-10.2.5 (App version and about) | 3 | About section with PackageInfo |
| NFR-8.1 (All screens light/dark/system) | 5 | Dark mode audit |
| NFR-8.2 (No hardcoded colors) | 5 | Audit + fixes |
| NFR-8.3 (Charts adapt to theme) | 5 | Chart widget fixes |
| NFR-8.4 (Glass effects in both themes) | 5 | LiquidGlass audit |
| NFR-11.1 (All strings localized) | 2 | EN + DE ARB files |
