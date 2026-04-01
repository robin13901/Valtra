# Phase 32: Heating Analytics & Cleanup - Research

**Researched:** 2026-04-01
**Domain:** Flutter / Heating Analytics Overhaul + Deprecated Widget Removal
**Confidence:** HIGH

## Summary

Phase 32 has three distinct workstreams: (1) rework the heating Analyse tab to use the shared widget composition pattern established in Phases 29-30, (2) add a per-heater pie chart showing percentage distribution of unitless counter readings (HEAT-02), and (3) remove deprecated `GlassBottomNav` and `buildGlassFAB` from `liquid_glass_widgets.dart` plus clean up all callers (DEBT-01).

The heating screen is the only remaining screen that still uses the old yearly-only Analyse tab pattern (with local `_YearNavigationHeader` and `_YearlySummaryCard` classes). The Gas screen (Phase 30) is the direct reference implementation: it uses `MonthSelector → MonthlySummaryCard → MonthlyBarChart → YearComparisonChart → HouseholdComparisonChart`, and its `initState` calls all three required provider setters (`setSelectedMeterType`, `setSelectedMonth`, `setSelectedYear`).

The per-heater pie chart requires building per-meter consumption data that the current `AnalyticsProvider` does not expose. The analytics provider internally maintains `_heatingRatios` but aggregates all meters into a single `monthlyData`/`yearlyData`. For HEAT-02, the pie chart must show the proportional share of each heater's raw counter readings (not ratio-adjusted consumption) as a fraction of the total across all meters for the selected month. This requires accessing the `HeatingProvider.metersWithRooms` and computing per-meter deltas from `HeatingProvider.getReadingsWithDeltas`.

**Primary recommendation:** Follow the gas_screen.dart pattern exactly for the Analyse tab overhaul (HEAT-01). For the per-heater pie (HEAT-02), compute percentages inline in the `_buildAnalyseTab` widget from `HeatingProvider` data. For DEBT-01, remove both deprecated symbols from `liquid_glass_widgets.dart` and migrate the three callers (`households_screen.dart`, `rooms_screen.dart`, `smart_plug_consumption_screen.dart`) to `LiquidGlassBottomNav`-style FABs or standard Flutter FABs — then also remove the `GlassBottomNav` and `buildGlassFAB` test groups from both widget test files.

## Standard Stack

### Core (already in project — no new dependencies)

| Library | Purpose | Used By |
|---------|---------|---------|
| `analytics_provider.dart` | Provides `monthlyData`, `yearlyData`, `householdComparisonData` | Heating Analyse tab |
| `heating_provider.dart` | Provides `metersWithRooms`, `getReadingsWithDeltas` | Per-heater pie |
| `consumption_pie_chart.dart` | `ConsumptionPieChart` widget, takes `List<PieSliceData>` | HEAT-02 |
| `month_selector.dart` | `MonthSelector` widget | Analyse tab |
| `monthly_summary_card.dart` | `MonthlySummaryCard` widget | Analyse tab |
| `monthly_bar_chart.dart` | `MonthlyBarChart` widget | Analyse tab |
| `year_comparison_chart.dart` | `YearComparisonChart` widget | Analyse tab |
| `household_comparison_chart.dart` | `HouseholdComparisonChart` widget | Analyse tab |
| `analytics_models.dart` | `MeterType`, `PieSliceData`, `pieChartColors` | Analyse tab |

### No New Dependencies

All required widgets exist. No new packages are needed.

## Architecture Patterns

### Recommended Project Structure (No Changes)

The heating screen stays as a single file: `lib/screens/heating_screen.dart`. The smart plug analytics was extracted to a separate `SmartPlugAnalyseTab` class — but for heating, the Analyse tab content is simpler (no second provider needed) and should stay inline as a method/private class, following the gas pattern exactly.

### Pattern 1: Gas Screen as Direct Reference (HEAT-01)

