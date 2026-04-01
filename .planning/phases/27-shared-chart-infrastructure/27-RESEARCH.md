# Phase 27: Shared Chart Infrastructure - Research

**Researched:** 2026-04-01
**Domain:** Flutter chart widgets (fl_chart), shared analytics UI components, widget deduplication
**Confidence:** HIGH

## Summary

Phase 27 requires building reusable chart widgets that all 5 analytics screens (electricity, gas, water, smart plug, heating) will consume in later phases. The codebase already has chart widgets (`MonthlyBarChart`, `YearComparisonChart`, `ConsumptionLineChart`, `ConsumptionPieChart`, `ChartLegend`) in `lib/widgets/charts/`, but they need significant reworking: the bar chart lacks horizontal scrolling and glow effects, the year comparison chart needs gradient fills and open-dot styling, and an entirely new household comparison chart is needed. Additionally, a month selector widget must replace the duplicated `_YearNavigationHeader` that exists identically in 4 screens, and a new monthly summary card must replace the duplicated `_YearlySummaryCard`.

The project uses fl_chart v0.68.0 (latest is v1.2.0, but upgrading is not necessary for the required features). All needed capabilities -- horizontal scrolling via SingleChildScrollView wrapping, gradient fills via `BarAreaData.gradient`, dashed lines via `dashArray`, custom dot painters via `FlDotCirclePainter`, and glow via custom `BoxShadow`/`BackgroundBarChartRodData` -- are available in v0.68.0. The codebase already uses `FlDotCirclePainter` with open dots (stroke-only circles) for the previous year line in `YearComparisonChart`, confirming the pattern works.

**Primary recommendation:** Refactor existing chart widgets in-place with new parameters, extract the duplicate navigation/summary widgets to `lib/widgets/charts/`, add a new `HouseholdComparisonChart`, and build a `MonthSelector` widget -- all tested in isolation before any screen integration.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fl_chart | ^0.68.0 (locked) | Bar, Line, Pie charts | Already in use; v0.68 has all needed APIs |
| provider | ^6.1.2 | State management | Already in use project-wide |
| intl | ^0.20.2 | Date formatting, locale-aware month names | Already in use for chart labels |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| google_fonts | ^6.2.1 | Plus Jakarta Sans font | Already wired in AppTheme |
| mocktail | ^0.3.0 | Mocking in tests | For AnalyticsProvider mock in widget tests |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| fl_chart 0.68 | fl_chart 1.2.0 | Upgrade would require migration effort; 0.68 has all needed features. Not worth the risk for this phase. |
| Custom glow via BoxShadow | fl_chart backDrawRodData | backDrawRodData draws a background bar, not a glow. Better to use a `Container` wrapper with `BoxShadow` or a `BackgroundBarChartRodData` with wider width and translucent color. |

## Architecture Patterns

### Recommended Project Structure
```
lib/widgets/charts/
  month_selector.dart              # NEW: Month navigation (replaces _YearNavigationHeader)
  monthly_summary_card.dart        # NEW: Monthly summary card (replaces _YearlySummaryCard)
  monthly_bar_chart.dart           # REFACTORED: Add scrolling, glow, opacity
  year_comparison_chart.dart       # REFACTORED: Gradient fill, open dots for prev year
  household_comparison_chart.dart  # NEW: Multi-household line chart
  consumption_line_chart.dart      # REFACTORED: Axis style updates (AXIS-01/02/03)
  consumption_pie_chart.dart       # UNCHANGED (kept for later phases)
  chart_legend.dart                # UNCHANGED
  chart_axis_style.dart            # NEW: Shared axis configuration (AXIS-01/02/03)

test/widgets/charts/
  month_selector_test.dart
  monthly_summary_card_test.dart
  monthly_bar_chart_test.dart      # Update existing tests
  year_comparison_chart_test.dart   # Update existing tests
  household_comparison_chart_test.dart
  chart_axis_style_test.dart
```

