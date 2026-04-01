# Phase 30: Water & Gas Analytics - Research

**Researched:** 2026-04-01
**Domain:** Flutter screen redesign -- replicate proven electricity Analyse tab pattern for water and gas
**Confidence:** HIGH

## Summary

Phase 30 is a straightforward replication task. The electricity screen (Phase 29) established a proven pattern for the unified analytics Analyse tab using shared widgets from Phase 27. Water and gas screens currently use an OLD year-based design with private `_YearNavigationHeader` and `_YearlySummaryCard` widgets. These must be replaced with the new month-based composition pattern: MonthSelector, MonthlySummaryCard, MonthlyBarChart, YearComparisonChart, HouseholdComparisonChart.

The shared widgets are already fully parameterized by color and unit. The `AnalyticsProvider` already supports water and gas meter types (it handles all four types). The transformation is primarily a screen-level refactor: change `initState` to use `setSelectedMonth`, replace the `_buildAnalyseTab`/`_buildAnalyseContent` methods, remove dead private widget classes, and update tests.

**Primary recommendation:** Follow the electricity_screen.dart Analyse tab implementation line-for-line, substituting only: MeterType, color, provider references, cost toggle icon, and removing SmartPlugAnalyticsProvider (electricity-only). No new widgets, models, or provider APIs are needed.

## Standard Stack

No new libraries or dependencies required. Everything needed already exists in the codebase.

### Core (already in project)
| Library | Purpose | How Used |
|---------|---------|----------|
| provider | State management | `context.watch<AnalyticsProvider>()` |
| fl_chart | Charts | Used by MonthlyBarChart, YearComparisonChart, HouseholdComparisonChart |
| intl | Date formatting | Used by MonthSelector for month names |

### Shared Widgets (from Phase 27, already built)
| Widget | File | Purpose |
|--------|------|---------|
| MonthSelector | `lib/widgets/charts/month_selector.dart` | Month navigation with left/right chevrons |
| MonthlySummaryCard | `lib/widgets/charts/monthly_summary_card.dart` | Total consumption + % change vs previous month |
| MonthlyBarChart | `lib/widgets/charts/monthly_bar_chart.dart` | Scrollable bar chart with highlight and cost toggle |
| YearComparisonChart | `lib/widgets/charts/year_comparison_chart.dart` | Current vs previous year line chart |
| HouseholdComparisonChart | `lib/widgets/charts/household_comparison_chart.dart` | Multi-household line chart comparison |
| ChartLegend | `lib/widgets/charts/chart_legend.dart` | Legend items for year comparison chart |

## Architecture Patterns

### Reference Implementation: Electricity Screen (Phase 29)

The electricity screen at `lib/screens/electricity_screen.dart` is the canonical reference. The exact pattern to replicate is:

#### initState Pattern
```dart
// ELECTRICITY (reference):
WidgetsBinding.instance.addPostFrameCallback((_) {
  final provider = context.read<AnalyticsProvider>();
  provider.setSelectedMeterType(MeterType.electricity);
  provider.setSelectedMonth(DateTime.now()); // triggers _loadMonthlyData
  provider.setSelectedYear(DateTime.now().year); // triggers _loadYearlyData + household comparison
  // Sync smart plug provider to current month
  context.read<SmartPlugAnalyticsProvider>().setSelectedMonth(DateTime.now());
});

// WATER (target) -- same but MeterType.water, NO smart plug:
WidgetsBinding.instance.addPostFrameCallback((_) {
  final provider = context.read<AnalyticsProvider>();
  provider.setSelectedMeterType(MeterType.water);
  provider.setSelectedMonth(DateTime.now());
  provider.setSelectedYear(DateTime.now().year);
});

// GAS (target) -- same but MeterType.gas, NO smart plug:
WidgetsBinding.instance.addPostFrameCallback((_) {
  final provider = context.read<AnalyticsProvider>();
  provider.setSelectedMeterType(MeterType.gas);
  provider.setSelectedMonth(DateTime.now());
  provider.setSelectedYear(DateTime.now().year);
});
```

