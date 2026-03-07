# fl_chart Research for Valtra Analytics

**Package:** fl_chart v0.68.0
**Researched:** 2026-03-07
**Source:** Verified from installed package source code in pub cache
**Confidence:** HIGH (all findings verified from actual v0.68.0 Dart source)

---

## 1. Line Charts -- Time-Series Consumption Trends

### Core Data Model

The `LineChart` widget accepts `LineChartData` which contains:

```dart
LineChartData(
  lineBarsData: [LineChartBarData(...)],  // one per line
  minX: double,  // if NaN, auto-calculated from spots
  maxX: double,
  minY: double,
  maxY: double,
  titlesData: FlTitlesData(...),
  gridData: FlGridData(...),
  borderData: FlBorderData(...),
  lineTouchData: LineTouchData(...),
  clipData: FlClipData.all(),
  extraLinesData: ExtraLinesData(...),  // for average lines, thresholds
  rangeAnnotations: RangeAnnotations(...),  // highlight regions
)
```

### FlSpot: The Data Point

Each point is an `FlSpot(double x, double y)`. For time-series:
- **x-axis**: Use `DateTime.millisecondsSinceEpoch.toDouble()` or a simpler mapping like days-since-epoch
- **y-axis**: The consumption value (kWh, m3, etc.)

**Line splitting:** Insert `FlSpot.nullSpot` between sections to create gaps in the line (useful for breaking lines at missing data boundaries).

### LineChartBarData: Per-Line Configuration

```dart
LineChartBarData(
  spots: [FlSpot(x, y), ...],
  show: true,
  color: Colors.blue,         // solid color OR
  gradient: LinearGradient(),  // gradient (not both)
  barWidth: 2.0,               // line thickness
  isCurved: true,              // smooth curves
  curveSmoothness: 0.35,       // 0.0 = sharp, 1.0 = very smooth
  preventCurveOverShooting: true,  // prevents overshooting on high value changes
  preventCurveOvershootingThreshold: 10.0,
  isStrokeCapRound: true,      // rounded line caps
  isStrokeJoinRound: true,     // rounded line joins
  dashArray: [5, 3],           // dashed line: 5px dash, 3px gap
  dotData: FlDotData(...),     // dot styling
  belowBarData: BarAreaData(show: true, color: color.withOpacity(0.3)),
  aboveBarData: BarAreaData(...),
  shadow: Shadow(color: Colors.black26, blurRadius: 4),
  isStepLineChart: false,      // step line mode
  lineChartStepData: LineChartStepData(stepDirection: 0.5),
)
```

### Recommended Pattern for Valtra Time-Series

```dart
// Convert readings to FlSpots
List<FlSpot> readingsToSpots(List<Reading> readings) {
  return readings.map((r) => FlSpot(
    r.timestamp.millisecondsSinceEpoch.toDouble(),
    r.value,
  )).toList();
}

// Configure line
LineChartBarData(
  spots: readingsToSpots(readings),
  isCurved: true,
  curveSmoothness: 0.25,
  preventCurveOverShooting: true,
  color: meterTypeColor,
  barWidth: 2.5,
  isStrokeCapRound: true,
  dotData: const FlDotData(show: false),  // hide dots by default, show on touch
  belowBarData: BarAreaData(
    show: true,
    color: meterTypeColor.withOpacity(0.1),
  ),
)
```

### Touch Interaction

`LineTouchData` controls all touch behavior:

```dart
LineTouchData(
  enabled: true,
  handleBuiltInTouches: true,  // auto tooltip on touch
  touchSpotThreshold: 10,       // distance threshold in pixels
  distanceCalculator: _xDistance,  // default: only x-axis distance (vertical crosshair)
  touchTooltipData: LineTouchTooltipData(
    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
      return LineTooltipItem(
        '${DateFormat.MMMd().format(date)}\n${spot.y.toStringAsFixed(1)} kWh',
        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList(),
    getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
    tooltipRoundedRadius: 8,
    tooltipPadding: const EdgeInsets.all(8),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
  ),
  getTouchedSpotIndicator: (barData, spotIndexes) {
    return spotIndexes.map((index) {
      return TouchedSpotIndicatorData(
        const FlLine(color: Colors.grey, strokeWidth: 1, dashArray: [5, 3]),
        FlDotData(
          getDotPainter: (spot, percent, bar, i) => FlDotCirclePainter(
            radius: 6,
            color: Colors.white,
            strokeColor: bar.color ?? Colors.blue,
            strokeWidth: 2,
          ),
        ),
      );
    }).toList();
  },
  getTouchLineStart: (barData, spotIndex) => -double.infinity,  // line from bottom
  getTouchLineEnd: (barData, spotIndex) => barData.spots[spotIndex].y,
)
```

