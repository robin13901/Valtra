# Phase 14: UI/UX Polish & Localization - Research

**Researched:** 2026-03-07
**Domain:** Flutter UI cleanup, localization, number formatting, navigation overhaul
**Confidence:** HIGH

## Summary

Phase 14 is a large-scope UI cleanup and localization phase that touches virtually every screen in the Valtra app. The codebase currently has 14 screen files, 10 dialog files, and 1 shared glass widget library. The home screen uses basic Material Chips for navigation with a non-functional FAB and a divider before the Analyse button. All screens use standard `AppBar` and `FloatingActionButton` rather than the glass-styled variants (`buildGlassAppBar`, `buildGlassFAB`, `GlassCard`) already defined in `lib/widgets/liquid_glass_widgets.dart`.

Number formatting is hardcoded to English locale (`NumberFormat('#,##0.0', 'en')`) in 16 locations across 8 files. Date formatting uses non-locale-aware patterns. The German localization file (`app_localizations_de.dart`) has 25+ strings using `ae/oe/ue` instead of proper umlauts (`ae` -> `a`, `oe` -> `o`, `ue` -> `u`). There is no in-app language toggle mechanism -- the app currently follows the device locale via `MaterialApp.localizationsDelegates`.

The analysis screens have daily views, custom date range features, and a "Benutzerdefiniert" (custom) tab on smart plug analytics that all need removal. The water meter form dialog uses `SegmentedButton` for type selection which causes text wrapping issues. The smart plug form dialog pre-selects the first room by default.

**Primary recommendation:** Structure this phase into 7 waves matching the FR-12.x requirement groups. Create a shared `ValtraNumberFormat` utility and `LocaleProvider` early, then cascade changes outward.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FR-12.1.1 | Remove divider before Analyse button | Home screen (main.dart:327-328) has explicit `Divider()` + `SizedBox` before analytics chip |
| FR-12.1.2 | Remove non-functional FAB on home screen | Home screen (main.dart:339-342) has `FloatingActionButton(onPressed: () {})` doing nothing |
| FR-12.1.3 | Replace home screen chips with GlassBottomNav | Home screen (main.dart:287-335) uses `_buildCategoryChip()` for 6 categories; `GlassBottomNav` already exists in liquid_glass_widgets.dart |
| FR-12.1.4 | Apply buildGlassFAB to all screens with FABs | 10 screens use plain `FloatingActionButton`; `buildGlassFAB()` exists in liquid_glass_widgets.dart |
| FR-12.1.5 | Apply GlassCard to all list items and summary cards | 12+ screens use plain `Card`; `GlassCard` exists in liquid_glass_widgets.dart |
| FR-12.1.6 | Apply buildGlassAppBar to all screens | 14 screens use plain `AppBar`; `buildGlassAppBar()` exists in liquid_glass_widgets.dart |
| FR-12.2.1 | German number format everywhere | 16 locations use `NumberFormat('#,##0.0', 'en')`; needs locale-aware formatting |
| FR-12.2.2 | Time display with "Uhr" suffix | Date formatters in 6+ files show `HH:mm` without "Uhr" suffix |
| FR-12.2.3 | Month names localized to device language | `DateFormat.yMMMM()` and `DateFormat('MMMM yyyy')` used without explicit locale |
| FR-12.2.4 | Fix umlaut encoding | 25+ German strings in `app_localizations_de.dart` use ae/oe/ue instead of umlauts |
| FR-12.3.1 | Remove unit badges from app bar headers | Chips in app bars: electricity_screen.dart:38-41, gas_screen.dart:38-41, water_screen.dart:40-43, smart_plugs_screen.dart:43-47 |
| FR-12.3.2 | Remove non-clickable info icons | settings_screen.dart:262 (`Icons.info_outline` in About), smart_plug_analytics_screen.dart:399-402 (`Icons.info_outline` for "Sonstiger" explanation) |
| FR-12.3.3 | Remove too-long hints in meter reading input fields | `meterValueHint` in form dialogs; `smartPlugNameHint` has "Enter smart plug name" |
| FR-12.3.4 | Style date/time picker fields as outlined input fields | electricity_reading_form_dialog.dart:69-75 uses `ListTile` for date/time; should use `InputDecorator` with outline border |
| FR-12.3.5 | No pre-selected room when adding new smart plug | smart_plug_form_dialog.dart:54-55 defaults to `widget.rooms.firstOrNull?.id` |
| FR-12.3.6 | No hint text in smart plug name field | smart_plug_form_dialog.dart:79 has `hintText: l10n.smartPlugNameHint` |
| FR-12.3.7 | Remove interpolation method setting from settings | settings_screen.dart:130-148 shows interpolation method dropdown per meter type |
| FR-12.4.1 | Black text on Lemon Chiffon accent backgrounds | `onSecondary` in dark theme uses `AppColors.darkOnSurface` (light color on light background) |
| FR-12.4.2 | Glass effects correct in both themes | Already handled; glass widgets use `isDark` checks |
| FR-12.4.3 | Smart plug detail room subtitle readable | smart_plug_consumption_screen.dart:74-76 uses `colorScheme.onSurfaceVariant` which may be too faint |
| FR-12.5.1 | Filled icons everywhere for water | water_screen.dart:144 uses `water_drop_outlined` for cold, `category_outlined` for other; should all be filled |
| FR-12.5.2 | Replace water type SegmentedButton with Dropdown | water_meter_form_dialog.dart:88-112 uses `SegmentedButton<WaterMeterType>` |
| FR-12.6.1 | Remove daily view from analysis screens | monthly_analytics_screen.dart:68-93 shows "Daily Trends" section with line chart |
| FR-12.6.2 | Remove custom date range from analysis screens | monthly_analytics_screen.dart:34-38 has date_range IconButton; analytics_provider.dart has `_customRange` |
| FR-12.6.3 | Remove "Benutzerdefiniert" tab from smart plug analysis | smart_plug_analytics_screen.dart:233-235 has `AnalyticsPeriod.custom` ButtonSegment |
| FR-12.6.4 | Rename "Monatsvergleich" to "Monatsverlauf" | app_localizations_de.dart:539 `monthlyComparison => 'Monatsvergleich'` |
| FR-12.6.5 | Analysis screens default to current month | analytics_provider.dart:32 already defaults to current month; verify all entry points |
| FR-12.7.1 | Add language toggle (DE/EN) to settings | No `LocaleProvider` exists; need new provider with SharedPreferences |
| FR-12.7.2 | Persist language selection across restarts | Need SharedPreferences key for locale |
| FR-12.7.3 | Language change applies immediately | Need `MaterialApp.locale` bound to provider |
</phase_requirements>

