# Phase 29: Electricity Analytics - Research

**Researched:** 2026-04-01
**Domain:** Flutter screen redesign, shared chart widget integration, smart plug coverage data
**Confidence:** HIGH

## Summary

Phase 29 replaces the electricity screen's existing yearly-based Analyse tab with the new unified month-based design built in Phase 27. All shared widgets from Phase 27 are production-ready and already tested. The primary work is: (1) replacing the existing `_buildAnalyseTab`/`_buildAnalyseContent` with a new implementation that uses `MonthSelector`, `MonthlySummaryCard`, `MonthlyBarChart`, `YearComparisonChart`, and `HouseholdComparisonChart`; (2) adding the smart plug coverage line to `MonthlySummaryCard` output (SUMM-02); and (3) wiring `HouseholdComparisonChart` with data from all households via `HouseholdProvider` + `AnalyticsProvider`.

The existing electricity screen already has `LiquidGlassBottomNav` with the correct two-tab (Analyse/Liste) structure and inline FAB on the Liste tab. That structure is preserved; only the Analyse tab content changes. The `AnalyticsProvider` currently operates on year-based data (`setSelectedYear`/`_loadYearlyData`). Phase 29 switches the electricity Analyse tab to use `setSelectedMonth`/`navigateMonth` (monthly data) and adds a household comparison data loading path.

**Primary recommendation:** Replace `_buildAnalyseContent` in `electricity_screen.dart` with month-based implementation using Phase 27 shared widgets. Extend `AnalyticsProvider` to load household comparison data. Add smart plug coverage fields to the data model and surface them in `MonthlySummaryCard`.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fl_chart | ^0.68.0 (locked) | Chart rendering | Already in use; all needed APIs available |
| provider | ^6.1.2 | State management | Project-wide pattern |
| intl | ^0.20.2 | Date/number formatting | Already in use everywhere |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mocktail | ^0.3.0 | Provider mocking in widget tests | Screen tests needing mock AnalyticsProvider |
| drift | ^2.x | In-memory test database | Screen integration tests |

### Key Existing Files (Phase 27 deliverables, fully ready)

| File | Exports | Confidence |
|------|---------|------------|
| `lib/widgets/charts/month_selector.dart` | `MonthSelector` | HIGH — tested, production |
| `lib/widgets/charts/monthly_summary_card.dart` | `MonthlySummaryCard` | HIGH — tested, production |
| `lib/widgets/charts/monthly_bar_chart.dart` | `MonthlyBarChart` | HIGH — tested, production |
| `lib/widgets/charts/year_comparison_chart.dart` | `YearComparisonChart` | HIGH — tested, production |
| `lib/widgets/charts/household_comparison_chart.dart` | `HouseholdComparisonChart`, `HouseholdChartData` | HIGH — tested, production |
| `lib/widgets/charts/chart_axis_style.dart` | `ChartAxisStyle` | HIGH — tested, production |
| `lib/widgets/charts/chart_legend.dart` | `ChartLegend`, `ChartLegendItem` | HIGH — tested, production |

## Architecture Patterns

### Recommended File Structure

```
lib/screens/electricity_screen.dart          # MODIFIED: Analyse tab redesign
lib/providers/analytics_provider.dart        # MODIFIED: household comparison data loading
lib/services/analytics/analytics_models.dart # MODIFIED: add smart plug coverage fields

test/screens/electricity_screen_test.dart    # MODIFIED: update Analyse tab tests
test/screens/electricity_screen_coverage_test.dart # MODIFIED: update coverage tests
test/providers/analytics_provider_test.dart  # MODIFIED: household comparison tests
```

### Pattern 1: Month-Based Analyse Tab

The existing `_buildAnalyseContent` uses year navigation + `YearlyAnalyticsData`. Replace with month navigation + `MonthlyAnalyticsData`.

