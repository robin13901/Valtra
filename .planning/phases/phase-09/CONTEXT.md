# Phase 9 Context — Analytics Hub & Monthly Analytics

## Phase Goal
Build the analytics hub screen and monthly analytics screen with interactive charts, enabling users to view consumption trends across all meter types with visual distinction between actual and interpolated values.

## Requirements Covered
- **FR-7.1**: Monthly Analytics (FR-7.1.1 through FR-7.1.6)
- **FR-7.3**: Analytics Navigation (FR-7.3.1 through FR-7.3.4)

## UAC Coverage
- **UAC-M2-1**: Monthly consumption view (given readings → see summary + line chart)
- **UAC-M2-2**: Interpolated values visually marked
- **UAC-M2-6**: Analytics hub accessible from home, overview of all meter types
- **UAC-M2-7**: Custom date range filtering

## Dependencies (Phase 8 — COMPLETED)
- `InterpolationService` — `getMonthlyBoundaries()`, `getMonthlyConsumption()` methods
- `GasConversionService` — m³ → kWh conversion
- `InterpolationSettingsProvider` — per-meter-type method preference + gas factor
- All DAOs have `getReadingsForRange(id, start, end)` methods
- Reading converters: `fromElectricityReadings`, `fromGasReadings`, `fromWaterReadings`, `fromHeatingReadings`
- Models: `ReadingPoint`, `TimestampedValue`, `PeriodConsumption`, `InterpolationMethod`

## Existing Patterns (MUST follow)
- **Screens**: `StatelessWidget` with `context.watch<Provider>()` for reactive updates
- **Providers**: `ChangeNotifier` with stream subscriptions, registered in `main.dart` MultiProvider
- **Navigation**: `Navigator.of(context).push(MaterialPageRoute(...))`
- **Localization**: `final l10n = AppLocalizations.of(context)!;`
- **Colors**: `AppColors.electricityColor`, `gasColor`, `waterColor`, `heatingColor`, `ultraViolet`
- **Home screen**: Column of category chips with icons — add analytics chip/button here
- **Provider init**: Created in `main()`, passed to ValtraApp, `.value()` in MultiProvider

## Available Libraries (already in pubspec)
- `fl_chart: ^0.68.0` — Line, Bar, Pie charts
- `provider: ^6.1.2` — State management
- `intl: ^0.20.2` — Date formatting
- `shared_preferences: ^2.2.3` — Settings

## fl_chart API Key Points (from research)
- Line chart: `LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: [FlSpot(...)])]))`
- Bar chart: `BarChart(BarChartData(barGroups: [BarChartGroupData(x: int, barRods: [...])]))`
- **BarChartGroupData.x is int, NOT double** — use sequential indices, map to labels
- `FlSpot.nullSpot` for line gaps, `dashArray: [8, 4]` for dashed lines
- Two-line approach for actual vs interpolated (solid vs dashed)
- Date axis: use `millisecondsSinceEpoch.toDouble()` for FlSpot x-values
- No built-in legend — must create custom widget
- Animation: automatic via `ImplicitlyAnimatedWidget`, set `duration: Duration(milliseconds: 300)`
- `clipData: FlClipData.all()` for date-range bounds
- Explicit `minX/maxX/minY/maxY` for performance

## Meter Type Scoping
- **Electricity, Gas**: Household-scoped (`householdId`)
- **Water, Heating**: Meter-scoped (multiple meters per household, need aggregation)
- Smart Plug: Phase 11 (not in scope here)

## Test Patterns
- Widget tests: `tester.pumpWidget(MaterialApp(home: WidgetUnderTest()))` with providers via `MultiProvider`
- Use `tester.runAsync()` for Drift stream tests
- Provider tests: `SharedPreferences.setMockInitialValues({})` for mock prefs
- Use `mocktail` for mocking
- Target 100% statement coverage on all new logic

## User Preferences (from CLAUDE.md)
- Ralph Loop: Implement → Test → Fix → Commit
- Flutter workflow: tests first, `flutter test`, `flutter analyze`, zero issues
- Comprehensive tests with 100% statement coverage aim
