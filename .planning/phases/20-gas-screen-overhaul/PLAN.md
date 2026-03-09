# Phase 20 Plan — Gas Screen Overhaul

## Goal
Mirror the electricity screen architecture (Phase 19) onto the gas screen: unified bottom navigation (Analyse | Liste), LiquidGlass FAB on Liste only, inline analysis tab with year comparison chart, and m³/€ toggle for switching between consumption and cost views.

## Success Criteria
- Bottom nav with Analyse (left) and Liste (right), default Liste (FR-18.1)
- IndexedStack preserves tab state when switching (FR-18.1)
- LiquidGlass FAB visible on Liste tab only (FR-18.2)
- App bar analysis icon removed — no navigation to MonthlyAnalyticsScreen (FR-18.3)
- Single analysis page (yearly view) embedded in Analyse tab (FR-18.4)
- Year comparison chart renders correctly for gas with calendar month alignment (FR-18.5)
- m³/€ toggle switches all chart data between consumption and cost (FR-18.6)
- Monthly consumption computed from interpolated deltas at month boundaries (FR-18.7)
- All strings already localized EN + DE — no new l10n strings needed (NFR-14)
- All tests pass, new tests cover navigation, FAB visibility, toggle, analysis tab (NFR-15)
- `flutter analyze` returns zero issues (NFR-16)

---

## Task Breakdown

### Wave 1: Screen Refactoring (single task — all changes in one file)

#### Task 20.1: Refactor GasScreen with Bottom Nav, IndexedStack, and Inline Analysis

**Files**:
- `lib/screens/gas_screen.dart`

**Changes**:

This is the core change. The `GasScreen` goes from `StatelessWidget` (400 lines) to `StatefulWidget` mirroring `ElectricityScreen` (748 lines) exactly.

1. **Add missing imports** at top of file:
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

3. **Convert GasScreen to StatefulWidget**:
   ```dart
   class GasScreen extends StatefulWidget {
     const GasScreen({super.key});
     @override
     State<GasScreen> createState() => _GasScreenState();
   }

   class _GasScreenState extends State<GasScreen> {
     int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)
     bool _showCosts = false; // m³/€ toggle for Analyse tab

     @override
     void initState() {
       super.initState();
       WidgetsBinding.instance.addPostFrameCallback((_) {
         context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.gas);
         context.read<AnalyticsProvider>().setSelectedYear(DateTime.now().year);
       });
     }
   ```

4. **Build method** — mirror electricity exactly with gas-specific substitutions:
   ```dart
   @override
   Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;

     return Scaffold(
       appBar: buildGlassAppBar(
         context: context,
         title: l10n.gas,
         actions: [
           // Visibility toggle: only on Liste tab
           if (_currentTab == 1)
             Builder(builder: (context) {
               final provider = context.watch<GasProvider>();
               return IconButton(
                 icon: Icon(
                   provider.showInterpolatedValues
                       ? Icons.visibility
                       : Icons.visibility_off,
                 ),
                 onPressed: () => provider.toggleInterpolatedValues(),
                 tooltip: provider.showInterpolatedValues
                     ? l10n.hideInterpolatedValues
                     : l10n.showInterpolatedValues,
               );
             }),
           // Cost toggle: only on Analyse tab + cost config exists
           if (_currentTab == 0) _buildCostToggle(context, l10n),
           const SizedBox(width: 8),
         ],
       ),
       body: IndexedStack(
         index: _currentTab,
         children: [
           _buildAnalyseTab(context),    // index 0
           _buildListeTab(context),      // index 1
         ],
       ),
       floatingActionButton: _currentTab == 1
           ? buildGlassFAB(
               context: context,
               icon: Icons.add,
               onPressed: () => _addReading(context),
             )
           : null,
       bottomNavigationBar: GlassBottomNav(
         currentIndex: _currentTab,
         onTap: (index) => setState(() => _currentTab = index),
         items: [
           BottomNavigationBarItem(
             icon: const Icon(Icons.analytics),
             label: l10n.analysis,
           ),
           BottomNavigationBarItem(
             icon: const Icon(Icons.list),
             label: l10n.list,
           ),
         ],
       ),
     );
   }
   ```

