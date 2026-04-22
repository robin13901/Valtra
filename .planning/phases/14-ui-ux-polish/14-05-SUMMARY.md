---
phase: 14-ui-ux-polish
plan: 05
subsystem: screens, dialogs, settings, water, smart-plugs
tags: [ui-cleanup, input-decorator, date-picker, dropdown, filled-icons, interpolation-removal]
dependency-graph:
  requires: [glass widgets from 14-03]
  provides: [cleaner UI across all screens and dialogs]
  affects: [7 screen files, 7 dialog files, 3 test files]
tech-stack:
  added: []
  patterns: [InputDecorator for date/time fields, DropdownButtonFormField for water type]
key-files:
  created: []
  modified:
    - lib/screens/electricity_screen.dart
    - lib/screens/gas_screen.dart
    - lib/screens/water_screen.dart
    - lib/screens/smart_plugs_screen.dart
    - lib/screens/smart_plug_analytics_screen.dart
    - lib/screens/settings_screen.dart
    - lib/widgets/dialogs/electricity_reading_form_dialog.dart
    - lib/widgets/dialogs/gas_reading_form_dialog.dart
    - lib/widgets/dialogs/water_reading_form_dialog.dart
    - lib/widgets/dialogs/heating_reading_form_dialog.dart
    - lib/widgets/dialogs/smart_plug_consumption_form_dialog.dart
    - lib/widgets/dialogs/smart_plug_form_dialog.dart
    - lib/widgets/dialogs/water_meter_form_dialog.dart
    - test/screens/settings_screen_test.dart
    - test/widgets/dialogs/water_meter_form_dialog_test.dart
    - test/widgets/smart_plug_form_dialog_test.dart
decisions:
  - "Water type colors: blue (cold), red (hot), grey (other) using Colors.* instead of AppColors"
  - "Interpolation settings fully removed from settings screen (linear-only decision from Phase 14 research)"
  - "Smart plug room subtitle in smart_plugs_screen.dart (not consumption screen) since consumption screen uses combined title"
metrics:
  duration: 15m
  completed: 2026-03-07
---

# Phase 14 Plan 05: UI Element Cleanup Summary

Removed unit badge chips, info icons, too-long hints; styled date/time pickers as InputDecorator; fixed water type selector, water icons, smart plug form defaults, and settings interpolation removal.

## What Was Done

### Task 1: Remove unit badges, info icons, hints, and fix settings/smart plug/water screens

**Unit badge Chips removed from 4 app bars:**
- electricity_screen.dart: Removed `Chip(label: Text(l10n.kWh))`
- gas_screen.dart: Removed `Chip(label: Text(l10n.cubicMeters))`
- water_screen.dart: Removed `Chip(label: Text(l10n.cubicMeters))`
- smart_plugs_screen.dart: Removed `Chip(label: Text(l10n.kWh))`

**Non-clickable info icons removed from 2 files:**
- settings_screen.dart: Removed `Icons.info_outline` from About section ListTile
- smart_plug_analytics_screen.dart: Removed Tooltip with `Icons.info_outline` for "Sonstiger" kWh explanation

**Smart plug form fixes (smart_plug_form_dialog.dart):**
- Removed `hintText: l10n.smartPlugNameHint` from name TextFormField
- No pre-selected room for new plugs: removed `?? widget.rooms.firstOrNull?.id` fallback

**Interpolation settings removed (settings_screen.dart):**
- Removed `_meterTypes` constant and `_buildInterpolationRow` method
- Removed `_meterTypeDisplayName` helper method
- Removed interpolation label and dropdown rows from meter settings section
- Removed unused `InterpolationMethod` import
- Kept gas conversion factor field

**Smart plug room subtitle readability (smart_plugs_screen.dart):**
- Changed room subtitle from `color: theme.colorScheme.onSurfaceVariant` to `fontWeight: FontWeight.w500` (uses default body text color, better contrast in light theme)

