---
name: flutter-yearly-analytics-csv
domain: analytics
tech: [flutter, dart, fl_chart, csv, share_plus, path_provider, provider, drift, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-07
validated_phases: [10-yearly-analytics-csv-export]
---

## Context
Use this pattern when building yearly analytics views with:
- Year-over-year comparison charts (current vs previous year)
- Year navigation (forward/back with clamping at current year)
- Aggregating monthly data into yearly totals with percentage change display
- CSV export from analytics views via system share sheet
- Extending an existing analytics provider with yearly state

## Pattern

### Tasks

| # | Task | File | Dependencies |
|---|------|------|--------------|
| 1 | Yearly data model + provider extension | `analytics_models.dart`, `analytics_provider.dart` | None |
| 2 | Year comparison chart widget | `lib/widgets/charts/year_comparison_chart.dart` (new) | Task 1 |
| 3 | CSV export service | `lib/services/csv_export_service.dart` (new) | Task 1 |
| 4 | Share service | `lib/services/share_service.dart` (new) | None |
| 5 | Yearly analytics screen | `lib/screens/yearly_analytics_screen.dart` (new) | Tasks 1-4 |
| 6 | Wire navigation + export buttons | Modify `monthly_analytics_screen.dart`, `analytics_screen.dart` | Task 5 |
| 7 | Add packages (csv, share_plus, path_provider) | `pubspec.yaml` | None |
| 8 | Localization (EN + DE) | `lib/l10n/app_*.arb` | None |
| 9 | Tests + analysis | Multiple test files | All |

### Wave Structure

```
Wave 1 (Parallel — no deps):
  ├── Task 7: Add packages (pubspec.yaml)
  ├── Task 8: Localization (EN + DE ARB files)
  └── Task 4: Share service (only needs share_plus + path_provider)

Wave 2 (Depends on Wave 1 packages):
  ├── Task 1: Yearly data model + provider extension
  └── Task 3: CSV export service (needs csv package)

Wave 3 (Depends on Task 1):
  └── Task 2: Year comparison chart widget

Wave 4 (Depends on Tasks 1, 2, 3, 4):
  └── Task 5: Yearly analytics screen

Wave 5 (Depends on Task 5):
  └── Task 6: Wire navigation + export buttons

Wave 6 (Depends on all):
  └── Task 9: Tests + flutter test + flutter analyze
```

### Key Components

#### YearlyAnalyticsData Model
```dart
class YearlyAnalyticsData {
  final MeterType meterType;
  final int year;
  final List<PeriodConsumption> monthlyBreakdown; // 12 months (bar chart)
  final List<PeriodConsumption>? previousYearBreakdown; // comparison
  final double? totalConsumption;
  final double? previousYearTotal;
  final String unit;
}
```

#### Provider Extension (Yearly State Added to Existing Provider)
```dart
// New fields added to existing AnalyticsProvider
int _selectedYear = DateTime.now().year;
YearlyAnalyticsData? _yearlyData;

void setSelectedYear(int year) {
  _selectedYear = year;
  notifyListeners();
  _loadYearlyData();
}

void navigateYear(int delta) {
  _selectedYear += delta;
  notifyListeners();
  _loadYearlyData();
}

Future<void> _loadYearlyData() async {
  // Current year: Jan 1 to Jan 1 of next year
  final yearStart = DateTime(_selectedYear, 1, 1);
  final yearEnd = DateTime(_selectedYear + 1, 1, 1);

  // Reuse existing _getReadingsPerMeter() and _aggregateMonthlyConsumption()
  final readingsPerMeter = await _getReadingsPerMeter(type, yearStart, yearEnd);
  var monthlyBreakdown = _aggregateMonthlyConsumption(readingsPerMeter, yearStart, yearEnd, method);

  // Previous year for comparison
  final prevReadings = await _getReadingsPerMeter(type, prevStart, prevEnd);
  // ... build YearlyAnalyticsData
}
```

#### YearComparisonChart (Two-Line Overlay)
```dart
// Current year: solid line, full opacity, dots with white stroke
LineChartBarData(
  spots: currentSpots,
  color: primaryColor,
  barWidth: 2.5,
  isCurved: true,
  curveSmoothness: 0.25,
  preventCurveOverShooting: true,
  dotData: FlDotData(show: true, getDotPainter: ...),
  belowBarData: BarAreaData(show: true, color: primaryColor.withValues(alpha: 0.1)),
),

// Previous year: dashed line, 50% opacity, smaller dots
LineChartBarData(
  spots: previousSpots,
  color: primaryColor.withValues(alpha: 0.5),
  barWidth: 2.0,
  dashArray: [8, 4],
  dotData: FlDotData(show: true, getDotPainter: ...),
),
```

#### Stateless CSV Export Service
```dart
class CsvExportService {
  const CsvExportService();
  static const _converter = ListToCsvConverter();

  String exportMonthlyData(MonthlyAnalyticsData data) { ... }
  String exportYearlyData(YearlyAnalyticsData data) { ... }
  String exportAllMeters({required int year, required Map<MeterType, List<PeriodConsumption>> dataByType}) { ... }
}
```

#### Share Service (Thin Platform Wrapper)
```dart
class ShareService {
  Future<void> shareCsvFile({required String csvContent, required String filename}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')]);
  }
}
```

#### Year Navigation with Current Year Clamping
```dart
// Disable forward arrow if at current year
final isCurrentYear = year == DateTime.now().year;
IconButton(
  icon: const Icon(Icons.chevron_right),
  onPressed: isCurrentYear ? null : onNext,
)
```

#### Percentage Change Display with Division-by-Zero Guard
```dart
if (totalConsumption != null && previousYearTotal != null && previousYearTotal! > 0) {
  final change = ((totalConsumption! - previousYearTotal!) / previousYearTotal!) * 100;
  final prefix = change >= 0 ? '+' : '';
  Text(l10n.changeFromLastYear('$prefix${change.toStringAsFixed(1)}'),
    style: TextStyle(color: change > 0 ? Colors.red : Colors.green));
}
```

#### Export FAB Conditionally Visible
```dart
floatingActionButton: data != null && data.monthlyBreakdown.isNotEmpty
    ? FloatingActionButton(
        onPressed: () => _exportCsv(context, data),
        tooltip: l10n.exportCsv,
        child: const Icon(Icons.file_download),
      )
    : null,
```

### Key Decisions

1. **Extend existing provider** — Added yearly state (`_selectedYear`, `_yearlyData`) alongside monthly state in same `AnalyticsProvider`, keeping single-provider orchestration pattern.
2. **Reuse MonthlyBarChart for 12-month breakdown** — The widget accepts any `List<PeriodConsumption>`, works with 6 or 12 bars without changes.
3. **New YearComparisonChart** — Two overlaid lines (solid current + dashed previous) is structurally different from the existing ConsumptionLineChart (which splits actual/interpolated). Cleaner as separate widget.
4. **CsvExportService as const stateless class** — Pure functions: data model in → CSV string out. No DI needed.
5. **ShareService as thin platform wrapper** — Isolates `share_plus` + `path_provider` behind simple interface for testability.
6. **Conditional comparison section** — Year-over-year chart only shown when `previousYearBreakdown != null && isNotEmpty`. No empty chart shown.
7. **Export FAB on analytics screens** — Consistent placement (bottom-right FAB) on monthly and yearly. Hub gets AppBar action for "export all".
8. **CSV includes interpolation flag** — "Yes"/"No" column lets users know which values are computed.
9. **Percentage change with color coding** — Red for increase, green for decrease (energy conservation context).
10. **Every-other-month labels** — When 12 data points on x-axis, show every 2nd month label to avoid crowding: `if (currentYear.length > 6 && index % 2 != 0) return SizedBox.shrink()`.

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| Year with no readings returns empty list | Check `monthlyBreakdown.isEmpty` → show empty state, don't render charts |
| Previous year query slow for many meters | Load previous year after current year succeeds; show comparison after delay |
| Gas conversion must apply to yearly data too | Call `GasConversionService.toKwhConsumptions()` on yearly breakdown, same as monthly |
| CSV commas in values break parsing | Use `csv` package `ListToCsvConverter` which handles quoting automatically |
| share_plus needs file on disk | Write to `getTemporaryDirectory()` first, share the file, don't cleanup immediately |
| Year navigation beyond data range shows empty | Allow navigation but show "No data" message — don't restrict year range |
| Percentage change division by zero | Guard `previousYearTotal == 0` or `null` → don't show percentage |
| MonthlyBarChart expects 6 months but yearly sends 12 | Widget already uses `periods.length` dynamically — works with any count |
| fl_chart LineChart with 2 lines needs distinct styling | `dashArray: [8, 4]` for previous year, solid for current year |
| 12-month x-axis labels crowded | Show every-other-month label: `if (length > 6 && index % 2 != 0) skip` |
| Export button shown when no data | Conditionally render FAB: `data != null && data.monthlyBreakdown.isNotEmpty` |
| context.mounted check after async | Always check `if (context.mounted)` before showing SnackBar after `await` |

### Test Coverage

| Component | Test Count | Coverage Focus |
|-----------|------------|----------------|
| AnalyticsProvider (yearly) | 36 | Yearly state mgmt, year navigation, multi-meter aggregation, gas conversion, empty data, previous year |
| CsvExportService | 27 | Monthly/yearly/all-meters export, empty data, interpolated flags, previous year column |
| YearComparisonChart | 8 | Single year, two years, empty, styling |
| YearlyAnalyticsScreen | 10 | Render, navigation, export FAB, loading, empty state, comparison visibility |
| **Total** | **~81** | |

### Localization Keys

```json
{
  "yearlyAnalytics": "Yearly Analytics",
  "monthlyBreakdown": "Monthly Breakdown",
  "yearOverYear": "Year-over-Year",
  "previousYear": "Previous Year",
  "nextYear": "Next Year",
  "currentYear": "Current Year",
  "totalForYear": "Total for {year}",
  "changeFromLastYear": "{change}% vs last year",
  "exportCsv": "Export CSV",
  "exportAll": "Export All Meters",
  "exportSuccess": "Export ready to share",
  "noYearlyData": "No data for {year}"
}
```

### Adaptation Notes
- CSV export pattern generalizes: `CsvExportService` takes any data model, returns CSV string. Add new `export*()` methods for new data types.
- ShareService is reusable across any file type — change mimeType parameter.
- Year comparison chart works for any two time series — rename to `TwoSeriesComparisonChart` for general use.
- Provider extension pattern: add new state + loader method alongside existing state in same provider, reuse existing data-fetching infrastructure.
- Percentage change pattern: `((current - previous) / previous) * 100` with zero/null guard, red/green coloring.