### Pattern 1: Shared Axis Configuration
**What:** Extract shared axis styling into a helper to enforce AXIS-01/02/03 across all charts
**When to use:** Every chart widget that uses fl_chart
**Example:**
```dart
// lib/widgets/charts/chart_axis_style.dart
class ChartAxisStyle {
  /// No vertical Y-axis line (AXIS-01)
  static FlBorderData borderData(BuildContext context) => FlBorderData(
    show: true,
    border: Border(
      bottom: BorderSide(color: Theme.of(context).dividerColor),
      // NO left border = removes vertical Y-axis line
    ),
  );

  /// Dashed horizontal grid lines with translucent labels (AXIS-02)
  static FlGridData gridData(BuildContext context) => FlGridData(
    show: true,
    drawVerticalLine: false,
    getDrawingHorizontalLine: (value) => FlLine(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
      strokeWidth: 1,
      dashArray: [4, 4],
    ),
  );

  /// Left titles as small translucent labels floating inside chart (AXIS-02)
  static AxisTitles leftTitles({
    required BuildContext context,
    required String unit,
  }) => AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 40,
      getTitlesWidget: (value, meta) {
        if (value == meta.min || value == meta.max) return const SizedBox.shrink();
        return Text(
          '${value.toStringAsFixed(0)} $unit',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
      },
    ),
  );
}
```

### Pattern 2: Scrollable Bar Chart
**What:** Wrap BarChart in SingleChildScrollView for horizontal scrolling, keeping axis labels fixed
**When to use:** MonthlyBarChart with >12 months of data
**Example:**
```dart
// AXIS-03: Chart content scrolls under fixed axis labels
Widget build(BuildContext context) {
  return Row(
    children: [
      // Fixed Y-axis labels
      SizedBox(
        width: 50,
        child: _buildYAxisLabels(context),
      ),
      // Scrollable chart area with equal padding on both sides
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController, // auto-scroll to current month
          child: SizedBox(
            width: _calculateChartWidth(), // barWidth * numBars + spacing
            child: BarChart(data),
          ),
        ),
      ),
    ],
  );
}
```

### Pattern 3: Month Selector Widget
**What:** Replaces `_YearNavigationHeader` with month-based navigation
**When to use:** Top of every analytics screen
**Example:**
```dart
class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onMonthChanged(
            DateTime(selectedMonth.year, selectedMonth.month - 1, 1),
          ),
        ),
        Expanded(
          child: Text(
            DateFormat.yMMMM(locale).format(selectedMonth), // "April 2026"
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _isCurrentMonth ? null : () => onMonthChanged(
            DateTime(selectedMonth.year, selectedMonth.month + 1, 1),
          ),
        ),
      ],
    );
  }
}
```

### Pattern 4: Bar Glow Effect
**What:** Glowing edge on current month bar (BAR-02)
**When to use:** Highlighted bar in MonthlyBarChart
**Example:**
```dart
// fl_chart doesn't have native glow, so use BackgroundBarChartRodData
// with a slightly wider, translucent rod behind the main bar
BarChartRodData(
  toY: value,
  color: primaryColor,
  width: 20,
  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
  backDrawRodData: isHighlighted ? BackgroundBarChartRodData(
    show: true,
    toY: value,
    color: primaryColor.withValues(alpha: 0.3),
    // Wider than the main bar to create glow effect
  ) : null,
)
// Alternative: wrap individual bar position in a Container with BoxShadow
// or use a CustomPainter overlay. backDrawRodData is simplest.
```

### Anti-Patterns to Avoid
- **Putting shared widgets in screen files:** All 4 screens have `_YearNavigationHeader` as private classes. The new widgets MUST be public in `lib/widgets/charts/`.
- **Hardcoding 12 months:** The bar chart should work with variable-length data. Use the periods list length, not a fixed 12.
- **Mixing data loading and UI:** Chart widgets should be pure stateless widgets taking data as input. The AnalyticsProvider handles all data fetching.
- **Upgrading fl_chart:** The current v0.68 has all needed features. Avoid a major version upgrade in this phase.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month name formatting | Custom month arrays | `DateFormat.yMMMM(locale)` / `DateFormat.MMM(locale)` from intl | Locale-aware, already used everywhere |
| Number formatting | Custom number formatters | `ValtraNumberFormat.consumption()` / `.currency()` | Already handles German decimal format |
| Dot painters for charts | Custom `CustomPainter` for dots | `FlDotCirclePainter` | fl_chart built-in; already used in YearComparisonChart for both filled (color=primary) and open (color=surface, stroke=primary) dots |
| Chart area gradient | Manual gradient painting | `BarAreaData(gradient: LinearGradient(...))` | fl_chart built-in; trivial to use |
| Dashed lines | Custom dash painting | `dashArray: [8, 4]` on `LineChartBarData` | fl_chart built-in; already used |
| Scrollable charts | Custom gesture detector | `SingleChildScrollView` + calculated width | Standard Flutter pattern; fl_chart is not natively scrollable |
| Color per meter type | Hardcoded colors | `colorForMeterType(MeterType)` from analytics_models.dart | Already implemented, returns AppColors constants |

