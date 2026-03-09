# Phase 18 Plan — Cost Settings & Household Configuration

## Goal
Restructure cost configuration to support per-household cost profile history with proper German energy naming conventions (Grundpreis/Arbeitspreis), move cost settings from global settings into household-specific settings, and implement expandable card UI with date-based cost lookup.

## Success Criteria
- Multiple cost profiles per meter type per household with date-based history (FR-16.1)
- Field labels: "Grundpreis pro Jahr" + "Arbeitspreis" (DE); "Annual Base Price" + "Energy Price" (EN) (FR-16.2)
- Cost calculation uses annual Grundpreis ÷ 12 for monthly pro-ration (FR-16.3)
- Form field order: Gültig ab → Grundpreis pro Jahr → Arbeitspreis (FR-16.4)
- Expandable card UI per meter type with cost profile sub-entries (FR-16.5)
- Cost config moved from global settings to household-specific settings (FR-16.6)
- Date-based cost lookup: correct profile used for each time period (FR-16.7)
- All strings localized EN + DE (NFR-14)
- All existing + new tests pass, zero flutter analyze issues (NFR-15)

---

## Task Breakdown

### Wave 1: Calculation Logic & Localization (2 parallel tasks)

No UI changes — pure logic and string changes.

#### Task 18.1: Update Cost Calculation for Annual Grundpreis
**Files**:
- `lib/providers/cost_config_provider.dart`
- `test/providers/cost_config_provider_test.dart`

**Changes**:
The `standingCharge` DB column now stores **annual** Grundpreis instead of monthly Grundgebühr. The CostCalculationService's pro-ration logic (`standingCharge * daysInPeriod / daysInMonth`) already handles partial-month scaling — we just need to divide by 12 before passing it to the service.

1. In `CostConfigProvider.calculateCost()` (line 83-91), change:
   ```dart
   standingCharge: config.standingCharge,
   ```
   to:
   ```dart
   standingCharge: config.standingCharge / 12,
   ```
   This converts the annual Grundpreis to a monthly base for the existing pro-ration logic.

2. Do NOT modify `CostCalculationService.calculateMonthlyCost()` — it remains a pure function that takes a monthly standing charge. The annual→monthly conversion is the caller's responsibility.

**Tests**:
- Update `cost_config_provider_test.dart`: adjust all `calculateCost` test expectations to account for the ÷12 division
- Add test: "calculateCost divides annual standing charge by 12" — verify that a config with standingCharge=120.0 produces standingCost=10.0 for a full month
- Add test: "calculateCost pro-rates annual standing charge for partial month" — verify 120.0 annual → 10.0/month → ~5.0 for 15-day period in a 30-day month

**Commit**: `feat(18): convert cost calculation to use annual Grundpreis (÷12)`

---

