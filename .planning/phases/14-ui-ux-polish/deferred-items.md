# Phase 14 - Deferred Items

## Pre-existing Test Failures (from Plan 14-01 glass widget conversions)

The uncommitted Plan 14-01 changes converted all screen files to use `buildGlassAppBar` and `buildGlassFAB` (from `liquid_glass_widgets.dart`), which require `ThemeProvider` in the widget tree. However, the corresponding screen test files and UAT tests were not updated to include `ThemeProvider` in their `wrapWithProviders` helpers.

**Affected test files (82 failures total):**
- `test/phase6_uat_test.dart` (3 failures) - GasScreen tests missing ThemeProvider
- `test/screens/analytics_screen_test.dart` (12 failures) - AnalyticsScreen missing ThemeProvider
- `test/screens/electricity_screen_test.dart` (5 failures) - ElectricityScreen missing ThemeProvider
- `test/screens/gas_screen_test.dart` (6 failures) - GasScreen missing ThemeProvider
- `test/screens/heating_screen_test.dart` (9 failures) - HeatingScreen missing ThemeProvider
- `test/screens/monthly_analytics_screen_test.dart` (7 failures) - MonthlyAnalyticsScreen missing ThemeProvider
- `test/screens/smart_plug_analytics_screen_test.dart` (14 failures) - SmartPlugAnalyticsScreen missing ThemeProvider
- `test/screens/water_screen_test.dart` (7 failures) - WaterScreen missing ThemeProvider
- `test/screens/yearly_analytics_screen_test.dart` (8 failures) - YearlyAnalyticsScreen missing ThemeProvider

**Fix needed:** Add `ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider())` to each test's `wrapWithProviders` helper, alongside initializing `SharedPreferences.setMockInitialValues({})` before `ThemeProvider().init()`.

**Also affected:** Some UAT tests check for `find.byType(FloatingActionButton)` which was replaced with `buildGlassFAB`. The `find.byType(FloatingActionButton)` will still work since `buildGlassFAB` wraps a `FloatingActionButton`.