**Key insight:** fl_chart is a low-level charting library with excellent customization hooks. Most visual requirements map directly to existing fl_chart properties. The glow effect is the only one that requires a creative workaround (using `backDrawRodData` or a custom overlay).

## Common Pitfalls

### Pitfall 1: Forgetting to Remove Left Border
**What goes wrong:** AXIS-01 says "remove vertical Y-axis line" but existing charts use `border: Border(bottom: ..., left: ...)` -- the `left` border IS the Y-axis line.
**Why it happens:** Copy-pasting existing chart code without updating `FlBorderData`.
**How to avoid:** Use the shared `ChartAxisStyle.borderData()` helper which only includes bottom border.
**Warning signs:** Charts still showing vertical line on left side.

### Pitfall 2: ScrollController Not Scrolling to Current Month
**What goes wrong:** Bar chart is horizontally scrollable but starts at month 1 instead of scrolling to show the current month.
**Why it happens:** Not calling `scrollController.jumpTo()` or `animateTo()` after initial layout.
**How to avoid:** Use `WidgetsBinding.instance.addPostFrameCallback` to scroll to the current month bar position after first build.
**Warning signs:** User always sees January bars, has to manually scroll to current period.

### Pitfall 3: Household Comparison Data Loading
**What goes wrong:** The current `AnalyticsProvider` only loads data for ONE household (the selected one). Household comparison (HCMP-01/02) needs data from ALL households.
**Why it happens:** `_getReadingsPerMeter()` uses `_householdId` internally.
**How to avoid:** The provider needs a new method that iterates over all household IDs from `HouseholdDao.getAllHouseholds()` and fetches per-household consumption data. This is a data layer change, not just a UI change.
**Warning signs:** Chart only shows one line when multiple households exist.

### Pitfall 4: Fixed vs Scrolling Axis Labels (AXIS-03)
**What goes wrong:** When chart scrolls horizontally, Y-axis labels scroll away.
**Why it happens:** Y-axis labels are inside the `BarChart`/`LineChart` widget which is inside `SingleChildScrollView`.
**How to avoid:** Split layout into fixed Y-axis column + scrollable chart area. Use `SideTitles(showTitles: false)` on left side of fl_chart, and render Y-axis labels separately as a `Column` outside the scroll view.
**Warning signs:** Y-axis labels disappear when scrolling right.

### Pitfall 5: Translucent Labels Inside Chart Area (AXIS-02)
**What goes wrong:** Value labels placed via `SideTitles` with `reservedSize` take space outside the chart, not inside.
**Why it happens:** fl_chart's `SideTitles` reserves space in the margin.
**How to avoid:** For "floating inside" labels, use `FlGridData.getDrawingHorizontalLine` to draw the grid lines, then overlay text via `extraLinesData` with `HorizontalLine` annotations, or use `SideTitles` with `reservedSize: 0` and `getTitlesWidget` returning a positioned widget. Another approach: keep labels in the side area but style them to appear as "inside" (small, translucent, aligned left).
**Warning signs:** Labels look like external axis labels rather than floating values.

### Pitfall 6: Test Isolation for Chart Widgets
**What goes wrong:** Chart widget tests fail because of missing localizations.
**Why it happens:** Chart widgets use `AppLocalizations.of(context)!` internally (e.g., for "No data" text).
**How to avoid:** Always wrap test widgets in `MaterialApp` with `localizationsDelegates` and `supportedLocales`. Initialize date formatting in `setUpAll`. Follow the established pattern from existing chart tests.
**Warning signs:** Null check errors on `AppLocalizations.of(context)`.

## Code Examples

### Current MonthlyBarChart (what exists)
```dart
// lib/widgets/charts/monthly_bar_chart.dart
// - Takes List<PeriodConsumption>, Color, String unit
// - NOT scrollable (renders all bars in available width)
// - No glow effect
// - Has border: Border(bottom: ..., left: ...) -- left line must be removed
// - Has highlightMonth but only changes color, no glow
// - Has cost/consumption toggle support
```

### Current Duplicate Widgets (confirmed identical)
```dart
// Found in: electricity_screen.dart, gas_screen.dart, water_screen.dart, heating_screen.dart
// _YearNavigationHeader: Row with chevron_left, year text, chevron_right
// _YearlySummaryCard: GlassCard showing totalConsumption, change%, cost, extrapolation
// ALL 4 copies are identical (verified by reading each one)
```

### Existing Dot Painter Pattern (from YearComparisonChart)
```dart
// Filled dot (current year):
FlDotCirclePainter(
  radius: 4,
  color: primaryColor,
  strokeColor: Theme.of(context).colorScheme.surface,
  strokeWidth: 1.5,
)

// Open dot (previous year):
FlDotCirclePainter(
  radius: 3,
  color: Theme.of(context).colorScheme.surface,  // transparent center
  strokeColor: primaryColor.withValues(alpha: 0.5),
  strokeWidth: 2,
)
```