## Standard Stack

### Core (Already in Project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter | 3.10+ | UI framework | Project foundation |
| intl | 0.20.2 | Number/date formatting, localization | Already used; `NumberFormat` and `DateFormat` locale-aware |
| provider | 6.1.2 | State management | Already used for all providers |
| shared_preferences | 2.2.3 | Persisting settings | Already used for theme; will use for language |
| flutter_localizations | SDK | Locale delegates | Already configured |

### No New Dependencies Needed
This phase requires zero new packages. All changes use existing Flutter/Dart capabilities:
- `NumberFormat('...', 'de')` for German formatting
- `DateFormat.Hm('de')` + "Uhr" for time display
- `MaterialApp.locale` for in-app language switching
- Existing `GlassBottomNav`, `buildGlassFAB`, `GlassCard`, `buildGlassAppBar` from `liquid_glass_widgets.dart`

## Architecture Patterns

### Recommended Project Structure (New/Modified Files)
```
lib/
  providers/
    locale_provider.dart            # NEW: Language toggle provider
  services/
    number_format_service.dart      # NEW: Centralized locale-aware formatting
  l10n/
    app_localizations_de.dart       # MODIFIED: Fix all umlaut strings
    app_localizations_en.dart       # MODIFIED: Add new strings
    app_localizations.dart          # MODIFIED: Add new string keys
  lib/l10n/
    app_en.arb                      # MODIFIED: Add new string keys
    app_de.arb                      # MODIFIED: Fix umlauts, add new strings
  main.dart                         # MODIFIED: Major home screen rewrite, add LocaleProvider
  screens/
    (all 14 screens)                # MODIFIED: Glass widgets, number formatting
  widgets/
    dialogs/
      water_meter_form_dialog.dart  # MODIFIED: SegmentedButton -> Dropdown
      smart_plug_form_dialog.dart   # MODIFIED: Remove pre-selected room, hint
      electricity_reading_form_dialog.dart  # MODIFIED: Styled date/time picker
      (all other form dialogs)      # MODIFIED: Date/time field styling
  widgets/
    liquid_glass_widgets.dart       # Existing, no changes needed
```