5. **`_buildCostToggle()`** — uses `CostMeterType.gas` and `Icons.local_fire_department` / `Icons.euro`:
   ```dart
   Widget _buildCostToggle(BuildContext context, AppLocalizations l10n) {
     final costProvider = context.watch<CostConfigProvider>();
     final hasGasCostConfig =
         costProvider.getConfigsForMeterType(CostMeterType.gas).isNotEmpty;

     if (!hasGasCostConfig) return const SizedBox.shrink();

     return IconButton(
       icon: Icon(_showCosts ? Icons.euro : Icons.local_fire_department),
       onPressed: () => setState(() => _showCosts = !_showCosts),
       tooltip: _showCosts ? l10n.showConsumption : l10n.showCosts,
     );
   }
   ```

6. **`_buildListeTab()`** — extract existing body into this method:
   ```dart
   Widget _buildListeTab(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;
     final provider = context.watch<GasProvider>();
     final items = provider.displayItems;

     if (items.isEmpty) {
       return _buildEmptyState(context, l10n);
     }

     return ListView.builder(
       padding: const EdgeInsets.all(16),
       itemCount: items.length,
       itemBuilder: (context, index) {
         final item = items[index];
         if (item.isInterpolated) {
           return _InterpolatedReadingCard(
             item: item,
             unit: l10n.cubicMeters,
             icon: Icons.local_fire_department,
           );
         }
         return _GasReadingCard(
           item: item,
           onTap: () => _editReading(context, item.readingId!),
           onDelete: () => _deleteReading(context, item.readingId!),
         );
       },
     );
   }
   ```

7. **`_buildAnalyseTab()`** and **`_buildAnalyseContent()`** — copy from electricity, adapt for gas:
   - Use `MeterType.gas` for color
   - Use `l10n.cubicMeters` as unit reference (actual unit comes from `data.unit` which is `'m³'`)
   - Same chart widget calls with cost parameters
   - Same `_YearlySummaryCard` widget (duplicate the private class into this file)

8. **`_buildEmptyState()`** — keep as-is but move into State class.

9. **Move helper methods** (`_addReading`, `_editReading`, `_deleteReading`) into the State class — logic unchanged.

10. **Duplicate helper widgets** into gas_screen.dart:
    - `_YearNavigationHeader` — exact copy from electricity_screen.dart (lines 391-433)
    - `_YearlySummaryCard` — exact copy from electricity_screen.dart (lines 437-549)

11. **Keep existing card widgets** (`_GasReadingCard`, `_InterpolatedReadingCard`) at bottom of file — unchanged.

**Commit**: `feat(20): refactor gas screen with bottom nav, IndexedStack, and inline analysis`

---

### Wave 2: Tests (depends on Wave 1)

#### Task 20.2: Expand Gas Screen Tests

**Files**:
- `test/screens/gas_screen_test.dart`

**Changes**:

Mirror the test structure from `test/screens/electricity_screen_test.dart` (571 lines). The gas test needs the same provider setup and test groups.

1. **Add missing imports**:
   ```dart
   import 'package:drift/drift.dart';
   import 'package:valtra/database/daos/cost_config_dao.dart';
   import 'package:valtra/database/daos/electricity_dao.dart';
   import 'package:valtra/database/daos/heating_dao.dart';
   import 'package:valtra/database/daos/water_dao.dart';
   import 'package:valtra/database/tables.dart';
   import 'package:valtra/providers/analytics_provider.dart';
   import 'package:valtra/providers/cost_config_provider.dart';
   import 'package:valtra/providers/interpolation_settings_provider.dart';
   import 'package:valtra/services/cost_calculation_service.dart';
   import 'package:valtra/services/gas_conversion_service.dart';
   import 'package:valtra/services/interpolation/interpolation_service.dart';
   ```