### Gradient Fill Pattern (for YCMP-02)
```dart
// Current year: solid line with gradient fill underneath
LineChartBarData(
  spots: currentSpots,
  color: primaryColor,
  barWidth: 2.5,
  belowBarData: BarAreaData(
    show: true,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.3),
        primaryColor.withValues(alpha: 0.0),
      ],
    ),
  ),
)
```

### Chart Test Pattern (established in codebase)
```dart
// From test/widgets/charts/monthly_bar_chart_test.dart
Widget buildTestWidget({...}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(locale),
    home: Scaffold(
      body: SizedBox(
        height: 300,
        width: 400,
        child: MyChartWidget(...),
      ),
    ),
  );
}

setUpAll(() async {
  await initializeDateFormatting('de');
  await initializeDateFormatting('en');
});

// Verify chart data by extracting fl_chart widget data:
final barChart = tester.widget<BarChart>(find.byType(BarChart));
final data = barChart.data;
expect(data.barGroups.length, 12);
```

### Meter Type Color System
```dart
// lib/services/analytics/analytics_models.dart
Color colorForMeterType(MeterType type) {
  // electricity: Color(0xFFF59E0B) -- amber/yellow
  // gas:         Color(0xFFF97316) -- orange
  // water:       Color(0xFF06B6D4) -- cyan
  // heating:     Color(0xFFEF4444) -- red
  // smart plug:  Color(0xFF8B5CF6) -- purple (in AppColors)
}

// Each also has a container color for backgrounds:
AppColors.containerFor(color, isDark: isDark)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Year-based navigation per screen | Shared month-based navigation | v0.6.0 (this phase) | All screens get month selector instead of year selector |
| Private `_YearNavigationHeader` in each screen | Public `MonthSelector` widget | v0.6.0 (this phase) | Deduplication (DEBT-02), single source of truth |
| Private `_YearlySummaryCard` in each screen | Public `MonthlySummaryCard` widget | v0.6.0 (this phase) | Month-based summary with % change vs previous month |
| No household comparison | `HouseholdComparisonChart` | v0.6.0 (this phase) | New feature comparing consumption across households |
| Left border on charts (Y-axis line) | No left border (AXIS-01) | v0.6.0 (this phase) | Cleaner chart appearance |
| External axis labels | Floating translucent labels inside chart (AXIS-02) | v0.6.0 (this phase) | Modern chart style |
| No bar chart scrolling | Horizontal scroll with fixed Y-axis (AXIS-03) | v0.6.0 (this phase) | More months visible via scroll |

**Current chart setup (will change):**
- `FlBorderData` has `left` border (will be removed for AXIS-01)
- `BarAreaData` uses flat `color: primaryColor.withValues(alpha: 0.1)` (will become gradient for YCMP-02)
- No scrolling wrapper on bar chart (will add SingleChildScrollView for BAR-01)
- `YearComparisonChart` already has dashed lines and open dots (just needs gradient fill upgrade)

## Data Layer Implications

### Existing Data Flow (per-household, yearly)
```
AnalyticsProvider
  ._householdId (single household)
  .setSelectedYear(year) -> _loadYearlyData()
  ._getReadingsPerMeter(type, rangeStart, rangeEnd)
  ._aggregateMonthlyConsumption(readingsPerMeter, rangeStart, rangeEnd)
  -> YearlyAnalyticsData { monthlyBreakdown, previousYearBreakdown, ... }
