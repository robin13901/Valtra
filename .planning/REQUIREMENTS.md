# Valtra v0.2.0 Requirements — Analytics & Visualization

**Milestone**: 2 — Analytics & Visualization (v0.2.0)
**Status**: Completed
**Predecessor**: v0.1.0 — Core Foundation (7 phases, 313 tests)

---

## Functional Requirements

### FR-7: Analytics & Visualization

#### FR-7.1: Monthly Analytics
- **FR-7.1.1**: Display monthly consumption summary for each meter type (electricity kWh, gas m³, water m³, heating units)
- **FR-7.1.2**: Navigate between months with forward/back controls
- **FR-7.1.3**: Show line chart of daily consumption trends within selected month
- **FR-7.1.4**: Show bar chart comparing consumption across recent months
- **FR-7.1.5**: Visually distinguish interpolated values from actual readings (e.g., dashed line, different marker)
- **FR-7.1.6**: Support custom date range selection in addition to fixed monthly periods

#### FR-7.2: Yearly Analytics
- **FR-7.2.1**: Display yearly consumption totals for each meter type
- **FR-7.2.2**: Navigate between years with forward/back controls
- **FR-7.2.3**: Show bar chart of monthly breakdown within selected year
- **FR-7.2.4**: Show year-over-year comparison when multiple years of data exist
- **FR-7.2.5**: Aggregate monthly interpolated values into yearly totals

#### FR-7.3: Analytics Navigation
- **FR-7.3.1**: Dedicated analytics hub screen accessible from home
- **FR-7.3.2**: Per-meter-type analytics accessible from each meter type screen
- **FR-7.3.3**: Cross-meter overview in analytics hub showing all meter types
- **FR-7.3.4**: Navigation between analytics hub and per-meter detail views

#### FR-7.4: Smart Plug Analytics
- **FR-7.4.1**: Pie chart showing consumption breakdown by individual smart plug
- **FR-7.4.2**: Pie chart showing consumption breakdown by room
- **FR-7.4.3**: Calculate and display "Other" consumption (total electricity minus total smart plug)
- **FR-7.4.4**: List view with detailed per-plug and per-room breakdown
- **FR-7.4.5**: Time period selection for smart plug analytics (monthly, yearly, custom range)

#### FR-7.5: CSV Export
- **FR-7.5.1**: Export analytics data to CSV format
- **FR-7.5.2**: CSV includes meter type, date, value, consumption delta, and interpolation flag
- **FR-7.5.3**: Export via system share sheet (share_plus)
- **FR-7.5.4**: Support export for individual meter type or all meters combined

### FR-8: Interpolation Engine

#### FR-8.1: Core Interpolation
- **FR-8.1.1**: Linear interpolation between two adjacent readings for continuous meters (electricity, gas, water)
- **FR-8.1.2**: Step function interpolation option for non-continuous meters (heating)
- **FR-8.1.3**: User-configurable interpolation method per meter type
- **FR-8.1.4**: Generate interpolated values at monthly boundaries (1st of month, 00:00)
- **FR-8.1.5**: Flag all interpolated values as such (isInterpolated = true)

#### FR-8.2: Edge Cases
- **FR-8.2.1**: Handle single reading gracefully (no interpolation possible, display as-is)
- **FR-8.2.2**: Handle readings spanning multiple months (interpolate each boundary)
- **FR-8.2.3**: Handle sparse data (large gaps between readings)
- **FR-8.2.4**: No extrapolation beyond first/last reading timestamps

### FR-9: Carry-Forward from Milestone 1

#### FR-9.1: Gas kWh Conversion
- **FR-9.1.1**: Display optional kWh equivalent for gas readings
- **FR-9.1.2**: Configurable conversion factor (default: 10.3 kWh/m³ for German natural gas)
- **FR-9.1.3**: Show both m³ and kWh in gas analytics views

#### FR-9.2: Smart Plug Aggregation UI
- **FR-9.2.1**: Smart plug consumption aggregated by plug (DAO exists from Phase 4)
- **FR-9.2.2**: Smart plug consumption aggregated by room (DAO exists from Phase 4)
- **FR-9.2.3**: Total smart plug consumption for household (DAO exists from Phase 4)

---

## Non-Functional Requirements

### NFR-5: Performance
- **NFR-5.1**: Analytics queries complete within 500ms for up to 1,000 readings per meter type
- **NFR-5.2**: Chart rendering completes within 1 second
- **NFR-5.3**: Interpolation engine processes 100 readings in under 100ms

### NFR-6: Localization (Continuation)
- **NFR-6.1**: All new analytics strings externalized to ARB files (EN + DE)
- **NFR-6.2**: Date/number formatting in charts follows device locale
- **NFR-6.3**: Chart axis labels and tooltips localized

### NFR-7: Testing (Continuation)
- **NFR-7.1**: Unit tests for interpolation engine with edge cases
- **NFR-7.2**: Unit tests for analytics DAO queries
- **NFR-7.3**: Widget tests for analytics screens
- **NFR-7.4**: Aim for 80%+ statement coverage on all new code

---

## User Acceptance Criteria

### UAC-M2-1: Monthly Consumption View
**Given** a household with electricity readings in January and February
**When** user opens monthly analytics for January
**Then** the monthly consumption summary displays the delta, and a line chart shows the trend

### UAC-M2-2: Interpolated Values
**Given** a household with electricity readings on Jan 15 and Feb 20
**When** user views monthly analytics
**Then** interpolated values appear at Feb 1 boundary, visually marked as interpolated

### UAC-M2-3: Year-Over-Year Comparison
**Given** a household with readings spanning 2025 and 2026
**When** user opens yearly analytics for 2026
**Then** year-over-year comparison chart shows both years side by side

### UAC-M2-4: Smart Plug Breakdown
**Given** a household with 3 smart plugs across 2 rooms, plus main electricity readings
**When** user opens smart plug analytics
**Then** pie chart shows per-plug breakdown, per-room breakdown, and "Other" (untracked) consumption

### UAC-M2-5: CSV Export
**Given** user is viewing monthly analytics
**When** user taps export button
**Then** system share sheet opens with CSV file containing the displayed data

### UAC-M2-6: Analytics Navigation
**Given** user is on the home screen
**When** user taps analytics hub
**Then** analytics overview displays consumption summaries for all meter types with navigation to details

### UAC-M2-7: Custom Date Range
**Given** user is viewing analytics
**When** user selects a custom date range (e.g., Dec 15 - Jan 15)
**Then** analytics display consumption data for the selected period only

---

## Requirements Traceability

| Requirement | Phase(s) | UAC |
|-------------|----------|-----|
| FR-7.1 (Monthly Analytics) | 9 | UAC-M2-1, UAC-M2-7 |
| FR-7.2 (Yearly Analytics) | 10 | UAC-M2-3 |
| FR-7.3 (Navigation) | 9 | UAC-M2-6 |
| FR-7.4 (Smart Plug Analytics) | 11 | UAC-M2-4 |
| FR-7.5 (CSV Export) | 10 | UAC-M2-5 |
| FR-8 (Interpolation) | 8 | UAC-M2-2 |
| FR-9.1 (Gas kWh) | 8 | — |
| FR-9.2 (Smart Plug Aggregation) | 11 | UAC-M2-4 |