**Touch callback for custom behavior:**

```dart
LineTouchData(
  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlTapUpEvent && response?.lineBarSpots != null) {
      final spot = response!.lineBarSpots!.first;
      // Navigate to reading detail, highlight selection, etc.
    }
  },
)
```

### Extra Lines (Average, Threshold)

```dart
ExtraLinesData(
  horizontalLines: [
    HorizontalLine(
      y: averageConsumption,
      color: Colors.orange,
      strokeWidth: 1,
      dashArray: [8, 4],
      label: HorizontalLineLabel(
        show: true,
        labelResolver: (line) => 'Avg: ${line.y.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.orange, fontSize: 10),
        alignment: Alignment.topRight,
      ),
    ),
  ],
)
```

---

## 2. Bar Charts -- Monthly Comparison & Year-over-Year

### Core Data Model

```dart
BarChartData(
  barGroups: [BarChartGroupData(...)],
  alignment: BarChartAlignment.spaceEvenly,
  groupsSpace: 16,
  maxY: double.nan,  // auto-calculated if NaN
  minY: double.nan,
  titlesData: FlTitlesData(...),
  gridData: FlGridData(...),
  barTouchData: BarTouchData(...),
  borderData: FlBorderData(...),
  extraLinesData: ExtraLinesData(...),  // horizontal only (vertical not supported)
)
```

### BarChartGroupData: Each Bar Group

```dart
BarChartGroupData(
  x: 0,              // integer! Used for title lookup, not positioning
  barRods: [BarChartRodData(...)],  // one rod = one bar; multiple = grouped
  barsSpace: 2,       // space between rods in a group
  groupVertically: false,  // false = side-by-side, true = stacked
  showingTooltipIndicators: [],  // rod indices to show tooltips on
)
```

**IMPORTANT:** `x` is an `int` (not double). It identifies the group for `SideTitles.getTitlesWidget`. It does NOT determine horizontal position -- bars are arranged by list order and `alignment`.

### BarChartRodData: Individual Bar

```dart
BarChartRodData(
  fromY: 0,           // bottom of bar (default 0)
  toY: 150.5,         // top of bar (required)
  color: Colors.blue,
  gradient: LinearGradient(...),  // alternative to color
  width: 16,           // bar thickness in pixels (default 8)
  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
  borderSide: BorderSide(color: Colors.blue.shade700, width: 1),
  borderDashArray: [5, 3],  // dashed border
  backDrawRodData: BackgroundBarChartRodData(
    show: true,
    toY: maxValue,
    color: Colors.grey.withOpacity(0.1),
  ),
  rodStackItems: [...],  // for stacked charts
)
```

### Monthly Comparison Pattern

```dart
// Each month = one BarChartGroupData
List<BarChartGroupData> buildMonthlyBars(Map<int, double> monthlyConsumption) {
  return monthlyConsumption.entries.map((entry) {
    return BarChartGroupData(
      x: entry.key,  // month index (0-11)
      barRods: [
        BarChartRodData(
          toY: entry.value,
          color: Colors.blue,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }).toList();
}

// Bottom titles for months
FlTitlesData(
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 30,
      getTitlesWidget: (value, meta) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final index = value.toInt();
        if (index < 0 || index >= months.length) return const SizedBox.shrink();
        return SideTitleWidget(
          axisSide: meta.axisSide,
          child: Text(months[index], style: const TextStyle(fontSize: 10)),
        );
      },
    ),
  ),
  leftTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 50,
      getTitlesWidget: (value, meta) => SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text('${value.toInt()} kWh', style: const TextStyle(fontSize: 10)),
      ),
    ),
  ),
  topTitles: const AxisTitles(),  // hidden
  rightTitles: const AxisTitles(),  // hidden
)
```

