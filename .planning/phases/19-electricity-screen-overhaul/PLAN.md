# Phase 19 Plan — Electricity Screen Overhaul

## Goal
Overhaul the electricity screen with unified bottom navigation (Analyse | Liste), LiquidGlass FAB on Liste only, consolidated single analysis page with year comparison chart fix, and kWh/€ toggle for cost display.

## Success Criteria
- Bottom nav with Analyse (left) and Liste (right), default Liste (FR-17.1)
- IndexedStack preserves tab state when switching (FR-17.1)
- LiquidGlass FAB visible on Liste tab only (FR-17.2)
- App bar analysis icon removed (FR-17.3)
- Single analysis page (yearly view) embedded in Analyse tab (FR-17.4)
- Year comparison chart: previous year line aligned by calendar month, starting at first month with data (FR-17.5)
- kWh/€ toggle switches all chart data between consumption and cost (FR-17.6)
- Monthly consumption computed from interpolated deltas at month boundaries (FR-17.7)
- All strings localized EN + DE (NFR-14)
- All tests pass, new tests cover navigation, FAB visibility, toggle, chart alignment (NFR-15)
- `flutter analyze` returns zero issues (NFR-16)

---

## Task Breakdown

### Wave 1: Data Layer & Chart Fix (2 parallel tasks)

No UI screen changes — pure data model + chart widget fixes.

#### Task 19.1: Extend YearlyAnalyticsData with Per-Month Costs

**Files**:
- `lib/services/analytics/analytics_models.dart`
- `lib/providers/analytics_provider.dart`
- `test/providers/analytics_provider_test.dart`

**Changes**:

1. **Extend `YearlyAnalyticsData`** in `analytics_models.dart` (line 66-93):
   Add two new optional fields:
   ```dart
   final List<double?>? monthlyCosts;           // cost per month (parallel to monthlyBreakdown)
   final List<double?>? previousYearMonthlyCosts; // cost per month for previous year
   ```
   Add them to the constructor as optional named parameters.

2. **Populate costs in `_loadYearlyData()`** in `analytics_provider.dart` (around line 459-489):
   The provider already computes `costs` as `monthlyBreakdown.map((p) => _calculatePeriodCost(p, _selectedMeterType)).toList()` for the total — just save this list:
   ```dart
   List<double?>? monthlyCosts;
   List<double?>? prevMonthlyCosts;
   // ... (existing cost calculation block)
   monthlyCosts = costs;
   // ... (existing prev cost calculation block)
   prevMonthlyCosts = prevCosts;
   ```
   Pass `monthlyCosts` and `previousYearMonthlyCosts: prevMonthlyCosts` to the `YearlyAnalyticsData` constructor.

3. **Update existing tests**: Adjust any `YearlyAnalyticsData` construction in tests that may break from the new fields (they are optional, so likely no changes needed).

**Tests**:
- Add test in `analytics_provider_test.dart`: verify `yearlyData.monthlyCosts` is populated when cost config exists
- Add test: verify `yearlyData.monthlyCosts` is null when no cost config
- Add test: verify `yearlyData.previousYearMonthlyCosts` is populated when previous year data + cost config exist

**Commit**: `feat(19): extend YearlyAnalyticsData with per-month cost lists`

---

#### Task 19.2: Fix Year Comparison Chart Calendar Month Alignment

**Files**:
- `lib/widgets/charts/year_comparison_chart.dart`
- `test/widgets/charts/year_comparison_chart_test.dart`

**Changes**:

The current chart uses array index (0, 1, 2, ...) as X-axis positions. Both current and previous year data plot at sequential indices regardless of calendar month. This means if the current year has Jan–Mar data (3 items), they plot at x=0,1,2 — but if previous year has Jan–Dec (12 items), those also plot at x=0..11, which clips at maxX=2.

**Fix**: Use `periodStart.month - 1` as the X-axis position (0=Jan, 11=Dec) for both datasets.

1. In `_buildData()` (line 37-146), change spot generation:
   ```dart
   // BEFORE:
   final currentSpots = currentYear
       .asMap().entries
       .map((e) => FlSpot(e.key.toDouble(), e.value.consumption))
       .toList();
   final previousSpots = previousYear
       ?.asMap().entries
       .map((e) => FlSpot(e.key.toDouble(), e.value.consumption))
       .toList();

   // AFTER:
   final currentSpots = currentYear
       .map((p) => FlSpot((p.periodStart.month - 1).toDouble(), p.consumption))
       .toList();
   final previousSpots = previousYear
       ?.map((p) => FlSpot((p.periodStart.month - 1).toDouble(), p.consumption))
       .toList();
   ```

