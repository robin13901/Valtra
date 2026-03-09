# Phase 20 Context — Gas Screen Overhaul

## Phase Goal
Mirror the electricity screen architecture (Phase 19) onto the gas screen: unified bottom navigation (Analyse | Liste), LiquidGlass FAB on Liste only, inline analysis tab with year comparison chart, and m³/€ toggle for switching between consumption and cost views.

## Requirements Source
ROADMAP.md Phase 20 items + PROJECT.md success criteria 15–18.

## Functional Requirements

### FR-18.1: Bottom Navigation (Analyse | Liste)
- Add GlassBottomNav with two tabs: "Analyse" (left) and "Liste" (right)
- Default to "Liste" tab on screen open
- Use IndexedStack to preserve state when switching tabs

### FR-18.2: LiquidGlass FAB
- FAB (add reading) visible on Liste tab only
- Hidden on Analyse tab
- Uses existing `buildGlassFAB()` helper

### FR-18.3: Remove App Bar Analysis Icon
- Remove the `Icons.analytics` action button from the app bar (currently navigates to MonthlyAnalyticsScreen)
- Analysis is now accessed via the bottom nav Analyse tab

### FR-18.4: Single Inline Analysis Page
- Embed yearly analytics content directly in the Analyse tab (year navigation, summary, monthly bar chart, year comparison chart)
- Remove MonthlyAnalyticsScreen navigation for gas
- All data from `context.watch<AnalyticsProvider>()` — gas path already fully supported

### FR-18.5: Fix Year Comparison Chart Month Alignment
- Already fixed globally in Phase 19 (Task 19.2) — chart uses `periodStart.month - 1` as X-axis
- Verify gas data renders correctly with calendar month alignment

### FR-18.6: m³/€ Toggle
- Toggle button in app bar on Analyse tab only
- Default: m³ (consumption)
- When € selected: summary shows cost, bar chart shows monthly costs, year comparison shows cost comparison
- Only available when cost config exists for gas in current household
- Falls back to m³-only when no cost config
- Icon: `Icons.local_fire_department` (consumption) ↔ `Icons.euro` (cost)

### FR-18.7: Monthly Consumption from Interpolated Deltas
- Monthly consumption values in charts always computed from interpolated value deltas at month boundaries
- Already implemented via InterpolationService.getMonthlyConsumption() — verify it's used correctly for gas

## Non-Functional Requirements

### NFR-14: Localization
- All required strings already exist in EN + DE ARB files (analysis, list, showCosts, showConsumption, costPerMonth)
- No new l10n strings needed

### NFR-15: Testing
- Tests for bottom nav switching, FAB visibility per tab, toggle state, chart data passing
- Mirror electricity_screen_test.dart structure for gas
- All existing gas screen tests continue to pass

### NFR-16: Code Quality
- `flutter analyze` returns zero issues

## Architecture Decisions

### AD-1: Mirror Electricity Architecture Exactly
The gas screen follows the identical pattern established in Phase 19 for electricity: StatefulWidget with IndexedStack, GlassBottomNav, conditional FAB, inline analysis tab. This ensures consistency across all meter screens.

### AD-2: Reuse Existing Infrastructure
All supporting infrastructure is already in place from Phase 19:
- `YearlyAnalyticsData` already has `monthlyCosts` and `previousYearMonthlyCosts`
- `AnalyticsProvider` already handles `MeterType.gas` with cost calculations (including m³→kWh conversion for cost)
- `MonthlyBarChart` and `YearComparisonChart` already support `showCosts`, `periodCosts`, `costUnit` parameters
- `GlassBottomNav`, `buildGlassFAB`, `buildGlassAppBar` are ready

### AD-3: Reuse _YearlySummaryCard
The `_YearlySummaryCard` private widget from electricity_screen.dart should be extracted or duplicated for gas. Since it's a private widget, the simplest approach is to duplicate it into gas_screen.dart (consistent with the electricity pattern). A shared widget can be extracted in a future cleanup phase if desired.

### AD-4: Cost Toggle State — Local Widget State
The toggle state lives as local widget state (`_showCosts` boolean) in the gas screen, identical to electricity. No provider-level change needed.

### AD-5: Gas Cost Calculation
Analytics provider already handles gas cost calculation by converting m³ to kWh via `GasConversionService` before applying the cost config. The `CostMeterType.gas` maps correctly. No changes needed in the data layer.

## Key Files

| File | Role |
|------|------|
| `lib/screens/gas_screen.dart` | Main screen — refactor to bottom nav, tab switching, FAB visibility, inline analysis |
| `lib/screens/electricity_screen.dart` | Reference implementation — mirror this exactly |
| `lib/widgets/liquid_glass_widgets.dart` | GlassBottomNav, buildGlassFAB (no changes) |
| `lib/widgets/charts/year_comparison_chart.dart` | Already supports cost mode (no changes) |
| `lib/widgets/charts/monthly_bar_chart.dart` | Already supports cost mode (no changes) |
| `lib/providers/analytics_provider.dart` | Already handles MeterType.gas fully (no changes) |
| `lib/services/analytics/analytics_models.dart` | YearlyAnalyticsData already has cost fields (no changes) |
| `lib/providers/cost_config_provider.dart` | Gas cost config support (no changes) |
| `test/screens/gas_screen_test.dart` | Expand tests to cover nav, FAB, toggle, analysis |

## Dependencies
- Phase 19 complete (electricity architecture established, chart fixes applied, cost mode in charts)
- Phase 18 complete (cost profiles exist for m³/€ toggle)
- GlassBottomNav widget exists in liquid_glass_widgets.dart
- InterpolationService already provides month boundary consumption for gas
