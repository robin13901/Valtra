# Phase 10 Plan — Yearly Analytics & CSV Export

**Phase**: 10 of 14
**Milestone**: 2 — Analytics & Visualization (v0.2.0)
**Requirements**: FR-7.2 (Yearly Analytics), FR-7.5 (CSV Export)
**Goal**: Build the yearly analytics screen with year navigation, monthly breakdown bar chart, year-over-year comparison chart, and implement CSV export service with system share sheet integration.

---

## Architecture Overview

```
AnalyticsScreen (hub)
  ├── OverviewCard (electricity) ──► MonthlyAnalyticsScreen ──► YearlyAnalyticsScreen
  ├── OverviewCard (gas)         ──► MonthlyAnalyticsScreen ──► YearlyAnalyticsScreen
  ├── OverviewCard (water)       ──► MonthlyAnalyticsScreen ──► YearlyAnalyticsScreen
  └── OverviewCard (heating)     ──► MonthlyAnalyticsScreen ──► YearlyAnalyticsScreen

MonthlyAnalyticsScreen
  └── AppBar "Yearly" action ──► YearlyAnalyticsScreen(meterType: ...)

YearlyAnalyticsScreen
  ├── Year navigation header (← year →)
  ├── Yearly total consumption summary card
  ├── Bar chart: 12 months of selected year (MonthlyBarChart reuse)
  ├── Year-over-year comparison chart (YearComparisonChart — new)
  ├── ChartLegend (current year vs previous year)
  └── Export FAB ──► CsvExportService ──► share_plus

AnalyticsProvider (extended)
  ├── existing: selectedMonth, selectedMeterType, customRange, monthlyData, overviewSummaries
  ├── NEW: selectedYear: int
  ├── NEW: yearlyData: YearlyAnalyticsData?
  ├── NEW: navigateYear(int delta)
  ├── NEW: setSelectedYear(int year)
  └── NEW: _loadYearlyData()

CsvExportService (new — stateless)
  ├── exportMonthlyData(MonthlyAnalyticsData) → String (CSV)
  ├── exportYearlyData(YearlyAnalyticsData) → String (CSV)
  └── exportAllMeters(Map<MeterType, YearlyAnalyticsData>) → String (CSV)

ShareService (new — thin wrapper)
  └── shareFile(String csvContent, String filename) → Future<void>
      (writes temp file → share_plus → cleanup)
```

---

## Data Models (New/Extended)

### `YearlyAnalyticsData` (new model in `analytics_models.dart`)
```dart
class YearlyAnalyticsData {
  final MeterType meterType;
  final int year;
  final List<PeriodConsumption> monthlyBreakdown; // 12 months (bar chart)
  final List<PeriodConsumption>? previousYearBreakdown; // 12 months (comparison)
  final double? totalConsumption; // sum of monthlyBreakdown
  final double? previousYearTotal; // sum of previousYearBreakdown
  final String unit;
}
```

### Year-over-year comparison data
- Reuse `PeriodConsumption` — already has `periodStart`, `consumption`, interpolation flags
- Current year: 12 `PeriodConsumption` entries (Jan-Dec)
- Previous year: 12 `PeriodConsumption` entries (Jan-Dec), null if no data

---

## Task Breakdown

### Task 1: Yearly data model & provider extension
**File**: `lib/services/analytics/analytics_models.dart`, `lib/providers/analytics_provider.dart`
**Dependencies**: None
**Effort**: Medium

Add `YearlyAnalyticsData` model to analytics_models.dart.

Extend `AnalyticsProvider` with:
- `int _selectedYear` field (default: current year)
- `YearlyAnalyticsData? _yearlyData` field
- `int get selectedYear`, `YearlyAnalyticsData? get yearlyData` getters
- `void setSelectedYear(int year)` — sets year, triggers `_loadYearlyData()`
- `void navigateYear(int delta)` — adjusts year by delta, triggers `_loadYearlyData()`
- `Future<void> _loadYearlyData()` — fetches 12-month data for current + previous year:
  1. Call `_getReadingsPerMeter(type, Jan 1 of year, Jan 1 of year+1)` for current year
  2. Call `_aggregateMonthlyConsumption()` for 12 monthly bars
  3. Repeat for previous year (year-1) — set to null if no readings exist
  4. Apply gas conversion if meter type is gas
  5. Compute totals (sum of consumption values)
  6. Build `YearlyAnalyticsData` and `notifyListeners()`

**Acceptance**: Provider loads yearly data, navigates years, handles gas conversion.

### Task 2: Year comparison chart widget
**File**: `lib/widgets/charts/year_comparison_chart.dart` (new)
**Dependencies**: Task 1 (needs `PeriodConsumption`)
**Effort**: Medium

Create `YearComparisonChart` widget using fl_chart `LineChart`:
- Constructor: `required List<PeriodConsumption> currentYear`, `List<PeriodConsumption>? previousYear`, `required Color primaryColor`, `required String unit`
- X-axis: 12 points (Jan-Dec), sequential int mapped to month abbreviations
- Line 1 (solid, full opacity): current year consumption values
- Line 2 (dashed, 50% opacity): previous year consumption values (if non-null)
- Dots at each data point; tooltips show month + value
- Handle empty/null previous year gracefully (show only current year line)
- Explicit `maxY = max(allValues) * 1.15`, `minY = 0`

