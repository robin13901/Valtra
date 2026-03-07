---
name: flutter-analytics-hub
domain: analytics
tech: [flutter, dart, fl_chart, provider, drift, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-07
validated_phases: [9-analytics-hub-monthly]
---

## Context
Use this pattern when building an analytics dashboard that:
- Aggregates data from multiple DAO sources via a single orchestrating provider
- Displays interactive charts (line + bar) using fl_chart
- Supports time navigation (month forward/back) and custom date ranges
- Visually distinguishes computed/interpolated vs actual values
- Handles both single-entity and multi-entity aggregation (e.g., one electricity meter vs multiple water meters)

## Pattern

### Tasks

| # | Task | File | Dependencies |
|---|------|------|--------------|
| 1 | Analytics data models + helpers | `lib/services/analytics/analytics_models.dart` | None |
| 2 | Analytics provider (orchestrator) | `lib/providers/analytics_provider.dart` | Task 1 |
| 3 | Line chart widget | `lib/widgets/charts/consumption_line_chart.dart` | Task 1 |
| 4 | Bar chart + legend widgets | `lib/widgets/charts/monthly_bar_chart.dart`, `chart_legend.dart` | Task 1 |
| 5 | Hub screen (overview cards) | `lib/screens/analytics_screen.dart` | Task 2 |
| 6 | Detail screen (charts + navigation) | `lib/screens/monthly_analytics_screen.dart` | Task 2-5 |
| 7 | Wire navigation from existing screens | Modify `*_screen.dart` files | Task 5, 6 |
| 8 | Register provider + route | `lib/main.dart` | Task 2 |
| 9 | Localization | `lib/l10n/app_*.arb` | None |
| 10 | Tests + analysis | `flutter test` + `flutter analyze` | All |

### Wave Structure

```
Wave 1 (Parallel — no deps):
  ├── Task 1: Analytics data models
  ├── Task 9: Localization (EN + DE)
  └── Task 3 + 4: Chart widgets (need only fl_chart)

Wave 2 (Depends on Task 1):
  └── Task 2: AnalyticsProvider

Wave 3 (Depends on Task 2):
  ├── Task 5: Hub screen
  └── Task 6: Monthly analytics screen

Wave 4 (Depends on Wave 3):
  ├── Task 7: Wire navigation from existing screens
  └── Task 8: Register provider + route

Wave 5 (Depends on all):
  └── Task 10: Tests + analyze
```

### Key Components

#### Multi-Dependency Provider Pattern
```dart
class AnalyticsProvider extends ChangeNotifier {
  final ElectricityDao _electricityDao;
  final GasDao _gasDao;
  final WaterDao _waterDao;
  final HeatingDao _heatingDao;
  final InterpolationService _interpolationService;
  final GasConversionService _gasConversionService;
  final InterpolationSettingsProvider _settingsProvider;

  // Persistent state (user selections)
  int? _householdId;
  DateTime _selectedMonth;
  MeterType _selectedMeterType;
  DateTimeRange? _customRange;

  // Computed state (rebuilt on demand)
  MonthlyAnalyticsData? _monthlyData;
  Map<MeterType, MeterTypeSummary> _overviewSummaries = {};
  bool _isLoading = false;

  // Setters trigger async loads → rebuild computed state → notifyListeners()
}
```

#### Multi-Meter Aggregation Strategy
```dart
// Returns List<List<ReadingPoint>> — one list per physical meter
Future<List<List<ReadingPoint>>> _getReadingsPerMeter(
  MeterType type, DateTime rangeStart, DateTime rangeEnd,
) async {
  switch (type) {
    case MeterType.electricity:  // Single meter
      return [fromElectricityReadings(await dao.getReadingsForRange(...))];
    case MeterType.water:        // Multiple meters
      final meters = await dao.getMetersForHousehold(householdId);
      return [for (final m in meters)
        fromWaterReadings(await dao.getReadingsForRange(m.id, ...))];
  }
}

// Interpolate per-meter independently, then sum
List<PeriodConsumption> _aggregateMonthlyConsumption(
  List<List<ReadingPoint>> readingsPerMeter, ...
) {
  final perMeter = readingsPerMeter.map((r) =>
    interpolationService.getMonthlyConsumption(readings: r, ...)).toList();
  if (perMeter.length == 1) return perMeter.first;
  // Sum consumption across meters for each period
  return base.asMap().entries.map((e) {
    var total = e.value.consumption;
    for (int m = 1; m < perMeter.length; m++) {
      if (e.key < perMeter[m].length) total += perMeter[m][e.key].consumption;
    }
    return PeriodConsumption(..., consumption: total);
  }).toList();
}
```

#### Two-Line Chart Split (Actual vs Interpolated)
```dart
(List<FlSpot>, List<FlSpot>) _splitByInterpolation() {
  for (int i = 0; i < dataPoints.length; i++) {
    if (dataPoints[i].isInterpolated) {
      interpolated.add(spot);
      actual.add(FlSpot.nullSpot);      // Gap in actual line
      // Add bridge point from previous actual for continuity
    } else {
      actual.add(spot);
      interpolated.add(FlSpot.nullSpot); // Gap in interpolated line
    }
  }
}
// Render: solid line for actual, dashed (dashArray: [8, 4]) for interpolated
```

#### Custom Range vs Month Navigation
```dart
void navigateMonth(int delta) {
  _selectedMonth = DateTime(year, month + delta, 1);
  _customRange = null;  // Clear custom range when navigating months
  notifyListeners();
  _loadMonthlyData();
}

void setCustomRange(DateTimeRange? range) {
  _customRange = range;  // Overrides month selection for data loading
  notifyListeners();
  _loadMonthlyData();
}
```

#### fl_chart Bar Chart with Sequential Int X-Axis
```dart
// BarChartGroupData.x requires int — use sequential index, map to month labels
final groups = periods.asMap().entries.map((entry) {
  return BarChartGroupData(
    x: entry.key,  // 0, 1, 2, ... not timestamp
    barRods: [BarChartRodData(
      toY: entry.value.consumption,
      borderDashArray: hasInterpolation ? [4, 2] : null,
    )],
  );
}).toList();

// Bottom titles map index → month abbreviation
getTitlesWidget: (value, meta) {
  final period = periods[value.toInt()];
  return Text(DateFormat.MMM().format(period.periodStart));
}
```

### Key Decisions
1. **Single orchestrating provider** — One AnalyticsProvider receives all DAOs + services via constructor DI
2. **Per-meter interpolation then sum** — Multi-meter types interpolated independently to preserve monotonic series
3. **Computed state pattern** — Setters trigger async loads, no caching across months
4. **Custom range overrides month** — `navigateMonth()` clears custom range to avoid confusion
5. **Two-line split for interpolation** — FlSpot.nullSpot creates gaps in each line, bridge points maintain continuity
6. **Sequential int x-axis for bar chart** — fl_chart BarChartGroupData.x requires int; map index → month label
7. **Gas conversion at provider layer** — Applied post-aggregation, not embedded in DAO
8. **Color/icon/unit helpers as top-level functions** — Not on enum to avoid importing UI into data layer
9. **Explicit maxY for charts** — `max * 1.15` with minimum 1.0 for consistent sizing

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| Multi-meter raw reading merge breaks interpolation | Interpolate per-meter independently, then sum results |
| FlSpot.nullSpot causes empty line when no interpolated data | Guard with `if (spots.any((s) => s != FlSpot.nullSpot))` |
| Custom range + month navigation confusion | `navigateMonth()` always clears `_customRange` |
| Different meters return different period counts | Bounds check: `if (i < perMeter[m].length)` before access |
| Gas unit display mismatch (m³ stored, kWh displayed) | Convert in provider post-aggregation, update unit string |
| fl_chart BarChartGroupData.x must be int | Use sequential index, map to month labels in titles |
| fl_chart has no built-in legend | Build custom ChartLegend widget with solid/dashed line painters |
| Overview needs wider lookback than detail view | `_loadOverview()` uses fixed 6-month range independently |
| fl_chart CustomPainter can't be inspected in widget tests | Focus tests on: data transformation, widget renders without crash, state management |
| DateFormat needs intl import | `import 'package:intl/intl.dart';` — already in pubspec from l10n |

### Test Coverage

| Component | Test Count | Coverage Focus |
|-----------|------------|----------------|
| AnalyticsProvider | 39 | State mgmt, async loads, multi-meter aggregation, gas conversion |
| Analytics data models + helpers | 24 | Construction, enum values, color/icon/unit mapping |
| AnalyticsScreen (hub) | 9 | 4 cards render, loading state, navigation |
| MonthlyAnalyticsScreen | 8 | Charts render, navigation, summary, date range |
| ConsumptionLineChart | 8 | Empty, actual-only, mixed, all-interpolated, single point |
| MonthlyBarChart | 6 | Empty, render, highlight, interpolated border |
| ChartLegend | 5 | Items, labels, solid/dashed, empty |
| **Total** | **~99** | |

### Mock Setup Pattern
```dart
class MockElectricityDao extends Mock implements ElectricityDao {}
// ... 7 mock classes total

setUpAll(() {
  registerFallbackValue(InterpolationMethod.linear);
  registerFallbackValue(DateTime(2024));
  registerFallbackValue(<ReadingPoint>[]);
});

setUp(() {
  // Initialize all 7 mocks
  // Set up default when() stubs for settings
  when(() => mockSettings.getMethodForMeterType(any()))
      .thenReturn(InterpolationMethod.linear);
  when(() => mockSettings.gasKwhFactor).thenReturn(10.3);

  provider = AnalyticsProvider(
    electricityDao: mockElectricityDao,
    gasDao: mockGasDao,
    waterDao: mockWaterDao,
    heatingDao: mockHeatingDao,
    interpolationService: mockInterpolationService,
    gasConversionService: mockGasConversionService,
    settingsProvider: mockSettings,
  );
});
```

### Localization Keys

```json
{
  "analyticsHub": "Analytics",
  "consumptionOverview": "Consumption Overview",
  "dailyTrends": "Daily Trends",
  "monthlyComparison": "Monthly Comparison",
  "customDateRange": "Custom Date Range",
  "totalConsumption": "Total Consumption",
  "consumption": "{value} {unit}",
  "noDataForPeriod": "No data available for this period",
  "previousMonth": "Previous Month",
  "nextMonth": "Next Month"
}
```

### Adaptation Notes
- Replace meter types with domain-specific entity types
- The multi-entity aggregation pattern generalizes to any multi-source aggregation
- Chart widgets are reusable — pass data points and color, they handle rendering
- Provider orchestrator pattern scales to any number of data sources
- The actual/interpolated split works for any binary data classification