2. Update `maxX` (line 61):
   ```dart
   // BEFORE:
   maxX: (currentYear.length - 1).toDouble(),
   // AFTER: show up to the last month with data in either dataset
   maxX: _computeMaxX(),
   ```
   Add helper:
   ```dart
   double _computeMaxX() {
     double maxMonth = 0;
     for (final p in currentYear) {
       final m = (p.periodStart.month - 1).toDouble();
       if (m > maxMonth) maxMonth = m;
     }
     if (previousYear != null) {
       for (final p in previousYear!) {
         final m = (p.periodStart.month - 1).toDouble();
         if (m > maxMonth) maxMonth = m;
       }
     }
     return maxMonth;
   }
   ```

3. Update `_buildTitles()` bottom titles (line 158-175):
   Change the index lookup from `currentYear[index]` to building month name from the index directly:
   ```dart
   getTitlesWidget: (value, meta) {
     final index = value.toInt();
     if (index < 0 || index > 11) return const SizedBox.shrink();
     // Show every other month if range > 6 months
     final monthRange = _computeMaxX().toInt() + 1;
     if (monthRange > 6 && index % 2 != 0) return const SizedBox.shrink();
     final monthName = DateFormat.MMM().format(DateTime(2024, index + 1));
     return SideTitleWidget(
       axisSide: meta.axisSide,
       child: Text(monthName, style: Theme.of(context).textTheme.bodySmall),
     );
   },
   ```

4. Update tooltip (line 127-141) to use month index directly:
   ```dart
   final monthIndex = spot.x.toInt();
   final monthName = DateFormat.MMM().format(DateTime(2024, monthIndex + 1));
   ```

5. **Add optional `costMode` support** to the chart for the kWh/€ toggle (Task 19.5 will use it):
   Add optional constructor parameters:
   ```dart
   final List<double?>? currentYearCosts;
   final List<double?>? previousYearCosts;
   final bool showCosts;
   final String? costUnit;
   ```
   When `showCosts` is true, use cost values instead of consumption for spot generation. Build spots from the parallel cost lists using the same month index from the consumption periods:
   ```dart
   if (showCosts && currentYearCosts != null) {
     // Use costs: pair each period's month with its cost value
     currentSpots = [];
     for (int i = 0; i < currentYear.length; i++) {
       final cost = i < currentYearCosts!.length ? currentYearCosts![i] : null;
       if (cost != null) {
         currentSpots.add(FlSpot((currentYear[i].periodStart.month - 1).toDouble(), cost));
       }
     }
   }
   ```
   Default `showCosts` to `false` so existing callers are unaffected.

**Tests**:
- Add test: current year Jan-Mar + previous year Jan-Dec → both lines use calendar month positions
- Add test: previous year with only Mar-Dec data starts at x=2 (March position)
- Add test: maxX includes the highest month across both datasets
- Add test: tooltip shows correct month name for calendar-aligned spots
- Update existing tests if they assert on index-based X positions

**Commit**: `fix(19): year comparison chart aligns by calendar month instead of array index`

---

### Wave 2: Localization & Bottom Nav (2 parallel tasks, depend on Wave 1)

#### Task 19.3: Add Localization Strings

**Files**:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`

**Changes**:

Add new ARB keys for the bottom navigation and cost toggle:

```json
// app_en.arb:
"list": "List",
"showCosts": "Show Costs",
"showConsumption": "Show Consumption",
"costPerMonth": "Cost per Month",