**What:** Replace the old yearly-only Analyse tab with the month-based composition pattern.

**Key differences from gas:**
- No cost toggle (heating has no cost config — `_toCostMeterType(MeterType.heating)` returns `null`)
- Unit is `'units'` (from `unitForMeterType(MeterType.heating)`)
- `showCosts: false` always on all chart widgets
- `periodCosts: null`, `costUnit: null` always

**initState (critical):**
```dart
// Source: gas_screen.dart lines 39-45
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final provider = context.read<AnalyticsProvider>();
    provider.setSelectedMeterType(MeterType.heating);
    provider.setSelectedMonth(DateTime.now()); // triggers _loadMonthlyData
    provider.setSelectedYear(DateTime.now().year); // triggers _loadYearlyData + household comparison
  });
}
```

All three calls are required. The current heating `initState` only calls `setSelectedMeterType` and `setSelectedYear` — it is missing `setSelectedMonth`, which means `monthlyData` is never populated.

**Analyse tab build pattern:**
```dart
// Source: gas_screen.dart _buildAnalyseTab + _buildAnalyseContent
final monthlyData = analyticsProvider.monthlyData;
final yearlyData = analyticsProvider.yearlyData;

if (analyticsProvider.isLoading) {
  return const Center(child: CircularProgressIndicator());
}
if (monthlyData == null) {
  return Center(child: Text(l10n.noData));
}

// previousMonthTotal computed from recentMonths
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
      unit: monthlyData.unit,  // 'units'
      month: analyticsProvider.selectedMonth,
      color: color,
      locale: locale,
    ),
    // ... bar chart, year comparison, household comparison
    // + per-heater pie chart section (HEAT-02)
  ],
);
```

**NO SmartPlugAnalyticsProvider** — heating Analyse tab uses `AnalyticsProvider` only, as confirmed by the project decision notes.

### Pattern 2: Per-Heater Pie Chart (HEAT-02)

**What:** A `ConsumptionPieChart` showing percentage distribution of heating counter readings across meters.

**Key insight:** Heating meters are unitless proportional counters. The "share" of each meter is its total consumption delta for the selected month divided by the sum across all meters. This is different from smart plugs which use `totalSmartPlug` as denominator.

**Data source:** `HeatingProvider.metersWithRooms` + `AnalyticsProvider.monthlyData`. However, `AnalyticsProvider.monthlyData` gives *aggregated* consumption (all meters summed with ratios applied). For individual-meter percentages, we need to go through the `HeatingProvider.meters` and look at what the analytics provider already computed per meter — but this is not exposed.

**Recommended approach (inline computation in the UI widget):**
Use `HeatingProvider.metersWithRooms` to get meter names and compute each meter's latest-reading-delta for the month using the `getReadingsWithDeltas` method that already exists on the provider. The percentage is then each meter's delta relative to the total across all meters.

```dart
// Build pie slices from HeatingProvider for the selected month
List<PieSliceData> _buildHeaterSlices(
  HeatingProvider heatingProvider,
  DateTime selectedMonth,
) {
  final meters = heatingProvider.metersWithRooms;
  if (meters.isEmpty) return [];

  // For each meter, sum all deltas that fall in selectedMonth
  final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

  final meterTotals = <String, double>{};
  for (final mwr in meters) {
    final readings = heatingProvider.getReadingsWithDeltas(mwr.meter.id);
    double monthlyDelta = 0;
    for (final r in readings) {
      if (r.delta != null &&
          r.reading.timestamp.isAfter(monthStart) &&
          r.reading.timestamp.isBefore(monthEnd)) {
        monthlyDelta += r.delta!;
      }
    }
    if (monthlyDelta > 0) {
      meterTotals[mwr.meter.name] = monthlyDelta;
    }
  }

  final total = meterTotals.values.fold<double>(0, (a, b) => a + b);
  if (total == 0) return [];

  final colors = pieChartColors;
  int colorIndex = 0;
  return meterTotals.entries.map((e) => PieSliceData(
    label: e.key,
    value: e.value,
    percentage: (e.value / total) * 100,
    color: colors[colorIndex++ % colors.length],
  )).toList();
}
```

