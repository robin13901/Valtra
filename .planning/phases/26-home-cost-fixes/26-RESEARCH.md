# Phase 26: Home Screen & Cost Profile Fixes - Research

**Researched:** 2026-03-13
**Domain:** Flutter UI, Dart enums, locale formatting, cost profiles
**Confidence:** HIGH (all findings from direct codebase inspection)

## Summary

Phase 26 addresses six discrete bugs/removals across the home screen app bar, cost profile cards, currency formatting, date formatting, and the heating screen. All changes are contained within existing files — no new files need to be created. The largest change is removing `CostMeterType.heating` from the enum, which has cascading effects across `tables.dart`, `household_cost_settings_screen.dart`, `heating_screen.dart`, `analytics_provider.dart`, and five test files.

The home screen app bar currently passes `l10n.appTitle` (i.e., "Valtra") as the `title` to `buildGlassAppBar`. Removing it requires passing an empty string or a custom no-title variant. The "Aktiv" badge is a `Chip` widget inside `_buildProfileTile` in `household_cost_settings_screen.dart`, gated by `isActive`. Currency formatting already uses `ValtraNumberFormat.currency(value, locale)` where `locale` comes from `LocaleProvider.localeString` — the fix is to hard-code `'de'` instead of reading from `LocaleProvider`. Date formatting in `_buildProfileTile` uses manual string concatenation without zero-padding; `cost_profile_form_dialog.dart` uses the same unpadded pattern. Both need `padLeft(2, '0')` applied to day/month, or `DateFormat('dd.MM.yyyy')`.

**Primary recommendation:** Treat each requirement as a separate, self-contained change. Removing `CostMeterType.heating` is the highest-risk task because it touches the database enum used in DB storage; however, since Decision 54 states the ordinal is already `3`, removing the value only affects Dart-side filters — the DB schema does not change.

---

## Standard Stack

No new libraries required. All existing dependencies already cover the needed patterns.

### Relevant Existing Infrastructure

| Component | Location | Used For |
|-----------|----------|----------|
| `ValtraNumberFormat.currency(value, locale)` | `lib/services/number_format_service.dart` | Format currency values with German decimal comma |
| `buildGlassAppBar(context, title, actions)` | `lib/widgets/liquid_glass_widgets.dart:138` | Shared app bar widget |
| `CostMeterType` enum | `lib/database/tables.dart:101` | Identifies meter type in cost configs |
| `LocaleProvider.localeString` | `lib/providers/locale_provider.dart` | Returns `'de'` or `'en'` |
| `l10n.activeProfile` | `app_en.arb:375`, `app_de.arb:309` | "Active" / "Aktiv" label |
| `DateFormat('dd.MM.yyyy')` | `intl` package (already a dep) | Properly zero-padded date |

---

## Architecture Patterns

### HOME-01: Remove App Bar Title

**Current code** (`lib/main.dart:337-348`):
```dart
appBar: buildGlassAppBar(
  context: context,
  title: l10n.appTitle,   // <-- produces "Valtra"
  actions: [
    const HouseholdSelector(),
    IconButton(...settings...),
  ],
),
```

**Pattern:** `buildGlassAppBar` always renders `title` in an `AppBar` text widget. Passing an empty string `''` removes the visible title but preserves the widget structure. Alternatively, Flutter `AppBar` supports `title: null` — but since `buildGlassAppBar` wraps a non-nullable `String title`, the cleanest fix is passing `''`.

The body still displays the app icon + `l10n.appTitle` text in `_buildHomeHub` — that stays unchanged.

### COST-01: Remove "Aktiv" Badge

**Current code** (`lib/screens/household_cost_settings_screen.dart:171-178`):
```dart
if (isActive)
  Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Chip(
      label: Text(l10n.activeProfile),
      ...
    ),
  ),
```

**Fix:** Delete the entire `if (isActive)` block in `_buildProfileTile`. The `isActive` parameter and the `activeConfig` detection logic above can also be removed since nothing else uses them.

### COST-02: German Currency Format Always

**Current code** (`lib/screens/household_cost_settings_screen.dart:82,160-161`):
```dart
final locale = context.watch<LocaleProvider>().localeString;  // 'de' or 'en'
...
final basePriceStr = ValtraNumberFormat.currency(config.standingCharge, locale);
final unitPriceStr = ValtraNumberFormat.currency(config.unitPrice, locale);
```