### Year-over-Year Grouped Bars

For comparing the same month across years, put multiple `BarChartRodData` in one group:

```dart
BarChartGroupData(
  x: monthIndex,
  barRods: [
    BarChartRodData(toY: thisYearValue, color: Colors.blue, width: 12),
    BarChartRodData(toY: lastYearValue, color: Colors.blue.shade200, width: 12),
  ],
  barsSpace: 4,  // gap between the two bars in the group
)
```

### Bar Touch Interaction

```dart
BarTouchData(
  enabled: true,
  handleBuiltInTouches: true,
  touchTooltipData: BarTouchTooltipData(
    getTooltipItem: (group, groupIndex, rod, rodIndex) {
      final month = months[group.x];
      final yearLabel = rodIndex == 0 ? 'This Year' : 'Last Year';
      return BarTooltipItem(
        '$month ($yearLabel)\n${rod.toY.toStringAsFixed(1)} kWh',
        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    },
    getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.8),
    tooltipRoundedRadius: 8,
    fitInsideHorizontally: true,
    fitInsideVertically: true,
  ),
  touchExtraThreshold: const EdgeInsets.all(4),
)
```

### Stacked Bars (Alternative for YoY)

```dart
BarChartRodData(
  toY: totalValue,
  color: Colors.grey,
  width: 20,
  rodStackItems: [
    BarChartRodStackItem(0, thisYearValue, Colors.blue),
    BarChartRodStackItem(thisYearValue, totalValue, Colors.blue.shade200),
  ],
)
```

---

## 3. Pie Charts -- Usage Breakdown by Category

### Core Data Model

```dart
PieChartData(
  sections: [PieChartSectionData(...)],
  centerSpaceRadius: 50,       // donut hole (double.infinity = auto/full)
  centerSpaceColor: Colors.transparent,
  sectionsSpace: 2,            // gap between slices (NOTE: broken on web HTML renderer)
  startDegreeOffset: -90,      // start from top (default 0 = right)
  pieTouchData: PieTouchData(...),
  titleSunbeamLayout: false,   // rotates titles to follow arc direction
)
```

### PieChartSectionData: Each Slice

```dart
PieChartSectionData(
  value: 42.5,                 // proportional value (auto-calculated percentage)
  title: '42.5 kWh',
  showTitle: true,
  titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
  titlePositionPercentageOffset: 0.6,  // 0=center, 1=edge
  color: Colors.blue,
  gradient: RadialGradient(...),  // overrides color if set
  radius: 80,                  // slice radius in pixels
  borderSide: const BorderSide(width: 0),
  badgeWidget: Icon(Icons.bolt),  // optional widget overlay
  badgePositionPercentageOffset: 1.1,  // >1 = outside the slice
)
```

**IMPORTANT:** `value` does not need to be a percentage. fl_chart calculates percentages via `value / sumValues * 360`. Pass raw consumption values directly.

### Percentage Labels Pattern

```dart
List<PieChartSectionData> buildSections(Map<String, double> breakdown, double total) {
  final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple];
  var colorIndex = 0;

  return breakdown.entries.map((entry) {
    final percentage = (entry.value / total * 100).toStringAsFixed(1);
    final color = colors[colorIndex++ % colors.length];

    return PieChartSectionData(
      value: entry.value,
      title: '${entry.key}\n$percentage%',
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titlePositionPercentageOffset: 0.55,
      color: color,
      radius: 80,
    );
  }).toList();
}
```

### Pie Touch Interaction

```dart
PieTouchData(
  enabled: true,
  touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
    if (event is FlTapUpEvent || event is FlLongPressStart) {
      final touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
      setState(() => _selectedIndex = touchedIndex);
    }
  },
)
```

**Common pattern -- enlarge touched section:**

```dart
PieChartSectionData(
  radius: index == _selectedIndex ? 90 : 80,
  titlePositionPercentageOffset: index == _selectedIndex ? 0.6 : 0.5,
)
```

### Smart Plug Breakdown (Valtra-specific)

For the "Other" (remaining electricity not attributed to smart plugs):

