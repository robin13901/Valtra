# Phase 31: Smart Plug Overhaul - Research

**Researched:** 2026-04-01
**Domain:** Flutter / Dart — smart plug analytics screen, expandable card pattern, single-hue pie chart color scheme
**Confidence:** HIGH (all findings from direct codebase inspection)

---

## Summary

Phase 31 overlays the new analytics design (Phase 27/29 shared widgets) onto the existing smart plug Analyse tab, and replaces the current pop-up-menu "edit" flow with an inline expandable card pattern copied from Phase 29/heating_screen.dart. Three existing files change significantly: `smart_plug_analytics_screen.dart`, `smart_plugs_screen.dart`, and supporting analytics models. One new structural element must be introduced: a single-hue color scheme for the pie chart.

The current Analyse tab in `SmartPlugAnalyseTab` already has a month navigator and a pie chart, but uses a bespoke `_MonthNavigation` widget and the rainbow `pieChartColors` palette. The Liste tab currently navigates to a separate `SmartPlugConsumptionScreen` on card tap; this must become inline expandable (same structural pattern as `_HeatingMeterCard` in `heating_screen.dart`).

Room-based grouping exists today as both a pie chart section ("Consumption by Room") and a list breakdown; both must be removed. The per-plug pie chart and per-plug list remain (now as the primary and sole breakdown).

**Primary recommendation:** Migrate `SmartPlugAnalyseTab` to use shared widgets (`MonthSelector`, `MonthlySummaryCard`, `MonthlyBarChart`, `YearComparisonChart`, `HouseholdComparisonChart`) following the electricity screen pattern. Replace the rainbow `pieChartColors` with a single-hue blue/violet palette. Replace `_SmartPlugCard` + `SmartPlugConsumptionScreen` navigation with `_SmartPlugExpandableCard` (inline) following the `_HeatingMeterCard` pattern.

---

## Standard Stack

### Core (already in project)
| Component | File | Purpose |
|-----------|------|---------|
| `MonthSelector` | `lib/widgets/charts/month_selector.dart` | Month navigation widget |
| `MonthlySummaryCard` | `lib/widgets/charts/monthly_summary_card.dart` | Total for month + % change |
| `MonthlyBarChart` | `lib/widgets/charts/monthly_bar_chart.dart` | Scrollable monthly bar chart |
| `YearComparisonChart` | `lib/widgets/charts/year_comparison_chart.dart` | YoY comparison line chart |
| `HouseholdComparisonChart` | `lib/widgets/charts/household_comparison_chart.dart` | Multi-household comparison |
| `ConsumptionPieChart` | `lib/widgets/charts/consumption_pie_chart.dart` | Existing pie chart (reuse) |
| `AnalyticsProvider` | `lib/providers/analytics_provider.dart` | Monthly + yearly data for shared widgets |
| `SmartPlugAnalyticsProvider` | `lib/providers/smart_plug_analytics_provider.dart` | Per-plug monthly data |
| `SmartPlugProvider` | `lib/providers/smart_plug_provider.dart` | Plug list + consumption CRUD |
| `GlassCard` | `lib/widgets/liquid_glass_widgets.dart` | Card container |
| `LiquidGlassBottomNav` | `lib/widgets/liquid_glass_widgets.dart` | Bottom nav |

### No New Libraries Needed
All chart widgets, provider infrastructure, and UI components are in place. Phase 31 is purely composition and pattern migration.

---

## Architecture Patterns

### Recommended Project Structure (files to change)

```
lib/screens/
├── smart_plugs_screen.dart          # CHANGED: ListeTab expands inline, remove room grouping in list UI
├── smart_plug_analytics_screen.dart # CHANGED: Analyse tab rebuilt with shared widgets
lib/services/analytics/analytics_models.dart  # CHANGED: add single-hue colors, remove RoomConsumption from byRoom use
lib/providers/smart_plug_analytics_provider.dart  # CHANGED: must sync with AnalyticsProvider (monthly+yearly), remove byRoom

test/screens/
├── smart_plugs_screen_test.dart          # CHANGED: new expandable card tests
├── smart_plug_analytics_screen_test.dart # CHANGED: new shared widget composition tests
```

### Pattern 1: Analyse Tab — Electricity Screen Reference

The new `SmartPlugAnalyseTab` must mirror `ElectricityScreen._buildAnalyseTab()` but without the cost toggle and with a per-plug pie chart replacing the smart plug coverage line in `MonthlySummaryCard`.