// app_de.arb:
"list": "Liste",
"showCosts": "Kosten anzeigen",
"showConsumption": "Verbrauch anzeigen",
"costPerMonth": "Kosten pro Monat",
```

Note: `"analysis"` already exists (EN: "Analysis", DE: "Analyse"). No need to add it.

Run `flutter gen-l10n` to regenerate l10n (project uses `generate: true` in pubspec.yaml).

**Tests**: None needed — localization strings verified in UI tests.

**Commit**: `feat(19): add l10n strings for bottom nav and cost toggle`

---

#### Task 19.4: Refactor ElectricityScreen with Bottom Nav + IndexedStack

**Files**:
- `lib/screens/electricity_screen.dart`
- `test/screens/electricity_screen_test.dart`

**Changes**:

This is the core architectural change. The `ElectricityScreen` goes from `StatelessWidget` to `StatefulWidget` with bottom nav tab switching.

1. **Convert to StatefulWidget**:
   ```dart
   class ElectricityScreen extends StatefulWidget {
     const ElectricityScreen({super.key});
     @override
     State<ElectricityScreen> createState() => _ElectricityScreenState();
   }

   class _ElectricityScreenState extends State<ElectricityScreen> {
     int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)
     bool _showCosts = false; // kWh/€ toggle

     @override
     void initState() {
       super.initState();
       // Trigger analytics data load for the Analyse tab
       WidgetsBinding.instance.addPostFrameCallback((_) {
         context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.electricity);
         context.read<AnalyticsProvider>().setSelectedYear(DateTime.now().year);
       });
     }
     // ...
   }
   ```

2. **Build method** — new Scaffold structure:
   ```dart
   @override
   Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context)!;
     return Scaffold(
       appBar: buildGlassAppBar(
         context: context,
         title: l10n.electricity,
         actions: [
           // Visibility toggle (only on Liste tab)
           if (_currentTab == 1)
             IconButton(
               icon: Icon(provider.showInterpolatedValues
                   ? Icons.visibility : Icons.visibility_off),
               onPressed: () => provider.toggleInterpolatedValues(),
               tooltip: ...,
             ),
           // kWh/€ toggle (only on Analyse tab, only if cost config exists)
           if (_currentTab == 0)
             _buildCostToggle(context),
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

3. **Remove the analytics IconButton** from app bar actions (was at lines 43-52).

4. **Remove the MonthlyAnalyticsScreen import** (line 9).

5. **`_buildListeTab()`**: Extract the current body (items.isEmpty ? emptyState : ListView.builder) as-is into this method.

6. **`_buildAnalyseTab()`**: Embed the yearly analytics content directly (adapted from `YearlyAnalyticsScreen._buildContent()`):
   - Year navigation header
   - Summary card (kWh or € based on toggle)
   - Monthly bar chart (consumption or cost based on toggle)
   - Year comparison chart (consumption or cost based on toggle)
   - Legend
   All using `context.watch<AnalyticsProvider>()` for data.

7. **`_buildCostToggle()`**: An IconButton or SegmentedButton in the app bar:
   ```dart
   Widget _buildCostToggle(BuildContext context) {
     final costConfig = context.read<CostConfigProvider>()
         .getActiveConfig(CostMeterType.electricity, DateTime.now());
     if (costConfig == null) return const SizedBox.shrink();
     return IconButton(
       icon: Icon(_showCosts ? Icons.euro : Icons.electric_bolt),
       onPressed: () => setState(() => _showCosts = !_showCosts),
       tooltip: _showCosts
           ? AppLocalizations.of(context)!.showConsumption
           : AppLocalizations.of(context)!.showCosts,
     );
   }
   ```

8. **Keep all helper methods** (`_addReading`, `_editReading`, `_deleteReading`) — move to the State class.

9. **Keep `_ReadingCard` and `_InterpolatedReadingCard`** as private widgets at the bottom of the file — unchanged.

**Tests** (in `electricity_screen_test.dart`):
- Bottom nav renders with "Analyse" and "Liste" tabs
- Default tab is Liste (index 1)
- Tapping Analyse switches to analysis content
- FAB visible on Liste tab
- FAB hidden on Analyse tab
- Visibility toggle only in app bar when on Liste tab
- Cost toggle only in app bar when on Analyse tab and cost config exists
- Cost toggle hidden when no cost config
- Existing reading list tests still pass
- Add/edit/delete still work from Liste tab

**Commit**: `feat(19): refactor electricity screen with bottom nav, IndexedStack, and inline analysis`

---

### Wave 3: Cost Toggle Integration (depends on Wave 2)

#### Task 19.5: Wire kWh/€ Toggle to Analysis Charts

**Files**:
- `lib/screens/electricity_screen.dart`
- `lib/widgets/charts/monthly_bar_chart.dart`
- `test/screens/electricity_screen_test.dart`
- `test/widgets/charts/monthly_bar_chart_test.dart`

**Changes**:

1. **MonthlyBarChart cost mode** — add optional cost support:
   ```dart
   final List<double?>? periodCosts;
   final bool showCosts;
   final String? costUnit;
   ```
   When `showCosts` is true, use `periodCosts[i]` for bar height instead of `periods[i].consumption`. Default `showCosts` to `false` so existing callers are unaffected.

2. **ElectricityScreen `_buildAnalyseTab()`** — pass cost data when `_showCosts` is true:
   ```dart
   // Summary card
   _YearlySummaryCard(
     totalConsumption: _showCosts ? data.totalCost : data.totalConsumption,
     // ... pass cost or consumption data based on _showCosts
   ),
   // Monthly bar chart
   MonthlyBarChart(
     periods: data.monthlyBreakdown,
     primaryColor: color,
     unit: _showCosts ? '€' : data.unit,
     showCosts: _showCosts,
     periodCosts: _showCosts ? data.monthlyCosts : null,
   ),
   // Year comparison chart
   YearComparisonChart(
     currentYear: data.monthlyBreakdown,
     previousYear: data.previousYearBreakdown,
     primaryColor: color,
     unit: _showCosts ? '€' : data.unit,
     showCosts: _showCosts,
     currentYearCosts: _showCosts ? data.monthlyCosts : null,
     previousYearCosts: _showCosts ? data.previousYearMonthlyCosts : null,
   ),
   ```

3. **Summary card in € mode**:
   When `_showCosts` is true, the summary card should show `totalCost` as the main value (with € prefix) instead of consumption. Adapt the embedded summary card widget or pass the appropriate value.

**Tests**:
- Toggle from kWh to €: bar chart shows cost values
- Toggle from kWh to €: year comparison shows cost lines
- Toggle from kWh to €: summary shows total cost
- Toggle back to kWh: reverts to consumption
- MonthlyBarChart with showCosts=true renders correct bar heights

**Commit**: `feat(19): wire kWh/€ toggle to analysis charts on electricity screen`

---

### Wave 4: Cleanup & Verification (depends on Wave 3)

#### Task 19.6: Remove analyticsHub Reference from Electricity & Final Cleanup

**Files**:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`
- Various test files (verification)

**Changes**:

1. **Verify `l10n.analyticsHub`** is no longer used in `electricity_screen.dart` (the analytics IconButton was removed in Task 19.4). Check if gas/water/heating screens still use it — if yes, keep the ARB key. If only electricity used it, remove it.

2. **Run `flutter gen-l10n`** to regenerate l10n after any ARB changes.

3. **Run `flutter test`** — all tests must pass.

4. **Run `flutter analyze`** — zero issues.

5. **Verify no orphaned imports**:
   - `grep -r "monthly_analytics_screen" lib/screens/electricity_screen.dart` should return nothing
   - `grep -r "analyticsHub" lib/screens/electricity_screen.dart` should return nothing

6. **Verify interpolated deltas are used correctly**:
   - The analytics provider's `_aggregateMonthlyConsumption()` uses `InterpolationService.getMonthlyConsumption()` which computes deltas at month boundaries. Confirm this is the source of data for the Analyse tab.

**Tests**:
- `flutter test` passes (all tests green)
- `flutter analyze` passes (zero issues)
- Dead code verification via grep

**Commit**: `test(19): verify full test suite (N pass) and zero analyze issues — mark phase 19 complete`

---

## Risk Mitigation

1. **StatefulWidget conversion**: Converting `ElectricityScreen` from `StatelessWidget` to `StatefulWidget` changes how it's used in tests. Update test scaffolding to pump the new widget correctly. The `const` constructor is preserved on the outer widget.

2. **IndexedStack memory**: Both tabs stay in the widget tree. The Analyse tab watches `AnalyticsProvider`, which triggers data loads. Use `addPostFrameCallback` in `initState` to load data only once, not on every tab switch.

3. **MonthlyBarChart backward compatibility**: The `showCosts` and `periodCosts` parameters default to `false`/`null`, so all existing callers (monthly analytics screen, yearly analytics screen) continue working without changes.

4. **YearComparisonChart backward compatibility**: Same approach — new optional parameters default to safe values. Gas/water/heating screens continue using the chart as-is until phases 20-22.

5. **MonthlyAnalyticsScreen preservation**: This screen is NOT deleted — gas, water, and heating still navigate to it. Only the electricity screen stops navigating there. The `import` is removed only from `electricity_screen.dart`.

6. **Year comparison chart fix scope**: The fix changes X-axis positioning globally for all callers of `YearComparisonChart`. Since gas/water/heating use the same chart widget on their yearly screens, they automatically benefit from the fix. Verify existing yearly analytics tests still pass.

7. **Cost toggle when config changes**: If the user deletes their cost config while on the Analyse tab with € mode, the toggle button disappears and `_showCosts` stays true but `monthlyCosts` will be null. Handle gracefully by falling back to consumption display when costs are unavailable.

## Verification Checklist

- [ ] **SC-15**: Bottom nav shows Analyse (left) + Liste (right), default Liste
- [ ] **SC-15**: IndexedStack preserves scroll position when switching tabs
- [ ] **SC-15**: FAB visible on Liste, hidden on Analyse
- [ ] **SC-16**: kWh/€ toggle in app bar on Analyse tab
- [ ] **SC-16**: Toggle switches all charts + summary between consumption and cost
- [ ] **SC-16**: Toggle hidden when no cost config exists
- [ ] **SC-17**: Year comparison chart: both lines aligned by calendar month
- [ ] **SC-17**: Previous year line starts at first data month, not January
- [ ] **SC-18**: Monthly bar chart shows correct per-month values
- [ ] **SC-19**: No separate navigation to MonthlyAnalyticsScreen from electricity
- [ ] **NFR-14**: All new strings localized EN + DE
- [ ] **NFR-15**: All tests pass, new tests cover nav, FAB, toggle, chart
- [ ] **NFR-16**: `flutter analyze` returns zero issues
