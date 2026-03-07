# Phase 9 Plan — Analytics Hub & Monthly Analytics

**Phase**: 9 of 14
**Milestone**: 2 — Analytics & Visualization (v0.2.0)
**Requirements**: FR-7.1 (Monthly Analytics), FR-7.3 (Analytics Navigation)
**Goal**: Build the analytics hub screen and monthly analytics screen with interactive fl_chart charts, month navigation, custom date ranges, and interpolated vs actual value distinction.

---

## Architecture Overview

```
HomeScreen
  └── Analytics chip (new) ─────────► AnalyticsScreen (hub)
                                        ├── OverviewCard (electricity) ──► MonthlyAnalyticsScreen(meterType: electricity)
                                        ├── OverviewCard (gas)         ──► MonthlyAnalyticsScreen(meterType: gas)
                                        ├── OverviewCard (water)       ──► MonthlyAnalyticsScreen(meterType: water)
                                        └── OverviewCard (heating)     ──► MonthlyAnalyticsScreen(meterType: heating)

ElectricityScreen / GasScreen / WaterScreen / HeatingScreen
  └── AppBar analytics action ──────► MonthlyAnalyticsScreen(meterType: ...)

AnalyticsProvider (ChangeNotifier)
  ├── selectedMonth: DateTime
  ├── selectedMeterType: MeterType
  ├── customRange: DateTimeRange?
  ├── monthlyConsumption: List<PeriodConsumption>  (bar chart data)
  ├── dailyBoundaries: List<TimestampedValue>      (line chart data)
  └── overviewSummaries: Map<MeterType, double?>   (hub cards)
  │
  ├── Uses: ElectricityDao, GasDao, WaterDao, HeatingDao
  ├── Uses: InterpolationService
  ├── Uses: InterpolationSettingsProvider (method per type)
  ├── Uses: GasConversionService (gas kWh)
  └── Uses: reading_converters (type → ReadingPoint)

Chart Widgets (StatelessWidget, receive data from provider)
  ├── ConsumptionLineChart  → LineChart with actual/interpolated two-line split
  ├── MonthlyBarChart       → BarChart with sequential int x-axis
  └── ChartLegend           → Custom Row widget (fl_chart has no built-in legend)
```

---

## Task Breakdown

### Task 1: Analytics Data Models & MeterType Enum
**File**: `lib/services/analytics/analytics_models.dart` (new)
**Dependencies**: None

Create shared data models for the analytics layer:

```dart
/// Meter type enum for analytics scoping.
enum MeterType { electricity, gas, water, heating }

/// Summary data for one meter type shown on the analytics hub.
class MeterTypeSummary {
  final MeterType meterType;
  final double? latestMonthConsumption;  // null if insufficient data
  final bool hasInterpolation;
  final String unit;  // 'kWh', 'm\u00b3', 'units'
  const MeterTypeSummary({...});
}

/// Chart-ready data point combining value + interpolation flag.
class ChartDataPoint {
  final DateTime timestamp;
  final double value;
  final bool isInterpolated;
  const ChartDataPoint({...});
}

/// Complete data package for the monthly analytics screen.
class MonthlyAnalyticsData {
  final MeterType meterType;
  final DateTime month;                           // 1st of selected month
  final List<ChartDataPoint> dailyValues;         // line chart (boundaries within month)
  final List<PeriodConsumption> recentMonths;     // bar chart (last 6 months)
  final double? totalConsumption;                 // sum for selected month
  final String unit;
  const MonthlyAnalyticsData({...});
}
```

**Test file**: `test/services/analytics/analytics_models_test.dart`
- Test MeterType values (4 types)
- Test MeterTypeSummary construction and properties
- Test ChartDataPoint construction
- Test MonthlyAnalyticsData construction
- Test unit string for each MeterType (electricity='kWh', gas='m\u00b3', water='m\u00b3', heating='units')

---

### Task 2: AnalyticsProvider — Data Aggregation Engine
**File**: `lib/providers/analytics_provider.dart` (new)
**Dependencies**: Task 1

Single provider orchestrating all analytics data. Receives all 4 DAOs + services in constructor (same pattern as existing providers created in main.dart).