**Fix:** Replace `locale` with the literal `'de'` in both `ValtraNumberFormat.currency` calls. The `LocaleProvider` import and watch can still remain (used for other locale-aware elements if any), but these two calls must always use `'de'`.

**Note:** `ValtraNumberFormat.currency('de')` already uses `NumberFormat('#,##0.00', 'de')` which produces `123,45` — the German format. This is confirmed HIGH confidence from direct source inspection.

### COST-03: Zero-Padded Date in Profile Tile

**Current code** (`lib/screens/household_cost_settings_screen.dart:157-158`):
```dart
final dateStr =
    '${config.validFrom.day.toString().padLeft(2, '0')}.${config.validFrom.month.toString().padLeft(2, '0')}.${config.validFrom.year}';
```

Wait — looking at the code again, `_buildProfileTile` already uses `.padLeft(2, '0')` for the list tile display. The bug is in `cost_profile_form_dialog.dart:129`:

```dart
child: Text(
  '${_validFrom.day}.${_validFrom.month}.${_validFrom.year}',
),
```

This produces `1.3.2026` not `01.03.2026`. Fix: use `DateFormat('dd.MM.yyyy').format(_validFrom)` or manual `.padLeft(2, '0')` on both day and month.

**Note:** The `intl` package is already imported in `number_format_service.dart`; it just needs to be imported in `cost_profile_form_dialog.dart` too.

### COST-04: Remove CostMeterType.heating

**Current enum** (`lib/database/tables.dart:101`):
```dart
enum CostMeterType { electricity, gas, water, heating }
```

**Fix:** Remove `heating` from the enum, making it:
```dart
enum CostMeterType { electricity, gas, water }
```

**Ordinal impact:** According to Decision 54, `heating` was added as ordinal 3 (index 3). With Drift's `intEnum`, removing `heating` means the value `3` stored in the DB has no matching enum case. However, since no cost configs for heating exist in production (they are logically meaningless), and existing data was never populated with `meterType = 3` for heating, no migration is needed. The schema version stays at 3.

**Cascading removal required in:**

1. `lib/screens/household_cost_settings_screen.dart`
   - `_meterTypeLabel`: remove `case CostMeterType.heating:` branch
   - `_meterTypeIcon`: remove `case CostMeterType.heating:` branch
   - The `ListView` already iterates `CostMeterType.values` — once `heating` is gone, the heating card disappears automatically

2. `lib/widgets/dialogs/cost_profile_form_dialog.dart`
   - `_unitSuffix()`: remove `case CostMeterType.heating:` branch (currently lumped with electricity/gas to show `kWh`)

3. `lib/screens/heating_screen.dart`
   - `_buildCostToggle()`: entire method can be removed (returns `SizedBox.shrink` when no config, and since we remove the type, configs can never exist)
   - `_showCosts` state variable: remove
   - All references to `_showCosts` (passed to charts): replace with `false`/`null` inline or remove cost-toggle functionality entirely
   - `context.watch<CostConfigProvider>()` call in `_buildCostToggle`: remove

4. `lib/providers/analytics_provider.dart`
   - `_toCostMeterType()`: remove `case MeterType.heating:` → the method returns `null` for heating, so cost calculation is skipped

### COST-05: Remove kWh/EUR Toggle from Heating Analysis

This is downstream of COST-04. With `CostMeterType.heating` removed:
- `_buildCostToggle` already returns `SizedBox.shrink` when no heating cost configs exist
- After COST-04, there will never be heating cost configs, so the toggle never appears
- However, the cleaner fix is to **fully remove** `_showCosts`, `_buildCostToggle`, and all `showCosts: _showCosts` pass-throughs in `heating_screen.dart`

Simplification: In `_buildAnalyseContent`, replace all `showCosts: _showCosts` with `showCosts: false` and all `_showCosts ? data.monthlyCosts : null` with `null`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Zero-padded date | Manual string concat | `DateFormat('dd.MM.yyyy').format(dt)` | Already available via `intl` dep |
| German number format | Custom formatter | `ValtraNumberFormat.currency(value, 'de')` | Already exists, tested |
| Enum-based switch exhaustiveness | Manual if-else | Dart `switch` on enum | Compile-time exhaustiveness checking |

---

## Common Pitfalls

