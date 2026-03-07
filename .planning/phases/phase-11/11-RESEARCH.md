# Phase 11: Smart Plug Analytics - Research

**Researched:** 2026-03-07
**Domain:** Smart plug consumption analytics with fl_chart pie charts, DAO aggregation, Provider state management
**Confidence:** HIGH

## Summary

Phase 11 adds a dedicated Smart Plug Analytics screen with two pie charts (consumption by plug, consumption by room), an "Other" consumption calculation (total electricity minus tracked smart plug usage), and a detailed breakdown list. All required DAO aggregation methods already exist in `SmartPlugDao` (Phase 4) and are fully tested. The analytics infrastructure from Phases 9-10 provides established patterns for Provider-based state management, fl_chart integration, date range selection, and localization.

The main new element is fl_chart's `PieChart` widget, which has not been used in the project yet (existing charts use `LineChart` and `BarChart`). fl_chart ^0.68.0 is already a dependency and its `PieChart` API follows the same pattern as existing chart widgets. The "Other" calculation requires combining data from two different DAOs (`ElectricityDao` for total household consumption and `SmartPlugDao` for tracked plug consumption), which is a new data-combination pattern for this project.

**Primary recommendation:** Create a new `SmartPlugAnalyticsProvider` (separate from the existing `AnalyticsProvider`) that orchestrates `SmartPlugDao`, `ElectricityDao`, and `InterpolationService` to produce chart-ready data. Follow the existing chart widget pattern for a new `ConsumptionPieChart` widget. Wire into the analytics hub with a new card entry and into the smart plugs screen via an AppBar action.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FR-7.4.1 | Pie chart showing consumption breakdown by individual smart plug | fl_chart PieChart API documented below; SmartPlugDao.getTotalConsumptionForPlug exists |
| FR-7.4.2 | Pie chart showing consumption breakdown by room | SmartPlugDao.getTotalConsumptionForRoom exists; RoomDao.getRoomsForHousehold for room list |
| FR-7.4.3 | Calculate and display "Other" consumption (total electricity minus total smart plug) | ElectricityDao + InterpolationService for total electricity; SmartPlugDao.getTotalSmartPlugConsumption for tracked total |
| FR-7.4.4 | List view with detailed per-plug and per-room breakdown | SmartPlugDao aggregation methods + SmartPlugProvider.plugsByRoom pattern |
| FR-7.4.5 | Time period selection for smart plug analytics (monthly, yearly, custom range) | Existing date range picker pattern from MonthlyAnalyticsScreen; period selection UI patterns established |
| FR-9.2.1 | Smart plug consumption aggregated by plug | SmartPlugDao.getTotalConsumptionForPlug (tested in smart_plug_dao_test.dart) |
| FR-9.2.2 | Smart plug consumption aggregated by room | SmartPlugDao.getTotalConsumptionForRoom (tested in smart_plug_dao_test.dart) |
| FR-9.2.3 | Total smart plug consumption for household | SmartPlugDao.getTotalSmartPlugConsumption (tested in smart_plug_dao_test.dart) |
</phase_requirements>

## Standard Stack

### Core (already in project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fl_chart | ^0.68.0 | PieChart widget for consumption breakdown | Already used for LineChart and BarChart in analytics; PieChart API follows same patterns |
| provider | ^6.1.2 | ChangeNotifier state management | Project-wide pattern for all providers |
| drift | ^2.19.0 | Database queries via SmartPlugDao/ElectricityDao | All DAO aggregation methods already exist |
| intl | ^0.20.2 | Date/number formatting in charts and lists | Used throughout analytics screens |

### Supporting (already in project)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mocktail | ^0.3.0 | Mocking DAOs/providers in tests | All widget and provider tests |

### No New Dependencies Needed
All required libraries are already in `pubspec.yaml`. No additions necessary.

## Architecture Patterns

### Recommended Project Structure
```
lib/
  providers/
    smart_plug_analytics_provider.dart    # NEW: Orchestrates data for smart plug analytics
  screens/
    smart_plug_analytics_screen.dart      # NEW: Main screen with pie charts + list
  services/analytics/
    analytics_models.dart                 # MODIFY: Add SmartPlugAnalyticsData model
  widgets/charts/
    consumption_pie_chart.dart            # NEW: Reusable pie chart widget

test/
  providers/
    smart_plug_analytics_provider_test.dart  # NEW
  screens/
    smart_plug_analytics_screen_test.dart    # NEW
  widgets/charts/
    consumption_pie_chart_test.dart          # NEW (optional - widget tests)
```