```dart
final smartPlugTotal = smartPlugConsumptions.values.fold(0.0, (a, b) => a + b);
final otherConsumption = totalElectricity - smartPlugTotal;

final sections = [
  ...smartPlugConsumptions.entries.map((e) => PieChartSectionData(
    value: e.value,
    title: '${e.key}\n${(e.value / totalElectricity * 100).toStringAsFixed(0)}%',
    color: plugColors[e.key],
    radius: 80,
  )),
  if (otherConsumption > 0)
    PieChartSectionData(
      value: otherConsumption,
      title: 'Other\n${(otherConsumption / totalElectricity * 100).toStringAsFixed(0)}%',
      color: Colors.grey,
      radius: 80,
    ),
];
```

---

## 4. Custom Date Ranges -- Dynamic Axis Configuration

### Strategy: Map Dates to Doubles

fl_chart uses `double` for all axis values. For date-based axes:

**Option A: Milliseconds since epoch (recommended for continuous time)**

```dart
// Conversion
double dateToX(DateTime date) => date.millisecondsSinceEpoch.toDouble();
DateTime xToDate(double x) => DateTime.fromMillisecondsSinceEpoch(x.toInt());

// Chart bounds
LineChartData(
  minX: dateToX(rangeStart),
  maxX: dateToX(rangeEnd),
  // ...
)
```

**Option B: Days since a reference date (better for sparse data)**

```dart
final referenceDate = DateTime(2024, 1, 1);
double dateToX(DateTime date) => date.difference(referenceDate).inDays.toDouble();
DateTime xToDate(double x) => referenceDate.add(Duration(days: x.toInt()));
```

### Dynamic Axis Labels for Date Ranges

The interval and format should adapt to the selected range:

```dart
SideTitles _bottomTitlesForRange(DateTime start, DateTime end) {
  final rangeDays = end.difference(start).inDays;

  double? interval;
  String Function(DateTime) formatter;

  if (rangeDays <= 7) {
    // Daily labels
    interval = const Duration(days: 1).inMilliseconds.toDouble();
    formatter = (d) => DateFormat.E().format(d);  // Mon, Tue, ...
  } else if (rangeDays <= 31) {
    // Every 7 days
    interval = const Duration(days: 7).inMilliseconds.toDouble();
    formatter = (d) => DateFormat.MMMd().format(d);  // Jan 5
  } else if (rangeDays <= 365) {
    // Monthly
    interval = const Duration(days: 30).inMilliseconds.toDouble();
    formatter = (d) => DateFormat.MMM().format(d);  // Jan, Feb, ...
  } else {
    // Quarterly
    interval = const Duration(days: 90).inMilliseconds.toDouble();
    formatter = (d) => DateFormat.yMMM().format(d);  // Jan 2025
  }

  return SideTitles(
    showTitles: true,
    reservedSize: 30,
    interval: interval,
    getTitlesWidget: (value, meta) {
      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
      return SideTitleWidget(
        axisSide: meta.axisSide,
        fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
        child: Text(
          formatter(date),
          style: const TextStyle(fontSize: 10),
        ),
      );
    },
  );
}
```

### Grid Lines Adapting to Range

```dart
FlGridData(
  show: true,
  drawVerticalLine: true,
  verticalInterval: interval,  // same interval as titles
  getDrawingVerticalLine: (value) => const FlLine(
    color: Colors.grey,
    strokeWidth: 0.3,
    dashArray: [4, 4],
  ),
  drawHorizontalLine: true,
  getDrawingHorizontalLine: (value) => const FlLine(
    color: Colors.grey,
    strokeWidth: 0.3,
    dashArray: [4, 4],
  ),
)
```

### Clip Data for Bounds

When zooming or filtering to a custom range, use `clipData` to prevent drawing outside:

```dart
LineChartData(
  clipData: const FlClipData.all(),
  minX: dateToX(rangeStart),
  maxX: dateToX(rangeEnd),
  // ...
)
```

### Range Annotations for Highlighting Periods

```dart
RangeAnnotations(
  verticalRangeAnnotations: [
    VerticalRangeAnnotation(
      x1: dateToX(highlightStart),
      x2: dateToX(highlightEnd),
      color: Colors.yellow.withOpacity(0.1),
    ),
  ],
)
```