### Pattern 1: Centralized Number Formatting
**What:** Create a `ValtraNumberFormat` utility class that provides locale-aware number formatting based on the current app locale.
**When to use:** Every place that currently uses `NumberFormat('#,##0.0', 'en')` or `toStringAsFixed()`.
**Example:**
```dart
// lib/services/number_format_service.dart
class ValtraNumberFormat {
  /// Format a consumption value (1 decimal place) using the given locale.
  static String consumption(double value, String locale) {
    return NumberFormat('#,##0.0', locale).format(value);
  }

  /// Format a water reading (3 decimal places) using the given locale.
  static String waterReading(double value, String locale) {
    return NumberFormat('#,##0.000', locale).format(value);
  }

  /// Format a currency value (2 decimal places) using the given locale.
  static String currency(double value, String locale) {
    return NumberFormat('#,##0.00', locale).format(value);
  }

  /// Format time with locale-appropriate suffix.
  /// German: "9:43 Uhr", English: "9:43 AM" or "9:43".
  static String time(DateTime dt, String locale) {
    if (locale == 'de') {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} Uhr';
    }
    return DateFormat.Hm(locale).format(dt);
  }
}
```

### Pattern 2: LocaleProvider for In-App Language Toggle
**What:** A new `ChangeNotifier` provider that manages the app's display locale independently of device locale.
**When to use:** Required for FR-12.7 (language toggle).
**Example:**
```dart
// lib/providers/locale_provider.dart
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  SharedPreferences? _prefs;
  Locale? _locale; // null = follow device locale

  Locale? get locale => _locale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(_localeKey);
    if (saved != null) {
      _locale = Locale(saved);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs?.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  /// The effective locale string for NumberFormat/DateFormat usage.
  String get localeString => _locale?.languageCode ?? 'de';
}
```

### Pattern 3: Home Screen with GlassBottomNav
**What:** Replace the current chip-based navigation with a tab-based layout using `GlassBottomNav`.
**When to use:** FR-12.1.3 home screen rewrite.
**Architecture note:** The home screen needs to become a `StatefulWidget` that manages a tab index. The GlassBottomNav has limited item count (5 max for standard bottom nav). With 6 categories (Electricity, Smart Plugs, Gas, Water, Heating, Analytics), we need to either:
  - Use 5 main tabs + settings icon in AppBar (recommended)
  - Group Electricity + Smart Plugs as one "Strom" tab

**Recommended approach:** Convert HomeScreen to a tabbed scaffold with GlassBottomNav containing: Strom (Electricity), Gas, Wasser (Water), Heizung (Heating), Analyse. Smart Plugs accessible from within Electricity screen or via Analytics. Settings remains an AppBar icon.

### Anti-Patterns to Avoid
- **Hardcoding locale strings:** Never use `NumberFormat('...', 'en')`. Always pass the current locale from `LocaleProvider`.
- **Inline number formatting:** Never use `toStringAsFixed(1)` for display values. Always use the centralized formatting utility.
- **Mixing outlined/filled icons:** FR-12.5.1 requires ALL water icons to be filled (`Icons.water_drop`), not outlined.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Number formatting | Custom string manipulation | `NumberFormat` from `intl` package | Handles comma/dot swapping, thousands separators correctly |
| Date localization | String interpolation | `DateFormat.yMMMM(locale)` from `intl` | Handles month names, ordering by locale |
| Locale persistence | Manual file I/O | `SharedPreferences` | Already used for theme; consistent pattern |
| Bottom navigation | Custom tab bar | `GlassBottomNav` (already exists) | Already implements glass effect styling |
| Glass app bars | Custom PreferredSizeWidget | `buildGlassAppBar()` (already exists) | Already handles dark/light theming |

## Common Pitfalls

### Pitfall 1: NumberFormat Locale Must Match Display Locale
**What goes wrong:** Using `NumberFormat('#,##0.0', 'de')` produces "1.234,5" but if the app is in English mode, user sees German formatting.
**Why it happens:** Locale for formatting and display are separate concerns.
**How to avoid:** Always derive the NumberFormat locale from `LocaleProvider.localeString`, not from a hardcoded string.
**Warning signs:** Numbers showing dots for thousands in English mode.

### Pitfall 2: ARB File Regeneration After Umlaut Fixes
**What goes wrong:** Changing strings in ARB files requires regeneration of `app_localizations*.dart` files.
**Why it happens:** Flutter's l10n tooling generates Dart files from ARB sources.
**How to avoid:** After modifying `app_de.arb`, always run `flutter gen-l10n` or `flutter pub get` to regenerate.
**Warning signs:** Changes in ARB files not reflected in the app.