### Pattern 1: Separate Provider for Smart Plug Analytics
**What:** Create `SmartPlugAnalyticsProvider` extending `ChangeNotifier`, separate from the existing `AnalyticsProvider`.
**When to use:** The smart plug analytics combines data from fundamentally different sources (SmartPlugDao consumption records vs ElectricityDao meter readings + interpolation). Mixing this into the existing `AnalyticsProvider` would overload it.
**Rationale:** The existing `AnalyticsProvider` handles meter-type analytics using `InterpolationService` and `ReadingPoint` data. Smart plug consumption data is pre-aggregated (already in kWh) and does not need interpolation. Different data flow = different provider.

```dart
// Pattern following existing AnalyticsProvider structure
class SmartPlugAnalyticsProvider extends ChangeNotifier {
  final SmartPlugDao _smartPlugDao;
  final ElectricityDao _electricityDao;
  final InterpolationService _interpolationService;
  final InterpolationSettingsProvider _settingsProvider;

  int? _householdId;
  SmartPlugAnalyticsData? _data;
  bool _isLoading = false;
  AnalyticsPeriod _period = AnalyticsPeriod.monthly;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _selectedYear = DateTime.now().year;
  DateTimeRange? _customRange;

  // Loads: per-plug breakdown, per-room breakdown, total tracked, total electricity, "other"
  Future<void> loadData() async { ... }
}
```

### Pattern 2: Data Model for Smart Plug Analytics
**What:** A dedicated data model that holds all chart-ready data.
**Example:**

```dart
/// Data model for smart plug analytics display.
class SmartPlugAnalyticsData {
  final List<PlugConsumption> byPlug;       // per-plug breakdown
  final List<RoomConsumption> byRoom;       // per-room breakdown
  final double totalSmartPlug;              // sum of all tracked plugs
  final double? totalElectricity;           // total household electricity (may be null if no readings)
  final double? otherConsumption;           // totalElectricity - totalSmartPlug (may be null/negative)
  final String unit;                        // always 'kWh'

  const SmartPlugAnalyticsData({...});
}

class PlugConsumption {
  final int plugId;
  final String plugName;
  final String roomName;
  final double consumption;
  final Color color;  // assigned for pie chart
  const PlugConsumption({...});
}

class RoomConsumption {
  final int roomId;
  final String roomName;
  final double consumption;
  final Color color;
  const RoomConsumption({...});
}
```

### Pattern 3: PieChart Widget (follows existing chart widget pattern)
**What:** A reusable `ConsumptionPieChart` widget, following the same stateless-widget-with-data-input pattern as `ConsumptionLineChart` and `MonthlyBarChart`.
**Example:**

```dart
class ConsumptionPieChart extends StatelessWidget {
  final List<PieSliceData> slices;
  final String unit;

  const ConsumptionPieChart({
    super.key,
    required this.slices,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return PieChart(
      PieChartData(
        sections: slices.map((s) => PieChartSectionData(
          value: s.value,
          color: s.color,
          title: '${s.percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) { /* optional: highlight on touch */ },
        ),
      ),
    );
  }
}
```

### Pattern 4: Navigation Wiring
**What:** Two entry points to `SmartPlugAnalyticsScreen`:
1. From `AnalyticsScreen` (analytics hub) -- add a new card or section below meter type cards
2. From `SmartPlugsScreen` -- add an AppBar action icon (e.g., `Icons.pie_chart`)

