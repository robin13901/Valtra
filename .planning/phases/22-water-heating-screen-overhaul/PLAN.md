# Phase 22 Plan — Water & Heating Screen Overhaul

## Goal
Overhaul the water and heating screens to match the bottom navigation architecture from phases 19-20: unified Analyse/Liste tabs via GlassBottomNav, IndexedStack for state preservation, LiquidGlass FAB on Liste only, inline analysis with year navigation, monthly bar chart, year comparison chart, cost toggle (m³/€ for water, kWh/€ for heating), and monthly consumption from interpolated deltas.

## Success Criteria
- Water: bottom nav with Analyse (left) and Liste (right), default Liste (FR-20.1)
- Water: IndexedStack preserves tab state when switching (FR-20.1)
- Water: LiquidGlass FAB visible on Liste tab only, hidden on Analyse (FR-20.1)
- Water: analysis page with year nav, summary, monthly bar chart, year comparison (FR-20.1)
- Water: m³/€ toggle switches all charts between consumption and cost (FR-20.2)
- Water: year comparison chart with correct month alignment (FR-20.2)
- Water: monthly values from interpolated deltas at month boundaries (FR-20.2)
- Heating: identical bottom nav architecture (FR-21.1)
- Heating: kWh/€ toggle for cost view (FR-21.2)
- Heating: year comparison chart with correct month alignment (FR-21.2)
- Heating: monthly values from interpolated deltas at month boundaries (FR-21.2)
- Heating: room management icon preserved on Liste tab (FR-21.1)
- App bar analytics icons removed from both screens (FR-20.1, FR-21.1)
- MonthlyAnalyticsScreen and YearlyAnalyticsScreen removed (dead code after this phase)
- All new strings localized EN + DE (NFR-14)
- All tests pass, new tests cover nav, FAB, toggle, analysis (NFR-15)
- `flutter analyze` returns zero issues (NFR-16)

---

## Task Breakdown

### Wave 1: Data Layer — Add Heating Cost Support (1 task)

#### Task 22.1: Extend CostMeterType Enum and AnalyticsProvider for Heating Costs

**Files**:
- `lib/database/tables.dart`
- `lib/providers/analytics_provider.dart`

**Changes**:

1. **Add `heating` to CostMeterType enum** in `tables.dart` (line 101):
   ```dart
   enum CostMeterType { electricity, gas, water, heating }
   ```
   Adding at the end means ordinal=3. Existing DB rows (0=electricity, 1=gas, 2=water) are unaffected. No migration needed since `intEnum` stores ordinal values.

2. **Update `_toCostMeterType` in AnalyticsProvider** (line 343-354) — return `CostMeterType.heating` instead of `null`:
   ```dart
   CostMeterType? _toCostMeterType(MeterType type) {
     switch (type) {
       case MeterType.electricity:
         return CostMeterType.electricity;
       case MeterType.gas:
         return CostMeterType.gas;
       case MeterType.water:
         return CostMeterType.water;
       case MeterType.heating:
         return CostMeterType.heating;
     }
   }
   ```
   Also update doc comment (line 342): remove "(heating has no cost tracking)".

3. **Fix any exhaustive switch warnings** — search for `switch` on `CostMeterType` in the codebase. The cost settings screen may need a heating case added.

**Tests**:
- Existing tests should still pass (no behavioral change for electricity/gas/water)
- Heating cost calculation now routed through same path as water

**Commit**: `feat(22): add heating to CostMeterType enum and enable heating cost calculation`

---

### Wave 2: Water Screen Refactoring (1 task, depends on Wave 1)

#### Task 22.2: Refactor WaterScreen with Bottom Nav, IndexedStack, and Inline Analysis

**Files**:
- `lib/screens/water_screen.dart`

**Changes**:

This converts `WaterScreen` from `StatelessWidget` (786 lines) to `StatefulWidget` with the electricity/gas bottom nav pattern.

1. **Add imports** at top of file:
   ```dart
   import '../database/tables.dart';
   import '../providers/cost_config_provider.dart';
   import '../widgets/charts/chart_legend.dart';
   import '../widgets/charts/monthly_bar_chart.dart';
   import '../widgets/charts/year_comparison_chart.dart';
   ```

