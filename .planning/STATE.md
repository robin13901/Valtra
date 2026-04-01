# Valtra - Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-01)

**Core value:** Users can track and analyze utility consumption across multiple households with an intuitive, polished interface
**Current focus:** v0.6.0 Analytics Redesign -- Phase 32 complete (DEBT-01 resolved), milestone ready for verification

## Current Position

Phase: 32 of 32 (Heating Analytics Cleanup)
Plan: 2 of 2 in current phase
Status: Phase complete -- ALL v0.6.0 phases complete
Last activity: 2026-04-01 -- Completed 32-02-PLAN.md (deprecated widget removal + dead code deletion)

Progress: ███████████████░░░░░░░░░░ 100% (v0.6.0) [15/15 plans]

## Performance Metrics

**Velocity:**
- Total plans completed: 15 (v0.6.0)
- Average duration: ~14 min
- Total execution time: ~196 min

*Updated after each plan completion*

## Completed Milestones
- **v0.1.0**: Core Foundation -- 7 phases, 313 tests
- **v0.2.0**: Analytics & Visualization -- 4 phases, 625 tests
- **v0.3.0**: Polish & Enhancement -- 5 phases, 1017 tests
- **v0.4.0**: UX Overhaul -- 6 phases, 1077 tests
- **v0.5.0**: Visual & UX Polish -- 4 phases, 1103 tests

## Completed Phases (v0.6.0)
- **Phase 27**: Shared Chart Infrastructure -- 4 plans, 1154 tests, verified 5/5
- **Phase 28**: Home & Nav Polish -- 3 plans, 1213 tests, verified 4/4
- **Phase 29**: Electricity Analytics -- 2 plans, 1221 tests, verified 3/3
- **Phase 30**: Water & Gas Analytics -- 2 plans, 1226 tests, verified 10/10
- **Phase 31**: Smart Plug Overhaul -- 2 plans, 1229 tests, verified 5/5
- **Phase 32**: Heating Analytics Cleanup -- 2 plans, 1213 tests (16 deleted dead-code tests)

## Accumulated Context