---

## 5. Interpolated vs Actual Data Points -- Visual Distinction

This is critical for Valtra since Phase 8 adds interpolation with an `isInterpolated` flag.

### Strategy: Two Separate LineChartBarData Lines

The cleanest approach is to overlay two lines: one for actual data (solid) and one for interpolated data (dashed), using `FlSpot.nullSpot` to create gaps.

```dart
// Split readings into two line datasets
(List<FlSpot> actualSpots, List<FlSpot> interpolatedSpots) splitByInterpolation(
  List<AnalyticsReading> readings,
) {
  final actual = <FlSpot>[];
  final interpolated = <FlSpot>[];

  for (int i = 0; i < readings.length; i++) {
    final r = readings[i];
    final spot = FlSpot(dateToX(r.date), r.value);

    if (r.isInterpolated) {
      interpolated.add(spot);
      // Add connecting points from neighboring actual readings
      if (i > 0 && !readings[i - 1].isInterpolated) {
        final prev = readings[i - 1];
        interpolated.insert(interpolated.length - 1, FlSpot(dateToX(prev.date), prev.value));
      }
      actual.add(FlSpot.nullSpot);  // gap in actual line
    } else {
      actual.add(spot);
      if (i > 0 && readings[i - 1].isInterpolated) {
        // Add this point to interpolated line too for continuity
        interpolated.add(spot);
      } else {
        interpolated.add(FlSpot.nullSpot);  // gap in interpolated line
      }
    }
  }

  return (actual, interpolated);
}
```

Then in the chart:

```dart
LineChartData(
  lineBarsData: [
    // Actual data: solid line, filled dots
    LineChartBarData(
      spots: actualSpots,
      color: Colors.blue,
      barWidth: 2.5,
      isCurved: true,
      dashArray: null,  // solid line
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
          radius: 4,
          color: Colors.blue,
          strokeColor: Colors.white,
          strokeWidth: 1.5,
        ),
      ),
    ),
    // Interpolated data: dashed line, different dot style
    LineChartBarData(
      spots: interpolatedSpots,
      color: Colors.blue.shade300,
      barWidth: 2.0,
      isCurved: true,
      dashArray: [8, 4],  // dashed line
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, pct, bar, idx) => FlDotSquarePainter(
          size: 6,
          color: Colors.blue.shade200,
          strokeColor: Colors.blue.shade400,
          strokeWidth: 1,
        ),
      ),
    ),
  ],
)
```

### Alternative: Single Line with Per-Spot Dot Customization

If you want one continuous line but different dot styles per point:

```dart
LineChartBarData(
  spots: allSpots,
  color: Colors.blue,
  barWidth: 2.5,
  isCurved: true,
  dotData: FlDotData(
    show: true,
    checkToShowDot: (spot, barData) => true,  // show all dots
    getDotPainter: (spot, xPercentage, barData, index) {
      final isInterpolated = readings[index].isInterpolated;
      if (isInterpolated) {
        return FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeColor: Colors.blue.shade300,
          strokeWidth: 2,  // hollow circle for interpolated
        );
      }
      return FlDotCirclePainter(
        radius: 4,
        color: Colors.blue,
        strokeColor: Colors.white,
        strokeWidth: 1.5,  // filled circle for actual
      );
    },
  ),
)
```

**Limitation:** This approach cannot make parts of the same line dashed. The entire `LineChartBarData` is either dashed or solid. Use the two-line approach if you need dashed segments.

### Available FlDotPainter Types

| Painter | Shape | Key Props | Best For |
|---------|-------|-----------|----------|
| `FlDotCirclePainter` | Circle | `radius`, `color`, `strokeColor`, `strokeWidth` | Actual data points (filled), interpolated (hollow) |
| `FlDotSquarePainter` | Square | `size`, `color`, `strokeColor`, `strokeWidth` | Interpolated points (distinct shape) |
| `FlDotCrossPainter` | X mark | `size`, `color`, `width` | Anomalous/flagged points |
| Custom `FlDotPainter` | Any | Override `draw()`, `getSize()`, `mainColor` | Diamond, triangle, or any custom shape |