#### Analyse Tab Widget Composition
```
MonthSelector
  -> onMonthChanged: set month on AnalyticsProvider, sync year if boundary crossing
SizedBox(height: 16)
MonthlySummaryCard
  -> totalConsumption, previousMonthTotal, unit, month, color, locale
  -> (NO smartPlugKwh/smartPlugPercent for water/gas)
SizedBox(height: 24)
Text("Monthly Breakdown") + MonthlyBarChart
  -> periods: monthlyData.recentMonths
  -> highlightMonth: analyticsProvider.selectedMonth
  -> showCosts/periodCosts/costUnit from _showCosts toggle
SizedBox(height: 24)
[conditional] Text("Year over Year") + YearComparisonChart + ChartLegend
  -> only if yearlyData.previousYearBreakdown is non-null and non-empty
SizedBox(height: 24)
[conditional] Text("Households") + HouseholdComparisonChart
  -> only if householdComparisonData.length > 1
```

#### previousMonthTotal Extraction Pattern
```dart
// Extract from monthlyData.recentMonths inline -- no new API needed
double? previousMonthTotal;
final selectedMonth = analyticsProvider.selectedMonth;
for (final period in monthlyData.recentMonths) {
  final pm = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
  if (period.periodStart.year == pm.year &&
      period.periodStart.month == pm.month) {
    previousMonthTotal = period.consumption;
    break;
  }
}
```

#### MonthSelector onMonthChanged Pattern
```dart
onMonthChanged: (month) {
  analyticsProvider.setSelectedMonth(month);
  // Sync year if month crossed a year boundary
  if (month.year != analyticsProvider.selectedYear) {
    analyticsProvider.setSelectedYear(month.year);
  }
},
```

### Current Water Screen -- What Exists (OLD design)

**File:** `lib/screens/water_screen.dart` (1139 lines)

Current Analyse tab uses:
- `_YearNavigationHeader` (private widget, year-based nav) -- lines 295-338
- `_YearlySummaryCard` (private widget, year-based summary) -- lines 341-454
- Year-based `initState`: only calls `setSelectedMeterType(MeterType.water)` and `setSelectedYear(DateTime.now().year)` -- does NOT call `setSelectedMonth`
- `_buildAnalyseContent` receives `YearlyAnalyticsData` directly instead of using `monthlyData`
- Missing: MonthSelector, MonthlySummaryCard, HouseholdComparisonChart
- Present but needing update: MonthlyBarChart (used but without `highlightMonth`), YearComparisonChart (used correctly)

**Imports to add:** `month_selector.dart`, `monthly_summary_card.dart`, `household_comparison_chart.dart`
**Imports to remove (after cleanup):** `app_database.dart` (if no longer needed after removing `WaterMeter` type reference)
**Private widgets to REMOVE:** `_YearNavigationHeader`, `_YearlySummaryCard`

### Current Gas Screen -- What Exists (OLD design)

**File:** `lib/screens/gas_screen.dart` (753 lines)

Current Analyse tab uses:
- `_YearNavigationHeader` (private widget, year-based nav) -- lines 391-433
- `_YearlySummaryCard` (private widget, year-based summary) -- lines 436-550
- Year-based `initState`: only calls `setSelectedMeterType(MeterType.gas)` and `setSelectedYear(DateTime.now().year)` -- does NOT call `setSelectedMonth`
- `_buildAnalyseContent` receives `YearlyAnalyticsData` directly
- Missing: MonthSelector, MonthlySummaryCard, HouseholdComparisonChart

**Imports to add:** `month_selector.dart`, `monthly_summary_card.dart`, `household_comparison_chart.dart`
**Private widgets to REMOVE:** `_YearNavigationHeader`, `_YearlySummaryCard`

### Key Differences: Water/Gas vs Electricity

