---
name: flutter-smart-plug-analytics
domain: analytics
tech: [flutter, dart, fl_chart, provider, drift, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-07
validated_phases: [11-smart-plug-analytics]
---

## Context
Use this pattern when building a categorical breakdown analytics feature that:
- Aggregates pre-computed consumption data by entity (e.g., per-device, per-room)
- Displays pie/donut charts using fl_chart PieChart
- Calculates a residual "Other" category from total minus tracked
- Supports period selection (monthly/yearly/custom) with navigation
- Uses a separate provider from the main analytics provider due to different data semantics

## Pattern

### Tasks

| # | Task | Files | Wave |
|---|------|-------|------|
| 1 | Data models (append to existing analytics_models.dart) | `lib/services/analytics/analytics_models.dart` | 1 |
| 2 | Orchestrating provider (multi-DAO) | `lib/providers/smart_plug_analytics_provider.dart` | 1 |
| 3 | Pie chart reusable widget | `lib/widgets/charts/consumption_pie_chart.dart` | 1 |
| 4 | Provider + widget tests | `test/providers/`, `test/widgets/charts/` | 1 |
| 5 | Localization (EN + DE) | `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb` | 2 |
| 6 | Register provider in main.dart | `lib/main.dart` | 2 |
| 7 | Analytics screen (period selector, charts, lists) | `lib/screens/smart_plug_analytics_screen.dart` | 2 |
| 8 | Wire navigation from hub + source screen | `lib/screens/analytics_screen.dart`, `lib/screens/smart_plugs_screen.dart` | 2 |
| 9 | Screen widget tests | `test/screens/smart_plug_analytics_screen_test.dart` | 2 |

### Wave Structure

```
Wave 1 (No dependencies):
  ├── Data models (append to existing file)
  ├── Provider (orchestrates multiple DAOs)
  ├── Pie chart widget
  └── Unit + widget tests for all above

Wave 2 (Depends on Wave 1):
  ├── Localization strings (EN + DE)
  ├── Provider registration in main.dart + household wiring
  ├── Analytics screen (consumes provider + chart widget)
  ├── Navigation wiring from 2 entry points
  └── Screen widget tests
```

### Key Components

#### Separate Provider for Pre-Aggregated Data
```dart
// When data is pre-aggregated (already in kWh) and doesn't need interpolation,
// create a SEPARATE provider from the main AnalyticsProvider
class SmartPlugAnalyticsProvider extends ChangeNotifier {
  final SmartPlugDao _smartPlugDao;      // pre-aggregated consumption
  final ElectricityDao _electricityDao;  // for "Other" calculation
  final RoomDao _roomDao;               // for room names
  final InterpolationService _interpolationService;  // only for "Other"
  final InterpolationSettingsProvider _settingsProvider;

  // Period state
  AnalyticsPeriod _period = AnalyticsPeriod.monthly;
  DateTime _selectedMonth;
  int _selectedYear;
  DateTimeRange? _customRange;

  // loadData() orchestrates all queries and builds SmartPlugAnalyticsData
}
```

#### "Other" (Residual) Calculation Pattern
```dart
// Total from separate source (electricity meter readings + interpolation)
final electricityReadings = await electricityDao.getReadingsForRange(...);
if (electricityReadings.isNotEmpty) {
  final readingPoints = fromElectricityReadings(electricityReadings);
  final monthly = interpolationService.getMonthlyConsumption(...);
  totalElectricity = monthly.fold<double>(0, (sum, p) => sum + p.consumption);
}

// Clamp to 0 — never negative
final otherConsumption = totalElectricity != null
    ? max(0.0, totalElectricity - totalSmartPlug)
    : null; // null when no source data exists
```

#### Pie Chart with "Other" Grey Slice
```dart
List<PieSliceData> _buildPlugSlices(SmartPlugAnalyticsData data) {
  final total = data.totalSmartPlug + (data.otherConsumption ?? 0);
  if (total == 0) return [];
  final slices = data.byPlug.map((p) => PieSliceData(
    label: p.plugName,
    value: p.consumption,
    percentage: (p.consumption / total) * 100,
    color: p.color,
  )).toList();
  if (data.otherConsumption != null && data.otherConsumption! > 0) {
    slices.add(PieSliceData(
      label: 'Other',
      value: data.otherConsumption!,
      percentage: (data.otherConsumption! / total) * 100,
      color: const Color(0xFF9E9E9E), // grey for residual
    ));
  }
  return slices;
}
```

#### fl_chart PieChart Widget
```dart
class ConsumptionPieChart extends StatelessWidget {
  final List<PieSliceData> slices;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return Center(child: Text(l10n.noData));
    return PieChart(PieChartData(
      sections: slices.map((s) => PieChartSectionData(
        value: s.value,
        color: s.color,
        title: '${s.percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      )).toList(),
      centerSpaceRadius: 40, // donut shape
      sectionsSpace: 2,
      startDegreeOffset: -90,
    ));
  }
}
```

#### SegmentedButton Period Selector
```dart
SegmentedButton<AnalyticsPeriod>(
  segments: [
    ButtonSegment(value: AnalyticsPeriod.monthly, label: Text(l10n.periodMonthly)),
    ButtonSegment(value: AnalyticsPeriod.yearly, label: Text(l10n.periodYearly)),
    ButtonSegment(value: AnalyticsPeriod.custom, label: Text(l10n.periodCustom)),
  ],
  selected: {provider.period},
  onSelectionChanged: (s) => provider.setPeriod(s.first),
)
```

#### Color Palette for Categorical Data
```dart
const List<Color> pieChartColors = [
  Color(0xFF5F4A8B), // ultra violet (brand)
  Color(0xFFFFD93D), // yellow
  Color(0xFF6BC5F8), // blue
  Color(0xFFFF8C42), // orange
  Color(0xFFFF6B6B), // red
  Color(0xFF4ECDC4), // teal
  Color(0xFF95E1D3), // mint
  Color(0xFFF38181), // salmon
  Color(0xFFAA96DA), // lavender
  Color(0xFFFCBFB7), // blush
];
// Assign: pieChartColors[index % pieChartColors.length]
```

### Key Decisions
1. **Separate provider** — Pre-aggregated data (smart plugs) uses different data flow than interpolated meter data; keep providers separate
2. **"Other" clamped to max(0, ...)** — Prevents negative pie slices when tracked exceeds total
3. **"Other" null when no source data** — Don't show "Other" if no electricity readings exist
4. **Grey slice for "Other"** — Color(0xFF9E9E9E) distinguishes residual from tracked categories
5. **Pie percentages use (tracked + other) as denominator** — Ensures all slices sum to 100%
6. **10-color palette** — Maximally distinct, wraps with modulo for > 10 entities
7. **Two navigation entry points** — Analytics hub card + source screen AppBar icon
8. **SegmentedButton for period** — Material 3 standard, replaces ChoiceChip
9. **Donut shape** — centerSpaceRadius: 40 for visual clarity
10. **Breakdown lists with colored dots** — Same color as pie slice for visual correlation

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| "Other" consumption negative (tracked > total) | Clamp: `max(0.0, totalElectricity - totalSmartPlug)` |
| "Other" undefined (no electricity readings) | Set to null, display "No electricity readings" text |
| Pie chart percentages don't sum to 100% | Use (tracked + other) as denominator, not just tracked |
| Pie chart empty with no data | Guard: `if (total == 0) return []` |
| Provider not registered | Add to MultiProvider AND wire to household change listener |
| Stale data after household switch | Wire `setHouseholdId()` in `_onHouseholdChanged` |
| Color collision for many entities | Predefined palette of 10 maximally distinct colors, wrap with modulo |
| Custom period with no range selected | Guard: `if (_customRange == null) return` in loadData() |
| Room name "Unknown" for orphaned plugs | Use `roomMap[plug.roomId]?.name ?? 'Unknown'` fallback |

### Test Coverage

| Component | Test Count | Focus |
|-----------|------------|-------|
| SmartPlugAnalyticsProvider | 24 | State mgmt, multi-DAO orchestration, Other calc, period switching, navigation |
| ConsumptionPieChart | 7 | Empty state, rendering, sections, colors, percentages, donut shape |
| SmartPlugAnalyticsScreen | 16 | AppBar, loading, empty, period selector, navigation, charts, Other card, breakdowns, summary |
| **Total** | **47** | |

### Mock Pattern for Provider Tests
```dart
class MockSmartPlugDao extends Mock implements SmartPlugDao {}
class MockElectricityDao extends Mock implements ElectricityDao {}
class MockRoomDao extends Mock implements RoomDao {}
class MockInterpolationService extends Mock implements InterpolationService {}
class MockInterpolationSettingsProvider extends Mock implements InterpolationSettingsProvider {}

// For Drift-generated data classes, mock them too:
class _MockSmartPlug extends Mock implements SmartPlug {}
class _MockRoom extends Mock implements Room {}

// Stub each DAO method individually per test scenario
```

### Mock Pattern for Screen Widget Tests
```dart
class MockSmartPlugAnalyticsProvider extends ChangeNotifier
    with Mock
    implements SmartPlugAnalyticsProvider {}

// Default stubs helper:
void setUpDefaultStubs({bool isLoading = false, SmartPlugAnalyticsData? data, ...}) {
  when(() => mockProvider.isLoading).thenReturn(isLoading);
  when(() => mockProvider.data).thenReturn(data);
  when(() => mockProvider.period).thenReturn(AnalyticsPeriod.monthly);
  // ... all getters
}
```

### Adaptation Notes
- Replace smart plug / room entities with any categorical breakdown (e.g., cost centers, departments)
- "Other" pattern works for any "total minus tracked" residual calculation
- Pie chart widget is fully reusable — just pass PieSliceData list
- Period selector can be extracted as a reusable widget for any analytics screen
- Color palette is extensible — add more colors for domains with > 10 categories