```dart
class AnalyticsProvider extends ChangeNotifier {
  final ElectricityDao _electricityDao;
  final GasDao _gasDao;
  final WaterDao _waterDao;
  final HeatingDao _heatingDao;
  final InterpolationService _interpolationService;
  final GasConversionService _gasConversionService;
  final InterpolationSettingsProvider _settingsProvider;

  int? _householdId;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  MeterType _selectedMeterType = MeterType.electricity;
  DateTimeRange? _customRange;  // null = use selectedMonth

  // Computed state
  MonthlyAnalyticsData? _monthlyData;
  Map<MeterType, MeterTypeSummary> _overviewSummaries = {};
  bool _isLoading = false;

  AnalyticsProvider({
    required ElectricityDao electricityDao,
    required GasDao gasDao,
    required WaterDao waterDao,
    required HeatingDao heatingDao,
    required InterpolationService interpolationService,
    required GasConversionService gasConversionService,
    required InterpolationSettingsProvider settingsProvider,
  }) : _electricityDao = electricityDao,
       _gasDao = gasDao,
       _waterDao = waterDao,
       _heatingDao = heatingDao,
       _interpolationService = interpolationService,
       _gasConversionService = gasConversionService,
       _settingsProvider = settingsProvider;

  // Getters
  DateTime get selectedMonth => _selectedMonth;
  MeterType get selectedMeterType => _selectedMeterType;
  DateTimeRange? get customRange => _customRange;
  MonthlyAnalyticsData? get monthlyData => _monthlyData;
  Map<MeterType, MeterTypeSummary> get overviewSummaries => _overviewSummaries;
  bool get isLoading => _isLoading;

  void setHouseholdId(int? id) { ... notifyListeners(); _loadOverview(); }
  void setSelectedMonth(DateTime month) { ... notifyListeners(); _loadMonthlyData(); }
  void setSelectedMeterType(MeterType type) { ... notifyListeners(); _loadMonthlyData(); }
  void setCustomRange(DateTimeRange? range) { ... notifyListeners(); _loadMonthlyData(); }
  void navigateMonth(int delta) {
    // delta = -1 (previous) or +1 (next), clamp to not exceed current month
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    _customRange = null;  // clear custom range when navigating months
    notifyListeners();
    _loadMonthlyData();
  }

  /// Load overview summaries for all 4 meter types (analytics hub).
  Future<void> _loadOverview() async { ... }

  /// Load detailed monthly data for selected meter type + month/range.
  Future<void> _loadMonthlyData() async {
    // 1. Determine date range (custom or month boundaries)
    // 2. Fetch readings via _getReadingsPerMeter() — returns List<List<ReadingPoint>>
    //    (one list per physical meter; single-meter types return a list of one)
    // 3. Get interpolation method from settingsProvider
    // 4. Call _aggregateDailyBoundaries() for line chart data
    //    (interpolates each meter independently, then sums boundary values)
    // 5. Call _aggregateMonthlyConsumption() for bar chart (last 6 months)
    //    (interpolates each meter independently, then sums consumption per period)
    // 6. For gas: apply gasConversionService if displaying kWh
    // 7. Build MonthlyAnalyticsData and notifyListeners()
  }

  /// Get readings for a meter type (handles household vs meter scoping).
  /// For single-meter types (electricity, gas): returns one ReadingPoint list.
  /// For multi-meter types (water, heating): returns one ReadingPoint list PER METER.
  Future<List<List<ReadingPoint>>> _getReadingsPerMeter(
    MeterType type, DateTime rangeStart, DateTime rangeEnd,
  ) async {
    switch (type) {
      case MeterType.electricity:
        final readings = await _electricityDao.getReadingsForRange(_householdId!, rangeStart, rangeEnd);
        return [fromElectricityReadings(readings)];
      case MeterType.gas:
        final readings = await _gasDao.getReadingsForRange(_householdId!, rangeStart, rangeEnd);
        return [fromGasReadings(readings)];
      case MeterType.water:
        // Each water meter interpolated independently, then consumption summed
        final meters = await _waterDao.getMetersForHousehold(_householdId!);
        if (meters.isEmpty) return [];
        final result = <List<ReadingPoint>>[];
        for (final meter in meters) {
          final readings = await _waterDao.getReadingsForRange(meter.id, rangeStart, rangeEnd);
          result.add(fromWaterReadings(readings));
        }
        return result;
      case MeterType.heating:
        // Same per-meter pattern as water
        final meters = await _heatingDao.getMetersForHousehold(_householdId!);
        if (meters.isEmpty) return [];
        final result = <List<ReadingPoint>>[];
        for (final meter in meters) {
          final readings = await _heatingDao.getReadingsForRange(meter.id, rangeStart, rangeEnd);
          result.add(fromHeatingReadings(readings));
        }
        return result;
    }
  }

  /// Get monthly consumption by interpolating each meter independently, then summing.
  /// This is correct for multi-meter types (water, heating) because each meter has its
  /// own monotonically increasing cumulative reading series. Merging raw readings from
  /// different meters into one list would break the InterpolationService's assumptions.
  List<PeriodConsumption> _aggregateMonthlyConsumption(
    List<List<ReadingPoint>> readingsPerMeter,
    DateTime rangeStart, DateTime rangeEnd, InterpolationMethod method,
  ) {
    if (readingsPerMeter.isEmpty) return [];

    // Interpolate each meter independently
    final perMeterConsumptions = readingsPerMeter
        .map((readings) => _interpolationService.getMonthlyConsumption(
              readings: readings, rangeStart: rangeStart,
              rangeEnd: rangeEnd, method: method,
            ))
        .toList();

    // If only one meter, return directly
    if (perMeterConsumptions.length == 1) return perMeterConsumptions.first;

    // Sum consumption across meters for each period
    // Use the first meter's periods as the base timeline
    final base = perMeterConsumptions.first;
    return base.asMap().entries.map((entry) {
      final i = entry.key;
      final basePeriod = entry.value;
      var totalConsumption = basePeriod.consumption;
      var anyInterpolated = basePeriod.startInterpolated || basePeriod.endInterpolated;
      for (int m = 1; m < perMeterConsumptions.length; m++) {
        if (i < perMeterConsumptions[m].length) {
          totalConsumption += perMeterConsumptions[m][i].consumption;
          anyInterpolated = anyInterpolated ||
              perMeterConsumptions[m][i].startInterpolated ||
              perMeterConsumptions[m][i].endInterpolated;
        }
      }
      return PeriodConsumption(
        periodStart: basePeriod.periodStart,
        periodEnd: basePeriod.periodEnd,
        startValue: basePeriod.startValue,  // from first meter (informational)
        endValue: basePeriod.endValue,      // from first meter (informational)
        consumption: totalConsumption,
        startInterpolated: anyInterpolated,
        endInterpolated: anyInterpolated,
      );
    }).toList();
  }

  /// Get daily boundary values by interpolating each meter independently, then summing.
  List<TimestampedValue> _aggregateDailyBoundaries(
    List<List<ReadingPoint>> readingsPerMeter,
    DateTime rangeStart, DateTime rangeEnd, InterpolationMethod method,
  ) {
    if (readingsPerMeter.isEmpty) return [];

    final perMeterBoundaries = readingsPerMeter
        .map((readings) => _interpolationService.getMonthlyBoundaries(
              readings: readings, rangeStart: rangeStart,
              rangeEnd: rangeEnd, method: method,
            ))
        .toList();

    if (perMeterBoundaries.length == 1) return perMeterBoundaries.first;

    final base = perMeterBoundaries.first;
    return base.asMap().entries.map((entry) {
      final i = entry.key;
      final baseVal = entry.value;
      var totalValue = baseVal.value;
      var anyInterpolated = baseVal.isInterpolated;
      for (int m = 1; m < perMeterBoundaries.length; m++) {
        if (i < perMeterBoundaries[m].length) {
          totalValue += perMeterBoundaries[m][i].value;
          anyInterpolated = anyInterpolated || perMeterBoundaries[m][i].isInterpolated;
        }
      }
      return TimestampedValue(
        timestamp: baseVal.timestamp,
        value: totalValue,
        isInterpolated: anyInterpolated,
      );
    }).toList();
  }

  /// Helper: get unit string for meter type.
  String unitForMeterType(MeterType type) {
    switch (type) {
      case MeterType.electricity: return 'kWh';
      case MeterType.gas: return 'm\u00b3';
      case MeterType.water: return 'm\u00b3';
      case MeterType.heating: return 'units';
    }
  }
}
```

