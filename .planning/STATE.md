# Valtra - Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-01)

**Core value:** Users can track and analyze utility consumption across multiple households with an intuitive, polished interface
**Current focus:** v0.6.0 Analytics Redesign -- Phase 28 (Home & Nav Polish)

## Current Position

Phase: 28 of 32 (Home & Nav Polish)
Plan: 3 of TBD in current phase
Status: In progress
Last activity: 2026-04-01 -- Completed 28-03-PLAN.md (frosted glass household carousel)

Progress: ██░░░░░░░░░░░░░░░░░░░░░░░ 9% (v0.6.0) [~6/~25 plans]

## Performance Metrics

**Velocity:**
- Total plans completed: ~6 (v0.6.0)
- Average duration: ~18 min
- Total execution time: ~96 min

*Updated after each plan completion*

## Completed Milestones
- **v0.1.0**: Core Foundation -- 7 phases, 313 tests
- **v0.2.0**: Analytics & Visualization -- 4 phases, 625 tests
- **v0.3.0**: Polish & Enhancement -- 5 phases, 1017 tests
- **v0.4.0**: UX Overhaul -- 6 phases, 1077 tests
- **v0.5.0**: Visual & UX Polish -- 4 phases, 1103 tests

## Completed Phases (v0.6.0)
- **Phase 27**: Shared Chart Infrastructure -- 4 plans, 1154 tests, verified 5/5
- **Phase 28 Plan 01**: personCount field on Household (schema v4) -- 1165 tests
- **Phase 28 Plan 02**: LiquidGlassBottomNav inline FAB + left FAB removed -- 1165 tests
- **Phase 28 Plan 03**: Frosted glass household carousel (PageView + BackdropFilter) -- 1213 tests

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

### Pending Todos
None yet.

### Blockers/Concerns
None.

## Technical Debt
1. Deprecated GlassBottomNav/buildGlassFAB -- SCHEDULED (Phase 32, DEBT-01)
2. Duplicate _YearNavigationHeader/_YearlySummaryCard -- REPLACEMENTS BUILT (27-01), integration in 29-32
3. App icon alpha channel (fix for App Store submission) -- unscheduled
4. 12 info-level deprecation warnings in flutter analyze (was 8, +4 from test files referencing deprecated widgets) -- unscheduled
5. Pre-existing migration_test.dart failure (v2→v3 smart plug interval conversion) -- unscheduled

## Session Continuity

Last session: 2026-04-01T11:52:29Z
Stopped at: Completed 28-03-PLAN.md
Resume file: None
