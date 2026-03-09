# Phase 22 Context — Water & Heating Screen Overhaul

## Phase Goal
Overhaul both the water and heating meter screens to use the same bottom navigation (Analyse | Liste) architecture established in phases 19-20 for electricity and gas. Add inline analysis tabs with year comparison charts, m³/€ toggle (water) and kWh/€ toggle (heating), and monthly consumption from interpolated deltas.

## Requirements Source
- ROADMAP.md Phase 22: Water & Heating Screen Overhaul
- REQUIREMENTS.md: FR-20 (Water Screen Overhaul), FR-21 (Heating Screen Overhaul)
- UAC-M4-7 (Water), UAC-M4-8 (Heating)

## Functional Requirements

### FR-20: Water Screen Overhaul
- FR-20.1.1: Add bottom navigation (Analyse left, Liste right, default Liste)
- FR-20.1.2: LiquidGlass FAB visible on Liste only
- FR-20.1.3: Analysis page with same pattern as electricity (year nav, summary, charts, comparison)
- FR-20.2.1: m³/€ toggle for consumption vs. cost view
- FR-20.2.2: Year comparison chart with correct month alignment
- FR-20.2.3: Monthly values from interpolated deltas at month boundaries

### FR-21: Heating Screen Overhaul
- FR-21.1.1: Add bottom navigation (Analyse left, Liste right, default Liste)
- FR-21.1.2: LiquidGlass FAB visible on Liste only
- FR-21.1.3: Analysis page with same pattern as electricity (year nav, summary, charts, comparison)
- FR-21.2.1: kWh/€ toggle for consumption vs. cost view
- FR-21.2.2: Year comparison chart with correct month alignment
- FR-21.2.3: Monthly values from interpolated deltas at month boundaries

## Non-Functional Requirements
- NFR-13: Do NOT change visual design beyond what's specified
- NFR-14: All new strings localized EN + DE
- NFR-15: All 1070 existing tests pass, new tests for nav, toggle, chart alignment
- NFR-16: `flutter analyze` returns zero issues

## Architecture Decisions

### AD-1: Mirror Electricity/Gas Pattern Exactly
Water and heating screens will be refactored to StatefulWidget with the exact same tab/IndexedStack/FAB/cost-toggle pattern as electricity_screen.dart and gas_screen.dart.

### AD-2: Water Uses Multi-Meter Pattern (Unlike Electricity/Gas)
Water has multiple meters per household (cold/hot/other). The Liste tab must preserve the expandable meter card pattern. The Analyse tab shows aggregated analytics across all water meters for the household (via AnalyticsProvider with MeterType.water).

### AD-3: Heating Uses Room-Grouped Multi-Meter Pattern
Heating has multiple meters per household grouped by room. The Liste tab must preserve the room-section + meter-card pattern. The Analyse tab shows aggregated analytics across all heating meters (via AnalyticsProvider with MeterType.heating).

### AD-4: Remove MonthlyAnalyticsScreen Navigation
Both water and heating currently navigate to MonthlyAnalyticsScreen via app bar icon. This navigation is removed — analysis is now inline in the Analyse tab. After this phase, MonthlyAnalyticsScreen and YearlyAnalyticsScreen become dead code and should be removed.

### AD-5: Duplicate Private Widgets
_YearNavigationHeader and _YearlySummaryCard are duplicated per screen file (same as electricity/gas pattern). This keeps each screen self-contained.

### AD-6: Heating Keeps Room Management Icon
The room management icon (meeting_room) moves from the app bar to only show on the Liste tab, alongside the visibility toggle.

## Key Files

| File | Role |
|------|------|
| lib/screens/water_screen.dart | Water screen — overhaul target |
| lib/screens/heating_screen.dart | Heating screen — overhaul target |
| lib/screens/electricity_screen.dart | Reference pattern (749 lines) |
| lib/screens/gas_screen.dart | Reference pattern (mirrors electricity) |
| lib/providers/water_provider.dart | Water data + interpolation |
| lib/providers/heating_provider.dart | Heating data + room grouping |
| lib/providers/analytics_provider.dart | Cross-meter analytics (already supports water + heating) |
| lib/providers/cost_config_provider.dart | Cost configuration (CostMeterType.water exists) |
| lib/widgets/liquid_glass_widgets.dart | GlassBottomNav, buildGlassFAB, GlassCard |
| lib/widgets/charts/monthly_bar_chart.dart | Monthly bar chart widget |
| lib/widgets/charts/year_comparison_chart.dart | Year comparison chart widget |
| lib/widgets/charts/chart_legend.dart | Chart legend widget |
| test/screens/water_screen_test.dart | Water tests (9 existing) |
| test/screens/heating_screen_test.dart | Heating tests (12 existing) |

## Dependencies
- Phase 19 (electricity pattern established)
- Phase 18 (cost profiles for m³/€ and kWh/€ toggle)
- CostMeterType enum already includes `water` (tables.dart:101)
- AnalyticsProvider already handles MeterType.water and MeterType.heating