2. **Extend setUp()** — add AnalyticsProvider, CostConfigProvider, InterpolationSettingsProvider initialization (same pattern as electricity test setUp, lines 64-109):
   ```dart
   late AnalyticsProvider analyticsProvider;
   late CostConfigProvider costConfigProvider;
   late InterpolationSettingsProvider interpolationSettingsProvider;

   // In setUp():
   interpolationSettingsProvider = InterpolationSettingsProvider();
   await interpolationSettingsProvider.init();

   final costConfigDao = CostConfigDao(database);
   final costCalculationService = CostCalculationService();
   costConfigProvider = CostConfigProvider(
     costConfigDao: costConfigDao,
     costCalculationService: costCalculationService,
   );

   analyticsProvider = AnalyticsProvider(
     electricityDao: ElectricityDao(database),
     gasDao: dao,
     waterDao: WaterDao(database),
     heatingDao: HeatingDao(database),
     interpolationService: InterpolationService(),
     gasConversionService: GasConversionService(),
     settingsProvider: interpolationSettingsProvider,
     costConfigProvider: costConfigProvider,
   );

   analyticsProvider.setHouseholdId(householdId);
   costConfigProvider.setHouseholdId(householdId);
   ```

3. **Extend wrapWithProviders()** — add AnalyticsProvider and CostConfigProvider:
   ```dart
   ChangeNotifierProvider<AnalyticsProvider>.value(value: analyticsProvider),
   ChangeNotifierProvider<CostConfigProvider>.value(value: costConfigProvider),
   ```

4. **Extend tearDown()** — dispose new providers:
   ```dart
   analyticsProvider.dispose();
   costConfigProvider.dispose();
   ```

5. **Add test groups** mirroring electricity tests:

   **Group: GasScreen - Bottom Navigation** (7 tests):
   - `renders bottom nav with Analysis and List labels` — find "Analysis", "List", GlassBottomNav
   - `default tab is Liste (index 1)` — find empty state "No readings yet..." with fire icon
   - `tapping Analysis switches to analysis content` — tap "Analysis", find year
   - `FAB visible on Liste tab` — find FloatingActionButton
   - `FAB hidden on Analyse tab` — switch tab, find no FloatingActionButton
   - `visibility toggle only in app bar on Liste tab` — check visibility icon presence per tab
   - `cost toggle hidden when no cost config` — switch to Analyse, no euro/fire icon

   **Group: GasScreen - Liste Tab** (keep existing 6 tests):
   - Existing empty state, readings list, FAB, delta, edit, delete tests — migrate into "Liste Tab" group. Minor adjustments: existing tests still work since Liste is default tab.

   **Group: GasScreen - Analyse Tab** (2 tests):
   - `shows no data message when no readings on Analyse tab` — switch tab, find year text
   - `shows year navigation and analytics content with readings` — add 3 readings at month boundaries for current year, switch to Analyse, find year, chevron icons, "Monthly Breakdown"

   **Group: GasScreen - Cost Toggle on Analyse Tab** (3 tests):
   - `cost toggle shown when cost config exists on Analyse tab` — insert CostMeterType.gas config, switch to Analyse, find `Icons.local_fire_department` icon
   - `toggling to EUR shows euro icon` — tap fire icon, find euro icon
   - `toggling back to m³ reverts to consumption display` — toggle twice, find m³ text

**Tests total**: ~18 tests (7 bottom nav + 6 existing liste + 2 analyse + 3 cost toggle)

**Commit**: `test(20): add comprehensive gas screen tests for bottom nav, analysis, and cost toggle`

---

### Wave 3: Cleanup & Verification (depends on Wave 2)

#### Task 20.3: Final Cleanup and Verification

**Files**:
- Various (verification only, no source changes expected)