**Key design decisions for water/heating aggregation:**
- For multi-meter types (water, heating), each meter is interpolated independently via its own `ReadingPoint` list.
- Monthly consumption and daily boundaries are computed per-meter, then summed across meters.
- This is correct because each meter has its own monotonically increasing cumulative reading series. Merging raw readings from different meters into one list would violate the InterpolationService's assumption of a single ascending timeline.
- The `_aggregateMonthlyConsumption` and `_aggregateDailyBoundaries` helper methods handle this correctly.
- For the overview hub cards: show total consumption (summed across all meters) for the household.
- For the monthly detail chart: show one aggregated line (sum of per-meter boundary values).

**Test file**: `test/providers/analytics_provider_test.dart`
Tests (use `mocktail` for mocking DAOs and services):
- `setHouseholdId` triggers overview load
- `setSelectedMonth` triggers monthly data load
- `navigateMonth(1)` increments month, `navigateMonth(-1)` decrements
- `setCustomRange` overrides month selection for data loading
- `_getReadingsPerMeter` calls correct DAO for each type
- Water aggregation: multiple meters interpolated independently, consumption summed
- Heating aggregation: same per-meter pattern as water
- Single-meter types (electricity, gas): returns single-element list
- Gas conversion applied when meter type is gas
- Loading state toggled during async operations
- Null householdId returns empty data
- Empty meters list returns empty consumption

---

### Task 3: Chart Widgets — ConsumptionLineChart
**File**: `lib/widgets/charts/consumption_line_chart.dart` (new)
**Dependencies**: Task 1

Reusable line chart widget using fl_chart, with two-line actual/interpolated split:

```dart
class ConsumptionLineChart extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final Color primaryColor;
  final String unit;

  const ConsumptionLineChart({
    super.key,
    required this.dataPoints,
    required this.rangeStart,
    required this.rangeEnd,
    required this.primaryColor,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return LineChart(
      _buildData(context),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  LineChartData _buildData(BuildContext context) {
    final (actualSpots, interpolatedSpots) = _splitByInterpolation();
    return LineChartData(
      minX: rangeStart.millisecondsSinceEpoch.toDouble(),
      maxX: rangeEnd.millisecondsSinceEpoch.toDouble(),
      minY: 0,
      maxY: _calculateMaxY(),
      clipData: const FlClipData.all(),
      lineBarsData: [
        // Actual readings: solid line
        LineChartBarData(
          spots: actualSpots,
          color: primaryColor,
          barWidth: 2.5,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 4, color: primaryColor,
              strokeColor: Colors.white, strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: primaryColor.withValues(alpha: 0.1),
          ),
        ),
        // Interpolated readings: dashed line
        if (interpolatedSpots.any((s) => s != FlSpot.nullSpot))
          LineChartBarData(
            spots: interpolatedSpots,
            color: primaryColor.withValues(alpha: 0.5),
            barWidth: 2.0,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            dashArray: [8, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3, color: Colors.white,
                strokeColor: primaryColor.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ),
          ),
      ],
      titlesData: _buildTitles(context),
      gridData: _buildGrid(),
      borderData: _buildBorder(context),
      lineTouchData: _buildTouch(context),
    );
  }

  /// Split data points into actual (solid) and interpolated (dashed) FlSpot lists.
  /// Uses FlSpot.nullSpot to create gaps where the other line has data.
  (List<FlSpot>, List<FlSpot>) _splitByInterpolation() {
    final actual = <FlSpot>[];
    final interpolated = <FlSpot>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final dp = dataPoints[i];
      final spot = FlSpot(
        dp.timestamp.millisecondsSinceEpoch.toDouble(),
        dp.value,
      );

      if (dp.isInterpolated) {
        interpolated.add(spot);
        // Connect from previous actual point
        if (i > 0 && !dataPoints[i - 1].isInterpolated) {
          final prev = dataPoints[i - 1];
          interpolated.insert(
            interpolated.length - 1,
            FlSpot(prev.timestamp.millisecondsSinceEpoch.toDouble(), prev.value),
          );
        }
        actual.add(FlSpot.nullSpot);
      } else {
        actual.add(spot);
        if (i > 0 && dataPoints[i - 1].isInterpolated) {
          interpolated.add(spot);  // bridge point for continuity
        } else {
          interpolated.add(FlSpot.nullSpot);
        }
      }
    }
    return (actual, interpolated);
  }

  // _buildTitles: bottom = date labels (adaptive interval), left = value labels
  // _buildGrid: dashed gridlines
  // _buildBorder: left + bottom borders only
  // _buildTouch: tooltip showing date + value + unit + "(interpolated)" marker
  // _calculateMaxY: max value * 1.1 for padding, minimum 1.0
}
```