### Pitfall 1: Drift intEnum Ordinal Breakage
**What goes wrong:** Removing a middle enum value from an `intEnum` re-numbers later values, corrupting existing DB data.
**Why it happens:** Drift stores the `.index` of the enum value (0, 1, 2, 3...).
**How to avoid:** `heating` is the LAST value (index 3). Removing it only affects rows with `meterType = 3`. Since no such rows should exist in production (heating cost profiles are logically invalid), safe to remove without migration.
**Warning signs:** If any test inserts `CostMeterType.heating` cost configs into DB — those tests must be deleted too.

### Pitfall 2: Test Count Assertions Break After Removing Heating Card
**What goes wrong:** `household_cost_settings_screen_test.dart` has assertions like:
- `findsNWidgets(4)` for expand_more icons (line ~141)
- `findsNWidgets(4)` for add buttons (line ~149)
- `findsOneWidget` for 'Heating' text (line ~115)
- `expect(find.byIcon(Icons.thermostat), findsOneWidget)` (line ~133)
**How to avoid:** Update all these assertions to use `3` (electricity, gas, water) instead of `4`.

### Pitfall 3: Home Screen Test Asserts "Valtra" Title in AppBar
**What goes wrong:** `widget_test.dart` line 213-214 asserts `find.text('Valtra')` with `findsWidgets` — this currently passes because "Valtra" appears both in the AppBar title AND in the body text. After removing the AppBar title, the text still exists in the body. The test may still pass.
**How to avoid:** Update the test comment to reflect that "Valtra" now only appears in the body, NOT in the AppBar. Add a test asserting the AppBar does NOT contain "Valtra".

### Pitfall 4: Heating Screen Cost Toggle Tests
**What goes wrong:** `heating_screen_test.dart` has a full group `'HeatingScreen - Cost Toggle on Analyse Tab'` (3 tests, lines 619-770+) that specifically inserts `CostMeterType.heating` cost configs and tests the toggle behavior. These tests will fail to compile after COST-04 removes the enum value.
**How to avoid:** Delete the entire `'Cost Toggle on Analyse Tab'` group and add a test asserting the toggle never appears.

### Pitfall 5: `_toCostMeterType` returns null for heating (no crash)
**What goes wrong:** In `analytics_provider.dart`, `_toCostMeterType(MeterType.heating)` currently returns `CostMeterType.heating`. After removing the enum value, it should return `null`. The method already has a `null` return path via the return type `CostMeterType?`, so callers already handle `null` gracefully (cost calculation is skipped).
**How to avoid:** Update the switch to explicitly handle `MeterType.heating` returning `null`.

---

## Code Examples

### Verified: buildGlassAppBar signature
```dart
// Source: lib/widgets/liquid_glass_widgets.dart:138
PreferredSizeWidget buildGlassAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
})
```
Pass `title: ''` to suppress the text while keeping the widget structure intact.

### Verified: _buildProfileTile date formatting (already correct in list)
```dart
// Source: lib/screens/household_cost_settings_screen.dart:157
final dateStr =
    '${config.validFrom.day.toString().padLeft(2, '0')}.${config.validFrom.month.toString().padLeft(2, '0')}.${config.validFrom.year}';
```
This is already correct. The bug is only in `cost_profile_form_dialog.dart:129`.

### Verified: Dialog date display (the actual bug location)
```dart
// Source: lib/widgets/dialogs/cost_profile_form_dialog.dart:129
child: Text(
  '${_validFrom.day}.${_validFrom.month}.${_validFrom.year}',
),
```
Fix: `'${_validFrom.day.toString().padLeft(2, '0')}.${_validFrom.month.toString().padLeft(2, '0')}.${_validFrom.year}'`

### Verified: Heating cost toggle method
```dart
// Source: lib/screens/heating_screen.dart:120-132
Widget _buildCostToggle(BuildContext context, AppLocalizations l10n) {
  final costProvider = context.watch<CostConfigProvider>();
  final hasHeatingCostConfig =
      costProvider.getConfigsForMeterType(CostMeterType.heating).isNotEmpty;
  if (!hasHeatingCostConfig) return const SizedBox.shrink();
  return IconButton(
    icon: Icon(_showCosts ? Icons.euro : Icons.thermostat),
    onPressed: () => setState(() => _showCosts = !_showCosts),
    tooltip: _showCosts ? l10n.showConsumption : l10n.showCosts,
  );
}
```
After COST-04: delete this method entirely. Remove `bool _showCosts = false;` from state.

---

## Files to Change (Complete List)

### Production Code