**Follows existing navigation pattern:**
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const SmartPlugAnalyticsScreen()),
);
```

### Pattern 5: Period Selection (monthly/yearly/custom)
**What:** Use a `SegmentedButton` or `ChoiceChip` row for period mode selection, following the established month/year navigation patterns.
**Example flow:**
- Monthly: Show month navigation header (chevron left/right) -- reuse `_MonthNavigationHeader` pattern from `MonthlyAnalyticsScreen`
- Yearly: Show year navigation header -- reuse `_YearNavigationHeader` pattern from `YearlyAnalyticsScreen`
- Custom: Show date range picker button triggering `showDateRangePicker`

### Anti-Patterns to Avoid
- **Mixing into AnalyticsProvider:** Don't add smart plug data loading to the existing `AnalyticsProvider`. It handles meter-type interpolation data, not pre-aggregated consumption.
- **Querying per-plug in a loop without batching:** The DAO methods for per-plug totals require one query per plug. For many plugs, consider a single query if performance becomes an issue (unlikely for typical household scale of 3-10 plugs).
- **Negative "Other" without handling:** If total smart plug > total electricity (e.g., user entered electricity reading is stale), "Other" will be negative. Clamp to 0 or show a warning.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-plug aggregation | Custom SQL query | `SmartPlugDao.getTotalConsumptionForPlug()` | Already built, tested, handles edge cases |
| Per-room aggregation | Custom join | `SmartPlugDao.getTotalConsumptionForRoom()` | Already built with proper join, tested |
| Total household smart plug consumption | Manual iteration | `SmartPlugDao.getTotalSmartPlugConsumption()` | Handles join through rooms table |
| Total electricity consumption | Manual reading subtraction | `InterpolationService.getMonthlyConsumption()` with `ElectricityDao.getReadingsForRange()` | Interpolation handles boundary values correctly |
| Pie chart rendering | Custom canvas drawing | `fl_chart PieChart` widget | Handles animations, touch, labels, responsive sizing |
| Color assignment for pie slices | Manual color array | Generate from a predefined palette list | Ensures distinct, accessible colors |
| Localization | Hardcoded strings | ARB files + `AppLocalizations` | Project convention, EN + DE support |

**Key insight:** The critical infrastructure (DAO aggregation, interpolation, chart library, state management) is all in place. Phase 11 is primarily a UI/integration task connecting existing data pipelines to new display components.

## Common Pitfalls

### Pitfall 1: "Other" Consumption Can Be Negative or Null
**What goes wrong:** If total smart plug consumption exceeds total electricity (stale readings, data entry errors), or if there are no electricity readings for the period, "Other" becomes negative or undefined.
**Why it happens:** Smart plug consumption is entered as consumption deltas (kWh used), while electricity is meter readings that need interpolation. They may not align temporally.
**How to avoid:** Clamp "Other" to max(0, totalElectricity - totalSmartPlug). If totalElectricity is null (no readings), show "Other" as unavailable rather than negative. Display a subtle info icon explaining the calculation.
**Warning signs:** Negative values in the "Other" pie slice, or percentages summing to > 100%.

### Pitfall 2: Empty State When No Smart Plug Data
**What goes wrong:** Screen shows blank charts with no helpful guidance.
**Why it happens:** New household or household with no smart plug consumption entries.
**How to avoid:** Follow the established empty state pattern (icon + text) from `SmartPlugsScreen`. Check if plugs exist but have no consumption vs no plugs at all -- different messages.
**Warning signs:** Empty white space where charts should be.

### Pitfall 3: Date Range Mismatch Between Smart Plug and Electricity Data
**What goes wrong:** Smart plug consumption uses `intervalStart` for date filtering while electricity uses `timestamp`. The semantics differ.
**Why it happens:** Smart plug consumption is pre-aggregated (a period's consumption), while electricity readings are point-in-time meter readings.
**How to avoid:** For smart plug data, filter by `intervalStart >= rangeStart && intervalStart < rangeEnd`. For electricity, use `InterpolationService.getMonthlyConsumption()` which handles boundary interpolation correctly.
**Warning signs:** Period totals not matching between the smart plug and electricity sides.

### Pitfall 4: Pie Chart Color Distinctness
**What goes wrong:** Multiple plugs/rooms get similar colors, making the chart unreadable.
**Why it happens:** Random or sequential color assignment from a limited palette.
**How to avoid:** Use a pre-defined palette with maximally distinct colors. The project already has category colors (`AppColors.electricityColor`, etc.). Extend with a list of 8-10 distinct colors for pie slices. Use the same color for a plug in both the chart and the list below it.
**Warning signs:** Adjacent pie slices with visually similar colors.

### Pitfall 5: Provider Not Registered in main.dart
**What goes wrong:** `Provider.of<SmartPlugAnalyticsProvider>` throws "ProviderNotFoundException".
**Why it happens:** New provider created but not added to `MultiProvider` in `main.dart`.
**How to avoid:** Add `ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value()` to the `MultiProvider` list in `main.dart`. Wire `setHouseholdId` in `_onHouseholdChanged()`.
**Warning signs:** Runtime crash when navigating to smart plug analytics.

### Pitfall 6: Forgetting to Wire Household Changes
**What goes wrong:** Smart plug analytics shows data from wrong/previous household.
**Why it happens:** `_onHouseholdChanged` in `_ValtraAppState` does not call `smartPlugAnalyticsProvider.setHouseholdId()`.
**How to avoid:** Add the new provider to the household change listener in `main.dart`, following the pattern used by `analyticsProvider`.

## Existing Infrastructure (Detailed API Reference)

### SmartPlugDao Aggregation Methods (Phase 4, fully tested)

```dart
// Per-plug total in date range
Future<double> getTotalConsumptionForPlug(int smartPlugId, DateTime from, DateTime to)