**Test file**: `test/widgets/charts/consumption_line_chart_test.dart`
- Renders without error with empty data (shows noData text)
- Renders with actual-only data (one line, no dashed)
- Renders with mixed actual+interpolated data (two lines)
- _splitByInterpolation correctly separates points
- FlSpot.nullSpot inserted at correct positions

---

### Task 4: Chart Widgets — MonthlyBarChart & ChartLegend
**File**: `lib/widgets/charts/monthly_bar_chart.dart` (new)
**File**: `lib/widgets/charts/chart_legend.dart` (new)
**Dependencies**: Task 1

**MonthlyBarChart** — Bar chart comparing consumption across recent months:

```dart
class MonthlyBarChart extends StatelessWidget {
  final List<PeriodConsumption> periods;  // ordered by date
  final Color primaryColor;
  final String unit;
  final DateTime? highlightMonth;  // currently selected month

  const MonthlyBarChart({
    super.key,
    required this.periods,
    required this.primaryColor,
    required this.unit,
    this.highlightMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noData));
    }
    return BarChart(
      _buildData(context),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  BarChartData _buildData(BuildContext context) {
    // BarChartGroupData.x is int — use sequential index, map to month labels
    final groups = periods.asMap().entries.map((entry) {
      final i = entry.key;
      final period = entry.value;
      final isHighlighted = highlightMonth != null &&
          period.periodStart.year == highlightMonth!.year &&
          period.periodStart.month == highlightMonth!.month;

      final hasInterpolation = period.startInterpolated || period.endInterpolated;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: period.consumption,
            color: isHighlighted ? primaryColor : primaryColor.withValues(alpha: 0.6),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            borderDashArray: hasInterpolation ? [4, 2] : null,  // dashed border if interpolated
          ),
        ],
      );
    }).toList();

    return BarChartData(
      barGroups: groups,
      alignment: BarChartAlignment.spaceEvenly,
      maxY: _calculateMaxY(),  // explicit bounds for performance
      titlesData: _buildTitles(context),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: _buildBorder(context),
      barTouchData: _buildTouch(context),
    );
  }

  // _buildTitles: bottom = month abbreviation (Jan, Feb...), left = value
  // Use intl DateFormat.MMM() for month names, respecting locale
  // _buildTouch: tooltip showing "Jan 2026: 142.5 kWh"
}
```

**ChartLegend** — Custom legend (fl_chart has no built-in legend):

```dart
class ChartLegend extends StatelessWidget {
  final List<ChartLegendItem> items;
  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) => _buildItem(context, item)).toList(),
    );
  }

  Widget _buildItem(BuildContext context, ChartLegendItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24, height: 3,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(2),
          ),
          // If dashed, use CustomPaint with dashed line painter
        ),
        const SizedBox(width: 6),
        Text(item.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class ChartLegendItem {
  final Color color;
  final String label;
  final bool isDashed;
  const ChartLegendItem({required this.color, required this.label, this.isDashed = false});
}
```

**Test file**: `test/widgets/charts/monthly_bar_chart_test.dart`
- Renders without error with empty data
- Renders with period data (correct number of bars)
- Highlighted month bar uses full opacity color
- Interpolated periods have dashed border

**Test file**: `test/widgets/charts/chart_legend_test.dart`
- Renders legend items
- Shows correct labels and colors

---

### Task 5: AnalyticsScreen (Hub)
**File**: `lib/screens/analytics_screen.dart` (new)
**Dependencies**: Task 1, Task 2, Task 6

The analytics hub showing overview cards for all 4 meter types with navigation to per-type monthly analytics:

```dart
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsHub)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.consumptionOverview,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                ...MeterType.values.map((type) => _MeterOverviewCard(
                  meterType: type,
                  summary: provider.overviewSummaries[type],
                  onTap: () => _navigateToMonthly(context, type),
                )),
              ],
            ),
    );
  }

  void _navigateToMonthly(BuildContext context, MeterType meterType) {
    final provider = context.read<AnalyticsProvider>();
    provider.setSelectedMeterType(meterType);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MonthlyAnalyticsScreen(),
      ),
    );
  }
}

class _MeterOverviewCard extends StatelessWidget {
  final MeterType meterType;
  final MeterTypeSummary? summary;
  final VoidCallback onTap;

  // Displays: icon, meter type name, latest month consumption, unit
  // Color from AppColors: electricityColor, gasColor, waterColor, heatingColor
  // Tap navigates to MonthlyAnalyticsScreen for that type
}
```

