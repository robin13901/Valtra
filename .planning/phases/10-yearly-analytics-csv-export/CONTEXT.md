# Phase 10 Context — Yearly Analytics & CSV Export

## Phase Goal
Build the yearly analytics screen with year navigation, monthly breakdown bar chart, year-over-year comparison, and implement CSV export with system share sheet integration for all analytics views.

## Requirements Covered
- **FR-7.2**: Yearly Analytics (FR-7.2.1 through FR-7.2.5)
- **FR-7.5**: CSV Export (FR-7.5.1 through FR-7.5.4)

## UAC Coverage
- **UAC-M2-3**: Year-over-year comparison (given multi-year data → side-by-side chart)
- **UAC-M2-5**: CSV export (tap export button → share sheet with CSV file)

## Dependencies (Phase 9 — COMPLETED)
- `AnalyticsProvider` — orchestrates all meter data, has `_getReadingsPerMeter()`, `_aggregateMonthlyConsumption()`, `_aggregateDailyBoundaries()` methods
- `MonthlyAnalyticsData` — data model for monthly screen (extend for yearly)
- `InterpolationService` — `getMonthlyConsumption()`, `getMonthlyBoundaries()` for 12-month yearly bars
- `GasConversionService` — m³ → kWh conversion (apply to yearly data too)
- `InterpolationSettingsProvider` — per-meter-type method + gas factor
- `MonthlyBarChart` widget — reusable for yearly monthly-breakdown bars
- `ConsumptionLineChart` widget — reusable for year-over-year overlay
- `ChartLegend` widget — reusable for legend display
- `MeterType` enum, `MeterTypeSummary`, `ChartDataPoint`, `PeriodConsumption` models
- `colorForMeterType()`, `iconForMeterType()`, `unitForMeterType()` helpers
- Reading converters: `fromElectricityReadings`, `fromGasReadings`, etc.
- All DAOs: `getReadingsForRange(id, start, end)` methods

## Existing Patterns (MUST follow)
- **Screens**: `StatelessWidget` with `context.watch<Provider>()` for reactive updates
- **Providers**: `ChangeNotifier` with constructor DI, registered in `main.dart` MultiProvider
- **Navigation**: `Navigator.of(context).push(MaterialPageRoute(...))`
- **Localization**: `final l10n = AppLocalizations.of(context)!;`
- **Colors**: `AppColors.electricityColor`, `gasColor`, `waterColor`, `heatingColor`, `ultraViolet`
- **Charts**: fl_chart with sequential int x-axis, explicit maxY, custom tooltips
- **Gas conversion**: Applied at provider layer post-aggregation
- **Multi-meter aggregation**: Interpolate per-meter independently, then sum

## New Packages Required
- `csv: ^6.0.0` — Generate CSV strings from list-of-lists
- `share_plus: ^10.0.0` — Share files via system share sheet (uses XFile)
- `path_provider: ^2.1.0` — Get temp directory for CSV file storage

## Package API Notes

### csv package
```dart
import 'package:csv/csv.dart';
// Generate CSV from list of lists
final csvString = const ListToCsvConverter().convert([
  ['Header1', 'Header2', 'Header3'],  // header row
  ['value1', 'value2', 'value3'],       // data rows
]);
```

### share_plus package
```dart
import 'package:share_plus/share_plus.dart';
// Share a file
await Share.shareXFiles(
  [XFile(filePath, mimeType: 'text/csv')],
  subject: 'Export Subject',
);
```

### path_provider
```dart
import 'package:path_provider/path_provider.dart';
final dir = await getTemporaryDirectory();
final file = File('${dir.path}/export.csv');
await file.writeAsString(csvString);
```

## AnalyticsProvider Extension Points
- Add `_selectedYear` state field (defaults to current year)
- Add `yearlyData` getter returning `YearlyAnalyticsData`
- Add `setSelectedYear(int year)`, `navigateYear(int delta)` methods
- Add `_loadYearlyData()` private method (12-month bars + year-over-year)
- Reuse `_getReadingsPerMeter()` and `_aggregateMonthlyConsumption()` with full-year range

## Chart Reuse Strategy
- **Monthly breakdown bar chart**: Reuse `MonthlyBarChart` with 12 periods (Jan-Dec)
- **Year-over-year comparison**: New `YearComparisonChart` using fl_chart `LineChart` with 2 lines (current year + previous year), 12 data points each
- **ChartLegend**: Reuse for current year vs previous year labels

## CSV Export Strategy
- `CsvExportService` — stateless service, receives data, returns CSV string
- CSV columns: Meter Type, Date, Value, Consumption Delta, Unit, Interpolated
- Per-meter export: current view data only
- All-meters export: all 4 meter types combined
- Trigger: Export FAB/button on analytics screens → generate CSV → write temp file → share_plus

## Test Patterns
- Widget tests: `tester.pumpWidget(MaterialApp(home: WidgetUnderTest()))` with providers
- Use `mocktail` for mocking
- Provider tests: mock DAOs + services, verify state transitions
- CsvExportService: pure function tests (input data → expected CSV string)
- Share integration: mock `share_plus` in tests, verify file path/content
- Target 100% statement coverage on all new logic
