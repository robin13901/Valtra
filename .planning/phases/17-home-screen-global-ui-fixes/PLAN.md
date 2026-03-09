# Phase 17 Plan — Home Screen & Global UI Fixes

## Goal
Remove unused features, fix UI inconsistencies, and clean up the home screen — establishing a clean baseline for the Milestone 4 UX overhaul.

## Success Criteria
- Household dropdown text is dark/black and readable in light mode (FR-15.1)
- Home screen has no bottom navigation bar (FR-15.2)
- No Analyse tile on home screen; AnalyticsScreen file deleted (FR-15.3)
- Home tiles in order: [Strom, Smart Home] [Gas, Heizung] [Wasser centered] (FR-15.4)
- All reading form dialogs show only Cancel + Save side-by-side; QuickEntryMixin deleted (FR-15.5)
- Global date/time format "dd.MM.yyyy, HH:mm Uhr" (DE) / "dd.MM.yyyy, HH:mm" (EN) everywhere (FR-15.6)
- No CSV export buttons, services, or dead code anywhere (FR-15.7)
- All strings localized EN + DE (NFR-14)
- All 1017+ existing tests pass, new tests cover changes (NFR-15)
- Zero flutter analyze issues (NFR-16)

---

## Task Breakdown

### Wave 1: Independent Cleanup (3 parallel tasks)

These three tasks touch completely separate files and can be executed in any order.

#### Task 17.1: Fix Household Dropdown Text Color
**Files**:
- `lib/widgets/household_selector.dart`
- `test/widgets/household_selector_test.dart`
- `test/widgets/household_selector_coverage_test.dart`

**Changes**:
- In `HouseholdSelector.build()`, line ~105: change `const TextStyle(fontWeight: FontWeight.w500)` to `TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)` so text is dark in light mode and light in dark mode
- The `Icon(Icons.home)` and `Icon(Icons.arrow_drop_down)` on lines ~98 and ~108 also have no explicit color — add `color: Theme.of(context).colorScheme.onSurface` to both so the entire row is theme-consistent
- Do NOT change the popup menu item styling (lines 43-91) — only the trigger button row (lines 93-111)

**Tests**:
- Update existing household_selector_test.dart and household_selector_coverage_test.dart
- Add tests verifying the Text widget in the trigger button has a non-null color (check `TextStyle.color` is not null)
- Verify the widget renders correctly in both light and dark themes using `ThemeData.light()` and `ThemeData.dark()`

**Commit**: `fix(17): household dropdown text color respects light/dark theme`

---

#### Task 17.2: Remove QuickEntryMixin and Simplify Form Buttons
**Files**:
- `lib/widgets/dialogs/reading_form_base.dart` (DELETE entire file)
- `lib/widgets/dialogs/electricity_reading_form_dialog.dart`
- `lib/widgets/dialogs/gas_reading_form_dialog.dart`
- `lib/widgets/dialogs/water_reading_form_dialog.dart`
- `lib/widgets/dialogs/heating_reading_form_dialog.dart`
- `test/widgets/electricity_reading_form_dialog_test.dart`
- `test/widgets/dialogs/electricity_reading_form_dialog_test.dart`
- `test/widgets/dialogs/gas_reading_form_dialog_test.dart`
- `test/widgets/dialogs/water_reading_form_dialog_test.dart`
- `test/widgets/dialogs/heating_reading_form_dialog_test.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`