// Per-room total in date range (joins smartPlugs to filter by room)
Future<double> getTotalConsumptionForRoom(int roomId, DateTime from, DateTime to)

// Total for entire household in date range (joins through rooms)
Future<double> getTotalSmartPlugConsumption(int householdId, DateTime from, DateTime to)

// Get all plugs for household (for iterating per-plug breakdown)
Future<List<SmartPlug>> getSmartPlugsForHousehold(int householdId)

// Get room for a plug (for building plug-to-room mapping)
Future<Room> getRoomForSmartPlug(int smartPlugId)
```

### ElectricityDao Methods for "Other" Calculation

```dart
// Get readings in date range + surrounding readings for interpolation
Future<List<ElectricityReading>> getReadingsForRange(int householdId, DateTime rangeStart, DateTime rangeEnd)
```

Use with `InterpolationService.getMonthlyConsumption()` to get total electricity for a period:
```dart
final readings = await electricityDao.getReadingsForRange(householdId, from, to);
final readingPoints = fromElectricityReadings(readings);
final monthly = interpolationService.getMonthlyConsumption(
  readings: readingPoints,
  rangeStart: from,
  rangeEnd: to,
  method: InterpolationMethod.linear,
);
final totalElectricity = monthly.fold<double>(0, (sum, p) => sum + p.consumption);
```

### RoomDao Methods for Room Listing

```dart
Future<List<Room>> getRoomsForHousehold(int householdId)
```

### SmartPlugProvider Existing Patterns

```dart
// Plugs grouped by room name (for display)
Map<String, List<SmartPlugWithRoom>> get plugsByRoom
```

### Database Tables (relevant)

```dart
// SmartPlugConsumptions table
class SmartPlugConsumptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get smartPlugId => integer().references(SmartPlugs, #id)();
  IntColumn get intervalType => intEnum<ConsumptionInterval>()(); // daily, weekly, monthly, yearly
  DateTimeColumn get intervalStart => dateTime()();
  RealColumn get valueKwh => real()();
}

// ElectricityReadings table
class ElectricityReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get valueKwh => real()(); // cumulative meter reading
}
```

## Code Examples

### PieChart Usage (fl_chart ^0.68.0)
```dart
// Source: fl_chart official documentation
PieChart(
  PieChartData(
    sections: [
      PieChartSectionData(
        value: 40,
        color: Colors.blue,
        title: '40%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: 30,
        color: Colors.red,
        title: '30%',
        radius: 80,
      ),
      PieChartSectionData(
        value: 30,
        color: Colors.green,
        title: '30%',
        radius: 80,
      ),
    ],
    centerSpaceRadius: 40,
    sectionsSpace: 2,
    startDegreeOffset: -90,
  ),
)
```

### "Other" Calculation Pattern
```dart
// Calculate "Other" (untracked) consumption
final totalSmartPlug = await smartPlugDao.getTotalSmartPlugConsumption(
  householdId, from, to,
);

final electricityReadings = await electricityDao.getReadingsForRange(
  householdId, from, to,
);
final readingPoints = fromElectricityReadings(electricityReadings);
final monthlyConsumption = interpolationService.getMonthlyConsumption(
  readings: readingPoints,
  rangeStart: from,
  rangeEnd: to,
  method: settingsProvider.getMethodForMeterType('electricity'),
);
final totalElectricity = monthlyConsumption.fold<double>(0, (sum, p) => sum + p.consumption);

// Clamp to 0 to avoid negative "other"
final otherConsumption = (totalElectricity - totalSmartPlug).clamp(0, double.infinity);
```

### Mock Pattern for Testing (follows existing test patterns)
```dart
// Source: existing analytics_provider_test.dart pattern
class MockSmartPlugDao extends Mock implements SmartPlugDao {}
class MockElectricityDao extends Mock implements ElectricityDao {}
class MockInterpolationService extends Mock implements InterpolationService {}

// Widget test pattern (follows analytics_screen_test.dart)
class MockSmartPlugAnalyticsProvider extends ChangeNotifier
    with Mock
    implements SmartPlugAnalyticsProvider {}