### Decisions
- Heating meters are unitless (proportional counters), no cost profiles, percentage distribution only
- German currency format always, regardless of app language
- LiquidGlass UI using real liquid_glass_renderer
- ChartAxisStyle.hiddenTitles: const to avoid repeated instantiation in chart renders
- MonthSelector.locale defaults 'de' matching existing chart widget convention
- MonthlySummaryCard: increase=error color, decrease=green (utility consumption semantics: more=bad)
- axisNameWidget tests replaced with sideTitles.showTitles when using ChartAxisStyle.leftTitles (unit is embedded per label)
- Gradient fill pattern: LinearGradient 0.3→0.0 alpha for current year line belowBarData (YCMP-02)
- HouseholdChartData.color is caller-assigned (provider assigns pieChartColors[index]); widget is color-agnostic
- Unified interpolated/extrapolated flag: any period with startInterpolated|endInterpolated|isExtrapolated renders as dashed
- MonthlyBarChart scroll: visibleBars=12 threshold; Row(fixed-Y-axis BarChart + Expanded ScrollView) for AXIS-03
- MonthlyBarChart alpha scheme: past=0.85, future/extrapolated=0.3, highlighted=1.0 (BAR-03)
- LiquidGlassBottomNav left FAB removed (unused by all screens): API simplified to rightIcon/onRightTap/rightVisibleForIndices only
- Inline FAB in nav pill: right FAB rendered as fixed-width Container inside pill Row, not external LiquidGlassLayer circle
- Inline FAB uses primary.withValues(alpha: 0.15/0.20 dark) tinted circle for visual blend with glass pill
- Frosted glass household card: BackdropFilter(sigmaX/Y=16) + ClipRRect, no LinearGradient (HOME-01)
- Carousel reverse-sync uses addPostFrameCallback to avoid animating during active build cycle
- Inline constants (BorderRadius.circular(20), padding 20) used; Radii/Spacing/Shadows design tokens not yet defined
- HouseholdDao injected into AnalyticsProvider constructor; householdComparisonData getter populated during _loadYearlyData (29-01)
- MonthlySummaryCard smartPlugCoverage line requires BOTH smartPlugKwh AND smartPlugPercent non-null (29-01)
- Electricity Analyse tab: MonthSelector syncs both AnalyticsProvider + SmartPlugAnalyticsProvider; setSelectedYear only on year boundary crossing (29-02)
- previousMonthTotal extracted from monthlyData.recentMonths inline; no new AnalyticsProvider API needed (29-02)
- SmartPlugAnalyticsProvider must be in provider tree for ElectricityScreen; affects all test files using ElectricityScreen (29-02)
- Reference composition pattern: MonthSelector → MonthlySummaryCard → MonthlyBarChart → YearComparisonChart → HouseholdComparisonChart (29-02)
- Water/Gas/Heating Analyse tabs: NO SmartPlugAnalyticsProvider; only AnalyticsProvider synced in onMonthChanged (30-01)
- analytics_models.dart must be imported explicitly for MeterType (not transitive from analytics_provider.dart) (30-01)
- Gas Analyse tab: MonthlySummaryCard without smartPlugKwh/smartPlugPercent (gas-only, no smart plug coverage) (30-02)
- initState must call setSelectedMeterType + setSelectedMonth + setSelectedYear (all three required for monthlyData + yearlyData to populate) (30-01/30-02)
- 300ms tearDown delay for water/gas tests: 2 async initState loads (setSelectedMonth + setSelectedYear) can race with disposal (30-01/30-02)
- SmartPlugAnalyseTab watches both AnalyticsProvider and SmartPlugAnalyticsProvider; onMonthChanged syncs both with year boundary detection (31-01)
- MonthlySummaryCard on SmartPlugAnalyseTab: no smartPlugKwh/smartPlugPercent -- redundant on a screen dedicated to smart plugs (31-01)
- Per-plug pie chart uses totalSmartPlug as denominator (not totalSmartPlug + otherConsumption) for within-smart-plug proportions (31-01)
- smart_plugs_screen_test.dart requires MockAnalyticsProvider because SmartPlugAnalyseTab is inside IndexedStack and watches AnalyticsProvider (31-01)
- smartPlugPieColors used for byPlug; pieChartColors retained for byRoom (31-01)
- SmartPlugsScreen Liste tab uses flat plug list with _SmartPlugExpandableCard; room grouping removed (31-02)
- registerFallbackValue(MeterType.electricity) required in setUpAll when using any() on MeterType enum parameters in mocktail stubs (31-02)
- SmartPlugConsumptionScreen still exists but is no longer navigated to from smart_plugs_screen.dart; remove in Phase 32 if confirmed unused (31-02)
- Standard FloatingActionButton replaces buildGlassFAB in HouseholdsScreen and RoomsScreen (32-02)
- SmartPlugConsumptionScreen deleted; zero navigation references confirmed before deletion (32-02)

### Pending Todos
None yet.

### Blockers/Concerns
None.

## Technical Debt
1. ~~Deprecated GlassBottomNav/buildGlassFAB~~ -- RESOLVED (32-02, DEBT-01)
2. Duplicate _YearNavigationHeader/_YearlySummaryCard -- REPLACEMENTS BUILT (27-01), ELECTRICITY DONE (29-02), WATER DONE (30-01), GAS DONE (30-02), remaining in heating (31-32)
3. App icon alpha channel (fix for App Store submission) -- unscheduled
4. ~~12 info-level deprecation warnings from test files referencing deprecated widgets~~ -- RESOLVED (32-02, deprecated symbols removed)
5. Pre-existing migration_test.dart failure (v2→v3 smart plug interval conversion) -- unscheduled

## Session Continuity

Last session: 2026-04-01
Stopped at: Phase 32 complete (DEBT-01 resolved -- deprecated widgets removed, dead SmartPlugConsumptionScreen deleted)
Resume file: None