```dart
// Source: lib/screens/electricity_screen.dart (_buildAnalyseTab)
return ListView(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
  children: [
    MonthSelector(
      selectedMonth: analyticsProvider.selectedMonth,
      onMonthChanged: (month) {
        analyticsProvider.setSelectedMonth(month);
        spProvider.setSelectedMonth(month);
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
      // No smartPlugKwh/smartPlugPercent for smart plugs screen
    ),
    const SizedBox(height: 24),
    // MonthlyBarChart
    // YearComparisonChart (if yearlyData has previousYear data)
    // HouseholdComparisonChart (if >1 household)
    // THEN: per-plug pie chart + per-plug list breakdown
  ],
);
```

**Key:** `initState` in `SmartPlugsScreen` must call all three required:
```dart
// Source: lib/screens/electricity_screen.dart (initState)
WidgetsBinding.instance.addPostFrameCallback((_) {
  final provider = context.read<AnalyticsProvider>();
  provider.setSelectedMeterType(MeterType.electricity);
  provider.setSelectedMonth(DateTime.now());
  provider.setSelectedYear(DateTime.now().year);
  context.read<SmartPlugAnalyticsProvider>().setSelectedMonth(DateTime.now());
});
```
For smart plugs, `setSelectedMeterType(MeterType.electricity)` is the correct type because smart plugs are a sub-dimension of electricity consumption.

### Pattern 2: Expandable Card — Heating Meter Reference

The current `_SmartPlugCard` navigates away to `SmartPlugConsumptionScreen` on tap. Replace with an inline expandable card following `_HeatingMeterCard`:

```dart
// Source: lib/screens/heating_screen.dart (_HeatingMeterCard)
class _SmartPlugExpandableCard extends StatefulWidget {
  final SmartPlugWithRoom plugWithRoom;
  const _SmartPlugExpandableCard({required this.plugWithRoom});
  @override State<_SmartPlugExpandableCard> createState() => _SmartPlugExpandableCardState();
}

class _SmartPlugExpandableCardState extends State<_SmartPlugExpandableCard> {
  bool _isExpanded = false;
  // ...
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header: tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // plug icon, name, room, latest consumption
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  PopupMenuButton<String>(/* edit / delete */),
                ],
              ),
            ),
          ),
          // Expanded: inline consumption list + add button
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildConsumptionSection(context),
          ],
        ],
      ),
    );
  }
}
```

The expanded section streams `provider.watchConsumptionsForPlug(plugId, locale)` (same stream used by `SmartPlugConsumptionScreen` today) and renders a `ListView.builder` with `shrinkWrap: true, physics: NeverScrollableScrollPhysics()`.

**Edit/Delete flow:** Inline consumption items use `SmartPlugConsumptionFormDialog.show()` and `ConfirmDeleteDialog.show()` — same dialogs already used. No new dialogs needed.

**Smart plug edit (name/room):** Continues to use `SmartPlugFormDialog.show()` from the PopupMenuButton, same as today.

### Pattern 3: Single-Hue Color Scheme

Current `pieChartColors` is a rainbow array defined in `analytics_models.dart`:
```dart
// Source: lib/services/analytics/analytics_models.dart
const List<Color> pieChartColors = [
  Color(0xFF5F4A8B), // ultra violet (brand)
  Color(0xFFFFD93D), // electricity yellow
  Color(0xFF6BC5F8), // water blue
  ...
];
```

For SPLG-02, define a new `smartPlugPieColors` list as shades of the electricity yellow (`AppColors.electricityColor = Color(0xFFFFD93D)`):

```dart
// New constant in analytics_models.dart
const List<Color> smartPlugPieColors = [
  Color(0xFFFFD93D), // 100% — brand electricity yellow
  Color(0xFFFFE57A), // ~75%
  Color(0xFFFFF0B0), // ~50%
  Color(0xFFEFC000), // darker shade
  Color(0xFFD4A800), // darker still
  Color(0xFFB88F00), // deep gold
  Color(0xFFFFEC99), // lighter
  Color(0xFFFFF5CC), // very light
  Color(0xFFFFD000), // saturated
  Color(0xFFE6B800), // mid-dark
];
```