### Recommended Visual Distinction for Valtra

| Data Type | Line Style | Dot Style | Color |
|-----------|------------|-----------|-------|
| Actual readings | Solid, 2.5px | Filled circle, r=4 | Full color (e.g., `Colors.blue`) |
| Interpolated readings | Dashed [8,4], 2px | Hollow circle, r=3, stroke=2 | Lighter shade (e.g., `Colors.blue.shade300`) |

### Legend Integration

Build a custom legend widget (fl_chart has no built-in legend):

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _LegendItem(color: Colors.blue, label: 'Actual', dashed: false),
    const SizedBox(width: 16),
    _LegendItem(color: Colors.blue.shade300, label: 'Interpolated', dashed: true),
  ],
)
```

---

## 6. Animation Support

All fl_chart widgets extend `ImplicitlyAnimatedWidget`. When you update `LineChartData`, `BarChartData`, or `PieChartData`, the chart animates automatically.

```dart
// Control animation timing
LineChart(
  data,
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
)
```

This means switching between date ranges, toggling meter types, or updating data will animate smoothly without any extra work.

---

## 7. Shared Configuration Patterns

### FlTitlesData: Title Configuration

```dart
FlTitlesData(
  show: true,
  leftTitles: AxisTitles(
    axisNameWidget: const Text('kWh'),  // axis label
    axisNameSize: 16,
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 50,
      interval: null,  // auto-calculated
      getTitlesWidget: (value, meta) => SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(value.toStringAsFixed(0)),
      ),
    ),
  ),
  bottomTitles: AxisTitles(...),
  topTitles: const AxisTitles(),    // hide
  rightTitles: const AxisTitles(),  // hide
)
```

### FlBorderData

```dart
FlBorderData(
  show: true,
  border: Border(
    bottom: BorderSide(color: Colors.grey.shade300),
    left: BorderSide(color: Colors.grey.shade300),
    top: BorderSide.none,
    right: BorderSide.none,
  ),
)
```

### SideTitleWidget

Always return `SideTitleWidget` from `getTitlesWidget` callbacks -- it handles alignment and spacing:

```dart
SideTitleWidget(
  axisSide: meta.axisSide,
  space: 8.0,
  angle: -0.5,  // radians, for rotated labels
  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
  child: Text('Label'),
)
```

---

## 8. Performance Considerations

### Large Datasets

- fl_chart redraws the entire canvas on every frame. For >500 data points, consider downsampling.
- Use `FlClipData.all()` to avoid rendering off-screen points.
- Set explicit `minX`, `maxX`, `minY`, `maxY` instead of letting the chart auto-calculate (avoids iterating all spots on each build).

### State Management Integration

fl_chart works with any state management. For Valtra's Provider architecture:

```dart
class AnalyticsProvider extends ChangeNotifier {
  DateTimeRange _dateRange = ...;
  List<FlSpot> _spots = [];

  void setDateRange(DateTimeRange range) {
    _dateRange = range;
    _loadData();
    notifyListeners();
  }