### Pitfall 3: GlassBottomNav Item Count Limit
**What goes wrong:** `BottomNavigationBar` with more than 5 items looks crowded and may not render properly.
**Why it happens:** Material Design guidelines limit bottom nav to 3-5 items.
**How to avoid:** Keep GlassBottomNav to 5 items maximum. Smart Plugs can be accessed from Electricity screen or Analytics hub.
**Warning signs:** Text labels overlapping or getting truncated in bottom nav.

### Pitfall 4: buildGlassAppBar Returns PreferredSizeWidget, Not AppBar
**What goes wrong:** Some screens may use `AppBar` features like `bottom:` (used in `smart_plug_consumption_screen.dart:67-79`) which `buildGlassAppBar` doesn't support.
**Why it happens:** `buildGlassAppBar` wraps an `AppBar` in a `PreferredSize` container but doesn't expose `bottom`.
**How to avoid:** For screens needing `AppBar.bottom`, either extend `buildGlassAppBar` to accept a `bottom` parameter, or use a custom solution. The smart plug consumption screen shows room name as a subtitle in `bottom:`.
**Warning signs:** Compiler errors about missing `bottom` parameter.

### Pitfall 5: SegmentedButton to Dropdown Migration (Water Type)
**What goes wrong:** Changing from `SegmentedButton` to `DropdownButtonFormField` changes the form's state management.
**Why it happens:** `SegmentedButton` uses `selected` set, while `DropdownButtonFormField` uses `initialValue`.
**How to avoid:** Keep the same state variable `_selectedType` and update using `onChanged`.
**Warning signs:** Type not being selected or form validation failing.

### Pitfall 6: Removing Daily View Breaks Line Chart Dependencies
**What goes wrong:** The monthly analytics screen references `data.dailyValues` for the line chart. Removing daily view means this data is no longer needed, but the `MonthlyAnalyticsData` model still has the field.
**Why it happens:** Data model is coupled to the removed UI element.
**How to avoid:** Remove the UI section and the data loading for daily values in `AnalyticsProvider._loadMonthlyData()`. Keep the field in the model but stop populating it (or make it optional).
**Warning signs:** Unnecessary data fetching slowing analytics load.

### Pitfall 7: Test Breakage from Glass Widget Changes
**What goes wrong:** Widget tests that find `AppBar`, `FloatingActionButton`, or `Card` widgets by type will break when replaced with glass variants.
**Why it happens:** `buildGlassFAB` returns a `Container` containing a `FloatingActionButton`, not a plain `FloatingActionButton`.
**How to avoid:** Update test finders to look for glass widget types or use `find.byType(FloatingActionButton)` which still works inside the Container wrapper.
**Warning signs:** Tests failing with "widget not found" errors.

## Code Examples

### All Screens Needing Glass Widget Updates

**Screens using plain `AppBar` (need `buildGlassAppBar`):**
1. `lib/main.dart` HomeScreen (line 253)
2. `lib/screens/households_screen.dart` (line 23)
3. `lib/screens/electricity_screen.dart` (line 25)
4. `lib/screens/gas_screen.dart` (line 25)
5. `lib/screens/water_screen.dart` (line 27)
6. `lib/screens/heating_screen.dart` (line 25)
7. `lib/screens/smart_plugs_screen.dart` (line 28)
8. `lib/screens/smart_plug_consumption_screen.dart` (line 65)
9. `lib/screens/smart_plug_analytics_screen.dart` (line 21)
10. `lib/screens/analytics_screen.dart` (line 23)
11. `lib/screens/monthly_analytics_screen.dart` (line 25)
12. `lib/screens/yearly_analytics_screen.dart` (line 42)
13. `lib/screens/settings_screen.dart` (line 29)
14. `lib/screens/rooms_screen.dart` (line 22)

**Screens using plain `FloatingActionButton` (need `buildGlassFAB`):**
1. `lib/main.dart` HomeScreen (line 339) -- REMOVE entirely, non-functional
2. `lib/screens/households_screen.dart` (line 47)
3. `lib/screens/electricity_screen.dart` (line 60)
4. `lib/screens/gas_screen.dart` (line 60)
5. `lib/screens/water_screen.dart` (line 50)
6. `lib/screens/heating_screen.dart` (line 44)
7. `lib/screens/smart_plugs_screen.dart` (line 53)
8. `lib/screens/smart_plug_consumption_screen.dart` (line 117)
9. `lib/screens/monthly_analytics_screen.dart` (line 110)
10. `lib/screens/yearly_analytics_screen.dart` (line 51)
11. `lib/screens/rooms_screen.dart` (line 27)

### All Umlaut Issues in app_localizations_de.dart

These lines use `ae/oe/ue` instead of proper German umlauts:

| Line | Current | Should Be |
|------|---------|-----------|
| 639 | `Aufschluesselung nach Steckdose` | `Aufschlüsselung nach Steckdose` |
| 642 | `Aufschluesselung nach Raum` | `Aufschlüsselung nach Raum` |
| 646 | `fuer diesen Zeitraum` | `für diesen Zeitraum` |
| 662 | `Jaehrlich` | `Jährlich` |
| 683 | `Zaehlereinstellungen` | `Zählereinstellungen` |
| 695 | `Ueber` | `Über` |
| 704 | `Bitte gueltige Zahl eingeben` | `Bitte gültige Zahl eingeben` |
| 716 | `Grundgebuehr` | `Grundgebühr` |
| 719 | `Grundgebuehr (pro Monat)` | `Grundgebühr (pro Monat)` |
| 739 | `Stufe hinzufuegen` | `Stufe hinzufügen` |
| 748 | `Gueltig ab` | `Gültig ab` |
| 751 | `Waehrung` | `Währung` |
| 754 | `Geschaetzte Kosten` | `Geschätzte Kosten` |
| 760 | `Jaehrliche Kosten` | `Jährliche Kosten` |
| 775 | `Preise loeschen` | `Preise löschen` |
| 779 | `fuer $meterType loeschen?` | `für $meterType löschen?` |
| 783 | `Kostenuebersicht` | `Kostenübersicht` |
| 807 | `Kosteneinstellung geloescht` | `Kosteneinstellung gelöscht` |

**IMPORTANT:** These same fixes must be applied in the `app_de.arb` source file first, then regenerated.

### All NumberFormat Locations (Need Locale-Aware Replacement)

| File | Line | Current Pattern | Locale Needed |
|------|------|----------------|---------------|
| electricity_screen.dart | 218 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| gas_screen.dart | 220 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| heating_screen.dart | 119, 251 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| water_screen.dart | 158, 284 | `NumberFormat('#,##0.000', 'en')` | From LocaleProvider |
| smart_plugs_screen.dart | 229 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| smart_plug_consumption_screen.dart | 233 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| electricity_provider.dart | 122, 132 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| gas_provider.dart | 123, 134 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| heating_provider.dart | 193, 201 | `NumberFormat('#,##0.0', 'en')` | From LocaleProvider |
| water_provider.dart | 208, 218 | `NumberFormat('#,##0.000', 'en')` | From LocaleProvider |

Additionally, `toStringAsFixed()` calls in these files need locale-aware replacement:
- `analytics_screen.dart` (lines 239, 242)
- `monthly_analytics_screen.dart` (lines 258, 268)
- `yearly_analytics_screen.dart` (lines 267, 283, 299)
- `smart_plug_analytics_screen.dart` (lines 379, 385, 396, 463, 491)
- Chart widgets (consumption_line_chart, monthly_bar_chart, year_comparison_chart, consumption_pie_chart)

### All Unit Badge Chips to Remove from App Bars

| File | Line | Current Code |
|------|------|-------------|
| electricity_screen.dart | 38-41 | `Chip(label: Text(l10n.kWh), ...)` |
| gas_screen.dart | 38-41 | `Chip(label: Text(l10n.cubicMeters), ...)` |
| water_screen.dart | 40-43 | `Chip(label: Text(l10n.cubicMeters), ...)` |
| smart_plugs_screen.dart | 43-47 | `Chip(label: Text(l10n.kWh), ...)` |

### Analysis Screen Changes Map

**MonthlyAnalyticsScreen (monthly_analytics_screen.dart):**
- REMOVE: Lines 34-38 -- custom date range `IconButton` in app bar
- REMOVE: Lines 68-93 -- "Daily Trends" section (title + `ConsumptionLineChart` + `ChartLegend`)
- RENAME: Line 96 `l10n.monthlyComparison` -> `l10n.monthlyProgress` (new l10n key for "Monatsverlauf")
- REMOVE: `_pickDateRange()` method (lines 133-150)
- REMOVE: `customRange` references in `_MonthNavigationHeader` (lines 181-228)

**SmartPlugAnalyticsScreen (smart_plug_analytics_screen.dart):**
- REMOVE: Lines 233-235 -- `AnalyticsPeriod.custom` ButtonSegment
- REMOVE: Lines 23-29 -- custom date range `IconButton` in app bar
- REMOVE: `_pickDateRange()` method (lines 189-206)
- REMOVE: `_CustomRangeDisplay` widget (lines 331-361)

**AnalyticsProvider (analytics_provider.dart):**
- REMOVE: `_customRange` field and `setCustomRange()` method
- UPDATE: `_selectedMonth` should default to current month (already does on line 32)