**Why electricity yellow (not ultraViolet):** Smart plugs are categorized under electricity in the app's color system (`AppColors.electricityColor`). The Analyse tab shares the `colorForMeterType(MeterType.electricity)` color. Using yellow shades aligns with the electricity theme while satisfying the single-hue requirement.

The `SmartPlugAnalyticsProvider` must assign `smartPlugPieColors[i % smartPlugPieColors.length]` for `byPlug` colors instead of `pieChartColors`.

### Pattern 4: Removing Room-Based Grouping

**From the Analyse tab (SPLG-04):**
- Remove the "Consumption by Room" section title
- Remove the room `ConsumptionPieChart` call
- Remove the `_buildRoomSlices()` helper
- Remove the `...data.byRoom.map(...)` list
- Keep only "Consumption by Plug" section

**From the Liste tab (SPLG-04):**
- The current `_SmartPlugsList` groups plugs by room using `_RoomSection` headers
- Remove the room section grouping; render plugs as a flat list
- The `SmartPlugWithRoom.roomName` can remain on the card as a subtitle (still useful info)
- This means `_SmartPlugsList` changes from `ListView.builder` over `roomNames` to `ListView.builder` over flat `plugs` list

**Provider side:**
- `SmartPlugAnalyticsProvider._data.byRoom` field can be kept but is no longer used by the screen
- Optionally remove `_buildRoomBreakdown` in `loadData()` to save computation (do not compute `byRoom` anymore)

### Pattern 5: Provider Initialization in SmartPlugsScreen

Following the locked decision: "SmartPlugAnalyticsProvider must be in provider tree for ElectricityScreen" and "Electricity Analyse tab: MonthSelector syncs both AnalyticsProvider + SmartPlugAnalyticsProvider."

For `SmartPlugsScreen`, the `initState` must now also initialize `AnalyticsProvider` (needed for `MonthlyBarChart`, `YearComparisonChart`, `HouseholdComparisonChart`):

```dart
// Current (insufficient for Phase 31):
WidgetsBinding.instance.addPostFrameCallback((_) {
  context.read<SmartPlugAnalyticsProvider>().loadData();
});

// New (mirrors electricity screen):
WidgetsBinding.instance.addPostFrameCallback((_) {
  final analyticsProvider = context.read<AnalyticsProvider>();
  analyticsProvider.setSelectedMeterType(MeterType.electricity);
  analyticsProvider.setSelectedMonth(DateTime.now());
  analyticsProvider.setSelectedYear(DateTime.now().year);
  context.read<SmartPlugAnalyticsProvider>().setSelectedMonth(DateTime.now());
});
```

`AnalyticsProvider` is already in the provider tree (from `main.dart` MultiProvider). No new wiring required.

### Anti-Patterns to Avoid

- **Navigating to SmartPlugConsumptionScreen from _SmartPlugExpandableCard:** The entire point of SPLG-05 is to eliminate this navigation. Do not keep `_navigateToConsumption` in the new card.
- **Using global pieChartColors for smart plug breakdown:** These are rainbow colors. The new cards use `smartPlugPieColors` for the single-hue requirement.
- **Rendering byRoom anywhere in Phase 31:** SPLG-04 removes room grouping from UI. Do not add room pie chart or room list items in the new screen.
- **Reinventing the month sync pattern:** Use `analyticsProvider.setSelectedMonth()` + `spProvider.setSelectedMonth()` in `MonthSelector.onMonthChanged`, exactly as electricity screen does.
- **Using loadData() directly:** The new analytics pattern calls `setSelectedMonth()` + `setSelectedYear()` which trigger loads internally. Do not call `loadData()` directly in initState.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month navigation with prev/next chevrons | `_MonthNavigation` (delete it) | `MonthSelector` | Already built in Phase 27 |
| Summary card with % change | Custom card | `MonthlySummaryCard` | Already built in Phase 27 |
| Bar chart | Custom bar | `MonthlyBarChart` | Already built in Phase 27 |
| Year comparison chart | Custom | `YearComparisonChart` | Already built in Phase 27 |
| Household comparison | Custom | `HouseholdComparisonChart` | Already built in Phase 27 |
| Pie chart | Custom painter | `ConsumptionPieChart` | Already built, just change colors |
| Consumption form dialog | New dialog | `SmartPlugConsumptionFormDialog` | Already exists |
| Confirm delete dialog | Inline AlertDialog | `ConfirmDeleteDialog` | Already exists |
| Smart plug name/room edit dialog | New dialog | `SmartPlugFormDialog` | Already exists |