2. **Remove obsolete imports**:
   ```dart
   // REMOVE:
   import '../screens/monthly_analytics_screen.dart';
   import '../services/analytics/analytics_models.dart';  // re-add only if needed for colorForMeterType
   ```
   Note: `analytics_models.dart` is still needed for `colorForMeterType` and `MeterType`. Keep it.

3. **Convert WaterScreen to StatefulWidget**:
   ```dart
   class WaterScreen extends StatefulWidget {
     const WaterScreen({super.key});
     @override
     State<WaterScreen> createState() => _WaterScreenState();
   }

   class _WaterScreenState extends State<WaterScreen> {
     int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)
     bool _showCosts = false; // m³/€ toggle for Analyse tab

     @override
     void initState() {
       super.initState();
       WidgetsBinding.instance.addPostFrameCallback((_) {
         context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.water);
         context.read<AnalyticsProvider>().setSelectedYear(DateTime.now().year);
       });
     }
   ```

4. **Build method** — mirror electricity/gas exactly with water-specific substitutions:
   - Title: `l10n.waterMeters`
   - App bar actions: visibility toggle on Liste tab (already exists), cost toggle on Analyse tab
   - Body: `IndexedStack` with `_buildAnalyseTab()` and `_buildListeTab()`
   - FAB: only on Liste tab — opens `_addMeter()` dialog (water adds meters, not readings, at top level)
   - Bottom nav: `GlassBottomNav` with Analyse/Liste items
   - **Remove** app bar analytics icon entirely

5. **`_buildCostToggle()`** — uses `CostMeterType.water` and `Icons.water_drop` / `Icons.euro`:
   ```dart
   Widget _buildCostToggle(BuildContext context, AppLocalizations l10n) {
     final costProvider = context.watch<CostConfigProvider>();
     final hasWaterCostConfig =
         costProvider.getConfigsForMeterType(CostMeterType.water).isNotEmpty;
     if (!hasWaterCostConfig) return const SizedBox.shrink();
     return IconButton(
       icon: Icon(_showCosts ? Icons.euro : Icons.water_drop),
       onPressed: () => setState(() => _showCosts = !_showCosts),
       tooltip: _showCosts ? l10n.showConsumption : l10n.showCosts,
     );
   }
   ```

6. **`_buildListeTab()`** — extract existing body (the `_WaterMetersList` widget) into this method:
   ```dart
   Widget _buildListeTab(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;
     final provider = context.watch<WaterProvider>();
     final meters = provider.meters;
     if (meters.isEmpty) {
       return _buildEmptyState(context, l10n);
     }
     return _WaterMetersList(meters: meters);
   }
   ```

7. **`_buildAnalyseTab()`** and **`_buildAnalyseContent()`** — copy from electricity_screen.dart, adapt:
   - Use `MeterType.water` for color (`colorForMeterType(MeterType.water)`)
   - Same chart widgets with cost parameters
   - Same `_YearlySummaryCard` and `_YearNavigationHeader` private widgets (duplicated into this file)

8. **Keep all existing private widgets** (`_WaterMetersList`, `_WaterMeterCard`, `_WaterMeterCardState`) — these are used by the Liste tab and remain unchanged.

9. **Move `_addMeter` and `_buildEmptyState`** into the State class.

**Commit**: `feat(22): refactor water screen with bottom nav, IndexedStack, and inline analysis`

---

### Wave 3: Heating Screen Refactoring (1 task, parallel with Wave 2)

#### Task 22.3: Refactor HeatingScreen with Bottom Nav, IndexedStack, and Inline Analysis

**Files**:
- `lib/screens/heating_screen.dart`

**Changes**:

Same pattern as water, with heating-specific adaptations.

1. **Add imports**:
   ```dart
   import '../database/tables.dart';
   import '../providers/cost_config_provider.dart';
   import '../widgets/charts/chart_legend.dart';
   import '../widgets/charts/monthly_bar_chart.dart';
   import '../widgets/charts/year_comparison_chart.dart';
   ```