**Current structure (to remove):**
```dart
// electricity_screen.dart — _buildAnalyseContent (current, year-based)
_YearNavigationHeader(...)            // private, local
_YearlySummaryCard(...)              // private, local
MonthlyBarChart(periods: data.monthlyBreakdown, ...)
YearComparisonChart(currentYear: ..., previousYear: ..., ...)
// No household comparison
```

**Replacement structure (month-based):**
```dart
// All Phase 27 shared widgets
MonthSelector(
  selectedMonth: provider.selectedMonth,
  onMonthChanged: (m) => provider.setSelectedMonth(m),
)
MonthlySummaryCard(
  totalConsumption: data.totalConsumption,
  previousMonthTotal: data.previousMonthTotal,
  unit: data.unit,
  month: provider.selectedMonth,
  color: colorForMeterType(MeterType.electricity),
  smartPlugKwh: data.smartPlugKwh,        // SUMM-02: new field
  smartPlugPercent: data.smartPlugPercent, // SUMM-02: new field
)
MonthlyBarChart(
  periods: data.recentMonths,
  primaryColor: color,
  unit: data.unit,
  highlightMonth: provider.selectedMonth,
)
YearComparisonChart(
  currentYear: yearData.monthlyBreakdown,
  previousYear: yearData.previousYearBreakdown,
  primaryColor: color,
  unit: data.unit,
)
HouseholdComparisonChart(
  households: householdData,  // List<HouseholdChartData>
  unit: data.unit,
)
```

### Pattern 2: Smart Plug Coverage (SUMM-02)

SUMM-02 requires the electricity summary card to show a "Smart plug coverage" line when smart plug data exists for the selected month. The data comes from `SmartPlugAnalyticsProvider.data` (already loaded and synced with `selectedHouseholdId`).

Two approaches:
- **Option A (preferred):** Add optional `smartPlugKwh` and `smartPlugPercent` to `MonthlySummaryCard`. The electricity screen passes them from `SmartPlugAnalyticsProvider`. Zero coupling between chart widget and provider.
- **Option B:** Create a subclass or wrapper `ElectricityMonthlySummaryCard`. Adds complexity, violates the "one widget, configurable" pattern.

Use Option A. The smart plug coverage is only relevant for electricity, so the fields are optional (nullable) and the card shows the coverage line only when non-null.

**Data computation:**
```dart
// In electricity screen's Analyse tab build method
final spData = context.watch<SmartPlugAnalyticsProvider>().data;
final double? spKwh = spData?.totalSmartPlug > 0 ? spData!.totalSmartPlug : null;
final double? spPercent = (spKwh != null && data.totalConsumption != null && data.totalConsumption! > 0)
    ? (spKwh / data.totalConsumption!) * 100
    : null;
```

**MonthlySummaryCard coverage line rendering:**
```dart
// In monthly_summary_card.dart — add optional fields and conditional row
if (smartPlugKwh != null && smartPlugPercent != null) ...[
  const SizedBox(height: 8),
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.power, size: 14, color: AppColors.electricityColor),
      const SizedBox(width: 4),
      Text(
        '${ValtraNumberFormat.consumption(smartPlugKwh!, locale)} kWh '
        '(${smartPlugPercent!.toStringAsFixed(1)}%)',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.electricityColor,
        ),
      ),
    ],
  ),
],
```

### Pattern 3: Household Comparison Data Loading

`HouseholdComparisonChart` requires `List<HouseholdChartData>` with per-household monthly consumption. The current `AnalyticsProvider` only loads data for the selected household.