#### Task 18.2: Rename Localization Strings
**Files**:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`

**Changes**:
Rename and add localization keys for the new field names and UI elements:

1. **Rename existing keys** (update values, keep keys for backward compat, or rename if no external refs):
   - `"unitPrice"`: EN `"Energy Price"` → DE `"Arbeitspreis"`
   - `"standingChargePerMonth"`: **Rename key** to `"annualBasePrice"`: EN `"Annual Base Price"` → DE `"Grundpreis pro Jahr"`
   - `"perMonth"`: **Rename key** to `"perYear"`: EN `"per year"` → DE `"pro Jahr"`

2. **Add new keys**:
   - `"costProfile"`: EN `"Cost Profile"` → DE `"Kostenprofil"`
   - `"addCostProfile"`: EN `"Add Cost Profile"` → DE `"Kostenprofil hinzufügen"`
   - `"editCostProfile"`: EN `"Edit Cost Profile"` → DE `"Kostenprofil bearbeiten"`
   - `"noCostProfiles"`: EN `"No cost profiles configured"` → DE `"Keine Kostenprofile konfiguriert"`
   - `"householdSettings"`: EN `"Household Settings"` → DE `"Haushalt-Einstellungen"`
   - `"costProfiles"`: EN `"Cost Profiles"` → DE `"Kostenprofile"`
   - `"activeProfile"`: EN `"Active"` → DE `"Aktiv"`
   - `"profileValidFrom"`: EN `"Valid from {date}"` → DE `"Gültig ab {date}"` (with `@profileValidFrom` metadata for the `date` parameter)

3. **Update `costNotConfigured` string** (currently references "Settings"):
   - EN: `"Configure pricing in Household Settings to see costs"` (was: "Configure pricing in Settings to see costs")
   - DE: `"Preise in Haushalt-Einstellungen konfigurieren, um Kosten zu sehen"` (was: "Preise in Einstellungen konfigurieren, um Kosten zu sehen")

4. **DO NOT remove old keys yet** — `"standingChargePerMonth"`, `"perMonth"`, and `"standingCharge"` are still referenced by `_CostConfigCard` in `settings_screen.dart` until Task 18.5 removes that widget. Mark them for removal in Task 18.5 instead.

5. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate l10n

**Tests**:
- No test file changes needed for localization alone — tests will be updated in subsequent tasks

**Commit**: `feat(18): rename cost field labels — Arbeitspreis + Grundpreis pro Jahr`

---

### Wave 2: Household Cost Settings Screen (depends on Wave 1)

#### Task 18.3: Create Cost Profile Form Dialog
**Files**:
- `lib/widgets/dialogs/cost_profile_form_dialog.dart` (NEW)
- `test/widgets/dialogs/cost_profile_form_dialog_test.dart` (NEW)

**Changes**:
Create a new form dialog following the established pattern (see `water_meter_form_dialog.dart`):

```dart
class CostProfileFormDialog extends StatefulWidget {
  final CostConfig? config;          // null = create, non-null = edit
  final CostMeterType meterType;
  final int householdId;

  static Future<CostProfileFormData?> show(
    BuildContext context, {
    CostConfig? config,
    required CostMeterType meterType,
    required int householdId,
  }) { ... }
}