```

### Required Data Flow Changes for v0.6.0
1. **Month-based navigation**: `AnalyticsProvider` already has `setSelectedMonth(DateTime)` and `navigateMonth(int delta)`. The monthly data loading exists but currently feeds `MonthlyAnalyticsData` with daily boundaries + recent months. This needs to be adapted to feed the new scrollable bar chart with many months of data.

2. **Household comparison (HCMP-01/02)**: Requires new data fetching that iterates ALL households:
```dart
// New method needed in AnalyticsProvider:
Future<Map<int, List<PeriodConsumption>>> _loadAllHouseholdsMonthly(
  MeterType type, DateTime rangeStart, DateTime rangeEnd,
) async {
  final allHouseholds = await _householdDao.getAllHouseholds();
  final result = <int, List<PeriodConsumption>>{};
  for (final household in allHouseholds) {
    // Temporarily switch householdId context or pass it through
    final readings = await _getReadingsPerMeterForHousehold(
      household.id, type, rangeStart, rangeEnd,
    );
    if (readings.isNotEmpty) {
      result[household.id] = _aggregateMonthlyConsumption(readings, rangeStart, rangeEnd);
    }
  }
  return result;
}
```
The current `_getReadingsPerMeter` uses `_householdId` instance variable. A refactored version that accepts householdId as parameter would be cleaner.

3. **Monthly summary with % change**: Need previous month's total for comparison. The existing `_loadMonthlyData()` already fetches bar data going back 6 months, so previous month total is available.

### New Analytics Model Needed
```dart
// Household comparison data
class HouseholdComparisonData {
  final Map<String, List<PeriodConsumption>> householdData; // name -> monthly
  final Map<String, Color> householdColors; // name -> color
}
```

## Open Questions

1. **Household comparison colors**: How to assign distinct colors to each household in the comparison chart? The codebase uses meter-type colors, not household colors. Options: use a predefined palette (like `pieChartColors`), or derive from household order.
   - What we know: `pieChartColors` has 10 distinct colors already defined.
   - Recommendation: Reuse `pieChartColors` for household comparison lines, assigned by household index.

2. **fl_chart v0.68 vs v1.2.0**: The project pins `^0.68.0` but latest is v1.2.0. Some APIs may have changed or been deprecated.
   - What we know: v0.68 has all needed features. The codebase compiles and tests pass with v0.68.
   - Recommendation: Stay on v0.68 for this phase. Upgrade can be a separate task if needed.

3. **Glow effect implementation (BAR-02)**: No native fl_chart glow API exists. Three approaches:
   - `BackgroundBarChartRodData` with wider translucent bar behind the main bar
   - Custom `BoxDecoration` with `BoxShadow` on a wrapper
   - Post-processing with `CustomPainter` overlay
   - Recommendation: Use `BackgroundBarChartRodData` -- it's built into fl_chart and requires no external overlay.

4. **Translucent labels inside chart (AXIS-02)**: fl_chart's `SideTitles` reserves space outside the chart drawing area. "Inside" labels need a different approach.
   - What we know: `reservedSize: 0` with a `getTitlesWidget` that returns a negative-offset positioned widget could work, but is hacky.
   - Recommendation: Use `SideTitles` with small `reservedSize` and style labels to be small + translucent. They'll be in the axis area but visually match the "floating inside" requirement. The alternative is to disable fl_chart titles entirely and overlay custom `Positioned` widgets, but that's fragile.

5. **Monthly summary card scope**: SUMM-01 says "total consumption for selected month with % change vs previous month." The existing `_YearlySummaryCard` shows yearly totals. The new card will have different data requirements.
   - Recommendation: Create a new `MonthlySummaryCard` widget rather than trying to make `_YearlySummaryCard` dual-purpose. The old yearly card may not be needed after the redesign.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `lib/widgets/charts/*.dart` -- all 5 existing chart widgets read and analyzed
- Codebase analysis: `lib/screens/{electricity,gas,water,heating}_screen.dart` -- all 4 duplicate widgets confirmed identical
- Codebase analysis: `lib/providers/analytics_provider.dart` -- full data flow understood
- Codebase analysis: `lib/services/analytics/analytics_models.dart` -- all data models documented
- Codebase analysis: `lib/app_theme.dart` -- color system and design tokens mapped
- Codebase analysis: `test/widgets/charts/*.dart` -- test patterns documented
- pubspec.lock: fl_chart version 0.68.0 confirmed

### Secondary (MEDIUM confidence)
- fl_chart GitHub documentation: bar_chart.md, line_chart.md -- API properties verified
- pub.dev: fl_chart latest version is 1.2.0, current project uses 0.68.0

### Tertiary (LOW confidence)
- fl_chart glow effect approach -- no official documentation, based on API analysis of `BackgroundBarChartRodData`
- AXIS-02 "inside labels" approach -- based on fl_chart architecture understanding, not verified implementation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- fl_chart v0.68 confirmed in lockfile, all APIs verified against docs
- Architecture: HIGH -- existing codebase patterns fully analyzed, widget locations confirmed
- Pitfalls: HIGH -- identified from direct codebase analysis (e.g., duplicate widgets verified, data flow traced)
- Glow effect: MEDIUM -- based on fl_chart API analysis, not tested implementation
- Inside labels: MEDIUM -- multiple approaches identified, best one needs implementation validation

**Research date:** 2026-04-01
**Valid until:** 2026-05-01 (stable: fl_chart 0.68 is locked, codebase well-understood)