**New method needed in `AnalyticsProvider`:**
```dart
// Add HouseholdDao dependency to AnalyticsProvider
final HouseholdDao _householdDao;

// New state field
List<HouseholdChartData> _householdComparisonData = [];

List<HouseholdChartData> get householdComparisonData => _householdComparisonData;

// New private method, called as part of _loadMonthlyData
Future<void> _loadHouseholdComparison(
  MeterType type,
  DateTime rangeStart,
  DateTime rangeEnd,
) async {
  final allHouseholds = await _householdDao.getAllHouseholds();
  final result = <HouseholdChartData>[];

  for (int i = 0; i < allHouseholds.length; i++) {
    final household = allHouseholds[i];
    final readings = await _getReadingsPerMeterForHousehold(
      household.id, type, rangeStart, rangeEnd,
    );
    if (readings.isEmpty) continue;

    final consumption = _aggregateMonthlyConsumption(readings, rangeStart, rangeEnd);
    if (consumption.isEmpty) continue;

    result.add(HouseholdChartData(
      name: household.name,
      periods: consumption,
      color: pieChartColors[i % pieChartColors.length],
    ));
  }

  _householdComparisonData = result;
}
```

**Refactor `_getReadingsPerMeter` to accept an optional householdId:**
The current implementation uses `_householdId` instance variable. Extract a `_getReadingsPerMeterForHousehold(int householdId, ...)` method that accepts householdId as parameter, then have the existing `_getReadingsPerMeter` call it with `_householdId!`.

### Pattern 4: AnalyticsProvider Month Navigation

The provider already supports month navigation:
- `setSelectedMonth(DateTime month)` → calls `_loadMonthlyData()`
- `navigateMonth(int delta)` → shifts month by delta, calls `_loadMonthlyData()`
- `selectedMonth` getter → returns `DateTime` (first of month)

The electricity screen currently calls `setSelectedYear(DateTime.now().year)` in `initState`. Change to:
```dart
// electricity_screen.dart initState
context.read<AnalyticsProvider>().setSelectedMeterType(MeterType.electricity);
context.read<AnalyticsProvider>().setSelectedMonth(DateTime.now());
```

The `MonthlyAnalyticsData.recentMonths` field provides the last 6 months for the bar chart. The bar chart's `highlightMonth` should be set to `provider.selectedMonth`.

### Pattern 5: Year Comparison Data

The electricity screen currently shows `YearComparisonChart` using `YearlyAnalyticsData.monthlyBreakdown` and `.previousYearBreakdown`. In the new design, year comparison for the selected month's year comes from `_loadYearlyData()`.

Two options:
- **Option A (simpler):** Keep the year comparison section using `yearlyData` (load both monthly + yearly). The screen calls both `setSelectedMonth` and also keeps track of the year to load yearly data.
- **Option B:** Add year comparison to `MonthlyAnalyticsData`. Requires provider changes.

Use Option A. The electricity screen watches both `monthlyData` (for summary + bar + smart plug coverage) and `yearlyData` (for year comparison + household comparison). Both are already in `AnalyticsProvider`.