class CostProfileFormData {
  final DateTime validFrom;
  final double annualBasePrice;
  final double energyPrice;
}
```

**Form field order** (FR-16.4):
1. **Gültig ab / Valid From** — date picker (InkWell + InputDecorator), default: 1st of current month
2. **Grundpreis pro Jahr / Annual Base Price** — TextField, decimal, suffix "€/Jahr" / "€/year", validate > 0
3. **Arbeitspreis / Energy Price** — TextField, decimal, suffix from `_unitSuffix()` (€/kWh or €/m³), validate > 0

**Dialog buttons**: Cancel + Save (following Phase 17 pattern)

**Mapping to DB fields**:
- `validFrom` → `CostConfig.validFrom`
- `annualBasePrice` → `CostConfig.standingCharge` (DB stores annual value)
- `energyPrice` → `CostConfig.unitPrice`

**Tests** (in `cost_profile_form_dialog_test.dart`):
- Renders all 3 fields in correct order
- Date picker opens and updates displayed date
- Validation: empty fields show error, negative values rejected
- Create mode: returns CostProfileFormData on save
- Edit mode: pre-fills fields from existing CostConfig
- Cancel: returns null
- Verify field labels use localized strings

**Commit**: `feat(18): add cost profile form dialog with Gültig ab, Grundpreis, Arbeitspreis`

---

#### Task 18.4: Create Household Cost Settings Screen
**Files**:
- `lib/screens/household_cost_settings_screen.dart` (NEW)
- `test/screens/household_cost_settings_screen_test.dart` (NEW)

**Changes**:
Create a new screen following the water screen expandable card pattern:

```dart
class HouseholdCostSettingsScreen extends StatelessWidget {
  const HouseholdCostSettingsScreen({super.key});
  // Build Scaffold with AppBar "Cost Profiles" / "Kostenprofile"
  // Body: ListView with one _CostMeterTypeCard per CostMeterType.values
}
```

**`_CostMeterTypeCard`** — expandable card per meter type (FR-16.5):
- **Header** (always visible): GlassCard with InkWell
  - Icon (electric_bolt / fire / water_drop) + meter type label + expand/collapse icon
  - "+" IconButton to add new profile (opens CostProfileFormDialog in create mode)
- **Expanded content**: list of cost profiles for this meter type, ordered by validFrom DESC
  - Each profile as a ListTile:
    - Title: formatted validFrom date (using ValtraNumberFormat.date)
    - Subtitle: "Grundpreis: €X/Jahr · Arbeitspreis: €Y/kWh"
    - Badge: "Aktiv" / "Active" chip on the currently active profile (latest validFrom ≤ now)
    - Trailing: PopupMenuButton with Edit / Delete options
  - Empty state: centered text "Keine Kostenprofile konfiguriert" / "No cost profiles configured"

**Profile CRUD operations** (via CostConfigProvider):
- **Add**: opens CostProfileFormDialog (create mode) → `costProvider.addConfig()`
- **Edit**: opens CostProfileFormDialog (edit mode, passes existing config) → `costProvider.updateConfig()`
- **Delete**: confirmation dialog → `costProvider.deleteConfig()`

**Tests** (in `household_cost_settings_screen_test.dart`):
- Renders one card per meter type (electricity, gas, water)
- Expand/collapse toggles profile list visibility
- Empty state shows "no profiles" message when no configs exist
- Profile list shows correct data (validFrom, prices)
- Active profile badge shown on correct profile
- Add button opens form dialog
- Edit/delete via popup menu work correctly
- Profiles ordered by validFrom DESC

**Commit**: `feat(18): add household cost settings screen with expandable profile cards`

---

### Wave 3: Integration (depends on Wave 2)

#### Task 18.5: Move Cost Config from Global Settings to Household Settings
**Files**:
- `lib/screens/settings_screen.dart`
- `lib/main.dart` (navigation)
- `test/screens/settings_screen_test.dart`
- `test/widget_test.dart` (if applicable)

**Changes**:

1. **Remove cost config section from settings_screen.dart**:
   - Delete `_buildCostConfigSection()` method (lines 189-209)
   - Delete `_CostConfigCard` widget class (lines 452-711)
   - Remove the `_buildCostConfigSection(context, l10n)` call from the ListView children (line 40)
   - Remove `const SizedBox(height: 8)` before it (line 39)
   - Remove `import '../providers/cost_config_provider.dart'` if no longer used
   - Remove `import '../database/tables.dart'` if no longer used
   - Remove `import '../database/app_database.dart'` if no longer used
   - Remove `import 'package:drift/drift.dart' hide Column;` if no longer used

2. **Add navigation to HouseholdCostSettingsScreen**:
   - Add a "Cost Profiles" / "Kostenprofile" ListTile in the settings screen that navigates to the new screen
   - Place it where the cost config section used to be (between meter settings and backup/restore)
   - Use a GlassCard with ListTile: leading Icon(Icons.euro), title "Kostenprofile", trailing chevron_right
   - `onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HouseholdCostSettingsScreen()))`

3. **Clean up obsolete ARB keys** (deferred from Task 18.2):
   - Remove `"standingChargePerMonth"` and its `@standingChargePerMonth` from both `app_en.arb` and `app_de.arb`
   - Remove `"perMonth"` from both ARB files
   - Remove `"standingCharge"` if no longer referenced anywhere
   - Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate l10n

4. **Update household-related data check**:
   - In `lib/database/daos/household_dao.dart`: add CostConfigs to the `@DriftAccessor(tables: [...])` list
   - Add cost config check in `hasRelatedData()`:
     ```dart
     final costCount = await (select(costConfigs)
           ..where((c) => c.householdId.equals(householdId)))
         .get();
     if (costCount.isNotEmpty) return true;
     ```
   - Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate DAO mixin

**Tests**:
- Update settings_screen_test.dart: remove tests for _CostConfigCard, add test for navigation ListTile
- Verify "Kostenprofile" ListTile renders and navigates on tap
- Verify cost config section no longer appears in settings
- Update household_dao_test.dart: add test for hasRelatedData including cost configs

**Commit**: `feat(18): move cost config from global settings to household cost settings screen`

---

### Wave 4: Analytics Integration & Cleanup (depends on Wave 3)

#### Task 18.6: Update Analytics Cost Display Labels
**Files**:
- `lib/providers/analytics_provider.dart`
- `test/providers/analytics_provider_test.dart`

**Changes**:
1. Verify analytics_provider.dart `calculateCost()` calls go through `CostConfigProvider.calculateCost()` — which was updated in Task 18.1 to do ÷12. No direct changes needed here.
2. If any analytics screen shows "Grundgebühr" or "Standing Charge" labels, update to use the new l10n keys.
3. **Update `costNotConfigured` string** — it currently says "Configure pricing in Settings" (EN) / "Preise in Einstellungen konfigurieren" (DE). This was already updated in the ARB files in Task 18.2 to reference "Household Settings" / "Haushalt-Einstellungen". Verify the updated string renders correctly wherever `l10n.costNotConfigured` is used.

**Tests**:
- Verify existing analytics tests still pass with the updated calculation
- No new test files needed

**Commit**: `fix(18): update analytics cost labels and config reference`

---

### Wave 5: Final Verification

#### Task 18.7: Full Test Suite & Analysis
**Files**:
- No new production files
- All test files (verification)

**Changes**:
1. Run `flutter pub run build_runner build --delete-conflicting-outputs` to ensure all generated code is up to date
2. Run `flutter test` — ALL tests must pass
3. Run `flutter analyze` — zero issues
4. Verify no remaining references to old field names:
   - `grep -r "standingChargePerMonth" lib/` should return nothing (only in test mocks if any)
   - `grep -r "Grundgebühr" lib/` should return nothing
   - `grep -r "Preis pro Einheit" lib/` should return nothing
   - `grep -r "perMonth" lib/l10n/` should return nothing
5. Verify cost config is no longer in global settings:
   - `grep -r "_CostConfigCard" lib/` should return nothing
   - `grep -r "_buildCostConfigSection" lib/` should return nothing
6. Verify new screen is properly navigable from settings

**Tests**:
- `flutter test` passes (all tests green)
- `flutter analyze` passes (zero issues)
- Dead code verification via grep

**Commit**: `test(18): verify full test suite and zero analyze issues after phase 18`

---

## Risk Mitigation

1. **Standing charge interpretation change**: Existing cost configs in the database store monthly values. After this change, the same column stores annual values. **Migration strategy**: no DB migration needed — the user simply re-enters their annual Grundpreis in the new form. Since this is a personal app with few entries, manual re-entry is acceptable. Add a note in the form dialog helper text if needed.

2. **ARB key renames may break generated l10n**: Always run `build_runner` after ARB changes. If a key is renamed (e.g., `standingChargePerMonth` → `annualBasePrice`), all usages of `l10n.standingChargePerMonth` must be updated to `l10n.annualBasePrice` in the same commit.

3. **Household DAO regeneration**: Adding CostConfigs to the `@DriftAccessor` tables list requires running `build_runner` to regenerate `household_dao.g.dart`. The generated mixin gains access to the costConfigs table.

4. **CostConfigProvider mock in tests**: The new HouseholdCostSettingsScreen will need a mocked CostConfigProvider in its test setup. Follow the existing pattern from settings_screen_test.dart.

5. **Expanding card state management**: The `_CostMeterTypeCard` uses local `_isExpanded` state. Since it's per-card, no provider needed — simple StatefulWidget with setState.

## Verification Checklist

- [ ] **UAC-M4-2**: Can create multiple cost profiles per meter type per household
- [ ] **UAC-M4-3**: Form labels show "Grundpreis pro Jahr" / "Arbeitspreis" (DE) and "Annual Base Price" / "Energy Price" (EN)
- [ ] **UAC-M4-4**: Cost calculation correctly divides annual Grundpreis by 12 for monthly figures
- [ ] **UAC-M4-5**: Form fields in order: Gültig ab → Grundpreis pro Jahr → Arbeitspreis
- [ ] **UAC-M4-6**: Expandable card UI per meter type with profile sub-entries and active badge
- [ ] **UAC-M4-7**: Cost config is in household settings, NOT in global settings
- [ ] **UAC-M4-8**: Date-based cost lookup uses correct profile for each time period
- [ ] **NFR-14**: All new/changed strings localized in both EN and DE ARB files
- [ ] **NFR-15**: All tests pass, new tests cover cost profile CRUD and date-based lookup
- [ ] **NFR-16**: `flutter analyze` returns zero issues