**Color mapping** (use existing AppColors):
```dart
Color colorForMeterType(MeterType type) {
  switch (type) {
    case MeterType.electricity: return AppColors.electricityColor;
    case MeterType.gas: return AppColors.gasColor;
    case MeterType.water: return AppColors.waterColor;
    case MeterType.heating: return AppColors.heatingColor;
  }
}

IconData iconForMeterType(MeterType type) {
  switch (type) {
    case MeterType.electricity: return Icons.electric_bolt;
    case MeterType.gas: return Icons.local_fire_department;
    case MeterType.water: return Icons.water_drop;
    case MeterType.heating: return Icons.thermostat;
  }
}
```

Put `colorForMeterType` and `iconForMeterType` in `analytics_models.dart` as top-level functions so both AnalyticsScreen and MonthlyAnalyticsScreen can use them.

**Test file**: `test/screens/analytics_screen_test.dart`
- Renders 4 overview cards (one per meter type)
- Shows loading indicator when isLoading=true
- Tapping a card navigates to MonthlyAnalyticsScreen
- Shows correct colors and icons per meter type
- Handles empty summaries gracefully

---

### Task 6: MonthlyAnalyticsScreen
**File**: `lib/screens/monthly_analytics_screen.dart` (new)
**Dependencies**: Task 2, Task 3, Task 4

Full monthly analytics screen with month navigation, line chart, bar chart, and custom date range:

```dart
class MonthlyAnalyticsScreen extends StatelessWidget {
  const MonthlyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AnalyticsProvider>();
    final data = provider.monthlyData;
    final color = colorForMeterType(provider.selectedMeterType);

    return Scaffold(
      appBar: AppBar(
        title: Text(_meterTypeLabel(l10n, provider.selectedMeterType)),
        actions: [
          // Custom date range picker button
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _pickDateRange(context),
            tooltip: l10n.customDateRange,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? Center(child: Text(l10n.noData))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Month navigation header
                    _MonthNavigationHeader(
                      selectedMonth: provider.selectedMonth,
                      customRange: provider.customRange,
                      onPrevious: () => provider.navigateMonth(-1),
                      onNext: () => provider.navigateMonth(1),
                    ),
                    const SizedBox(height: 16),

                    // Consumption summary card
                    _ConsumptionSummaryCard(
                      totalConsumption: data.totalConsumption,
                      unit: data.unit,
                      color: color,
                    ),
                    const SizedBox(height: 24),

                    // Line chart: daily consumption trends
                    Text(l10n.dailyTrends,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: ConsumptionLineChart(
                        dataPoints: data.dailyValues,
                        rangeStart: provider.customRange?.start ?? provider.selectedMonth,
                        rangeEnd: provider.customRange?.end ??
                            DateTime(provider.selectedMonth.year, provider.selectedMonth.month + 1, 0),
                        primaryColor: color,
                        unit: data.unit,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ChartLegend(items: [
                      ChartLegendItem(color: color, label: l10n.actual),
                      ChartLegendItem(
                        color: color.withValues(alpha: 0.5),
                        label: l10n.interpolated,
                        isDashed: true,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Bar chart: monthly comparison
                    Text(l10n.monthlyComparison,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: MonthlyBarChart(
                        periods: data.recentMonths,
                        primaryColor: color,
                        unit: data.unit,
                        highlightMonth: provider.selectedMonth,
                      ),
                    ),
                  ],
                ),
    );
  }

  String _meterTypeLabel(AppLocalizations l10n, MeterType type) {
    switch (type) {
      case MeterType.electricity: return l10n.electricity;
      case MeterType.gas: return l10n.gas;
      case MeterType.water: return l10n.water;
      case MeterType.heating: return l10n.heating;
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<AnalyticsProvider>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: provider.customRange ??
          DateTimeRange(
            start: provider.selectedMonth,
            end: DateTime(provider.selectedMonth.year, provider.selectedMonth.month + 1, 0),
          ),
    );
    if (range != null) {
      provider.setCustomRange(range);
    }
  }
}

class _MonthNavigationHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTimeRange? customRange;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  // Displays: < January 2026 >  or  "Dec 15 - Jan 15" if custom range active
  // Forward button disabled if selected month is current month
}

class _ConsumptionSummaryCard extends StatelessWidget {
  final double? totalConsumption;
  final String unit;
  final Color color;
  // Large text showing total consumption for the period
}
```

**Test file**: `test/screens/monthly_analytics_screen_test.dart`
- Renders month navigation header with correct month
- Previous/next buttons call provider.navigateMonth
- Shows consumption summary card
- Renders line chart section
- Renders bar chart section
- Custom date range picker opens on icon tap
- Shows noData when data is null
- Shows loading indicator when isLoading

---

### Task 7: Wire Navigation — HomeScreen + Per-Meter Screens
**Files** (modify existing):
- `lib/main.dart` — Register AnalyticsProvider in MultiProvider + wire household changes
- `lib/screens/electricity_screen.dart` — Add analytics action button in AppBar
- `lib/screens/gas_screen.dart` — Add analytics action button in AppBar
- `lib/screens/water_screen.dart` — Add analytics action button in AppBar
- `lib/screens/heating_screen.dart` — Add analytics action button in AppBar
**Dependencies**: Task 2, Task 5, Task 6