  LineChartData get chartData => LineChartData(
    minX: dateToX(_dateRange.start),
    maxX: dateToX(_dateRange.end),
    lineBarsData: [LineChartBarData(spots: _spots)],
    // ...
  );
}
```

### Testing

fl_chart widgets can be tested with `flutter_test`. Use `pumpWidget` with `MaterialApp` wrapper. Touch interactions can be tested via `finders` and `tester.tap()`. The data classes are all `Equatable`, making assertion easy.

---

## 9. API Gotchas and Pitfalls

### Critical

1. **BarChartGroupData.x is an int, not double** -- you cannot use timestamp doubles for bar chart x values. Use sequential integers and map to labels via `getTitlesWidget`.

2. **minX/maxX/minY/maxY default to NaN** -- which triggers auto-calculation. Always set explicit bounds for date-range charts to avoid wasting CPU and getting unexpected ranges.

3. **dashArray on LineChartBarData applies to the ENTIRE line** -- you cannot have a partially dashed line. Use two overlapping `LineChartBarData` entries instead.

4. **sectionsSpace on PieChart is broken on web HTML renderer** -- Flutter engine issue #44572. If targeting web, set `sectionsSpace: 0`.

5. **No built-in legend** -- you must create your own legend widget.

### Moderate

6. **SideTitles.interval must not be zero** -- assertion will fire. Always check for edge cases in your interval calculation.

7. **FlSpot equality uses NaN comparison** -- `FlSpot.nullSpot == FlSpot.nullSpot` returns true (special-cased).

8. **Color vs gradient -- provide only one** -- providing both will use gradient and ignore color, but the API docs say not to provide both.

9. **BarChart extraLinesData only supports horizontal lines** -- vertical extra lines are not rendered. See issue #1149.

10. **isCurved can cause overshooting** -- enable `preventCurveOverShooting: true` for consumption data that may have spikes.

### Minor

11. **Default FlDotCirclePainter strokeWidth is 0.0** -- changed in v0.66.0. If you want visible stroke, set it explicitly.

12. **LineChart auto-calculates axis bounds from spots** -- if you add spots dynamically, the chart may rescale unexpectedly. Pin bounds explicitly.

13. **Animation duration defaults to 150ms** -- may feel too fast for data transitions. Consider 300-400ms with `Curves.easeInOut`.

---

## 10. Recommended Architecture for Valtra Charts

### Widget Hierarchy

```
AnalyticsScreen
  |-- DateRangePicker
  |-- MeterTypeSelector
  |-- ConsumptionLineChart (custom widget wrapping LineChart)
  |-- MonthlyBarChart (custom widget wrapping BarChart)
  |-- SmartPlugPieChart (custom widget wrapping PieChart)
```

### Reusable Chart Widget Pattern

```dart
class ConsumptionLineChart extends StatelessWidget {
  final List<FlSpot> actualSpots;
  final List<FlSpot> interpolatedSpots;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final Color primaryColor;
  final String unit;  // 'kWh', 'm3', etc.
  final double? averageValue;

  // ... constructor

  @override
  Widget build(BuildContext context) {
    return LineChart(
      _buildData(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  LineChartData _buildData() => LineChartData(
    minX: dateToX(rangeStart),
    maxX: dateToX(rangeEnd),
    clipData: const FlClipData.all(),
    lineBarsData: [
      _actualLine(),
      if (interpolatedSpots.isNotEmpty) _interpolatedLine(),
    ],
    titlesData: _buildTitles(),
    gridData: _buildGrid(),
    borderData: _buildBorder(),
    lineTouchData: _buildTouch(),
    extraLinesData: _buildExtraLines(),
  );
}
```

### Chart Color Scheme (Align with Existing Meter Types)

| Meter Type | Suggested Primary | Suggested Light |
|------------|-------------------|-----------------|
| Electricity | `Colors.amber` | `Colors.amber.shade200` |
| Gas | `Colors.deepOrange` | `Colors.deepOrange.shade200` |
| Water | `Colors.blue` | `Colors.blue.shade200` |
| Heating | `Colors.red` | `Colors.red.shade200` |
| Smart Plug | varies per plug | varies |

---

## Sources

All findings verified from the installed fl_chart v0.68.0 source code:
- `C:\Users\I551358\AppData\Local\Pub\Cache\hosted\pub.dev\fl_chart-0.68.0\lib\src\chart\line_chart\line_chart_data.dart`
- `C:\Users\I551358\AppData\Local\Pub\Cache\hosted\pub.dev\fl_chart-0.68.0\lib\src\chart\bar_chart\bar_chart_data.dart`
- `C:\Users\I551358\AppData\Local\Pub\Cache\hosted\pub.dev\fl_chart-0.68.0\lib\src\chart\pie_chart\pie_chart_data.dart`
- `C:\Users\I551358\AppData\Local\Pub\Cache\hosted\pub.dev\fl_chart-0.68.0\lib\src\chart\base\axis_chart\axis_chart_data.dart`
- `C:\Users\I551358\AppData\Local\Pub\Cache\hosted\pub.dev\fl_chart-0.68.0\lib\src\chart\base\base_chart\base_chart_data.dart`
- `C:\Users\I551358\AppData\Local\Pub\Cache\hosted\pub.dev\fl_chart-0.68.0\CHANGELOG.md`