**Water filled icons (water_screen.dart):**
- Replaced `Icons.water_drop_outlined` with `Icons.water_drop` (filled) for cold
- Replaced `Icons.category_outlined` with `Icons.water_drop` (filled) for other
- Replaced `Icons.water_drop_outlined` with `Icons.water_drop` in empty state
- Changed colors: blue (cold), red (hot), grey (other)

**Water type selector (water_meter_form_dialog.dart):**
- Replaced `SegmentedButton<WaterMeterType>` with `DropdownButtonFormField<WaterMeterType>`
- Each item has colored `Icons.water_drop` icon (blue/red/grey) + localized label

### Task 2: Style date/time picker fields as InputDecorator in all form dialogs

Replaced ListTile-based date/time pickers with InkWell + InputDecorator in all 5 reading form dialogs:
- electricity_reading_form_dialog.dart
- gas_reading_form_dialog.dart
- water_reading_form_dialog.dart
- heating_reading_form_dialog.dart
- smart_plug_consumption_form_dialog.dart

Removed `hintText: l10n.meterValueHint` from meter value TextFormFields in all 4 applicable dialogs (electricity, gas, water, heating).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Smart plug room subtitle location mismatch**
- **Found during:** Task 1
- **Issue:** Plan referenced smart_plug_consumption_screen.dart for room subtitle fix, but decision #30 (from Plan 14-03) combined plug+room into title string. The room subtitle only exists in smart_plugs_screen.dart.
- **Fix:** Applied readability fix to smart_plugs_screen.dart instead.
- **Files modified:** lib/screens/smart_plugs_screen.dart

**2. [Rule 1 - Bug] Settings screen gas conversion test finder**
- **Found during:** Test verification
- **Issue:** Pre-existing bug from Phase 13 -- `find.byType(TextField)` found too many elements after cost config TextFields were added to settings screen.
- **Fix:** Changed to `find.byType(TextField).first` to target gas conversion field.
- **Files modified:** test/screens/settings_screen_test.dart

**3. [Rule 3 - Blocking] Water meter form dialog test adaptation**
- **Found during:** Test verification
- **Issue:** Tests used `tester.tap(find.text('Hot Water'))` which worked with SegmentedButton (all options visible) but fails with DropdownButtonFormField (must open dropdown first).
- **Fix:** Open dropdown via `find.byType(DropdownButtonFormField)`, then tap `.last` of the target text.
- **Files modified:** test/widgets/dialogs/water_meter_form_dialog_test.dart

**4. [Rule 3 - Blocking] Smart plug form dialog test adaptation**
- **Found during:** Test verification
- **Issue:** Tests expected room to be pre-selected for new plugs. After removing pre-selection fallback, must explicitly select a room.
- **Fix:** Added room dropdown selection step before save in "submits form with valid data" test. Changed "dropdown shows all rooms" test to open dropdown by widget type.
- **Files modified:** test/widgets/smart_plug_form_dialog_test.dart

## Verification

- `flutter analyze --no-pub`: No issues found
- `flutter test --no-pub`: 689 passing, 83 pre-existing screen test failures (ThemeProvider gap)
- Grep for `Chip(label:` in lib/screens/: 0 matches
- Grep for `info_outline` in lib/screens/: 0 matches
- Grep for `SegmentedButton` in water_meter_form_dialog.dart: 0 matches

## Test Impact

- Removed 5 obsolete tests (3 interpolation, 1 info icon, 1 duplicate): settings_screen_test.dart
- Fixed 2 pre-existing bugs: settings_screen_test.dart gas conversion TextField finder
- Updated 2 tests: water_meter_form_dialog_test.dart (dropdown interaction)
- Updated 2 tests: smart_plug_form_dialog_test.dart (no pre-selection)
- Net: 694 -> 689 passing (removed 5 obsolete tests), 83 pre-existing failures unchanged

## Commits

| Hash | Message |
|------|---------|
| 9230cf2 | feat(14-05): clean up UI elements, style pickers, fix water and smart plug screens |