**Changes**:

1. **Run `flutter test`** — all tests must pass (expected: ~1075 tests: 1057 existing + ~18 new)

2. **Run `flutter analyze`** — zero issues

3. **Verify no orphaned imports**:
   - `monthly_analytics_screen` should NOT be imported in `gas_screen.dart`
   - `monthly_analytics_screen.dart` still exists (used by water, heating screens)

4. **Verify analytics data flow**:
   - `AnalyticsProvider` already handles `MeterType.gas` in `_getReadingsPerMeter()`, `_loadYearlyData()`, and `_calculatePeriodCost()` (with m³→kWh conversion via GasConversionService)
   - `YearlyAnalyticsData` already populates `monthlyCosts` and `previousYearMonthlyCosts` for gas

5. **Verify chart month alignment**:
   - Fixed globally in Phase 19 (Task 19.2) — `YearComparisonChart` uses `periodStart.month - 1` as X-axis
   - Gas data automatically benefits from this fix

**Commit**: `test(20): verify full test suite (N pass) and zero analyze issues — mark phase 20 complete`

---

## Risk Mitigation

1. **StatelessWidget → StatefulWidget conversion**: Same pattern as Phase 19 electricity screen. The `const` constructor is preserved on the outer widget. Tests need to pump the new widget correctly — no issues expected since electricity tests already work this way.

2. **Duplicate private widgets**: `_YearNavigationHeader` and `_YearlySummaryCard` are duplicated from electricity_screen.dart rather than extracted to a shared file. This is intentional — each meter screen can evolve independently. A shared widget extraction can be done in a cleanup phase later.

3. **IndexedStack memory**: Both tabs stay in the widget tree. The Analyse tab watches `AnalyticsProvider` which triggers data loads. The `addPostFrameCallback` in `initState` loads data only once, not on every tab switch.

4. **MonthlyAnalyticsScreen preservation**: This screen is NOT deleted — water and heating still navigate to it. Only the gas screen stops navigating there. The import is removed only from `gas_screen.dart`.

5. **Cost toggle when config changes**: If the user deletes their gas cost config while on the Analyse tab with € mode, the toggle button disappears and `_showCosts` stays true but `monthlyCosts` will be null. The charts handle this gracefully by falling back to consumption display when costs are unavailable (same behavior as electricity).

6. **Gas cost calculation**: The `AnalyticsProvider._calculatePeriodCost()` already handles gas by converting m³ to kWh via `GasConversionService` before applying the cost config (lines 363-368). No changes needed.

7. **Test provider setup**: Gas screen tests need `AnalyticsProvider` and `CostConfigProvider` now. Follow the exact setup pattern from `electricity_screen_test.dart` (lines 64-109).

## Verification Checklist

- [ ] **FR-18.1**: Bottom nav shows Analyse (left) + Liste (right), default Liste
- [ ] **FR-18.1**: IndexedStack preserves scroll position when switching tabs
- [ ] **FR-18.2**: FAB visible on Liste, hidden on Analyse
- [ ] **FR-18.3**: No app bar analytics icon, no MonthlyAnalyticsScreen navigation
- [ ] **FR-18.4**: Inline analysis tab with year nav, summary, bar chart, comparison chart
- [ ] **FR-18.5**: Year comparison chart renders gas data with calendar month alignment
- [ ] **FR-18.6**: m³/€ toggle in app bar on Analyse tab
- [ ] **FR-18.6**: Toggle switches all charts + summary between consumption and cost
- [ ] **FR-18.6**: Toggle hidden when no cost config exists
- [ ] **FR-18.7**: Monthly consumption from interpolated deltas (via AnalyticsProvider)
- [ ] **NFR-14**: No new l10n strings needed — all existing
- [ ] **NFR-15**: All tests pass, new tests cover nav, FAB, toggle, analysis
- [ ] **NFR-16**: `flutter analyze` returns zero issues