---

## Common Pitfalls

### Pitfall 1: Missing initState calls for AnalyticsProvider
**What goes wrong:** `monthlyData` and `yearlyData` are `null` → screens show "noData" even when data exists.
**Why it happens:** `AnalyticsProvider` only loads data when `setSelectedMeterType`, `setSelectedMonth`, and `setSelectedYear` are all called.
**How to avoid:** Call all three in `initState` (see Pattern 5 above). This is identical to the electricity/water/gas screens.
**Warning signs:** `monthlyData == null` in widget despite provider having household ID set.

### Pitfall 2: SmartPlugsScreen initState fires before AnalyticsProvider has householdId
**What goes wrong:** `setSelectedMeterType` is called but `_householdId == null` so `_loadMonthlyData` returns early.
**Why it happens:** Provider household IDs are set in `_onHouseholdChanged` in `_ValtraAppState`, which also uses `addPostFrameCallback`. The order is deterministic (they share the same household init path).
**How to avoid:** Use `WidgetsBinding.instance.addPostFrameCallback` (as current screens do) — this ensures the household ID has been set before loading. Do not call `setSelectedMonth` synchronously in the constructor.

### Pitfall 3: Expandable card using StatelessWidget
**What goes wrong:** `_isExpanded` state cannot be maintained; card always collapses.
**Why it happens:** StatelessWidget has no mutable state.
**How to avoid:** Expandable card must be `StatefulWidget` with `bool _isExpanded = false` state, matching `_HeatingMeterCard` pattern.

### Pitfall 4: StreamBuilder inside expanded section without shrinkWrap
**What goes wrong:** `StreamBuilder<List<ConsumptionWithLabel>>` renders a `ListView` that takes infinite height inside a `Column` inside a `GlassCard`.
**Why it happens:** Inner `ListView` has no bounded height constraint.
**How to avoid:** Use `shrinkWrap: true, physics: const NeverScrollableScrollPhysics()` on inner `ListView.builder`, exactly as `_HeatingMeterCard._buildReadingsSection` does.

### Pitfall 5: Deleting _SmartPlugsList room grouping breaks existing test expectations
**What goes wrong:** Tests checking for `_RoomSection` headers or room icons at specific positions fail.
**Why it happens:** `smart_plugs_screen_test.dart` has test: `'shows room section icon'` checking `Icons.meeting_room` in the list.
**How to avoid:** Update tests to reflect flat plug list. The room name still appears as a subtitle within each card but no longer as a section header.

### Pitfall 6: SmartPlugAnalyticsProvider still computing byRoom unnecessarily
**What goes wrong:** Unnecessary DAO calls computing room consumption data that is no longer rendered.
**Why it happens:** `loadData()` still queries `getTotalConsumptionForRoom` for each room.
**How to avoid:** Once byRoom section is removed from UI, either (a) remove the byRoom computation from `loadData()` entirely, or (b) keep it but it won't be rendered. Option (a) is cleaner for performance. This is not blocking but is tech debt if left.

### Pitfall 7: Single-hue colors too light to distinguish in pie chart
**What goes wrong:** Adjacent pie slices look identical.
**Why it happens:** Using too narrow a hue range or insufficiently spaced lightness values.
**How to avoid:** Ensure at least 30% perceived brightness difference between adjacent slice colors. Use a range spanning from saturated (0xFFFFD93D) to darker (0xFFB88F00) and lighter (0xFFFFF0B0).

---

## Code Examples

### Analyse Tab: Full Composition Pattern

