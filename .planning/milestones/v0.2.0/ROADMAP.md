# Milestone 2: Analytics & Visualization (v0.2.0) — Archived Roadmap

**Shipped**: 2026-03-07
**Phases**: 4 (Phase 8-11), 6 plans
**Tests**: 625 (312 new)
**Commits**: 17

---

## Key Accomplishments

1. **Interpolation engine** — Linear + step interpolation with configurable methods per meter type, monthly boundary generation, no-extrapolation edge case handling
2. **Gas kWh conversion** — Configurable m³→kWh conversion (default 10.3 kWh/m³) integrated into all gas analytics views
3. **Analytics hub & monthly analytics** — Central analytics screen with per-meter overview cards, line/bar charts via fl_chart, month navigation, custom date ranges, interpolation markers
4. **Yearly analytics & year-over-year comparison** — Yearly breakdown charts, previous-year overlay, percentage change display
5. **CSV export** — Export per-meter or all-meters data via system share sheet (csv + share_plus)
6. **Smart plug analytics** — Pie chart breakdown by plug/room, "Other" (untracked) consumption calculation, dual navigation entry points

---

## Phase 8: Interpolation Engine & Gas kWh Conversion
**Requirements**: FR-8, FR-9.1
**Dependencies**: Milestone 1 (all meter DAOs)
**Tests added**: 82 | **Cumulative**: 395

- [x] Create `InterpolationService` with linear interpolation for continuous meters (electricity, gas, water)
- [x] Add step function interpolation for non-continuous meters (heating)
- [x] Implement user-configurable interpolation method per meter type (setting stored locally)
- [x] Build monthly boundary interpolation (1st of month, 00:00) across all meter types
- [x] Add `isInterpolated` flag to interpolated values for display distinction
- [x] Handle edge cases: single reading, multi-month spans, sparse data, no extrapolation
- [x] Add gas kWh conversion service with configurable factor (default 10.3 kWh/m³)
- [x] Comprehensive unit tests for interpolation and gas conversion
- [x] Localize all new strings (EN + DE)

**New files**: InterpolationService, GasConversionService, ReadingConverters, InterpolationSettingsProvider, models
**Modified**: 4 DAOs (getReadingsForRange), main.dart, EN/DE ARB files

---

## Phase 9: Analytics Hub & Monthly Analytics
**Requirements**: FR-7.1, FR-7.3
**Dependencies**: Phase 8 (interpolation service)
**Tests added**: 102 | **Cumulative**: 497

- [x] Create `AnalyticsScreen` hub accessible from home screen (analytics icon/button)
- [x] Build cross-meter overview cards showing latest consumption summaries
- [x] Create `MonthlyAnalyticsScreen` with month navigation (forward/back)
- [x] Build line chart for daily consumption trends within selected month (fl_chart)
- [x] Build bar chart comparing consumption across recent months
- [x] Visually distinguish interpolated vs actual values (dashed/solid, markers)
- [x] Add custom date range picker for analytics filtering
- [x] Wire per-meter analytics buttons on each meter type screen
- [x] Add analytics provider(s) for data aggregation
- [x] Comprehensive widget and unit tests
- [x] Localize all new strings (EN + DE)

**New files**: AnalyticsProvider, AnalyticsScreen, MonthlyAnalyticsScreen, ConsumptionLineChart, MonthlyBarChart, ChartLegend, analytics_models, analytics_helpers
**Modified**: main.dart, 4 meter screens, EN/DE ARB files

---

## Phase 10: Yearly Analytics & CSV Export
**Requirements**: FR-7.2, FR-7.5
**Dependencies**: Phase 9 (analytics infrastructure, charts)
**Tests added**: 81 | **Cumulative**: 578

- [x] Create `YearlyAnalyticsScreen` with year navigation
- [x] Build bar chart of monthly breakdown within selected year
- [x] Build year-over-year comparison chart when multi-year data exists
- [x] Aggregate monthly interpolated values into yearly totals
- [x] Implement CSV export service (using `csv` package)
- [x] Add share functionality via `share_plus` for generated CSV files
- [x] Support per-meter and all-meters CSV export options
- [x] CSV columns: meter type, date, value, delta, interpolated flag
- [x] Add export button to analytics screens
- [x] Comprehensive unit and widget tests
- [x] Localize all new strings (EN + DE)

**New files**: YearlyAnalyticsScreen, YearComparisonChart, CsvExportService, ShareService
**Modified**: MonthlyAnalyticsScreen, AnalyticsScreen, AnalyticsProvider, main.dart, EN/DE ARB files

---

## Phase 11: Smart Plug Analytics
**Requirements**: FR-7.4, FR-9.2
**Dependencies**: Phase 9 (analytics infrastructure), Phase 4 DAO aggregation methods
**Plans**: 2
**Tests added**: 47 | **Cumulative**: 625

### Plan 11-01: Data models, SmartPlugAnalyticsProvider, ConsumptionPieChart widget
- [x] Data models: AnalyticsPeriod, PieSliceData, PlugConsumption, RoomConsumption, SmartPlugAnalyticsData, pieChartColors
- [x] SmartPlugAnalyticsProvider with multi-DAO orchestration (SmartPlugDao + ElectricityDao + RoomDao)
- [x] ConsumptionPieChart (fl_chart PieChart donut-style, percentage labels, empty state)
- [x] 31 tests (24 provider + 7 widget)

### Plan 11-02: SmartPlugAnalyticsScreen, navigation wiring, localization
- [x] SmartPlugAnalyticsScreen with SegmentedButton period selector, month/year navigation, two pie charts, summary card, breakdown lists
- [x] Navigation from analytics hub (card) and smart plugs screen (AppBar icon)
- [x] 14 localization keys (EN + DE)
- [x] Provider registration in main.dart
- [x] 16 widget tests

---

## Codebase Stats at v0.2.0

| Metric | v0.1.0 | v0.2.0 | Delta |
|--------|--------|--------|-------|
| Source files | 44 | 71 | +27 |
| Test files | 35 | 55 | +20 |
| Source LOC | 9,681 | 21,131 | +11,450 |
| Test LOC | 7,492 | 14,156 | +6,664 |
| Tests | 313 | 625 | +312 |

## Key Decisions

1. **Interpolation methods**: Linear (default for electricity/gas/water) + Step function (heating), configurable per meter type
2. **Chart types**: Line + Bar + Pie using fl_chart
3. **Analytics navigation**: Dedicated analytics hub from home + per-meter analytics buttons on each meter screen
4. **Time periods**: Monthly calendar + custom date range selection
5. **CSV export**: via csv + share_plus packages, system share sheet
6. **Carry-forward included**: Gas kWh conversion (FR-5.3) and smart plug aggregation UI (FR-3.5/3.6)
7. **Separate SmartPlugAnalyticsProvider**: Smart plug analytics uses its own provider (not AnalyticsProvider) since data is pre-aggregated
8. **Other consumption clamped**: max(0, totalElectricity - totalSmartPlug), null when no electricity data
9. **Smart plug analytics navigation**: Two entry points — analytics hub card and smart plugs AppBar icon