**Changes**:
For each of the 4 reading form dialogs (electricity, gas, water, heating):
1. Remove `with QuickEntryMixin` from the State class declaration
2. Remove `import '../../l10n/app_localizations.dart';` if only used for QuickEntryMixin (check — likely still needed)
3. Remove `import 'reading_form_base.dart';`
4. Remove `@override bool get isEditMode => ...;`
5. Remove `@override void clearValueField() { ... }` method
6. Replace `quickEntryTitle(l10n, addTitle, editTitle)` in the dialog title with a simple ternary: `widget.reading != null ? editTitle : addTitle` (use the same string variables already in scope)
7. Replace `buildQuickEntryActions(l10n, onSavePressed: ..., onCancelPressed: ...)` with a simple 2-button list:
   ```dart
   actions: [
     TextButton(
       onPressed: () => Navigator.of(context).pop(),
       child: Text(l10n.cancel),
     ),
     FilledButton(
       onPressed: _canSave ? () => _onSave() : null,
       child: Text(l10n.save),
     ),
   ],
   ```
   (Adapt `_canSave` and `_onSave` to match each dialog's existing validation/save logic)
8. Remove `handlePostSave()` call from the save method — just close the dialog with `Navigator.of(context).pop(result)` after saving
9. Remove `buildSuccessIndicator(l10n)` widget if present in the dialog body

Then:
- DELETE `lib/widgets/dialogs/reading_form_base.dart`
- Remove ARB keys from both `app_en.arb` and `app_de.arb`:
  - `"saveAndNext"` and its description
  - `"addReadingCount"` and its `@addReadingCount` metadata
  - `"saved"` (if only used by QuickEntryMixin success indicator — verify first)

**Tests**:
- Update all form dialog tests: remove any "Save & Next" button assertions
- Add test for each dialog: verify only Cancel and Save buttons are shown in add mode
- Add test for each dialog: verify only Cancel and Save buttons are shown in edit mode
- Verify save still works correctly (returns reading data)
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after ARB changes to regenerate l10n

**Commit**: `refactor(17): remove QuickEntryMixin, simplify form buttons to Cancel+Save`

---

#### Task 17.3: Remove CSV Export Feature Entirely
**Files**:
- `lib/services/csv_export_service.dart` (DELETE)
- `lib/services/share_service.dart` (DELETE)
- `lib/screens/monthly_analytics_screen.dart` (remove export button + import)
- `lib/screens/yearly_analytics_screen.dart` (remove export button + import)
- `test/services/csv_export_service_test.dart` (DELETE)
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`
- `pubspec.yaml` (remove `csv` dependency)

**Changes**:
1. DELETE `lib/services/csv_export_service.dart`
2. DELETE `lib/services/share_service.dart`
3. DELETE `test/services/csv_export_service_test.dart`
4. In `lib/screens/monthly_analytics_screen.dart`:
   - Remove `import '../services/csv_export_service.dart';`
   - Remove `import '../services/share_service.dart';`
   - Remove the export IconButton from the AppBar actions (line ~85-86, the `Icons.file_download` button)
   - Remove the `_exportMonthlyCsv()` method entirely (lines ~114-128)
5. In `lib/screens/yearly_analytics_screen.dart`:
   - Remove `import '../services/csv_export_service.dart';`
   - Remove `import '../services/share_service.dart';`
   - Remove the export IconButton from the AppBar actions (line ~58-59, the `Icons.file_download` button)
   - Remove the `_exportCsv()` method entirely (lines ~166-180)
6. In `pubspec.yaml`: remove `csv: ^6.0.0` from dependencies (keep `share_plus` — used by backup_restore_service)
7. Remove ARB keys from both `app_en.arb` and `app_de.arb`:
   - `"exportCsv"` and any description
   - Do NOT remove `"exportAll"` or `"exportSuccess"` yet — `analytics_screen.dart` still references them (deleted in Task 17.4)
   - Keep `"analyticsHub"`, `"consumptionOverview"`, `"smartPlugAnalytics"`, `"consumptionByPlug"` (still used until Task 17.4 removes AnalyticsScreen)
8. Run `flutter pub get` after pubspec changes

**Tests**:
- Update `test/screens/monthly_analytics_screen_test.dart`: remove any test that taps the export button or expects CSV output
- Update `test/screens/yearly_analytics_screen_test.dart`: same
- Verify no remaining imports of csv_export_service or share_service in production code (except backup uses share_plus directly, not ShareService)

**Commit**: `feat(17): remove CSV export feature — delete service, buttons, and csv dependency`

---

### Wave 2: Home Screen Overhaul (depends on Wave 1 completing Task 17.3)

#### Task 17.4: Remove Bottom Nav, Remove Analyse Tile, Reorder Tiles, Delete AnalyticsScreen
**Files**:
- `lib/main.dart`
- `lib/screens/analytics_screen.dart` (DELETE)
- `test/screens/analytics_screen_test.dart` (DELETE)
- `test/widget_test.dart` (if it references HomeScreen/bottom nav)
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`

**Changes**:
In `lib/main.dart`:
1. Remove `import 'screens/analytics_screen.dart';` (line ~30)
2. Remove `_currentIndex` state variable (line ~282)
3. Remove `_onBottomNavTap()` method entirely (lines ~284-324)
4. Remove the `bottomNavigationBar: GlassBottomNav(...)` from the Scaffold (lines ~366-391)
5. In `_buildHomeHub()`, replace the `GridView.count` children list — remove the Analyse tile (6th tile, lines ~465-472) and reorder the remaining 5 tiles:
   ```dart
   children: [
     // Row 1
     _buildCategoryCard(context, icon: Icons.electric_bolt, label: l10n.electricity, color: AppColors.electricityColor, onTap: () => _navigateToScreen(const ElectricityScreen())),
     _buildCategoryCard(context, icon: Icons.power, label: l10n.smartPlugs, color: AppColors.electricityColor, onTap: () => _navigateToScreen(const SmartPlugsScreen())),
     // Row 2
     _buildCategoryCard(context, icon: Icons.local_fire_department, label: l10n.gas, color: AppColors.gasColor, onTap: () => _navigateToScreen(const GasScreen())),
     _buildCategoryCard(context, icon: Icons.thermostat, label: l10n.heating, color: AppColors.heatingColor, onTap: () => _navigateToScreen(const HeatingScreen())),
     // Row 3 (single centered tile)
     _buildCategoryCard(context, icon: Icons.water_drop, label: l10n.water, color: AppColors.waterColor, onTap: () => _navigateToScreen(const WaterScreen())),
   ],
   ```
   Note the new order: Electricity, Smart Home, Gas, Heating, Water (5 tiles). The GridView with crossAxisCount: 2 will naturally place the 5th tile left-aligned. To center the last tile, wrap it in a `Center` widget, or better: keep the GridView.count for the first 4 tiles and add the 5th tile separately below as a centered single card with constrained width matching the grid tile width.
6. Since `_currentIndex` and `_onBottomNavTap` are removed, the class can also become a StatelessWidget if no other state remains. If `_navigateToScreen` and `_navigateToSettings` don't need State, convert to StatelessWidget. Otherwise keep as StatefulWidget but remove the unused state.
7. Remove unused import for `AnalyticsScreen`

Then:
- DELETE `lib/screens/analytics_screen.dart`
- DELETE `test/screens/analytics_screen_test.dart`
- Remove ARB keys no longer used:
  - `"exportAll"` and `"exportSuccess"` — were deferred from Task 17.3 since analytics_screen.dart referenced them; now safe to remove
  - `"consumptionOverview"` — only used in AnalyticsScreen (now deleted)
  - Do NOT remove `"analyticsHub"` — still used as tooltip in electricity_screen.dart:52, gas_screen.dart:52, water_screen.dart:55, heating_screen.dart:56 (removed in Phases 19-22)
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after ARB changes

**Tests**:
- Update `test/widget_test.dart` if it tests the HomeScreen (remove bottom nav assertions, update tile count to 5)
- Add new test: verify HomeScreen shows exactly 5 tiles in correct order (Strom, Smart Home, Gas, Heizung, Wasser)
- Add new test: verify no GlassBottomNav widget exists on home screen
- Add new test: verify Wasser tile is visually centered (check the layout — may need to verify the parent widget is a Center or the tile is properly positioned)
- Add new test: verify tapping each tile navigates to the correct screen

**Commit**: `feat(17): overhaul home screen — remove bottom nav, remove Analyse, reorder tiles`

---

### Wave 3: Global Date/Time Format (independent of Waves 1-2, but logically last for clean diffs)

#### Task 17.5: Add dateTime() Method and Apply Global Date Format
**Files**:
- `lib/services/number_format_service.dart`
- `lib/screens/electricity_screen.dart`
- `lib/screens/gas_screen.dart`
- `lib/screens/water_screen.dart`
- `lib/screens/heating_screen.dart`
- `test/services/number_format_service_test.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`

**Changes**:
1. In `lib/services/number_format_service.dart`, add a new `dateTime()` method:
   ```dart
   /// Format a date and time value.
   ///
   /// DE: "09.03.2026, 14:30 Uhr" | EN: "09.03.2026, 14:30"
   static String dateTime(DateTime dt, String locale) {
     final datePart = DateFormat('dd.MM.yyyy', locale).format(dt);
     final timePart = DateFormat('HH:mm', locale).format(dt);
     if (locale == 'de') {
       return '$datePart, $timePart Uhr';
     } else {
       return '$datePart, $timePart';
     }
   }
   ```
   Note: Use `HH:mm` (24-hour, zero-padded) for both locales in dateTime, unlike the existing `time()` method which uses `H:mm` for DE. The spec says "HH:mm Uhr".

2. In each of the 4 meter screens (electricity, gas, water, heating), find every `DateFormat('dd.MM.yyyy HH:mm')` usage and replace with `ValtraNumberFormat.dateTime(timestamp, locale)`:
   - `electricity_screen.dart` lines ~218 and ~333: replace `dateFormatter.format(reading.timestamp)` with `ValtraNumberFormat.dateTime(reading.timestamp, locale)` (get `locale` from `context.read<LocaleProvider>().localeString`)
   - `gas_screen.dart` lines ~219 and ~337: same pattern
   - `water_screen.dart` lines ~303 and ~435: same pattern
   - `heating_screen.dart` lines ~374 and ~510: same pattern
   - Add `import '../services/number_format_service.dart';` and `import '../providers/locale_provider.dart';` if not already present
   - Remove `import 'package:intl/intl.dart';` if no longer used in the file (check for other DateFormat usages)

3. Add ARB key for "Uhr" suffix (optional — only needed if we want to localize via ARB instead of hardcoding in the service). The CONTEXT.md says "Uhr" is localized. Add:
   - `app_de.arb`: `"timeSuffix": "Uhr"`
   - `app_en.arb`: `"timeSuffix": ""`
   However, since the service already hardcodes the locale check, this ARB key is not strictly needed. Use Claude's discretion: keep the hardcoded approach in the service (simpler, no l10n dependency in service layer). Do NOT add the ARB key.

**Tests**:
- In `test/services/number_format_service_test.dart`:
  - Add test group for `ValtraNumberFormat.dateTime()`:
    - DE: `dateTime(DateTime(2026, 3, 9, 14, 30), 'de')` returns `"09.03.2026, 14:30 Uhr"`
    - EN: `dateTime(DateTime(2026, 3, 9, 14, 30), 'en')` returns `"09.03.2026, 14:30"`
    - Edge case: midnight `dateTime(DateTime(2026, 1, 1, 0, 0), 'de')` returns `"01.01.2026, 00:00 Uhr"`
    - Single-digit hour: `dateTime(DateTime(2026, 3, 9, 9, 5), 'de')` returns `"09.03.2026, 09:05 Uhr"`
- Update screen tests if any assert on the old date format string (search for "dd.MM.yyyy HH:mm" in test files)

**Commit**: `feat(17): global date/time format "dd.MM.yyyy, HH:mm Uhr" with locale support`

---

### Wave 4: Final Verification

#### Task 17.6: Integration Testing & Full Suite Verification
**Files**:
- No new production files
- All test files (read-only verification)

**Changes**:
1. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate l10n files after all ARB changes
2. Run `flutter analyze` — fix ANY issues (warnings, errors, info)
3. Run `flutter test` — ALL tests must pass (should be 1017+ minus deleted CSV tests, plus new tests)
4. Verify no remaining references to deleted files:
   - `grep -r "csv_export_service" lib/` should return nothing
   - `grep -r "share_service" lib/` should return nothing (except backup_restore_service.dart which uses share_plus directly)
   - `grep -r "reading_form_base" lib/` should return nothing
   - `grep -r "analytics_screen" lib/` should return nothing (except monthly/yearly/smart_plug analytics which are kept)
   - `grep -r "QuickEntryMixin" lib/` should return nothing
   - `grep -r "saveAndNext" lib/` should return nothing
5. Check that `analyticsHub` key removal didn't break anything — if any screen still uses `l10n.analyticsHub`, re-add it to ARBs
6. Run `flutter test --coverage` to verify coverage does not drop significantly

**Tests**:
- `flutter test` passes (all tests green)
- `flutter analyze` passes (zero issues)
- Manual grep checks confirm no dead code references

**Commit**: `test(17): verify full test suite and zero analyze issues after phase 17`

---

## Risk Mitigation

1. **ARB key removal may break generated l10n code**: Always run `flutter pub run build_runner build --delete-conflicting-outputs` after modifying ARB files, before running tests. If generated files reference removed keys, the build step will catch it.

2. **QuickEntryMixin removal may miss a dialog**: The smart_plug_consumption_form_dialog does NOT use QuickEntryMixin (confirmed). Only electricity, gas, water, and heating form dialogs need changes.

3. **share_plus must NOT be removed from pubspec**: backup_restore_service.dart uses `share_plus` directly (not via ShareService). Only the `csv` package can be removed.

4. **Centered Wasser tile**: A GridView.count with 5 items and crossAxisCount=2 places the 5th item left-aligned. For centering, either: (a) replace GridView.count with a Column of Rows + a centered single Row for the last tile, or (b) add a transparent/invisible 6th placeholder tile. Option (a) is cleaner.

5. **DateFormat locale parameter**: The `DateFormat('dd.MM.yyyy', locale)` pattern produces locale-correct results. Verify in tests that the separator is always `.` regardless of locale (intl may try to use `/` for EN — use explicit pattern, not locale-default).

6. **Existing tests referencing deleted widgets/features**: Search test files for `GlassBottomNav`, `analyticsHub`, `exportCsv`, `saveAndNext`, `Save & next`, `Speichern & weiter` — update or remove those assertions.

## Verification Checklist

- [ ] **UAC-M4-1**: Home screen shows dark dropdown text, no bottom nav, 5 tiles in [Strom, Smart Home] [Gas, Heizung] [Wasser centered] order
- [ ] **UAC-M4-9**: All 4 reading form dialogs show only Cancel + Save side-by-side (no "Save & Continue")
- [ ] **UAC-M4-10**: Date/time displays use "dd.MM.yyyy, HH:mm Uhr" (DE) / "dd.MM.yyyy, HH:mm" (EN)
- [ ] **UAC-M4-12**: No CSV export button or functionality exists anywhere
- [ ] **NFR-13**: Visual design unchanged (same GlassCard, colors, icons, layout patterns)
- [ ] **NFR-14**: All new/changed strings localized in both EN and DE ARB files
- [ ] **NFR-15**: All tests pass, deleted features have no orphan tests
- [ ] **NFR-16**: `flutter analyze` returns zero issues, no dead code references