**main.dart changes:**

```dart
// Import new dependencies
import 'providers/analytics_provider.dart';
import 'services/analytics/analytics_models.dart';
import 'services/interpolation/interpolation_service.dart';
import 'services/gas_conversion_service.dart';

// In main():
final interpolationService = InterpolationService();
final gasConversionService = GasConversionService();
final analyticsProvider = AnalyticsProvider(
  electricityDao: ElectricityDao(database),
  gasDao: GasDao(database),
  waterDao: WaterDao(database),
  heatingDao: HeatingDao(database),
  interpolationService: interpolationService,
  gasConversionService: gasConversionService,
  settingsProvider: interpolationSettingsProvider,
);

// Pass to ValtraApp, add field + constructor param
// Add to MultiProvider:
ChangeNotifierProvider<AnalyticsProvider>.value(value: widget.analyticsProvider),

// In _onHouseholdChanged():
widget.analyticsProvider.setHouseholdId(householdId);

// In initial household connection block:
analyticsProvider.setHouseholdId(householdProvider.selectedHouseholdId);
```

**HomeScreen changes** — Add analytics chip between the Valtra title section and the meter type chips:

```dart
// After the existing "Heating" chip and before the FAB:
const SizedBox(height: 16),
const Divider(),
const SizedBox(height: 8),
_buildCategoryChip(
  context,
  Icons.analytics,
  l10n.analyticsHub,
  AppColors.ultraViolet,
  onTap: () => _navigateToAnalytics(context),
),

// New method:
void _navigateToAnalytics(BuildContext context) {
  final householdProvider = context.read<HouseholdProvider>();
  if (householdProvider.selectedHousehold == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.selectHousehold)),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
  );
}
```

**Per-meter screen changes** — Add analytics IconButton in AppBar actions (same pattern for all 4):

```dart
// In ElectricityScreen AppBar actions (before existing Chip):
IconButton(
  icon: const Icon(Icons.analytics),
  onPressed: () {
    final analyticsProvider = context.read<AnalyticsProvider>();
    analyticsProvider.setSelectedMeterType(MeterType.electricity);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MonthlyAnalyticsScreen()),
    );
  },
  tooltip: l10n.analyticsHub,
),
```

Repeat for GasScreen (MeterType.gas), WaterScreen (MeterType.water), HeatingScreen (MeterType.heating).

**Test file**: `test/main_analytics_wiring_test.dart` (new, lightweight)
- AnalyticsProvider is accessible via Provider.of in widget tree
- HomeScreen has analytics chip that navigates to AnalyticsScreen

---

### Task 8: Localization — EN + DE Strings
**Files** (modify existing):
- `lib/l10n/app_en.arb`
- `lib/l10n/app_de.arb`
**Dependencies**: None

Add localization keys for all analytics UI:

**English (app_en.arb) — add these keys:**
```json
"analyticsHub": "Analytics",
"consumptionOverview": "Consumption Overview",
"monthlyAnalytics": "Monthly Analytics",
"dailyTrends": "Daily Trends",
"monthlyComparison": "Monthly Comparison",
"customDateRange": "Custom Date Range",
"totalConsumption": "Total Consumption",
"noAnalyticsData": "Not enough data for analytics. Add more readings!",
"consumptionValue": "{value} {unit}",
"monthlyConsumptionValue": "{value} {unit} in {month}",
"analyticsFor": "Analytics for {meterType}",
"previousMonth": "Previous Month",
"nextMonth": "Next Month",
"recentMonths": "Recent Months",
"averageConsumption": "Average: {value} {unit}"
```

**German (app_de.arb) — add these keys:**
```json
"analyticsHub": "Analyse",
"consumptionOverview": "Verbrauchsuebersicht",
"monthlyAnalytics": "Monatsanalyse",
"dailyTrends": "Tagesverlauf",
"monthlyComparison": "Monatsvergleich",
"customDateRange": "Eigener Zeitraum",
"totalConsumption": "Gesamtverbrauch",
"noAnalyticsData": "Nicht genuegend Daten fuer Analysen. Fuegen Sie weitere Ablesungen hinzu!",
"consumptionValue": "{value} {unit}",
"monthlyConsumptionValue": "{value} {unit} im {month}",
"analyticsFor": "Analyse fuer {meterType}",
"previousMonth": "Vorheriger Monat",
"nextMonth": "Naechster Monat",
"recentMonths": "Letzte Monate",
"averageConsumption": "Durchschnitt: {value} {unit}"
```

Note: Use proper German characters (umlauts) in the actual ARB file. The examples above use ASCII approximations for readability.

After adding keys, run `flutter gen-l10n` to regenerate the localization delegates.

**Test**: Run `flutter gen-l10n` — no errors. Run `flutter analyze` — no missing l10n references.

---

### Task 9: Comprehensive Tests & Verification
**Dependencies**: All previous tasks

1. Run `flutter test` — all tests must pass (existing ~370 + new ~60-70)
2. Run `flutter analyze` — zero issues
3. Verify test counts per component:

| Component | Expected Tests |
|-----------|---------------|
| analytics_models | ~6 (construction, MeterType, unit mapping) |
| AnalyticsProvider | ~12 (state management, data loading, navigation, aggregation) |
| ConsumptionLineChart | ~5 (rendering, split logic, empty state) |
| MonthlyBarChart | ~4 (rendering, highlighting, empty state) |
| ChartLegend | ~3 (rendering, items) |
| AnalyticsScreen (hub) | ~5 (cards, navigation, loading) |
| MonthlyAnalyticsScreen | ~8 (navigation, charts, date picker, loading) |
| Navigation wiring | ~3 (main.dart, home screen, per-meter) |
| **Total new** | **~46-50** |

---

## Wave Execution Plan

```
Wave 1 (Parallel — no dependencies):
  ├── Task 1: Analytics data models & MeterType enum
  └── Task 8: Localization (EN + DE strings)

Wave 2 (Parallel — depends on Task 1):
  ├── Task 2: AnalyticsProvider (data aggregation engine)
  ├── Task 3: ConsumptionLineChart widget
  └── Task 4: MonthlyBarChart + ChartLegend widgets

Wave 3 (Sequential — depends on Tasks 2, 3, 4):
  └── Task 6: MonthlyAnalyticsScreen (uses provider + chart widgets)

Wave 4 (Sequential — depends on Task 6):
  └── Task 5: AnalyticsScreen hub (imports MonthlyAnalyticsScreen for navigation)

Wave 5 (Sequential — depends on Tasks 2, 5, 6):
  └── Task 7: Wire navigation (main.dart + HomeScreen + per-meter screens)

Wave 6 (Sequential — depends on all):
  └── Task 9: Run tests + analyze
```

Note: AnalyticsScreen (Task 5) imports and navigates TO MonthlyAnalyticsScreen (Task 6), so Task 6 must exist before Task 5. Tasks 3 and 4 are pure widget tasks that only depend on the data models from Task 1.

---

## Files Created (New)

| File | Type |
|------|------|
| `lib/services/analytics/analytics_models.dart` | Data models + enums |
| `lib/providers/analytics_provider.dart` | Analytics state management |
| `lib/widgets/charts/consumption_line_chart.dart` | Line chart widget |
| `lib/widgets/charts/monthly_bar_chart.dart` | Bar chart widget |
| `lib/widgets/charts/chart_legend.dart` | Custom legend widget |
| `lib/screens/analytics_screen.dart` | Analytics hub screen |
| `lib/screens/monthly_analytics_screen.dart` | Monthly detail screen |
| `test/services/analytics/analytics_models_test.dart` | Tests |
| `test/providers/analytics_provider_test.dart` | Tests |
| `test/widgets/charts/consumption_line_chart_test.dart` | Tests |
| `test/widgets/charts/monthly_bar_chart_test.dart` | Tests |
| `test/widgets/charts/chart_legend_test.dart` | Tests |
| `test/screens/analytics_screen_test.dart` | Tests |
| `test/screens/monthly_analytics_screen_test.dart` | Tests |
| `test/main_analytics_wiring_test.dart` | Tests |

## Files Modified

| File | Change |
|------|--------|
| `lib/main.dart` | Register AnalyticsProvider, wire household, add to MultiProvider |
| `lib/screens/electricity_screen.dart` | Add analytics IconButton in AppBar |
| `lib/screens/gas_screen.dart` | Add analytics IconButton in AppBar |
| `lib/screens/water_screen.dart` | Add analytics IconButton in AppBar |
| `lib/screens/heating_screen.dart` | Add analytics IconButton in AppBar |
| `lib/l10n/app_en.arb` | Add ~14 analytics localization keys |
| `lib/l10n/app_de.arb` | Add ~14 analytics localization keys |

---

## Key Design Decisions

1. **Single AnalyticsProvider, not one per meter type** — One provider handles all 4 meter types with a `selectedMeterType` field. This keeps the provider tree simple and avoids 4 nearly-identical providers. The provider switches data sources internally via `_getReadingsForMeterType()`.

2. **Chart data preparation in Provider, not in widgets** — The Provider converts DAO readings to `ChartDataPoint` objects (with isInterpolated flags). Widgets receive chart-ready data and only handle FlSpot conversion. This keeps widgets stateless and testable, and avoids service dependencies in the widget layer.

3. **Water/Heating aggregation: interpolate per-meter, then sum** — For households with multiple water meters or heating meters, each meter is interpolated independently (preserving its own monotonically increasing cumulative reading series). Monthly consumption and daily boundary values are computed per-meter, then summed across all meters. This gives a correct total-household consumption view. Merging raw readings from different meters would violate the InterpolationService's single-timeline assumption. Per-meter breakdown is deferred to a future enhancement.

4. **Two-line approach for actual vs interpolated** — Following the fl_chart research, we use two overlapping `LineChartBarData` entries: solid line for actual readings, dashed line for interpolated. `FlSpot.nullSpot` creates gaps so lines only appear where their data type exists. This is cleaner than trying to change line style mid-line (which fl_chart does not support).

5. **BarChartGroupData.x uses sequential int indices** — Per fl_chart API constraint, `x` is `int`. We use `0, 1, 2, ...` as group indices and map to month labels via `getTitlesWidget`. The month name is derived from the `PeriodConsumption.periodStart` date.

6. **Month navigation state in Provider** — `selectedMonth` (DateTime, always 1st of month) and `navigateMonth(delta)` handle forward/back. When a custom date range is set, it overrides the month selection. Navigating months clears the custom range.

7. **Custom date range via Flutter's built-in `showDateRangePicker`** — No custom widget needed. The Material date range picker is well-tested, accessible, and localized. The selected range is stored in `AnalyticsProvider.customRange` and cleared when using month navigation.