2. **Remove obsolete imports**:
   ```dart
   // REMOVE:
   import '../screens/monthly_analytics_screen.dart';
   ```

3. **Convert HeatingScreen to StatefulWidget**:
   ```dart
   class HeatingScreen extends StatefulWidget {
     const HeatingScreen({super.key});
     @override
     State<HeatingScreen> createState() => _HeatingScreenState();
   }

   class _HeatingScreenState extends State<HeatingScreen> {
     int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)
     bool _showCosts = false; // kWh/€ toggle

     @override
     void initState() {
       super.initState();
       WidgetsBinding.instance.addPostFrameCallback((_) {
         context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.heating);
         context.read<AnalyticsProvider>().setSelectedYear(DateTime.now().year);
       });
     }
   ```

4. **Build method** — mirror electricity exactly:
   - Title: `l10n.heatingMeters`
   - App bar actions on Liste tab: visibility toggle + room management icon (meeting_room)
   - App bar actions on Analyse tab: cost toggle
   - Body: `IndexedStack` with Analyse and Liste tabs
   - FAB: only on Liste tab — opens `_addMeter()` dialog
   - Bottom nav: GlassBottomNav
   - **Remove** app bar analytics icon entirely

5. **`_buildCostToggle()`** — uses `CostMeterType.heating` and `Icons.thermostat` / `Icons.euro`:
   ```dart
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

6. **`_buildListeTab()`** — extract existing body:
   ```dart
   Widget _buildListeTab(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;
     final provider = context.watch<HeatingProvider>();
     final metersByRoom = provider.metersByRoom;
     if (metersByRoom.isEmpty) {
       return _buildEmptyState(context, l10n);
     }
     return _HeatingMetersByRoom(metersByRoom: metersByRoom);
   }
   ```

7. **`_buildAnalyseTab()`** and **`_buildAnalyseContent()`** — same pattern as water/electricity:
   - Use `MeterType.heating` for color
   - Same chart widgets
   - Duplicate `_YearNavigationHeader` and `_YearlySummaryCard`

8. **Keep all existing private widgets** (`_HeatingMetersByRoom`, `_RoomSection`, `_HeatingMeterCard`, `_HeatingMeterCardState`).

9. **Move `_addMeter`, `_buildEmptyState`, `_navigateToRooms`** into the State class.

**Commit**: `feat(22): refactor heating screen with bottom nav, IndexedStack, and inline analysis`

---

### Wave 4: Dead Code Cleanup (1 task, depends on Waves 2-3)

#### Task 22.4: Remove MonthlyAnalyticsScreen and YearlyAnalyticsScreen (Dead Code)

**Files**:
- `lib/screens/monthly_analytics_screen.dart` — DELETE
- `lib/screens/yearly_analytics_screen.dart` — DELETE
- `test/screens/monthly_analytics_screen_test.dart` — DELETE (if exists)
- `test/screens/yearly_analytics_screen_test.dart` — DELETE (if exists)

**Changes**:

1. After Waves 2-3, no screen imports `MonthlyAnalyticsScreen` or `YearlyAnalyticsScreen`. Verify with grep.
2. Delete both screen files.
3. Delete corresponding test files if they exist.
4. Remove any route definitions referencing these screens.
5. Run `flutter analyze` to confirm no broken imports.

**Commit**: `refactor(22): remove dead MonthlyAnalyticsScreen and YearlyAnalyticsScreen`

---

### Wave 5: Tests (depends on Waves 1-4)

#### Task 22.5: Expand Water Screen Tests

**Files**:
- `test/screens/water_screen_test.dart`

**Changes**:

Mirror the test structure from `gas_screen_test.dart` (18 tests). Water tests need the same provider setup expansion.

1. **Add imports**:
   ```dart
   import 'package:drift/drift.dart';
   import 'package:valtra/database/daos/cost_config_dao.dart';
   import 'package:valtra/database/daos/electricity_dao.dart';
   import 'package:valtra/database/daos/gas_dao.dart';
   import 'package:valtra/database/daos/heating_dao.dart';
   import 'package:valtra/providers/analytics_provider.dart';
   import 'package:valtra/providers/cost_config_provider.dart';
   import 'package:valtra/providers/interpolation_settings_provider.dart';
   import 'package:valtra/services/cost_calculation_service.dart';
   import 'package:valtra/services/gas_conversion_service.dart';
   import 'package:valtra/services/interpolation/interpolation_service.dart';
   ```

2. **Extend setUp()** — add AnalyticsProvider, CostConfigProvider, InterpolationSettingsProvider:
   ```dart
   late AnalyticsProvider analyticsProvider;
   late CostConfigProvider costConfigProvider;
   late InterpolationSettingsProvider interpolationSettingsProvider;
   // initialize same pattern as electricity_screen_test.dart
   ```

3. **Extend wrapWithProviders()** — add:
   ```dart
   ChangeNotifierProvider<AnalyticsProvider>.value(value: analyticsProvider),
   ChangeNotifierProvider<CostConfigProvider>.value(value: costConfigProvider),
   ```

4. **Add test groups**:

   **Group: WaterScreen - Bottom Navigation** (~7 tests):
   - `renders bottom nav with Analysis and List labels`
   - `default tab is Liste (index 1)`
   - `tapping Analysis switches to analysis content`
   - `FAB visible on Liste tab` (FAB adds meters for water)
   - `FAB hidden on Analyse tab`
   - `visibility toggle only in app bar on Liste tab`
   - `cost toggle hidden when no cost config`

   **Group: WaterScreen - Liste Tab** (keep existing 9 tests):
   - Existing tests should still work since Liste is the default tab

   **Group: WaterScreen - Analyse Tab** (~2 tests):
   - `shows no data message when no readings on Analyse tab`
   - `shows year navigation and analytics content with readings`

   **Group: WaterScreen - Cost Toggle** (~3 tests):
   - `cost toggle shown when water cost config exists on Analyse tab`
   - `toggling to EUR shows euro icon`
   - `toggling back to m³ reverts to consumption display`

**Tests total**: ~21 tests (9 existing + 12 new)

**Commit**: `test(22): add comprehensive water screen tests for bottom nav, analysis, and cost toggle`

---

#### Task 22.6: Expand Heating Screen Tests

**Files**:
- `test/screens/heating_screen_test.dart`

**Changes**:

Same expansion pattern as water tests.

1. **Add same imports** as water test.

2. **Extend setUp()** — add AnalyticsProvider, CostConfigProvider.

3. **Add test groups**:

   **Group: HeatingScreen - Bottom Navigation** (~8 tests):
   - `renders bottom nav with Analysis and List labels`
   - `default tab is Liste (index 1)`
   - `tapping Analysis switches to analysis content`
   - `FAB visible on Liste tab`
   - `FAB hidden on Analyse tab`
   - `visibility toggle only in app bar on Liste tab`
   - `room management icon only in app bar on Liste tab`
   - `cost toggle hidden when no cost config`

   **Group: HeatingScreen - Liste Tab** (keep existing 12 tests):
   - Existing tests should still work since Liste is the default tab

   **Group: HeatingScreen - Analyse Tab** (~2 tests):
   - `shows no data message when no readings on Analyse tab`
   - `shows year navigation and analytics content with readings`

   **Group: HeatingScreen - Cost Toggle** (~3 tests):
   - `cost toggle shown when heating cost config exists on Analyse tab`
   - `toggling to EUR shows euro icon`
   - `toggling back to kWh reverts to consumption display`

**Tests total**: ~25 tests (12 existing + 13 new)

**Commit**: `test(22): add comprehensive heating screen tests for bottom nav, analysis, and cost toggle`

---

### Wave 6: Final Verification (depends on Wave 5)

#### Task 22.7: Final Cleanup and Verification

**Files**:
- Various (verification only, minimal source changes expected)

**Changes**:

1. **Run `flutter test`** — all tests must pass (expected: ~1095 tests: 1070 existing + ~25 new)

2. **Run `flutter analyze`** — zero issues

3. **Verify no orphaned imports**:
   - `monthly_analytics_screen` should NOT be imported anywhere
   - `yearly_analytics_screen` should NOT be imported anywhere

4. **Verify analytics data flow**:
   - `AnalyticsProvider` already handles `MeterType.water` and `MeterType.heating` in `_getReadingsPerMeter()` and `_loadYearlyData()`
   - Water cost calculation works via `CostMeterType.water` (already existed)
   - Heating cost calculation now works via `CostMeterType.heating` (added in Task 22.1)

5. **Verify chart month alignment**:
   - Fixed globally in Phase 19 — `YearComparisonChart` uses `periodStart.month - 1` as X-axis
   - Water and heating data automatically benefit from this fix

6. **Verify cost config UI supports heating**:
   - Check household cost settings screen handles new `CostMeterType.heating` in its switch/display logic
   - Fix any exhaustive switch warnings

**Commit**: `test(22): verify full test suite and zero analyze issues — mark phase 22 complete`

---

## Risk Mitigation

1. **StatelessWidget → StatefulWidget conversion**: Proven pattern from phases 19 (electricity) and 20 (gas). Water and heating use the same approach. Tests need the expanded provider setup.

2. **Multi-meter screens (water + heating) vs single-meter (electricity + gas)**: Water and heating have multiple meters per household. The Liste tab preserves the existing meter card UI. The Analyse tab shows aggregated analytics via AnalyticsProvider, which already handles multi-meter aggregation for water and heating in `_getReadingsPerMeter()`.

3. **Adding CostMeterType.heating**: Uses `intEnum` (ordinal-based). Adding at end (ordinal 3) doesn't affect existing rows (0-2). No DB migration. Existing switch statements on CostMeterType may need a new case — the analyzer will catch missing cases.

4. **Duplicate private widgets**: `_YearNavigationHeader` and `_YearlySummaryCard` are duplicated per file (same as gas). Each screen evolves independently. A shared widget extraction is a future cleanup task.

5. **MonthlyAnalyticsScreen removal**: Only water and heating import it. After both are refactored, it becomes dead code. Verify with grep before deleting.

6. **Cost toggle when no config exists**: Toggle button is hidden when no cost config exists for the meter type. `_showCosts` may remain `true` if config is deleted, but charts handle null costs gracefully by falling back to consumption view.

7. **Room management for heating**: The rooms icon moves to the Liste tab app bar actions only. It's not shown on the Analyse tab (same as visibility toggle pattern).

8. **Existing test breakage**: The 9 water tests and 12 heating tests check current behavior. Since Liste is the default tab, existing tests should still find the same UI elements. However, some tests may check for the analytics app bar icon (now removed) or the FAB (now conditional on tab). These need updating in the test files.

## Verification Checklist

- [ ] **FR-20.1.1**: Water bottom nav shows Analyse (left) + Liste (right), default Liste
- [ ] **FR-20.1.2**: Water FAB visible on Liste, hidden on Analyse
- [ ] **FR-20.1.3**: Water analysis page with year nav, summary, bar chart, comparison chart
- [ ] **FR-20.2.1**: Water m³/€ toggle in app bar on Analyse tab
- [ ] **FR-20.2.2**: Water year comparison chart with correct month alignment
- [ ] **FR-20.2.3**: Water monthly values from interpolated deltas
- [ ] **FR-21.1.1**: Heating bottom nav shows Analyse (left) + Liste (right), default Liste
- [ ] **FR-21.1.2**: Heating FAB visible on Liste, hidden on Analyse
- [ ] **FR-21.1.3**: Heating analysis page with year nav, summary, bar chart, comparison chart
- [ ] **FR-21.2.1**: Heating kWh/€ toggle in app bar on Analyse tab
- [ ] **FR-21.2.2**: Heating year comparison chart with correct month alignment
- [ ] **FR-21.2.3**: Heating monthly values from interpolated deltas
- [ ] **Cleanup**: MonthlyAnalyticsScreen and YearlyAnalyticsScreen deleted
- [ ] **Cleanup**: No orphaned imports remain
- [ ] **NFR-14**: All new strings localized EN + DE (reuse existing l10n keys from electricity/gas)
- [ ] **NFR-15**: All tests pass (~1095 tests)
- [ ] **NFR-16**: `flutter analyze` returns zero issues