```dart
// Source: lib/screens/electricity_screen.dart (_buildAnalyseTab)
Widget _buildAnalyseTab(BuildContext context) {
  final analyticsProvider = context.watch<AnalyticsProvider>();
  final spProvider = context.watch<SmartPlugAnalyticsProvider>();
  final locale = context.watch<LocaleProvider>().localeString;
  final color = colorForMeterType(MeterType.electricity);
  final monthlyData = analyticsProvider.monthlyData;
  final yearlyData = analyticsProvider.yearlyData;

  if (analyticsProvider.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (monthlyData == null) {
    return Center(child: Text(l10n.noData));
  }

  // previousMonthTotal from recentMonths (same pattern)
  double? previousMonthTotal;
  final selectedMonth = analyticsProvider.selectedMonth;
  for (final period in monthlyData.recentMonths) {
    final pm = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    if (period.periodStart.year == pm.year && period.periodStart.month == pm.month) {
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
          spProvider.setSelectedMonth(month);
          if (month.year != analyticsProvider.selectedYear) {
            analyticsProvider.setSelectedYear(month.year);
          }
        },
        locale: locale,
      ),
      const SizedBox(height: 16),
      MonthlySummaryCard(/* ... */),
      const SizedBox(height: 24),
      // MonthlyBarChart, YearComparisonChart, HouseholdComparisonChart ...
      // THEN per-plug pie + list
      if (spProvider.data != null && spProvider.data!.byPlug.isNotEmpty) ...[
        Text(l10n.consumptionByPlugTitle, style: ...),
        SizedBox(height: 250, child: ConsumptionPieChart(slices: ..., unit: 'kWh', locale: locale)),
        ...spProvider.data!.byPlug.map((plug) => _PlugBreakdownItem(plug: plug, locale: locale)),
      ],
    ],
  );
}
```

### Expandable Card: Consumption Section

```dart
// Source: lib/screens/heating_screen.dart (_buildReadingsSection pattern, adapted)
Widget _buildConsumptionSection(BuildContext context) {
  final provider = context.read<SmartPlugProvider>();
  final locale = context.watch<LocaleProvider>().localeString;
  return StreamBuilder<List<ConsumptionWithLabel>>(
    stream: provider.watchConsumptionsForPlug(widget.plugWithRoom.plug.id, locale),
    builder: (context, snapshot) {
      final items = snapshot.data ?? [];
      return Column(
        children: [
          // Header row: "Consumption" label + "Add" TextButton.icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(l10n.consumption, style: theme.textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addConsumption(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addConsumption),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noConsumption)),
          ...items.map((item) => ListTile(
            leading: const Icon(Icons.electric_bolt, color: AppColors.electricityColor),
            title: Text(item.intervalLabel),
            trailing: Row(children: [
              Text('${ValtraNumberFormat.consumption(item.consumption.valueKwh, locale)} kWh'),
              PopupMenuButton<String>(/* edit / delete */),
            ]),
          )),
          const SizedBox(height: 8),
        ],
      );
    },
  );
}
```

### Single-Hue Color Scheme

```dart
// Add to lib/services/analytics/analytics_models.dart
/// Single-hue (electricity yellow shades) colors for smart plug pie charts.
/// Satisfies SPLG-02 requirement.
const List<Color> smartPlugPieColors = [
  Color(0xFFFFD93D), // electricity yellow — brand
  Color(0xFFEFC000), // darker gold
  Color(0xFFFFE57A), // lighter yellow
  Color(0xFFD4A800), // deep amber
  Color(0xFFFFF0B0), // pale yellow
  Color(0xFFB88F00), // dark gold
  Color(0xFFFFEC99), // light amber
  Color(0xFFCC9900), // medium dark
  Color(0xFFFFF5CC), // very light
  Color(0xFFE6B800), // mid amber
];
```

---

## State of the Art

| Old Approach | New Approach | When Changed | Impact |
|--------------|--------------|--------------|--------|
| `_MonthNavigation` (bespoke) | `MonthSelector` (shared) | Phase 27 | Delete bespoke widget |
| Rainbow `pieChartColors` | `smartPlugPieColors` (single-hue) | Phase 31 | Define new constant |
| Navigation to `SmartPlugConsumptionScreen` | Inline expandable card | Phase 31 | Delete navigation, new card |
| Room-based pie chart + list | Removed | Phase 31 | Less surface area |
| `loadData()` in initState | `setSelectedMonth()` etc. | Phase 29/30 pattern | Use standard provider init |

**Deprecated/outdated in Phase 31:**
- `_MonthNavigation` class in `smart_plug_analytics_screen.dart`: removed entirely
- `_buildRoomSlices()` helper: removed
- `_RoomBreakdownItem` widget: removed
- `_SmartPlugCard._navigateToConsumption()`: removed (navigation eliminated)
- `SmartPlugConsumptionScreen`: NOT deleted (may be used from tests or future features), but no longer navigated to from `SmartPlugsScreen`
- `_RoomSection` in `_SmartPlugsList`: removed (flat list replaces room grouping)

---

## File Impact Summary