8. **Analytics accessible from both hub and per-meter screens** — Hub card tap navigates to MonthlyAnalyticsScreen with the selected meter type. Per-meter screen AppBar icon does the same. Both use the same AnalyticsProvider instance, just setting `selectedMeterType` before navigation.

9. **No extrapolation, matching Phase 8 behavior** — If there is insufficient reading data for a month boundary, that boundary is simply omitted from the chart. No synthetic data outside the reading range.

10. **All dates in local time** — `DateTime(year, month, 1)` creates local-time dates. This matches the InterpolationService behavior from Phase 8 and user expectations.

---

## Acceptance Criteria

- [ ] AnalyticsScreen hub is accessible from HomeScreen via analytics chip (FR-7.3.1)
- [ ] Hub shows 4 overview cards with latest month consumption per meter type (FR-7.3.3)
- [ ] Tapping a hub card navigates to MonthlyAnalyticsScreen for that type (FR-7.3.4)
- [ ] Per-meter screens (electricity, gas, water, heating) have analytics button navigating to MonthlyAnalyticsScreen (FR-7.3.2)
- [ ] MonthlyAnalyticsScreen shows line chart of daily consumption trends (FR-7.1.3)
- [ ] MonthlyAnalyticsScreen shows bar chart of recent months comparison (FR-7.1.4)
- [ ] Month navigation (forward/back) works and updates charts (FR-7.1.2)
- [ ] Interpolated values shown as dashed line with distinct markers (FR-7.1.5)
- [ ] Custom date range picker filters analytics to selected period (FR-7.1.6)
- [ ] Monthly consumption summary displayed for selected period (FR-7.1.1)
- [ ] Gas analytics shows m3 values (kWh conversion available via GasConversionService)
- [ ] Water/heating analytics aggregate across all meters for household
- [ ] All new strings localized in EN + DE ARB files (NFR-6.1)
- [ ] Chart axis labels use locale-appropriate date formatting (NFR-6.2)
- [ ] `flutter test` passes (existing ~370 + ~50 new)
- [ ] `flutter analyze` reports zero issues

---

## Executor Notes

1. **fl_chart v0.68.0 is already installed** — No need to add to pubspec.yaml. Import via `import 'package:fl_chart/fl_chart.dart';`

2. **InterpolationService has no constructor dependencies** — It is a pure Dart class. Instantiate directly: `final interpolationService = InterpolationService();`

3. **GasConversionService has no constructor dependencies** — Same pattern: `final gasConversionService = GasConversionService();`

4. **Widget tests with AnalyticsProvider** — Use `mocktail` to create a `MockAnalyticsProvider extends Mock implements AnalyticsProvider`. Wrap test widgets with `ChangeNotifierProvider<AnalyticsProvider>.value(value: mockProvider)`.

5. **fl_chart widget testing** — fl_chart widgets render via `CustomPainter`. Widget tests can verify the widget renders without error via `findsOneWidget`, but cannot inspect canvas contents. Focus on: data transformation logic (unit testable), widget rendering (no crash), and state management (provider updates trigger rebuilds).

6. **`flutter gen-l10n` must be run** after modifying ARB files to regenerate `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`. These generated files should be committed.

7. **Water/Heating meter aggregation edge case** — If a household has zero water/heating meters, `_getReadingsForMeterType` returns empty list, which results in `MonthlyAnalyticsData` with empty `dailyValues` and `recentMonths`. The chart widgets handle empty data by showing the noData message.

8. **`DateTimeRange` import** — This is from `package:flutter/material.dart`, already available.

---

## Verification

**Plan check result**: PASS (after iteration)
**Checker**: All FR-7.1.x and FR-7.3.x requirements covered. Water/heating aggregation correctly interpolates per-meter independently then sums. Wave dependencies corrected (Task 5 depends on Task 6, not vice versa). BarChart explicit bounds added. Chart patterns follow fl_chart research. Architecture fits existing provider/screen patterns.

## Executor Notes (from plan verification)

1. **Water/heating multi-meter aggregation** — `_getReadingsPerMeter` returns `List<List<ReadingPoint>>` (one list per physical meter). `_aggregateMonthlyConsumption` and `_aggregateDailyBoundaries` interpolate each meter independently then sum. This is critical — never merge raw readings from different meters.
2. **AnalyticsScreen imports MonthlyAnalyticsScreen** — Task 5 depends on Task 6, not the other way around. Wave ordering reflects this (Task 6 in Wave 3, Task 5 in Wave 4).
3. **Existing l10n keys "actual" and "interpolated"** — These exist from Phase 8. Do NOT re-add them in Task 8. The plan's chart legend references `l10n.actual` and `l10n.interpolated` which are already present.
4. **HomeScreen is inside main.dart** — Not a separate file. Task 7 correctly references `lib/main.dart`.
5. **German localization** — Use proper umlauts (ü, ö, ä) in actual ARB files, not ASCII approximations.
6. **DAO instances** — The plan creates new DAO instances for AnalyticsProvider. This means duplicate instances (one for meter provider, one for analytics). This works fine with Drift but executor could optionally share.
7. **`DateTime(year, month + 1, 0)` for month end** — This gives the last day of the current month. Correct for rangeEnd boundaries.

---

## Commit Message
```
Implement Phase 9: Analytics hub with overview cards, monthly analytics with fl_chart line/bar charts, month navigation, custom date ranges, and interpolated value distinction
```