**Note:** Use `pieChartColors` (multi-hue brand colors), NOT `smartPlugPieColors` (single-hue yellow). The smart plug pie uses single-hue because SPLG-02 required it. Heating has no such constraint — multi-hue helps distinguish meters named after rooms.

**List below pie:** Similar to `_PlugBreakdownItem` in smart_plug_analytics_screen.dart — show meter name, room name, and percentage.

### Pattern 3: Deprecated Widget Removal (DEBT-01)

**What:** Remove `GlassBottomNav` class and `buildGlassFAB` function from `liquid_glass_widgets.dart`, and migrate all callers.

**Callers of `buildGlassFAB` (3 files):**
1. `lib/screens/households_screen.dart` — `floatingActionButton: buildGlassFAB(...)`
2. `lib/screens/rooms_screen.dart` — `floatingActionButton: buildGlassFAB(...)`
3. `lib/screens/smart_plug_consumption_screen.dart` — `floatingActionButton: buildGlassFAB(...)`

**No callers of `GlassBottomNav` in production code** — all screens already use `LiquidGlassBottomNav`. `GlassBottomNav` is only referenced in test files.

**Migration for FAB callers:** Replace `buildGlassFAB(...)` with a standard `FloatingActionButton` or `FloatingActionButton.extended`, styled to match the app theme. The simplest approach that preserves the glass aesthetic is:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => _showCreateDialog(context),
  tooltip: l10n.createHousehold,
  child: const Icon(Icons.add),
),
```

**Test file updates required:**
Both `test/widgets/liquid_glass_widgets_test.dart` and `test/widgets/liquid_glass_widgets_coverage_test.dart` contain `group('GlassBottomNav', ...)` and `group('buildGlassFAB', ...)` test groups that reference these deprecated symbols. These groups must be removed when the symbols are deleted.

**SmartPlugConsumptionScreen:** This file uses `buildGlassFAB` and is confirmed unused from navigation (no `Navigator.push` or route to it anywhere in `lib/`). It exists only as a test artifact. Decision: remove the file entirely along with its test file `test/screens/smart_plug_consumption_screen_test.dart`, as the context notes indicate "remove in Phase 32 if confirmed unused" and no navigation to it exists.

### Anti-Patterns to Avoid

- **Calling only `setSelectedYear` without `setSelectedMonth`:** The current heating screen's `initState` is missing `setSelectedMonth`. Without it, `monthlyData` is never loaded. The new initState must call all three setters.
- **Using SmartPlugAnalyticsProvider for heating:** The project decision notes explicitly state "Water/Gas/Heating Analyse tabs: NO SmartPlugAnalyticsProvider". Only `AnalyticsProvider` is used.
- **Using `smartPlugPieColors` for heater pie chart:** Those are single-hue yellow — appropriate for smart plugs, not for distinguishing rooms on a heating screen.
- **Keeping duplicate `_YearNavigationHeader` / `_YearlySummaryCard`:** These private classes in `heating_screen.dart` become dead code after the Analyse tab overhaul. Remove them.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month navigation | Custom date picker | `MonthSelector` | Already built in Phase 27 |
| Monthly summary display | Custom card | `MonthlySummaryCard` | Already built in Phase 27 |
| Bar chart | Custom painter | `MonthlyBarChart` | Already built in Phase 27 |
| Year comparison chart | Custom painter | `YearComparisonChart` | Already built in Phase 27 |
| Household comparison | Custom chart | `HouseholdComparisonChart` | Already built in Phase 27 |
| Pie chart | Custom painter | `ConsumptionPieChart` | Already built in Phase 31 |
| Pie slice data model | Custom model | `PieSliceData` | Already in `analytics_models.dart` |
| Pie colors | Custom color list | `pieChartColors` | Already in `analytics_models.dart` |

## Common Pitfalls

### Pitfall 1: Missing `setSelectedMonth` in initState

**What goes wrong:** `monthlyData` remains null, Analyse tab shows "No data available" even when readings exist.
**Why it happens:** `setSelectedMeterType` triggers `_loadMonthlyData` but it returns early if `_selectedMeterType` was already set. The new initState must call `setSelectedMonth` after `setSelectedMeterType`.
**How to avoid:** Use the exact three-call pattern from gas_screen.dart: `setSelectedMeterType` → `setSelectedMonth` → `setSelectedYear`.
**Warning signs:** `monthlyData == null` but `yearlyData != null`.

### Pitfall 2: tearDown Async Race

**What goes wrong:** Tests fail with "used after being disposed" or "A ChangeNotifier was used after being disposed".
**Why it happens:** New initState fires 2 async operations (`setSelectedMonth` + `setSelectedYear`). If tearDown disposes providers before these complete, errors occur.
**How to avoid:** Add `await Future.delayed(const Duration(milliseconds: 300))` at the top of `tearDown`, matching the gas/water test pattern.
**Warning signs:** Intermittent test failures on tearDown.

### Pitfall 3: Pie Chart Shows Nothing

**What goes wrong:** Per-heater pie chart is empty even when meters have readings.
**Why it happens:** Using year-aggregated data instead of month-scoped data, or `getReadingsWithDeltas` returns empty because readings are keyed by meterId in `HeatingProvider._readingsByMeter` which only loads when `setHouseholdId` is called.
**How to avoid:** Verify that `HeatingProvider` is provided and `setHouseholdId` has been called before accessing `getReadingsWithDeltas`. Use the same test setup pattern as existing heating tests.
**Warning signs:** `slices.isEmpty` in `ConsumptionPieChart`.

### Pitfall 4: Removing `buildGlassFAB` Without Updating Tests

**What goes wrong:** Compilation errors in `liquid_glass_widgets_test.dart` and `liquid_glass_widgets_coverage_test.dart` because they reference the deleted symbol.
**Why it happens:** Two test files both test `buildGlassFAB` in a `group('buildGlassFAB', ...)` block.
**How to avoid:** When deleting from lib, also delete the test groups in both test files.
**Warning signs:** `flutter test` fails to compile with `'buildGlassFAB' is not defined`.

### Pitfall 5: SmartPlugConsumptionScreen Deletion Without Test File

**What goes wrong:** Test file `test/screens/smart_plug_consumption_screen_test.dart` becomes orphaned or causes compile errors if the screen is deleted but the test is not.
**Why it happens:** Test imports the screen directly.
**How to avoid:** Delete both files together.
**Warning signs:** `flutter test` fails to import deleted screen.

### Pitfall 6: Unit Display for Heating

**What goes wrong:** The summary card shows "units" as the unit string which may look odd.
**Why it happens:** `unitForMeterType(MeterType.heating)` returns `'units'` (from `analytics_models.dart` line 138).
**How to avoid:** Accept `'units'` as-is — this is the established string in the codebase. Do not invent a new unit string.

## Code Examples

### Analyse Tab Widget Composition (HEAT-01)

```dart
// Source: gas_screen.dart _buildAnalyseTab (adapted for heating, no costs)
// Called from IndexedStack with _currentTab == 0