| Aspect | Electricity | Water | Gas |
|--------|-------------|-------|-----|
| MeterType | `MeterType.electricity` | `MeterType.water` | `MeterType.gas` |
| Color | `AppColors.electricityColor` (0xFFFFD93D yellow) | `AppColors.waterColor` (0xFF6BC5F8 blue) | `AppColors.gasColor` (0xFFFF8C42 orange) |
| Unit | `kWh` | `m3` | `m3` |
| SmartPlug coverage | YES (SmartPlugAnalyticsProvider) | NO | NO |
| Cost toggle icon | `Icons.electric_bolt` | `Icons.water_drop` | `Icons.local_fire_department` |
| Cost meter type | `CostMeterType.electricity` | `CostMeterType.water` | `CostMeterType.gas` |
| Data provider (Liste) | `ElectricityProvider` | `WaterProvider` | `GasProvider` |
| Provider needed | `SmartPlugAnalyticsProvider` | NOT needed | NOT needed |
| Liste tab structure | Flat list of readings | Meters with expandable readings | Flat list of readings |

**Critical simplification:** Water and gas do NOT need SmartPlugAnalyticsProvider. This means:
1. No `spProvider` / `SmartPlugAnalyticsProvider` in imports or providers
2. No `smartPlugKwh` / `smartPlugPercent` computation
3. MonthlySummaryCard gets `smartPlugKwh: null, smartPlugPercent: null` (or just omit them -- they're optional)

### Anti-Patterns to Avoid
- **Do NOT copy `_YearlySummaryCard` or `_YearNavigationHeader`:** These are dead code after conversion. Remove them entirely.
- **Do NOT keep year-based navigation in the Analyse tab:** The new design uses MonthSelector exclusively. Year changes happen implicitly when month crosses year boundary.
- **Do NOT duplicate the `previousMonthTotal` extraction:** Use the exact same inline pattern from electricity.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month navigation | Custom `_YearNavigationHeader` | `MonthSelector` | Already built, tested, handles edge cases (no future months) |
| Monthly summary with % change | Custom `_YearlySummaryCard` | `MonthlySummaryCard` | Already handles increase=error, decrease=green semantics |
| Bar chart | Custom chart code | `MonthlyBarChart` with `highlightMonth` | Scroll, alpha, cost toggle already built |
| Household comparison | N/A | `HouseholdComparisonChart` | Already handles interpolated vs actual lines |
| Year comparison | Already using `YearComparisonChart` | Keep using it | Already correct |
| Chart legend | Already using `ChartLegend` | Keep using it | Already correct |

## Common Pitfalls

### Pitfall 1: Forgetting setSelectedMonth in initState
**What goes wrong:** The old water/gas initState only calls `setSelectedYear`, not `setSelectedMonth`. If `setSelectedMonth` is not called, `monthlyData` remains null and the Analyse tab shows "No data available" even when data exists.
**Why it happens:** Copy-paste from old pattern without updating.
**How to avoid:** initState MUST call all three: `setSelectedMeterType`, `setSelectedMonth`, `setSelectedYear`
**Warning signs:** Analyse tab shows "No data available" despite readings existing in the database.

### Pitfall 2: Not Removing Dead Private Widgets
**What goes wrong:** `_YearNavigationHeader` and `_YearlySummaryCard` remain in the file as dead code, triggering analyzer warnings.
**Why it happens:** Forgetting to clean up after replacing the Analyse tab.
**How to avoid:** After replacing `_buildAnalyseTab` / `_buildAnalyseContent`, search for `_YearNavigationHeader` and `_YearlySummaryCard` and delete them entirely.

### Pitfall 3: Water Screen Has Multiple Meters
**What goes wrong:** Water has a different data model -- multiple meters per household (cold, hot, other). The `AnalyticsProvider` already handles this (aggregates across all meters for water), so no special handling is needed in the screen. But the Liste tab structure is completely different from electricity/gas.
**Why it happens:** Confusion about water's multi-meter model.
**How to avoid:** Only modify the Analyse tab. Leave the Liste tab completely unchanged. The AnalyticsProvider already aggregates water data across all meters.

### Pitfall 4: Teardown Timing in Tests
**What goes wrong:** Provider disposal races with async postFrameCallback loads, causing "used after being disposed" errors.
**Why it happens:** The new initState fires async operations. If tearDown disposes providers before these complete, errors occur.
**How to avoid:** Use the same tearDown pattern as electricity tests: `await Future.delayed(const Duration(milliseconds: 300))` before disposing providers.
**Reference:** `test/screens/electricity_screen_test.dart` lines 124-134.

### Pitfall 5: Test Expectations for Old Year-Based Assertions
**What goes wrong:** Existing gas/water tests check for year-based navigation (`find.text(year.toString())`, year chevrons). After conversion, these assertions will fail because the Analyse tab now uses MonthSelector (month-based).
**Why it happens:** Tests assert old behavior that no longer exists.
**How to avoid:** Update test assertions to check for MonthSelector, MonthlySummaryCard, MonthlyBarChart instead of year navigation and yearly summary.

### Pitfall 6: Gas Cost Config Uses kWh
**What goes wrong:** Gas cost configuration uses EUR/kWh (not EUR/m3). The AnalyticsProvider handles the m3-to-kWh conversion internally for cost calculations. No special handling needed in the screen.
**Why it happens:** Gas has a conversion factor (m3 -> kWh).
**How to avoid:** The screen just passes `_showCosts` to chart widgets. All conversion happens in AnalyticsProvider.

## Code Examples

### Complete Analyse Tab for Water (target implementation)

Based on electricity_screen.dart lines 156-296, adapted for water:

```dart
Widget _buildAnalyseTab(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final analyticsProvider = context.watch<AnalyticsProvider>();
  final locale = context.watch<LocaleProvider>().localeString;
  final color = colorForMeterType(MeterType.water);
  final monthlyData = analyticsProvider.monthlyData;
  final yearlyData = analyticsProvider.yearlyData;

  if (analyticsProvider.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (monthlyData == null) {
    return Center(child: Text(l10n.noData));
  }

  // Compute previousMonthTotal from recentMonths
  double? previousMonthTotal;
  final selectedMonth = analyticsProvider.selectedMonth;
  for (final period in monthlyData.recentMonths) {
    final pm = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    if (period.periodStart.year == pm.year &&
        period.periodStart.month == pm.month) {
      previousMonthTotal = period.consumption;
      break;
    }
  }

  return ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
    children: [
      MonthSelector(
        selectedMonth: analyticsProvider.selectedMonth,
        onMonthChanged: (month) {
          analyticsProvider.setSelectedMonth(month);
          if (month.year != analyticsProvider.selectedYear) {
            analyticsProvider.setSelectedYear(month.year);
          }
        },
        locale: locale,
      ),
      const SizedBox(height: 16),
      MonthlySummaryCard(
        totalConsumption: monthlyData.totalConsumption,
        previousMonthTotal: previousMonthTotal,
        unit: monthlyData.unit,
        month: analyticsProvider.selectedMonth,
        color: color,
        locale: locale,
      ),
      const SizedBox(height: 24),
      Text(l10n.monthlyBreakdown,
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SizedBox(
        height: 200,
        child: MonthlyBarChart(
          periods: monthlyData.recentMonths,
          primaryColor: color,
          unit: monthlyData.unit,
          highlightMonth: analyticsProvider.selectedMonth,
          locale: locale,
          showCosts: _showCosts,
          periodCosts: _showCosts ? monthlyData.periodCosts : null,
          costUnit: _showCosts ? (monthlyData.currencySymbol ?? '\u20AC') : null,
        ),
      ),
      const SizedBox(height: 24),
      if (yearlyData != null &&
          yearlyData.previousYearBreakdown != null &&
          yearlyData.previousYearBreakdown!.isNotEmpty) ...[
        Text(l10n.yearOverYear,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: YearComparisonChart(
            currentYear: yearlyData.monthlyBreakdown,
            previousYear: yearlyData.previousYearBreakdown,
            primaryColor: color,
            unit: yearlyData.unit,
            locale: locale,
            showCosts: _showCosts,
            currentYearCosts: _showCosts ? yearlyData.monthlyCosts : null,
            previousYearCosts:
                _showCosts ? yearlyData.previousYearMonthlyCosts : null,
            costUnit:
                _showCosts ? (yearlyData.currencySymbol ?? '\u20AC') : null,
          ),
        ),
        const SizedBox(height: 8),
        ChartLegend(items: [
          ChartLegendItem(color: color, label: l10n.currentYear),
          ChartLegendItem(
            color: color.withValues(alpha: 0.5),
            label: l10n.previousYear,
            isDashed: true,
          ),
        ]),
        const SizedBox(height: 24),
      ],
      if (analyticsProvider.householdComparisonData.length > 1) ...[
        Text(l10n.households, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: HouseholdComparisonChart(
            households: analyticsProvider.householdComparisonData,
            unit: monthlyData.unit,
            locale: locale,
          ),
        ),
      ],
    ],
  );
}
```

### Updated initState for Water
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = context.read<AnalyticsProvider>();
    provider.setSelectedMeterType(MeterType.water);
    provider.setSelectedMonth(DateTime.now());
    provider.setSelectedYear(DateTime.now().year);
  });
}
```

### Test Pattern: Verifying MonthSelector Appears on Analyse Tab
```dart
testWidgets('Analyse tab shows MonthSelector when data exists',
    (tester) => tester.runAsync(() async {
      // Add a water meter with readings
      final meterId = await dao.insertMeter(WaterMetersCompanion.insert(
        householdId: householdId,
        name: 'Cold Water',
        type: WaterMeterType.cold,
      ));
      final year = DateTime.now().year;
      final month = DateTime.now().month;
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(year, month > 1 ? month - 1 : 1, 1),
        valueCubicMeters: 100.0,
      ));
      await dao.insertReading(WaterReadingsCompanion.insert(
        waterMeterId: meterId,
        timestamp: DateTime(year, month, 15),
        valueCubicMeters: 130.0,
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      await tester.pumpWidget(wrapWithProviders(const WaterScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analysis'));
      await Future.delayed(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(MonthSelector), findsOneWidget);
      expect(find.byType(MonthlySummaryCard), findsOneWidget);

      await tester.pumpWidget(Container());
    }));
```

## State of the Art

| Old Approach (Water/Gas now) | New Approach (Electricity has) | Phase that Changed | Impact |
|------------------------------|-------------------------------|-------------------|--------|
| `_YearNavigationHeader` (year-based) | `MonthSelector` (month-based) | Phase 27 (widget) + 29 (electricity) | Monthly granularity, better UX |
| `_YearlySummaryCard` (year totals) | `MonthlySummaryCard` (month totals + % change) | Phase 27 (widget) + 29 (electricity) | Shows trends, not just annual sum |
| No household comparison | `HouseholdComparisonChart` | Phase 27 (widget) + 29 (electricity) | Multi-household users see comparison |
| `MonthlyBarChart` without highlight | `MonthlyBarChart` with `highlightMonth` | Phase 27 (widget) | Selected month visually highlighted |
| `setSelectedYear` only | `setSelectedMonth` + `setSelectedYear` | Phase 29 (electricity) | Both monthly and yearly data loaded |

**Dead code to remove from water_screen.dart:**
- `_YearNavigationHeader` class (lines 295-338)
- `_YearlySummaryCard` class (lines 341-454)
- `_buildAnalyseContent` method (replaced by new `_buildAnalyseTab`)

**Dead code to remove from gas_screen.dart:**
- `_YearNavigationHeader` class (lines 391-433)
- `_YearlySummaryCard` class (lines 436-550)
- `_buildAnalyseContent` method (replaced by new `_buildAnalyseTab`)

## Task Breakdown Guidance

This phase naturally splits into two plans:

### Plan 30-01: Water Analytics Screen Redesign
- Modify `lib/screens/water_screen.dart`:
  - Update initState (add setSelectedMonth)
  - Replace `_buildAnalyseTab` and `_buildAnalyseContent` with new month-based composition
  - Add missing imports (MonthSelector, MonthlySummaryCard, HouseholdComparisonChart)
  - Remove dead widgets (`_YearNavigationHeader`, `_YearlySummaryCard`)
  - Remove unused import (`app_database.dart` if no longer needed)
- Update `test/screens/water_screen_test.dart`:
  - Update Analyse tab tests to check for MonthSelector, MonthlySummaryCard, MonthlyBarChart
  - Add tests for month navigation, summary card display, household comparison
  - Use same tearDown timing pattern as electricity tests (300ms delay)

### Plan 30-02: Gas Analytics Screen Redesign
- Modify `lib/screens/gas_screen.dart`:
  - Identical transformation as water (different MeterType, color, icon)
  - Update initState
  - Replace `_buildAnalyseTab` and `_buildAnalyseContent`
  - Remove dead widgets
- Update `test/screens/gas_screen_test.dart`:
  - Mirror the water test updates
  - Gas readings use `GasReadingsCompanion.insert` with `valueCubicMeters`

### Estimated Line Counts
- Water screen: ~1139 lines -> ~900 lines (removal of ~250 lines of dead code, addition of ~10 lines for new imports)
- Gas screen: ~753 lines -> ~500 lines (removal of ~200 lines of dead code)
- Both screens gain: MonthSelector, MonthlySummaryCard, HouseholdComparisonChart, highlightMonth on MonthlyBarChart

## Open Questions

None. This is a well-defined replication task with a proven reference implementation. All widgets, providers, and data models already exist.

## Sources

### Primary (HIGH confidence)
- `lib/screens/electricity_screen.dart` -- reference implementation (Phase 29 output)
- `lib/screens/water_screen.dart` -- current water screen to transform
- `lib/screens/gas_screen.dart` -- current gas screen to transform
- `lib/widgets/charts/month_selector.dart` -- MonthSelector widget API
- `lib/widgets/charts/monthly_summary_card.dart` -- MonthlySummaryCard widget API
- `lib/widgets/charts/monthly_bar_chart.dart` -- MonthlyBarChart widget API
- `lib/widgets/charts/year_comparison_chart.dart` -- YearComparisonChart widget API
- `lib/widgets/charts/household_comparison_chart.dart` -- HouseholdComparisonChart widget API
- `lib/providers/analytics_provider.dart` -- AnalyticsProvider API (handles all meter types)
- `lib/services/analytics/analytics_models.dart` -- MeterType, MonthlyAnalyticsData, YearlyAnalyticsData, colorForMeterType, unitForMeterType
- `test/screens/electricity_screen_test.dart` -- reference test pattern
- `test/screens/water_screen_test.dart` -- current water tests to update
- `test/screens/gas_screen_test.dart` -- current gas tests to update

### Color Reference
| Meter Type | Color Constant | Hex Value | Visual |
|------------|---------------|-----------|--------|
| Electricity | `AppColors.electricityColor` | `0xFFFFD93D` | Yellow |
| Water | `AppColors.waterColor` | `0xFF6BC5F8` | Blue |
| Gas | `AppColors.gasColor` | `0xFFFF8C42` | Orange |
| Heating | `AppColors.heatingColor` | `0xFFFF6B6B` | Red |

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all widgets and providers already exist and are verified
- Architecture: HIGH -- electricity reference implementation is the exact pattern to replicate
- Pitfalls: HIGH -- based on direct code inspection of current vs target state
- Task breakdown: HIGH -- straightforward transformation with clear before/after

**Research date:** 2026-04-01
**Valid until:** 2026-05-01 (stable -- no external dependencies, internal codebase only)