**Screen initialization:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final provider = context.read<AnalyticsProvider>();
  provider.setSelectedMeterType(MeterType.electricity);
  provider.setSelectedMonth(DateTime.now());        // triggers _loadMonthlyData
  provider.setSelectedYear(DateTime.now().year);    // triggers _loadYearlyData
});
```

### Anti-Patterns to Avoid

- **Keep local `_YearNavigationHeader` and `_YearlySummaryCard`:** These private classes become dead code after Phase 29. Remove them.
- **Passing `yearlyData.monthlyBreakdown` to the bar chart:** The bar chart in the new design shows recent months (6+ months scrollable), not a full year. Use `monthlyData.recentMonths`.
- **Hardcoding `locale = 'de'` in the screen:** Use `context.watch<LocaleProvider>().localeString`.
- **Forgetting smart plug month sync:** `SmartPlugAnalyticsProvider` has its own `selectedMonth`. When the electricity screen's month changes, it must call `spProvider.setSelectedMonth(month)` so coverage data is for the same month.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month navigation UI | Custom chevron row | `MonthSelector` from Phase 27 | Already built, tested, locale-aware |
| Monthly summary display | Custom GlassCard with total | `MonthlySummaryCard` from Phase 27 | Already built, handles null/previous/change% |
| Bar chart | Custom bar widget | `MonthlyBarChart` from Phase 27 | Has scrolling, glow, alpha scheme |
| Year comparison | Custom line chart | `YearComparisonChart` from Phase 27 | Has gradient fill, dashed prev year |
| Household lines | Custom multi-line chart | `HouseholdComparisonChart` from Phase 27 | Has solid/dashed actual/interpolated |
| Number formatting | Custom formatters | `ValtraNumberFormat.consumption()` | German locale already handled |
| Color per meter type | Hardcoded hex color | `colorForMeterType(MeterType.electricity)` → `AppColors.electricityColor` | Consistent across screens |
| Household colors | Hardcoded colors | `pieChartColors[index % pieChartColors.length]` | 10-color palette already defined |

**Key insight:** All five chart/navigation widgets are already implemented and tested. Phase 29 is primarily a screen-level composition task, not a widget-building task.

## Common Pitfalls

### Pitfall 1: Smart Plug Month Mismatch
**What goes wrong:** Electricity screen shows month "March 2026" but smart plug coverage shows data from a different month.
**Why it happens:** `SmartPlugAnalyticsProvider` has its own `_selectedMonth`. If the electricity screen changes months without notifying the SP provider, coverage data is stale.
**How to avoid:** In `MonthSelector.onMonthChanged` callback, also call `context.read<SmartPlugAnalyticsProvider>().setSelectedMonth(newMonth)`.
**Warning signs:** Coverage percentage doesn't match what smart plug analytics screen shows for same month.

### Pitfall 2: Year Comparison Uses Wrong Data Source
**What goes wrong:** Year comparison chart appears empty even though electricity data exists.
**Why it happens:** Switching from yearly-based (`yearlyData.monthlyBreakdown`) to monthly-based (`monthlyData.recentMonths`) changes data source. Year comparison needs the full year's monthly breakdown, not recent 6 months.
**How to avoid:** Year comparison continues to use `yearlyData.monthlyBreakdown` and `yearlyData.previousYearBreakdown`. The screen initializes both `setSelectedMonth` and `setSelectedYear`.
**Warning signs:** Year comparison section shows "No data" while bar chart shows data.

### Pitfall 3: `HouseholdDao` Not Injected Into `AnalyticsProvider`
**What goes wrong:** `AnalyticsProvider` cannot call `_householdDao.getAllHouseholds()`.
**Why it happens:** `HouseholdDao` is not a current `AnalyticsProvider` dependency.
**How to avoid:** Add `HouseholdDao` to `AnalyticsProvider`'s constructor. Update `main.dart` where `AnalyticsProvider` is instantiated. Update all mock setups in tests that construct `AnalyticsProvider`.
**Warning signs:** Compile error or null reference in household comparison loading.

### Pitfall 4: Private Local Widgets Not Removed
**What goes wrong:** `_YearNavigationHeader` and `_YearlySummaryCard` remain in `electricity_screen.dart` as dead code.
**Why it happens:** Forgetting to delete them after replacing with shared widgets.
**How to avoid:** Delete both private classes. Run `flutter analyze` to confirm no unused declarations.
**Warning signs:** `flutter analyze` warning about unused private classes, or confusion about which card is rendering.

### Pitfall 5: Existing Analyse Tab Tests Break
**What goes wrong:** `electricity_screen_test.dart` tests check for year-based content ("Monthly Breakdown", year number in navigation). After redesign, the tests see month-based content.
**Why it happens:** Tests are brittle to the specific content of the Analyse tab.
**How to avoid:** Update tests to expect month-based content: `MonthSelector` widget, `MonthlySummaryCard` widget, month string in header.
**Warning signs:** Tests fail with "widget not found" for `_YearNavigationHeader` or year number in text.

### Pitfall 6: MonthlySummaryCard API Extension Breaks Existing Tests
**What goes wrong:** Adding `smartPlugKwh` and `smartPlugPercent` to `MonthlySummaryCard` constructor causes compile errors in existing tests.
**Why it happens:** Tests construct `MonthlySummaryCard` without the new fields.
**How to avoid:** Make both fields optional (nullable with default `null`). `const` constructor remains valid since nullable fields default to null.
**Warning signs:** Compile errors in `monthly_summary_card_test.dart`.

### Pitfall 7: Test Provider Setup Missing SmartPlugAnalyticsProvider
**What goes wrong:** Electricity screen test crashes because `SmartPlugAnalyticsProvider` is not in the provider tree.
**Why it happens:** New Analyse tab reads `SmartPlugAnalyticsProvider` for smart plug coverage.
**How to avoid:** Add `ChangeNotifierProvider<SmartPlugAnalyticsProvider>` to the test `MultiProvider` wrapper in electricity screen tests.
**Warning signs:** `ProviderNotFoundException` or `null` from `context.watch<SmartPlugAnalyticsProvider>()`.

## Code Examples

### MonthSelector Usage
```dart
// Source: lib/widgets/charts/month_selector.dart
MonthSelector(
  selectedMonth: analyticsProvider.selectedMonth,
  onMonthChanged: (month) {
    analyticsProvider.setSelectedMonth(month);
    spProvider.setSelectedMonth(month);  // sync smart plug coverage month
  },
  locale: locale,
)
```

### MonthlySummaryCard with Smart Plug Coverage (SUMM-02)
```dart
// Source: lib/widgets/charts/monthly_summary_card.dart (to be extended)
MonthlySummaryCard(
  totalConsumption: monthlyData.totalConsumption,
  previousMonthTotal: monthlyData.previousMonthTotal,
  unit: monthlyData.unit,
  month: analyticsProvider.selectedMonth,
  color: colorForMeterType(MeterType.electricity),
  locale: locale,
  // SUMM-02: optional smart plug coverage
  smartPlugKwh: spData?.totalSmartPlug,
  smartPlugPercent: computedPercent,
)
```

### MonthlyBarChart with Highlight
```dart
// Source: lib/widgets/charts/monthly_bar_chart.dart
SizedBox(
  height: 200,
  child: MonthlyBarChart(
    periods: monthlyData.recentMonths,
    primaryColor: color,
    unit: monthlyData.unit,
    highlightMonth: analyticsProvider.selectedMonth,
    locale: locale,
  ),
)
```

### YearComparisonChart (year data, not monthly)
```dart
// Source: lib/widgets/charts/year_comparison_chart.dart
if (yearlyData != null && yearlyData!.previousYearBreakdown != null) ...[
  Text(l10n.yearOverYear, style: Theme.of(context).textTheme.titleMedium),
  const SizedBox(height: 8),
  SizedBox(
    height: 250,
    child: YearComparisonChart(
      currentYear: yearlyData!.monthlyBreakdown,
      previousYear: yearlyData!.previousYearBreakdown,
      primaryColor: color,
      unit: yearlyData!.unit,
      locale: locale,
    ),
  ),
  const SizedBox(height: 8),
  ChartLegend(items: [
    ChartLegendItem(color: color, label: l10n.currentYear),
    ChartLegendItem(color: color.withValues(alpha: 0.5), label: l10n.previousYear, isDashed: true),
  ]),
],
```

### HouseholdComparisonChart
```dart
// Source: lib/widgets/charts/household_comparison_chart.dart
if (analyticsProvider.householdComparisonData.length > 1) ...[
  Text(l10n.households, style: Theme.of(context).textTheme.titleMedium),
  const SizedBox(height: 8),
  SizedBox(
    height: 250,
    child: HouseholdComparisonChart(
      households: analyticsProvider.householdComparisonData,
      unit: 'kWh',
      locale: locale,
    ),
  ),
],
```

### AnalyticsProvider Constructor Extension
```dart
// lib/providers/analytics_provider.dart — add HouseholdDao
class AnalyticsProvider extends ChangeNotifier {
  final ElectricityDao _electricityDao;
  // ... existing fields ...
  final HouseholdDao _householdDao;  // NEW

