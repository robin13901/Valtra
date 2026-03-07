# Phase 10 UAT — Yearly Analytics & CSV Export

## UAT-10.1: Yearly Consumption View
**Given** a household with electricity readings spanning January through December 2026
**When** user opens yearly analytics for 2026
**Then** a bar chart shows 12 bars (one per month) with consumption values, and a summary card displays the yearly total

## UAT-10.2: Year Navigation
**Given** user is viewing yearly analytics for 2026
**When** user taps the back arrow
**Then** yearly analytics loads for 2025, and forward arrow navigates back to 2026

## UAT-10.3: Year-over-Year Comparison
**Given** a household with electricity readings in both 2025 and 2026
**When** user views yearly analytics for 2026
**Then** a line chart overlays 2025 (dashed) and 2026 (solid) monthly consumption with a legend

## UAT-10.4: Year-over-Year Hidden When No Previous Data
**Given** a household with readings only in 2026 (no 2025 data)
**When** user views yearly analytics for 2026
**Then** the year-over-year comparison section is not visible

## UAT-10.5: Percentage Change Display
**Given** yearly total for 2026 is 3,000 kWh and 2025 was 2,500 kWh
**When** user views yearly analytics for 2026
**Then** summary card shows "+20% vs last year"

## UAT-10.6: Gas kWh Conversion in Yearly View
**Given** gas readings in m³ exist for a household
**When** user views gas yearly analytics
**Then** all values are displayed in kWh (converted using the configured factor)

## UAT-10.7: Monthly to Yearly Navigation
**Given** user is viewing monthly analytics for electricity
**When** user taps the "Yearly" action in the AppBar
**Then** app navigates to yearly analytics screen for electricity

## UAT-10.8: CSV Export from Yearly Screen
**Given** user is viewing yearly analytics with data loaded
**When** user taps the export FAB
**Then** system share sheet opens with a CSV file containing month, consumption, unit, and interpolated flag columns

## UAT-10.9: CSV Export from Monthly Screen
**Given** user is viewing monthly analytics with data loaded
**When** user taps the export FAB
**Then** system share sheet opens with a CSV file containing the monthly analytics data

## UAT-10.10: CSV Export All Meters
**Given** user is on the analytics hub screen
**When** user taps "Export All" in the AppBar
**Then** system share sheet opens with a CSV file combining all 4 meter types for the current year

## UAT-10.11: CSV Content Correctness
**Given** exported CSV file for yearly electricity analytics
**When** file is opened
**Then** columns are: Month, Consumption, Unit, Interpolated — and data matches what was displayed on screen

## UAT-10.12: Empty Year State
**Given** a household with no readings in 2024
**When** user navigates yearly analytics to 2024
**Then** empty state message "No data for 2024" is shown, no charts rendered, export button is disabled

## UAT-10.13: Multi-Meter Aggregation in Yearly View
**Given** a household with 2 water meters, both with readings in 2026
**When** user views water yearly analytics
**Then** monthly breakdown shows aggregated (summed) consumption from both meters

## UAT-10.14: Localization
**Given** device language is set to German
**When** user views yearly analytics
**Then** all labels show German translations (e.g., "Jahresanalyse", "Monatsaufschlüsselung", "CSV exportieren")