Widget _buildAnalyseTab(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final analyticsProvider = context.watch<AnalyticsProvider>();
  final heatingProvider = context.watch<HeatingProvider>();
  final locale = context.watch<LocaleProvider>().localeString;
  final color = colorForMeterType(MeterType.heating);
  final monthlyData = analyticsProvider.monthlyData;
  final yearlyData = analyticsProvider.yearlyData;

  if (analyticsProvider.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (monthlyData == null) {
    return Center(child: Text(l10n.noData));
  }

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
          showCosts: false,
          periodCosts: null,
          costUnit: null,
        ),
      ),
      // YearComparisonChart if prevYear data exists...
      // HouseholdComparisonChart if >1 household...
      // Per-heater pie chart section (HEAT-02)...
    ],
  );
}
```

### Per-Heater Pie Slices (HEAT-02)

```dart
// Compute per-meter monthly deltas from HeatingProvider
List<PieSliceData> _buildHeaterSlices(
  HeatingProvider heatingProvider,
  DateTime selectedMonth,
) {
  final meters = heatingProvider.metersWithRooms;
  if (meters.isEmpty) return [];

  final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

  double totalDelta = 0;
  final meterDeltas = <String, double>{};
  for (final mwr in meters) {
    final readings = heatingProvider.getReadingsWithDeltas(mwr.meter.id);
    double sum = 0;
    for (final r in readings) {
      if (r.delta != null &&
          !r.reading.timestamp.isBefore(selectedMonth) &&
          r.reading.timestamp.isBefore(monthEnd)) {
        sum += r.delta!;
      }
    }
    if (sum > 0) {
      meterDeltas[mwr.meter.name] = sum;
      totalDelta += sum;
    }
  }

  if (totalDelta == 0) return [];

  final colors = pieChartColors;
  int i = 0;
  return meterDeltas.entries.map((e) => PieSliceData(
    label: e.key,
    value: e.value,
    percentage: (e.value / totalDelta) * 100,
    color: colors[i++ % colors.length],
  )).toList();
}
```

### Pie Chart List Item (HEAT-02)

```dart
// Follows _PlugBreakdownItem from smart_plug_analytics_screen.dart
class _HeaterBreakdownItem extends StatelessWidget {
  final String meterName;
  final String roomName;
  final double percentage;
  final Color color;