| File | Change Type | Nature of Change |
|------|-------------|------------------|
| `lib/screens/smart_plug_analytics_screen.dart` | Major rewrite | Replace entire Analyse tab with shared widget composition; remove room sections; add per-plug section using electricity pattern |
| `lib/screens/smart_plugs_screen.dart` | Significant | Replace `_SmartPlugCard` with `_SmartPlugExpandableCard`; update `initState`; flatten `_SmartPlugsList` to remove room grouping |
| `lib/services/analytics/analytics_models.dart` | Minor add | Add `smartPlugPieColors` constant |
| `lib/providers/smart_plug_analytics_provider.dart` | Minor | Change `byPlug` color assignment to use `smartPlugPieColors`; optionally remove byRoom computation |
| `test/screens/smart_plugs_screen_test.dart` | Update | Remove room grouping tests; add expandable card tests |
| `test/screens/smart_plug_analytics_screen_test.dart` | Major update | Replace all bespoke widget tests with shared widget tests; remove room chart tests |
| `lib/screens/smart_plug_consumption_screen.dart` | No change | Screen kept; no longer primary entry point |

---

## Open Questions

1. **Should `SmartPlugConsumptionScreen` be deleted or kept?**
   - What we know: Phase 31 removes navigation to it from `SmartPlugsScreen`. It is a complete, tested screen.
   - What's unclear: Whether any other nav path leads to it (analytics hub, deep links, etc.).
   - Recommendation: Keep the file; do not delete. Just stop navigating to it from `SmartPlugsScreen`. Reduces risk.

2. **Should `byRoom` computation be removed from `SmartPlugAnalyticsProvider.loadData()`?**
   - What we know: The `byRoom` list is no longer rendered after Phase 31.
   - What's unclear: Whether future phases will reintroduce room analytics.
   - Recommendation: Keep the field + computation for now to avoid breaking the data model. The DB cost is minimal (one aggregation query). This is not a blocker.

3. **MonthlySummaryCard for smart plugs: show `smartPlugKwh`/`smartPlugPercent`?**
   - What we know: The electricity screen passes `smartPlugKwh` and `smartPlugPercent` to show coverage. For the smart plugs screen, these would be redundant (the entire screen is about smart plugs).
   - Recommendation: Pass `smartPlugKwh: null, smartPlugPercent: null` (default) — i.e., do NOT show smart plug coverage line on the smart plugs Analyse tab summary card.

---

## Sources

### Primary (HIGH confidence — all from direct codebase inspection)
- `lib/screens/smart_plugs_screen.dart` — current ListeTab, card, navigation, room grouping
- `lib/screens/smart_plug_analytics_screen.dart` — current Analyse tab structure
- `lib/providers/smart_plug_analytics_provider.dart` — full provider API
- `lib/screens/electricity_screen.dart` — reference implementation for shared widget composition
- `lib/screens/heating_screen.dart` — reference implementation for expandable card pattern
- `lib/screens/smart_plug_consumption_screen.dart` — existing consumption entry screen
- `lib/services/analytics/analytics_models.dart` — `pieChartColors`, data models
- `lib/app_theme.dart` — brand colors (electricityColor, ultraViolet)
- `lib/widgets/charts/month_selector.dart` — MonthSelector API
- `lib/widgets/charts/monthly_summary_card.dart` — MonthlySummaryCard API
- `lib/widgets/charts/monthly_bar_chart.dart` — MonthlyBarChart API
- `lib/widgets/charts/consumption_pie_chart.dart` — ConsumptionPieChart API
- `lib/widgets/charts/household_comparison_chart.dart` — HouseholdComparisonChart API
- `lib/providers/analytics_provider.dart` — AnalyticsProvider init pattern
- `lib/main.dart` — provider tree setup, household wiring
- `test/screens/smart_plugs_screen_test.dart` — existing test patterns (39 tests across 3 files)
- `test/screens/smart_plug_analytics_screen_test.dart` — existing test expectations

---

## Metadata

**Confidence breakdown:**
- Current screen architecture: HIGH — read source files directly
- Shared widget APIs: HIGH — read all widget source files
- Expandable card pattern: HIGH — read heating_screen.dart fully
- Single-hue color palette: MEDIUM — color values derived from brand palette logic; exact shades are implementation-time choices
- Provider init pattern: HIGH — verified against electricity/water/gas screens

**Research date:** 2026-04-01
**Valid until:** 2026-05-01 (stable codebase, no external dependencies)