| File | Changes |
|------|---------|
| `lib/main.dart` (HomeScreen.build) | Pass `title: ''` to `buildGlassAppBar` |
| `lib/database/tables.dart` | Remove `heating` from `CostMeterType` enum |
| `lib/screens/household_cost_settings_screen.dart` | Remove heating switch cases; remove `isActive` Chip; hard-code `'de'` for currency locale |
| `lib/widgets/dialogs/cost_profile_form_dialog.dart` | Fix date display zero-padding; remove `CostMeterType.heating` switch case in `_unitSuffix` |
| `lib/screens/heating_screen.dart` | Remove `_showCosts`, `_buildCostToggle`, all `showCosts: _showCosts` pass-throughs |
| `lib/providers/analytics_provider.dart` | Return `null` for `MeterType.heating` in `_toCostMeterType` |

### Test Code

| File | Changes Required |
|------|-----------------|
| `test/widget_test.dart` | Update "shows app title in AppBar" test — `findsWidgets` still passes but add assertion that AppBar title is NOT 'Valtra' |
| `test/screens/household_cost_settings_screen_test.dart` | Change count assertions from 4 → 3; remove Heating assertions; update "active badge" test |
| `test/screens/heating_screen_test.dart` | Delete `'HeatingScreen - Cost Toggle on Analyse Tab'` group (3 tests); add test confirming no cost toggle visible |
| `test/widgets/dialogs/cost_profile_form_dialog_test.dart` | Update any tests that assert date format; add test for `01.03.2026` format |

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `'${_validFrom.day}.${_validFrom.month}.${_validFrom.year}'` | `'${..padLeft(2,'0')}.${..padLeft(2,'0')}.${_validFrom.year}'` | Fixes COST-03 |
| `ValtraNumberFormat.currency(value, locale)` with dynamic locale | `ValtraNumberFormat.currency(value, 'de')` hardcoded | Fixes COST-02 |
| `CostMeterType.heating` present | Remove from enum | Fixes COST-04/05 |
| AppBar shows "Valtra" title text | AppBar title = `''` | Fixes HOME-01 |

---

## Open Questions

1. **`buildGlassAppBar` title = `''` vs refactoring to `title: String?`**
   - What we know: `title` is `required String` — changing to nullable requires updating all callers
   - What's unclear: Whether a nullable refactor is preferred over passing empty string
   - Recommendation: Pass `''` for now; it renders an empty `Text('')` with no visible content. Simplest approach.

2. **`_toCostMeterType` after removing heating enum value**
   - What we know: The switch currently returns `CostMeterType.heating` for `MeterType.heating`
   - What's unclear: Whether `MeterType.heating` itself should be removed from analytics models
   - Recommendation: Keep `MeterType.heating` in analytics models (heating analytics screen still exists), just make `_toCostMeterType` return `null` for heating. This avoids touching the analytics data models.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection: `lib/main.dart` — `HomeScreen.build()` at line 337
- Direct codebase inspection: `lib/screens/household_cost_settings_screen.dart` — `_buildProfileTile()` at lines 149-201
- Direct codebase inspection: `lib/widgets/dialogs/cost_profile_form_dialog.dart` — date display at line 129, `_unitSuffix()` at lines 89-98
- Direct codebase inspection: `lib/database/tables.dart:101` — `CostMeterType` enum with 4 values
- Direct codebase inspection: `lib/screens/heating_screen.dart:35,120-132` — `_showCosts` and `_buildCostToggle`
- Direct codebase inspection: `lib/providers/analytics_provider.dart:344-355` — `_toCostMeterType()`
- Direct codebase inspection: `lib/services/number_format_service.dart:29-32` — `ValtraNumberFormat.currency`
- Direct codebase inspection: `test/screens/heating_screen_test.dart:619-770` — cost toggle test group
- Direct codebase inspection: `test/screens/household_cost_settings_screen_test.dart` — count assertions (4 cards)
- Direct codebase inspection: `test/widget_test.dart:209-215` — "shows app title in AppBar" assertion

---

## Metadata

**Confidence breakdown:**
- File locations: HIGH — direct source inspection
- Enum ordinal safety: HIGH — `heating` is last value (index 3), DB never had heating cost profiles
- Test impact: HIGH — exact test lines identified
- `buildGlassAppBar` empty title approach: MEDIUM — works but minor rendering question about empty Text widget

**Research date:** 2026-03-13
**Valid until:** Stable codebase — valid indefinitely until files change