### Settings Screen Changes

**Remove interpolation method section (settings_screen.dart):**
- REMOVE: Lines 130-148 -- interpolation method label + dropdown rows
- KEEP: Gas conversion factor field (lines 128-129)
- REMOVE: `_meterTypes` constant (line 22) and `_buildInterpolationRow` method (lines 166-201)

**Add language toggle section:**
- ADD: New section between Theme and Meter Settings
- USE: `SegmentedButton<Locale>` with segments for Deutsch and English
- WIRE: To new `LocaleProvider.setLocale()`

**Remove info icon from About section (settings_screen.dart:262):**
- REMOVE: `leading: Icon(Icons.info_outline, ...)` from the ListTile

### Smart Plug Form Dialog Changes

**smart_plug_form_dialog.dart:**
- Line 54-55: Change `_selectedRoomId = widget.plug?.roomId ?? widget.initialRoomId ?? widget.rooms.firstOrNull?.id;` to `_selectedRoomId = widget.plug?.roomId ?? widget.initialRoomId;` (no default first room)
- Line 79: Remove `hintText: l10n.smartPlugNameHint`

### Water Screen Changes

**water_screen.dart -- Icons:**
- Line 144: Change `Icons.water_drop_outlined` to `Icons.water_drop` for cold water
- Line 148: Change `Icons.category_outlined` to `Icons.water_drop` for other water (with gray color)
- Line 63 (empty state): Change `Icons.water_drop_outlined` to `Icons.water_drop`

**water_meter_form_dialog.dart -- Type Selector:**
- Lines 88-112: Replace `SegmentedButton<WaterMeterType>` with `DropdownButtonFormField<WaterMeterType>`
- All three segment icons should be `Icons.water_drop` (filled)

### Dark Mode Fix

**app_theme.dart:**
- Line 97: `onSecondary: AppColors.darkOnSurface` should be changed to use black text for Lemon Chiffon backgrounds
- Add: `static const lemonChiffonOnColor = Color(0xFF000000);` to AppColors
- Update dark theme: `onSecondary: Colors.black` (black text on Lemon Chiffon accent)

### Smart Plug Consumption Screen -- Room Subtitle Fix

**smart_plug_consumption_screen.dart:**
- Line 74-76: The room subtitle uses `colorScheme.onSurfaceVariant` which is fine for dark mode but may be too faint in light mode
- Fix: Use a more prominent color or increase font weight for the room subtitle

### Date/Time Picker Field Styling

**Current pattern (ListTile-based, in electricity_reading_form_dialog.dart:69-75):**
```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.calendar_today),
  title: Text(l10n.dateAndTime),
  subtitle: Text(_formatDateTime(_selectedDateTime)),
  onTap: _selectDateTime,
),
```

**Target pattern (InputDecorator-based, matching meter reading fields):**
```dart
InkWell(
  onTap: _selectDateTime,
  child: InputDecorator(
    decoration: InputDecoration(
      labelText: l10n.dateAndTime,
      suffixIcon: const Icon(Icons.calendar_today),
    ),
    child: Text(_formatDateTime(_selectedDateTime)),
  ),
),
```

This same pattern change applies to:
- `electricity_reading_form_dialog.dart`
- `gas_reading_form_dialog.dart`
- `water_reading_form_dialog.dart`
- `heating_reading_form_dialog.dart`
- `smart_plug_consumption_form_dialog.dart` (date picker only, lines 92-98)

### MaterialApp Locale Binding

**main.dart -- Current (line 234):**
```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

**Target (add locale from provider):**
```dart
locale: localeProvider.locale, // null = follow device
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `NumberFormat('...', 'en')` hardcoded | `NumberFormat('...', locale)` dynamic | This phase | All number displays become locale-aware |
| Device-only locale | In-app language toggle | This phase | Users can override device language |
| Chip navigation on home | GlassBottomNav tabs | This phase | Major UX improvement |
| `SegmentedButton` for water type | `DropdownButtonFormField` | This phase | Fixes text wrapping issue |
| Daily trends in monthly analytics | Monthly bar chart only | This phase | Removes misleading data (monthly readings only) |
| Custom date ranges | Fixed month/year navigation | This phase | Simplifies analytics UX |

## Open Questions

