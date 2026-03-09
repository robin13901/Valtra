# Phase 19 Context — Electricity Screen Overhaul

## Phase Goal
Overhaul the electricity screen to have a unified list/analysis bottom navigation, LiquidGlass FAB on the list tab only, consolidate monthly+yearly analytics into a single "Analyse" tab, fix the year comparison chart alignment bug, and add a kWh/€ toggle for switching between consumption and cost views.

## Requirements Source
ROADMAP.md Phase 19 items + PROJECT.md success criteria 15–18.

## Functional Requirements

### FR-17.1: Bottom Navigation (Analyse | Liste)
- Add GlassBottomNav with two tabs: "Analyse" (left) and "Liste" (right)
- Default to "Liste" tab on screen open
- Use IndexedStack to preserve state when switching tabs

### FR-17.2: LiquidGlass FAB
- FAB (add reading) visible on Liste tab only
- Hidden on Analyse tab
- Uses existing `buildGlassFAB()` helper

### FR-17.3: Remove App Bar Analysis Icon
- Remove the `Icons.analytics` action button from the app bar
- Analysis is now accessed via the bottom nav Analyse tab

### FR-17.4: Consolidated Single Analysis Page
- Merge the current MonthlyAnalyticsScreen and YearlyAnalyticsScreen content into one inline Analyse tab
- The tab is the current yearly view (year navigation, summary, monthly bar chart, year comparison chart)
- Remove MonthlyAnalyticsScreen navigation for electricity
- Remove the separate "navigate to yearly" flow for electricity

### FR-17.5: Fix Year Comparison Chart
- Previous year line should start at the first month that has data, not at January (index 0)
- If previous year only has data from March–December, the line should start at the March position
- Both lines must align by calendar month (January=0, February=1, ..., December=11)

### FR-17.6: kWh/€ Toggle
- Toggle button at the top of the analysis tab (or in the app bar)
- Default: kWh (consumption)
- When € selected: summary shows cost, bar chart shows monthly costs, year comparison shows cost comparison
- Only available when cost config exists for electricity in current household
- Falls back to kWh-only when no cost config

### FR-17.7: Monthly Consumption from Interpolated Deltas
- Monthly consumption values in charts always computed from interpolated value deltas at month boundaries
- Already implemented via InterpolationService.getMonthlyConsumption() — verify it's used correctly

## Non-Functional Requirements

### NFR-14: Localization
- All new/changed strings localized in both EN and DE ARB files

### NFR-15: Testing
- Tests for bottom nav switching, FAB visibility per tab, toggle state, chart alignment
- All existing tests continue to pass

### NFR-16: Code Quality
- `flutter analyze` returns zero issues

## Architecture Decisions

### AD-1: IndexedStack for Tab State
The Analyse and Liste tabs use IndexedStack so provider state (scroll position, analytics data) is preserved when switching. This avoids re-fetching data on every tab switch.

### AD-2: Inline Analysis (No Separate Screens)
Instead of navigating to MonthlyAnalyticsScreen → YearlyAnalyticsScreen, the Analyse tab embeds the yearly analytics content directly. This eliminates navigation depth and provides a more integrated UX. The MonthlyAnalyticsScreen is NOT deleted (still used by gas/water/heating until phases 20-22), but electricity no longer navigates to it.

### AD-3: Year Comparison Fix — Calendar Month Alignment
Both current and previous year data should use `periodStart.month - 1` as the X-axis index (0=Jan, 11=Dec). This ensures lines align by calendar month regardless of which months have data. The chart's maxX should be 11 (always show full year) or the max month index across both datasets.

### AD-4: kWh/€ Toggle — Provider-Level
The toggle state lives as local widget state in the electricity screen (no need for provider). When toggled to €, the analysis widgets receive cost data instead of consumption data. The YearlyAnalyticsData already contains `totalCost`, `previousYearTotalCost`, and `currencySymbol`.

### AD-5: Cost Per Month Data
Analytics provider needs to supply per-month cost values for the bar chart and comparison chart in € mode. This requires extending YearlyAnalyticsData with `monthlyCosts` and `previousYearMonthlyCosts` lists (parallel to monthlyBreakdown/previousYearBreakdown).

## Key Files

| File | Role |
|------|------|
| `lib/screens/electricity_screen.dart` | Main screen — needs bottom nav, tab switching, FAB visibility |
| `lib/screens/yearly_analytics_screen.dart` | Source for analysis content to inline |
| `lib/screens/monthly_analytics_screen.dart` | Still used by other meters; electricity stops navigating here |
| `lib/widgets/liquid_glass_widgets.dart` | GlassBottomNav, buildGlassFAB |
| `lib/widgets/charts/year_comparison_chart.dart` | Chart fix: calendar month alignment |
| `lib/widgets/charts/monthly_bar_chart.dart` | May need cost data support |
| `lib/providers/analytics_provider.dart` | Data loading, per-month cost calculation |
| `lib/services/analytics/analytics_models.dart` | YearlyAnalyticsData model extension |
| `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb` | New localization strings |
| `test/screens/electricity_screen_test.dart` | Screen tests |

## Dependencies
- Phase 18 complete (cost profiles exist for kWh/€ toggle)
- GlassBottomNav widget exists in liquid_glass_widgets.dart
- InterpolationService already provides month boundary consumption