**Acceptance**: Chart renders current year line, optionally overlays previous year as dashed line.

### Task 3: CSV export service
**File**: `lib/services/csv_export_service.dart` (new)
**Dependencies**: Task 1 (needs `YearlyAnalyticsData`)
**Effort**: Medium

Create `CsvExportService` (stateless, no DI needed):

```dart
class CsvExportService {
  /// Export monthly analytics data to CSV string
  String exportMonthlyData(MonthlyAnalyticsData data) {
    // Headers: Date, Value, Consumption, Unit, Interpolated
    // Rows from data.dailyValues (line chart points) + data.recentMonths (bar chart periods)
  }

  /// Export yearly analytics data to CSV string
  String exportYearlyData(YearlyAnalyticsData data) {
    // Headers: Month, Consumption, Unit, Interpolated
    // 12 rows from monthlyBreakdown
    // If previousYear exists: add "Previous Year" column
  }

  /// Export all meter types for a year
  String exportAllMeters({
    required int year,
    required Map<MeterType, List<PeriodConsumption>> dataByType,
  }) {
    // Headers: Meter Type, Month, Consumption, Unit, Interpolated
    // Rows for each meter type's 12 months
  }
}
```

Use `csv` package `ListToCsvConverter` for proper CSV encoding (handles commas in values, quoting).

**Acceptance**: Service produces valid CSV strings from analytics data models.

### Task 4: Share service
**File**: `lib/services/share_service.dart` (new)
**Dependencies**: None
**Effort**: Small

Create `ShareService` (thin wrapper around share_plus + path_provider):

```dart
class ShareService {
  /// Write CSV content to temp file and share via system share sheet
  Future<void> shareCsvFile({
    required String csvContent,
    required String filename, // e.g., "valtra_electricity_2026.csv"
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvContent);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
    );
  }
}
```

**Acceptance**: CSV content written to temp file and share sheet opens.

### Task 5: Yearly analytics screen
**File**: `lib/screens/yearly_analytics_screen.dart` (new)
**Dependencies**: Task 1 (provider), Task 2 (chart)
**Effort**: Large

Build `YearlyAnalyticsScreen`:
- **AppBar**: Title "{Meter Type} Yearly" with export button action
- **Year navigation header**: ← {year} → (disable forward if current year)
- **Summary card**: "Total: {value} {unit}" for selected year, with comparison to previous year ("+12%" or "-5%")
- **Bar chart section**: "Monthly Breakdown" label + `MonthlyBarChart` with 12 periods
- **Comparison section**: "Year-over-Year" label + `YearComparisonChart` (hide section if no previous year data)
- **Chart legend**: Current year (solid) + Previous year (dashed) — only if comparison data exists
- **Export FAB**: Floating action button that triggers CSV export → share
- **Empty state**: Show message if no data for selected year
- **Loading state**: `CircularProgressIndicator` while data loads

Provider interaction:
- On init: `provider.setSelectedYear(DateTime.now().year)` and `provider.setSelectedMeterType(meterType)`
- Watch `provider.yearlyData` and `provider.isLoading`
- Navigation arrows call `provider.navigateYear(±1)`

**Acceptance**: Screen shows yearly bar chart, comparison chart, navigation, export button.

### Task 6: Wire navigation & export buttons
**File**: Modify `lib/screens/monthly_analytics_screen.dart`, `lib/screens/analytics_screen.dart`
**Dependencies**: Task 5 (yearly screen exists)
**Effort**: Small

Changes:
1. **MonthlyAnalyticsScreen AppBar**: Add "Yearly" icon button that navigates to `YearlyAnalyticsScreen(meterType: currentType)`
2. **MonthlyAnalyticsScreen**: Add export FAB for monthly CSV export (uses `CsvExportService.exportMonthlyData()` + `ShareService`)
3. **AnalyticsScreen (hub)**: Add "Export All" button in AppBar that exports all meter types for current year

**Acceptance**: Users can navigate from monthly → yearly, export from any analytics screen.

### Task 7: Add packages to pubspec.yaml
**File**: `pubspec.yaml`
**Dependencies**: None
**Effort**: Small

Add:
```yaml
dependencies:
  csv: ^6.0.0
  share_plus: ^10.0.0
  path_provider: ^2.1.0
```

Run `flutter pub get`.

**Acceptance**: Dependencies resolve, no conflicts.

### Task 8: Localization (EN + DE)
**File**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Dependencies**: None
**Effort**: Small

New keys:

| Key | EN | DE |
|-----|----|----|
| `yearlyAnalytics` | `"Yearly Analytics"` | `"Jahresanalyse"` |
| `monthlyBreakdown` | `"Monthly Breakdown"` | `"Monatsaufschlüsselung"` |
| `yearOverYear` | `"Year-over-Year"` | `"Jahresvergleich"` |
| `previousYear` | `"Previous Year"` | `"Vorheriges Jahr"` |
| `nextYear` | `"Next Year"` | `"Nächstes Jahr"` |
| `currentYear` | `"Current Year"` | `"Aktuelles Jahr"` |
| `totalForYear` | `"Total for {year}"` | `"Gesamt für {year}"` |
| `changeFromLastYear` | `"{change}% vs last year"` | `"{change}% ggü. Vorjahr"` |
| `exportCsv` | `"Export CSV"` | `"CSV exportieren"` |
| `exportAll` | `"Export All Meters"` | `"Alle Zähler exportieren"` |
| `exportSuccess` | `"Export ready to share"` | `"Export bereit zum Teilen"` |
| `noYearlyData` | `"No data for {year}"` | `"Keine Daten für {year}"` |

**Acceptance**: All new strings in both EN and DE ARB files.

### Task 9: Comprehensive tests
**File**: Multiple test files (new)
**Dependencies**: Tasks 1-8
**Effort**: Large

Test files and focus:

| Test File | Focus | Est. Tests |
|-----------|-------|------------|
| `test/providers/analytics_provider_yearly_test.dart` | Yearly state mgmt, year navigation, multi-meter aggregation, gas conversion, empty data | ~25 |
| `test/services/csv_export_service_test.dart` | Monthly export, yearly export, all-meters export, edge cases (empty, single month, interpolated flags) | ~15 |
| `test/services/share_service_test.dart` | File creation, share invocation, filename generation | ~5 |
| `test/widgets/charts/year_comparison_chart_test.dart` | Single year, two years, empty, max scale | ~8 |
| `test/screens/yearly_analytics_screen_test.dart` | Render, navigation, export button, loading, empty state, comparison visibility | ~10 |
| **Total** | | **~63** |

Mock pattern: Follow Phase 9 pattern — mock all DAOs + services, use `mocktail`, register fallback values.

**Acceptance**: All tests pass, `flutter test` green, `flutter analyze` clean.

---

## Wave Execution Plan

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

---

## Key Decisions

1. **Extend AnalyticsProvider** — Add yearly state alongside monthly state (same provider, not new one). This keeps the single-provider orchestration pattern from Phase 9.
2. **Reuse MonthlyBarChart for yearly breakdown** — The 12-month bar chart is structurally identical to the 6-month bar chart, just with more bars. Reuse the widget directly.
3. **New YearComparisonChart** — Year-over-year needs two overlaid lines with different styling, which is distinct from the existing ConsumptionLineChart (which splits actual/interpolated). A new widget is cleaner.
4. **CsvExportService as stateless class** — Pure functions that transform data models → CSV strings. No DI needed, easy to test.
5. **ShareService as thin wrapper** — Isolates platform dependency (share_plus + path_provider) behind a simple interface for testability.
6. **Year-over-year only shows when data exists** — If previous year has zero readings, hide the comparison section entirely rather than showing an empty chart.
7. **Export FAB on analytics screens** — Consistent placement (bottom-right FAB) on both monthly and yearly screens. Hub gets AppBar action for "export all".
8. **CSV columns include interpolation flag** — Users need to know which values are computed vs actual in exported data.

## Common Pitfalls

| Issue | Solution |
|-------|----------|
| Year with no readings returns empty list | Check `monthlyBreakdown.isEmpty` → show empty state, don't render charts |
| Previous year query slow for many meters | Load previous year only if current year succeeds, show comparison after delay |
| Gas conversion must apply to yearly data too | Call `GasConversionService.toKwhConsumptions()` on yearly breakdown, same as monthly |
| CSV commas in values break parsing | Use `csv` package `ListToCsvConverter` which handles quoting automatically |
| share_plus needs file on disk | Write to `getTemporaryDirectory()` first, share the file, don't clean up immediately |
| Year navigation beyond data range shows empty | Allow navigation but show "No data" message — don't restrict year range |
| Percentage change calculation: division by zero | Guard `previousYearTotal == 0` or `null` → don't show percentage |
| MonthlyBarChart expects 6 months but yearly sends 12 | MonthlyBarChart already uses `periods.length` dynamically — works with any count |
| fl_chart LineChart with 2 lines needs distinct styling | Use `dashArray: [8, 4]` for previous year, solid for current year |

## Requirements Traceability

| Requirement | Task(s) | Verification |
|-------------|---------|--------------|
| FR-7.2.1 (Yearly totals) | 1, 5 | Summary card shows total |
| FR-7.2.2 (Year navigation) | 1, 5 | ← year → arrows work |
| FR-7.2.3 (Monthly breakdown bar chart) | 1, 5 | 12-bar chart renders |
| FR-7.2.4 (Year-over-year comparison) | 1, 2, 5 | Two-line comparison chart |
| FR-7.2.5 (Aggregate interpolated → yearly) | 1 | Provider sums monthly breakdown |
| FR-7.5.1 (CSV export) | 3 | CsvExportService produces valid CSV |
| FR-7.5.2 (CSV columns) | 3 | Meter type, date, value, delta, interpolated |
| FR-7.5.3 (Share sheet) | 4, 6 | share_plus opens share dialog |
| FR-7.5.4 (Per-meter + all-meters export) | 3, 6 | Both export options available |