1. **GlassBottomNav Tab Count**
   - What we know: There are 6 navigation categories (Electricity, Smart Plugs, Gas, Water, Heating, Analytics). GlassBottomNav wraps `BottomNavigationBar` which supports max 5 items comfortably.
   - What's unclear: How to fit all 6 into the bottom nav.
   - Recommendation: Use 5 tabs: Strom (with Smart Plugs accessible from within), Gas, Wasser, Heizung, Analyse. Or combine Strom + Smart Plugs into one view. The home screen could also remain a hub page that is itself one of the tabs (Home, Strom, Gas, Wasser, Analyse), with Heating and Smart Plugs accessible from sub-navigation.

2. **Home Screen Architecture Change**
   - What we know: Current home screen is a single `StatelessWidget` with push navigation. GlassBottomNav implies tab-based navigation where each tab shows a different screen.
   - What's unclear: Whether the home screen should become a full tab controller or keep push navigation from a redesigned hub.
   - Recommendation: Keep the home screen as a hub page but redesign it with GlassCard-based navigation items instead of chips. Add GlassBottomNav for the main categories (5 tabs). The home "hub" view becomes one of the tabs.

3. **NumberFormat in Providers vs Screens**
   - What we know: Providers format numbers for validation error messages (e.g., `electricity_provider.dart:122`). The provider layer doesn't have access to `BuildContext` or `LocaleProvider`.
   - What's unclear: How to pass locale to providers for error messages.
   - Recommendation: Have providers return raw numbers for error messages (e.g., the threshold value), and format them in the screen/widget layer where `LocaleProvider` is accessible via `context.watch()`.

4. **Removing Daily View from Chart Widgets**
   - What we know: `ConsumptionLineChart` is only used in the monthly analytics daily trends section that's being removed.
   - What's unclear: Whether `ConsumptionLineChart` widget itself should be deleted or kept for potential future use.
   - Recommendation: Keep the widget file but remove the import and usage from monthly analytics. It's also used by the `ChartLegend` display. Clean up if not referenced anywhere else.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mocktail 0.3.0 |
| Config file | `pubspec.yaml` (dev_dependencies) |
| Quick run command | `flutter test --no-pub` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FR-12.1.1-2 | Home screen has no divider/FAB | widget | `flutter test test/widget_test.dart -x` | Needs update |
| FR-12.1.3 | GlassBottomNav on home | widget | `flutter test test/widget_test.dart -x` | Needs update |
| FR-12.2.1 | German number formatting | unit | `flutter test test/services/number_format_service_test.dart -x` | Wave 0 |
| FR-12.2.4 | Umlaut strings correct | unit | `flutter test test/l10n/localization_test.dart -x` | Wave 0 |
| FR-12.3.7 | No interpolation setting | widget | `flutter test test/screens/settings_screen_test.dart -x` | Exists, needs update |
| FR-12.5.2 | Water type dropdown | widget | `flutter test test/widgets/dialogs/water_meter_form_dialog_test.dart -x` | Exists, needs update |
| FR-12.6.1-3 | No daily/custom in analytics | widget | `flutter test test/screens/monthly_analytics_screen_test.dart -x` | Exists, needs update |
| FR-12.7.1-3 | Language toggle works | unit+widget | `flutter test test/providers/locale_provider_test.dart -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test --no-pub`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green + `flutter analyze` clean

### Wave 0 Gaps
- [ ] `test/services/number_format_service_test.dart` -- covers FR-12.2.1
- [ ] `test/providers/locale_provider_test.dart` -- covers FR-12.7.1-3
- [ ] `test/l10n/localization_test.dart` -- covers FR-12.2.4 (umlaut verification)
- [ ] Update existing tests that find `AppBar`/`FloatingActionButton` to accommodate glass variants

## Complete File Impact Map

This section maps every file that needs modification in Phase 14, grouped by change type.

### New Files (4)
| File | Purpose |
|------|---------|
| `lib/providers/locale_provider.dart` | In-app language toggle state management |
| `lib/services/number_format_service.dart` | Centralized locale-aware number formatting |
| `test/providers/locale_provider_test.dart` | Tests for locale provider |
| `test/services/number_format_service_test.dart` | Tests for number formatting |

### Modified: Localization (3 source + 2 generated)
| File | Changes |
|------|---------|
| `lib/l10n/app_de.arb` | Fix 18+ umlaut strings; add new keys (monthlyProgress, language, languageDE, languageEN) |
| `lib/l10n/app_en.arb` | Add new keys (monthlyProgress, language, languageDE, languageEN) |
| `lib/l10n/app_localizations.dart` | Regenerated (new abstract getters) |
| `lib/l10n/app_localizations_de.dart` | Regenerated (umlaut fixes + new strings) |
| `lib/l10n/app_localizations_en.dart` | Regenerated (new strings) |