  const _HeaterBreakdownItem({
    required this.meterName,
    required this.roomName,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(meterName),
      subtitle: Text(roomName),
      trailing: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

### Deprecated Widget Removal (DEBT-01)

**In `liquid_glass_widgets.dart`:**
- Delete lines 15-63 (the entire `GlassBottomNav` class and its `@Deprecated` annotation)
- Delete lines 101-135 (the entire `buildGlassFAB` function and its `@Deprecated` annotation)

**In `households_screen.dart`:**
```dart
// BEFORE:
floatingActionButton: buildGlassFAB(
  context: context,
  icon: Icons.add,
  onPressed: () => _showCreateDialog(context),
  tooltip: l10n.createHousehold,
),

// AFTER:
floatingActionButton: FloatingActionButton(
  onPressed: () => _showCreateDialog(context),
  tooltip: l10n.createHousehold,
  child: const Icon(Icons.add),
),
```

Same migration for `rooms_screen.dart`.

**`smart_plug_consumption_screen.dart`** — delete the entire file (confirmed: no callers in `lib/`).
**`test/screens/smart_plug_consumption_screen_test.dart`** — delete alongside the screen file.

**In test files:** Remove `group('GlassBottomNav', ...)` and `group('buildGlassFAB', ...)` blocks from both:
- `test/widgets/liquid_glass_widgets_test.dart` (lines 100-138 and 197-236)
- `test/widgets/liquid_glass_widgets_coverage_test.dart` (lines 100-138 and 197-236)

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `_YearNavigationHeader` + `_YearlySummaryCard` private classes (heating only) | `MonthlySummaryCard` + `MonthSelector` shared widgets | Eliminates ~100 LOC of duplicated widget code |
| Yearly-only Analyse tab (year nav + bar chart only) | Monthly-based design with month nav, summary, bar, year comparison, household comparison | Matches electricity/gas/water |
| `GlassBottomNav` (deprecated) | `LiquidGlassBottomNav` (current) | Full removal, zero warnings |
| `buildGlassFAB` (deprecated) | Standard `FloatingActionButton` | Full removal, zero warnings |

**Deprecated/outdated in current heating_screen.dart:**
- `_YearNavigationHeader`: Remove after Analyse tab overhaul
- `_YearlySummaryCard`: Remove after Analyse tab overhaul
- Old `_buildAnalyseContent` method: Replace entirely
- `initState` missing `setSelectedMonth` call: Fix in new implementation
- Imports: `year_comparison_chart.dart`, `monthly_bar_chart.dart`, `chart_legend.dart` already imported but need additions: `month_selector.dart`, `monthly_summary_card.dart`, `household_comparison_chart.dart`, `consumption_pie_chart.dart`

## Open Questions

1. **Per-heater pie denominator for central meter**
   - What we know: A `centralMeter` has a `heatingRatio` (e.g., 0.25) that is applied to its readings for aggregated consumption. For the pie chart (HEAT-02), should the pie show raw reading deltas or ratio-adjusted values?
   - What's unclear: The requirement says "percentage distribution of unitless counter readings across heaters" — this implies raw deltas, not ratio-adjusted. But visually it may be confusing if meter A reads 100 units and has 0.3 ratio while meter B reads 80 units with 1.0 ratio.
   - Recommendation: Use raw reading deltas as the requirement states "unitless counter readings". Document this decision in the plan.

2. **FloatingActionButton styling after `buildGlassFAB` removal**
   - What we know: `HouseholdsScreen` and `RoomsScreen` are full-page screens (not tab screens), so they use `Scaffold.floatingActionButton`. The `buildGlassFAB` gave them a glass container look.
   - What's unclear: Does the replacement standard FAB need custom styling to match the app's LiquidGlass aesthetic?
   - Recommendation: Use standard `FloatingActionButton` — the app theme likely already styles it appropriately. If not, add `FilledButton`-style FAB. Do not re-create the glass effect manually.

## Sources

### Primary (HIGH confidence)
- Direct code inspection of `lib/screens/heating_screen.dart` — current state (1215 lines)
- Direct code inspection of `lib/screens/gas_screen.dart` — reference pattern (596 lines)
- Direct code inspection of `lib/screens/smart_plug_analytics_screen.dart` — pie chart reference
- Direct code inspection of `lib/widgets/liquid_glass_widgets.dart` — deprecated symbols
- Direct code inspection of `lib/providers/analytics_provider.dart` — data flow
- Direct code inspection of `lib/providers/heating_provider.dart` — per-meter data
- Direct code inspection of `lib/services/analytics/analytics_models.dart` — models
- Direct code inspection of `test/screens/heating_screen_test.dart` — current test structure
- Direct code inspection of `test/screens/gas_screen_test.dart` — test pattern reference
- Direct code inspection of `test/widgets/liquid_glass_widgets_test.dart` — deprecated test groups
- Direct code inspection of `test/widgets/liquid_glass_widgets_coverage_test.dart` — deprecated test groups
- `lib/widgets/charts/consumption_pie_chart.dart` — pie chart widget API
- `lib/widgets/charts/monthly_summary_card.dart` — summary card API

### Grep analysis (HIGH confidence)
- `GlassBottomNav` / `buildGlassFAB` call sites in `lib/` — confirmed 3 callers for FAB, 0 callers for GlassBottomNav in production code
- `SmartPlugConsumptionScreen` references — confirmed: only defined in its own file + test, no navigation from `lib/`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all widgets already exist and are verified by code inspection
- Architecture (HEAT-01): HIGH — gas_screen.dart is a complete reference implementation
- Architecture (HEAT-02): MEDIUM — per-meter pie chart data approach requires inline computation; denominator question for centralMeter is an open design decision
- Architecture (DEBT-01): HIGH — all callers identified, removal is mechanical
- Pitfalls: HIGH — based on actual test patterns from water/gas implementation

**Research date:** 2026-04-01
**Valid until:** Stable codebase — valid until Phase 32 implementation begins