Widget buildSubject() {
  return ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value(
    value: mockProvider,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const SmartPlugAnalyticsScreen(),
    ),
  );
}
```

### Color Palette for Pie Chart Slices
```dart
/// Distinct colors for pie chart slices, max 10 plugs/rooms expected.
const List<Color> pieChartColors = [
  Color(0xFF5F4A8B), // ultra violet (brand)
  Color(0xFFFFD93D), // electricity yellow
  Color(0xFF6BC5F8), // water blue
  Color(0xFFFF8C42), // gas orange
  Color(0xFFFF6B6B), // heating red
  Color(0xFF4ECDC4), // teal
  Color(0xFF95E1D3), // mint
  Color(0xFFF38181), // salmon
  Color(0xFFAA96DA), // lavender
  Color(0xFFFCBFB7), // blush
];
```

## Localization Strings Needed

### English (app_en.arb) -- new keys
```json
{
  "smartPlugAnalytics": "Smart Plug Analytics",
  "consumptionByPlug": "Consumption by Plug",
  "consumptionByRoom": "Consumption by Room",
  "otherConsumption": "Other (Untracked)",
  "otherConsumptionExplanation": "Difference between total electricity and tracked smart plug consumption",
  "plugBreakdown": "Plug Breakdown",
  "roomBreakdown": "Room Breakdown",
  "noSmartPlugData": "No smart plug consumption data for this period.",
  "noElectricityData": "No electricity readings to calculate 'Other'.",
  "totalTracked": "Total Tracked",
  "totalElectricity": "Total Electricity",
  "periodMonthly": "Monthly",
  "periodYearly": "Yearly",
  "periodCustom": "Custom"
}
```

### German (app_de.arb) -- corresponding keys
```json
{
  "smartPlugAnalytics": "Smart-Plug-Analyse",
  "consumptionByPlug": "Verbrauch nach Steckdose",
  "consumptionByRoom": "Verbrauch nach Raum",
  "otherConsumption": "Sonstiger (nicht erfasst)",
  "otherConsumptionExplanation": "Differenz zwischen Gesamtstrom und erfasstem Smart-Plug-Verbrauch",
  "plugBreakdown": "Aufschluesselung nach Steckdose",
  "roomBreakdown": "Aufschluesselung nach Raum",
  "noSmartPlugData": "Keine Smart-Plug-Verbrauchsdaten fuer diesen Zeitraum.",
  "noElectricityData": "Keine Stromablesungen zur Berechnung von 'Sonstiges'.",
  "totalTracked": "Gesamt erfasst",
  "totalElectricity": "Gesamtstrom",
  "periodMonthly": "Monatlich",
  "periodYearly": "Jaehrlich",
  "periodCustom": "Benutzerdefiniert"
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single monolithic analytics provider | Separate providers per analytics domain | Phase 11 | Keeps AnalyticsProvider focused on meter-type analytics |
| No pie charts | fl_chart PieChart for categorical breakdown | Phase 11 | New chart type in the project |
| Smart plug data display-only | Smart plug data aggregated + visualized in analytics | Phase 11 | Fulfills FR-7.4, FR-9.2 |

**No deprecated/outdated patterns detected:** fl_chart ^0.68.0 PieChart API is stable and well-documented. The project note mentions fl_chart ^0.68.0 but pub.dev shows 1.1.1 as latest -- the ^0.68.0 constraint should resolve correctly since the package appears to have jumped versioning. The existing codebase uses fl_chart successfully for LineChart and BarChart, so PieChart should work identically.

## Open Questions

1. **Should "Other" be a pie slice or a separate card?**
   - What we know: Requirements say "calculate and display" Other consumption
   - What's unclear: Whether it should be integrated into the by-plug pie chart (making it visually comparable) or shown as a separate summary card
   - Recommendation: Include "Other" as a greyed-out slice in the by-plug pie chart for visual proportion, AND show it as a summary number below the chart. This gives both the proportional view and the exact value.

2. **Should the smart plug analytics reuse AnalyticsPeriod enum or create its own?**
   - What we know: MonthlyAnalyticsScreen uses selectedMonth + customRange; YearlyAnalyticsScreen uses selectedYear
   - What's unclear: Whether to unify period selection into a single widget
   - Recommendation: Create a simple `AnalyticsPeriod` enum (monthly, yearly, custom) in the new provider. Use `SegmentedButton` for period switching. This keeps it self-contained.

3. **Provider initialization in main.dart**
   - What we know: All providers are instantiated in `main()` and added to `MultiProvider`
   - What's unclear: Whether the new provider needs `SmartPlugDao` AND `ElectricityDao` (for "Other" calculation)
   - Recommendation: Yes, inject both DAOs plus `InterpolationService` and `InterpolationSettingsProvider` (for interpolation method). Follow the existing `AnalyticsProvider` constructor pattern.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + mocktail ^0.3.0 |
| Config file | pubspec.yaml (dev_dependencies) |
| Quick run command | `flutter test test/providers/smart_plug_analytics_provider_test.dart test/screens/smart_plug_analytics_screen_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FR-7.4.1 | Pie chart by plug renders with correct sections | widget | `flutter test test/screens/smart_plug_analytics_screen_test.dart -x` | No -- Wave 0 |
| FR-7.4.2 | Pie chart by room renders with correct sections | widget | `flutter test test/screens/smart_plug_analytics_screen_test.dart -x` | No -- Wave 0 |
| FR-7.4.3 | "Other" consumption calculated correctly | unit | `flutter test test/providers/smart_plug_analytics_provider_test.dart -x` | No -- Wave 0 |
| FR-7.4.4 | List view shows per-plug and per-room breakdown | widget | `flutter test test/screens/smart_plug_analytics_screen_test.dart -x` | No -- Wave 0 |
| FR-7.4.5 | Period selection (monthly/yearly/custom) loads correct data | unit | `flutter test test/providers/smart_plug_analytics_provider_test.dart -x` | No -- Wave 0 |
| FR-9.2.1 | Smart plug consumption aggregated by plug | unit (DAO) | `flutter test test/database/smart_plug_dao_test.dart -x` | Yes (existing) |
| FR-9.2.2 | Smart plug consumption aggregated by room | unit (DAO) | `flutter test test/database/smart_plug_dao_test.dart -x` | Yes (existing) |
| FR-9.2.3 | Total smart plug consumption for household | unit (DAO) | `flutter test test/database/smart_plug_dao_test.dart -x` | Yes (existing) |

### Sampling Rate
- **Per task commit:** `flutter test test/providers/smart_plug_analytics_provider_test.dart test/screens/smart_plug_analytics_screen_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before verify-work

### Wave 0 Gaps
- [ ] `test/providers/smart_plug_analytics_provider_test.dart` -- covers FR-7.4.3, FR-7.4.5
- [ ] `test/screens/smart_plug_analytics_screen_test.dart` -- covers FR-7.4.1, FR-7.4.2, FR-7.4.4
- [ ] `test/widgets/charts/consumption_pie_chart_test.dart` -- covers pie chart widget rendering (optional)
- [ ] `test/services/analytics/analytics_models_test.dart` -- add tests for new data models (SmartPlugAnalyticsData)

*(Framework and fixtures exist -- test_database.dart, test_utils.dart, mocktail all in place)*

## Sources

### Primary (HIGH confidence)
- **SmartPlugDao source code** (`lib/database/daos/smart_plug_dao.dart`) -- All three aggregation methods confirmed: `getTotalConsumptionForPlug`, `getTotalConsumptionForRoom`, `getTotalSmartPlugConsumption`
- **SmartPlugDao tests** (`test/database/smart_plug_dao_test.dart`) -- All aggregation methods have passing tests
- **ElectricityDao source code** (`lib/database/daos/electricity_dao.dart`) -- `getReadingsForRange` confirmed with surrounding-reading logic
- **AnalyticsProvider source code** (`lib/providers/analytics_provider.dart`) -- Provider pattern, interpolation integration, monthly consumption aggregation
- **fl_chart ^0.68.0** (`pubspec.yaml`) -- Already installed, LineChart and BarChart usage verified in 4 widget files
- **fl_chart PieChart docs** (GitHub raw docs) -- PieChartData and PieChartSectionData API confirmed

### Secondary (MEDIUM confidence)
- **pub.dev fl_chart page** -- Current version 1.1.1, ^0.68.0 constraint compatible

### Tertiary (LOW confidence)
- None. All findings verified against source code.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries already in project and in use
- Architecture: HIGH -- follows established patterns from Phases 9-10
- Pitfalls: HIGH -- derived from direct source code analysis
- PieChart API: HIGH -- verified against fl_chart official docs and consistent with LineChart/BarChart patterns already in use
- "Other" calculation: HIGH -- both DAOs and InterpolationService verified in source

**Research date:** 2026-03-07
**Valid until:** 2026-04-07 (stable, no fast-moving dependencies)