### Modified: Core (2)
| File | Changes |
|------|---------|
| `lib/main.dart` | Major rewrite: HomeScreen with GlassBottomNav, add LocaleProvider, wire locale to MaterialApp |
| `lib/app_theme.dart` | Fix `onSecondary` in dark theme for black text on Lemon Chiffon |

### Modified: Screens (14)
| File | Changes |
|------|---------|
| `lib/screens/electricity_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, remove unit chip, locale-aware NumberFormat |
| `lib/screens/gas_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, remove unit chip, locale-aware NumberFormat |
| `lib/screens/water_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, remove unit chip, locale-aware NumberFormat, filled icons |
| `lib/screens/heating_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, locale-aware NumberFormat |
| `lib/screens/smart_plugs_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, remove unit chip, locale-aware NumberFormat |
| `lib/screens/smart_plug_consumption_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, locale-aware NumberFormat, fix room subtitle readability |
| `lib/screens/smart_plug_analytics_screen.dart` | buildGlassAppBar, GlassCard, remove custom period, remove info icon, locale-aware NumberFormat |
| `lib/screens/analytics_screen.dart` | buildGlassAppBar, GlassCard, locale-aware NumberFormat |
| `lib/screens/monthly_analytics_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, remove daily trends, remove custom date range, rename monthlyComparison |
| `lib/screens/yearly_analytics_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard, locale-aware NumberFormat |
| `lib/screens/households_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard |
| `lib/screens/rooms_screen.dart` | buildGlassAppBar, buildGlassFAB, GlassCard |
| `lib/screens/settings_screen.dart` | buildGlassAppBar, GlassCard, remove interpolation method, add language toggle, remove About info icon |

### Modified: Dialogs (6)
| File | Changes |
|------|---------|
| `lib/widgets/dialogs/electricity_reading_form_dialog.dart` | Style date/time as InputDecorator, remove hint if too long |
| `lib/widgets/dialogs/gas_reading_form_dialog.dart` | Style date/time as InputDecorator |
| `lib/widgets/dialogs/water_reading_form_dialog.dart` | Style date/time as InputDecorator |
| `lib/widgets/dialogs/heating_reading_form_dialog.dart` | Style date/time as InputDecorator |
| `lib/widgets/dialogs/water_meter_form_dialog.dart` | Replace SegmentedButton with Dropdown, filled icons |
| `lib/widgets/dialogs/smart_plug_form_dialog.dart` | Remove pre-selected room, remove hint text |
| `lib/widgets/dialogs/smart_plug_consumption_form_dialog.dart` | Style date as InputDecorator |

### Modified: Providers (6)
| File | Changes |
|------|---------|
| `lib/providers/analytics_provider.dart` | Remove customRange, ensure default month = current |
| `lib/providers/smart_plug_analytics_provider.dart` | Remove custom period support |
| `lib/providers/electricity_provider.dart` | Return raw numbers (not formatted) for validation errors |
| `lib/providers/gas_provider.dart` | Return raw numbers for validation errors |
| `lib/providers/heating_provider.dart` | Return raw numbers for validation errors |
| `lib/providers/water_provider.dart` | Return raw numbers for validation errors |

### Modified: Charts (4)
| File | Changes |
|------|---------|
| `lib/widgets/charts/consumption_line_chart.dart` | Locale-aware tooltip formatting |
| `lib/widgets/charts/monthly_bar_chart.dart` | Locale-aware tooltip/axis formatting |
| `lib/widgets/charts/year_comparison_chart.dart` | Locale-aware tooltip/axis formatting |
| `lib/widgets/charts/consumption_pie_chart.dart` | Locale-aware percentage formatting |

### Modified: Models (1)
| File | Changes |
|------|---------|
| `lib/services/analytics/analytics_models.dart` | Remove `custom` from `AnalyticsPeriod` enum (or keep and ignore) |

### Total Impact: ~4 new files + ~35 modified files + ~20+ test files to update

## Sources

### Primary (HIGH confidence)
- All findings based on direct codebase analysis of 75+ source files
- `intl` package NumberFormat/DateFormat API: verified in existing codebase usage
- Flutter localization (ARB -> generated Dart): verified via l10n.yaml configuration

### Secondary (MEDIUM confidence)
- BottomNavigationBar 5-item guideline: Material Design specification
- SharedPreferences locale persistence pattern: consistent with existing ThemeProvider pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependencies, all existing tools
- Architecture: HIGH - patterns directly derived from existing codebase patterns
- Pitfalls: HIGH - identified from actual code analysis
- File impact map: HIGH - every file listed was read and analyzed

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (stable - no external dependencies changing)