  List<HouseholdChartData> _householdComparisonData = [];  // NEW
  List<HouseholdChartData> get householdComparisonData => _householdComparisonData;

  AnalyticsProvider({
    required ElectricityDao electricityDao,
    // ... existing ...
    required HouseholdDao householdDao,   // NEW
  }) : // ... existing assignments ...
       _householdDao = householdDao;      // NEW
}
```

### New private helper: `_getReadingsPerMeterForHousehold`
```dart
// Extracted from _getReadingsPerMeter — accepts explicit householdId
Future<List<List<ReadingPoint>>> _getReadingsPerMeterForHousehold(
  int householdId,
  MeterType type,
  DateTime rangeStart,
  DateTime rangeEnd,
) async {
  // Same logic as _getReadingsPerMeter but with explicit householdId
  // instead of using _householdId instance variable
}

// Existing method becomes a thin wrapper:
Future<List<List<ReadingPoint>>> _getReadingsPerMeter(
  MeterType type, DateTime rangeStart, DateTime rangeEnd,
) async {
  if (_householdId == null) return [];
  return _getReadingsPerMeterForHousehold(_householdId!, type, rangeStart, rangeEnd);
}
```

### Test Provider Wrapper (for electricity screen tests)
```dart
// test/screens/electricity_screen_test.dart — updated wrapWithProviders
Widget wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: database),
      ChangeNotifierProvider<ElectricityProvider>.value(value: electricityProvider),
      ChangeNotifierProvider<AnalyticsProvider>.value(value: analyticsProvider),
      ChangeNotifierProvider<CostConfigProvider>.value(value: costConfigProvider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value(value: smartPlugAnalyticsProvider), // NEW
    ],
    child: MaterialApp(...),
  );
}
```

### l10n Strings Required for Phase 29

All needed strings already exist in `app_en.arb` and `app_de.arb`:
- `l10n.totalForMonth(monthName)` — `MonthlySummaryCard` header
- `l10n.previousMonth` / `l10n.nextMonth` — `MonthSelector` tooltips
- `l10n.changeFromLastMonth(changeStr)` — `MonthlySummaryCard` change row
- `l10n.monthlyBreakdown` — bar chart section header
- `l10n.yearOverYear` — year comparison section header
- `l10n.currentYear` / `l10n.previousYear` — chart legend labels
- `l10n.households` — household comparison section header (existing string)
- `l10n.noData` — empty state in charts

**Missing l10n strings (need to add):**
- `smartPlugCoverage` — label for coverage line in summary card (e.g., "Smart Plug Coverage")
- No other strings appear to be missing.

Verify by checking `app_en.arb` — "Smart Plug Coverage" or equivalent does not currently exist.

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `_YearNavigationHeader` (private local) | `MonthSelector` (shared Phase 27 widget) | Deduplication, month-based |
| `_YearlySummaryCard` (private local) | `MonthlySummaryCard` (shared Phase 27 widget) | Month totals + % change |
| No smart plug coverage in summary | Smart plug coverage line (SUMM-02) | New feature |
| `setSelectedYear` drives Analyse tab | `setSelectedMonth` drives Analyse tab | Month-level granularity |
| No household comparison | `HouseholdComparisonChart` | Cross-household visibility |
| `YearlyAnalyticsData` for bar chart | `MonthlyAnalyticsData.recentMonths` for bar chart | 6-month rolling window |

**Deprecated/outdated in Phase 29:**
- `_YearNavigationHeader` in `electricity_screen.dart`: remove
- `_YearlySummaryCard` in `electricity_screen.dart`: remove (yearly summary not shown in new design)
- `setSelectedYear` init call in electricity screen initState: replace with `setSelectedMonth`

## Open Questions

1. **Year comparison data source in month-based design**
   - What we know: `YearlyAnalyticsData.monthlyBreakdown` has the full year; `MonthlyAnalyticsData.recentMonths` only has 6 months.
   - What's unclear: Does Phase 29 show year comparison for the year containing the selected month, or a trailing 12-month window?
   - Recommendation: Show year comparison for the calendar year of the selected month (e.g., if March 2026 is selected, compare 2026 vs 2025). This requires `setSelectedYear` to stay in sync with `selectedMonth.year`. Call `provider.setSelectedYear(newMonth.year)` when month changes to a different year.

2. **`previousMonthTotal` field in `MonthlyAnalyticsData`**
   - What we know: `MonthlyAnalyticsData` currently has no `previousMonthTotal` field (see `analytics_models.dart`). `MonthlySummaryCard` requires it.
   - What's unclear: Does `_loadMonthlyData()` already fetch the previous month's consumption?
   - Looking at `_loadMonthlyData()`: it fetches `barStart` = 6 months back. `recentMonths` includes the previous month. The electricity screen can compute `previousMonthTotal` by finding the month before `selectedMonth` in `recentMonths`.
   - Recommendation: Compute `previousMonthTotal` in the screen by searching `monthlyData.recentMonths` for the month before `selectedMonth`. Do NOT add a new field to the model unless the pattern requires it in multiple places.

3. **Household comparison section title l10n key**
   - What we know: `l10n.households` exists (returns "Households" in English).
   - What's unclear: Is "Households" the right section label, or should it be "Household Comparison"?
   - Recommendation: Use `l10n.households` for now (consistent with existing pattern). If a dedicated "Household Comparison" key is needed, add it during planning.

4. **Chart height for household comparison**
   - The requirement says "household comparison" but doesn't specify height.
   - Other line charts in the codebase use `SizedBox(height: 250)`.
   - Recommendation: Use `height: 250` matching `YearComparisonChart` usage.

## Sources

### Primary (HIGH confidence)
- Codebase: `lib/screens/electricity_screen.dart` — full screen read, current structure documented
- Codebase: `lib/widgets/charts/*.dart` — all Phase 27 widgets read; APIs confirmed
- Codebase: `lib/providers/analytics_provider.dart` — full provider read; data flow traced
- Codebase: `lib/providers/smart_plug_analytics_provider.dart` — full read; `totalSmartPlug` field confirmed
- Codebase: `lib/services/analytics/analytics_models.dart` — `MonthlyAnalyticsData`, `YearlyAnalyticsData`, `SmartPlugAnalyticsData` models read
- Codebase: `lib/database/daos/household_dao.dart` — `getAllHouseholds()` method confirmed
- Codebase: `lib/providers/household_provider.dart` — household list management confirmed
- Codebase: `lib/l10n/app_en.arb` — all required l10n strings inventoried
- Test: `test/screens/electricity_screen_test.dart` — test patterns and existing coverage documented
- Test: `test/widgets/charts/monthly_summary_card_test.dart` — MonthlySummaryCard test patterns documented
- Planning: `.planning/phases/27-shared-chart-infrastructure/27-RESEARCH.md` — Phase 27 architecture confirmed
- Planning: `.planning/REQUIREMENTS.md` — ELEC-01, SUMM-02 requirements confirmed

### Secondary (MEDIUM confidence)
- Planning: `.planning/phases/27-shared-chart-infrastructure/27-04-PLAN.md` — `HouseholdChartData` API confirmed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries locked, all APIs verified in codebase
- Architecture: HIGH — existing code fully read; Phase 27 widgets confirmed production-ready
- Smart plug coverage: HIGH — `SmartPlugAnalyticsProvider.data.totalSmartPlug` confirmed available
- Household comparison data loading: HIGH — `HouseholdDao.getAllHouseholds()` confirmed, refactoring approach clear
- Pitfalls: HIGH — identified from direct code analysis

**Research date:** 2026-04-01
**Valid until:** 2026-05-01 (stable stack, all dependencies in-codebase)
