# Valtra v0.2.0 Requirements — Analytics & Visualization (ARCHIVED)

**Milestone**: 2 — Analytics & Visualization (v0.2.0)
**Status**: COMPLETED — All requirements validated
**Shipped**: 2026-03-07
**Predecessor**: v0.1.0 — Core Foundation (7 phases, 313 tests)

---

## Functional Requirements

### FR-7: Analytics & Visualization

#### FR-7.1: Monthly Analytics
- [x] **FR-7.1.1**: Display monthly consumption summary for each meter type (electricity kWh, gas m³, water m³, heating units)
- [x] **FR-7.1.2**: Navigate between months with forward/back controls
- [x] **FR-7.1.3**: Show line chart of daily consumption trends within selected month
- [x] **FR-7.1.4**: Show bar chart comparing consumption across recent months
- [x] **FR-7.1.5**: Visually distinguish interpolated values from actual readings (dashed line, different marker)
- [x] **FR-7.1.6**: Support custom date range selection in addition to fixed monthly periods

#### FR-7.2: Yearly Analytics
- [x] **FR-7.2.1**: Display yearly consumption totals for each meter type
- [x] **FR-7.2.2**: Navigate between years with forward/back controls
- [x] **FR-7.2.3**: Show bar chart of monthly breakdown within selected year
- [x] **FR-7.2.4**: Show year-over-year comparison when multiple years of data exist
- [x] **FR-7.2.5**: Aggregate monthly interpolated values into yearly totals

#### FR-7.3: Analytics Navigation
- [x] **FR-7.3.1**: Dedicated analytics hub screen accessible from home
- [x] **FR-7.3.2**: Per-meter-type analytics accessible from each meter type screen
- [x] **FR-7.3.3**: Cross-meter overview in analytics hub showing all meter types
- [x] **FR-7.3.4**: Navigation between analytics hub and per-meter detail views

#### FR-7.4: Smart Plug Analytics
- [x] **FR-7.4.1**: Pie chart showing consumption breakdown by individual smart plug
- [x] **FR-7.4.2**: Pie chart showing consumption breakdown by room
- [x] **FR-7.4.3**: Calculate and display "Other" consumption (total electricity minus total smart plug)
- [x] **FR-7.4.4**: List view with detailed per-plug and per-room breakdown
- [x] **FR-7.4.5**: Time period selection for smart plug analytics (monthly, yearly, custom range)

#### FR-7.5: CSV Export
- [x] **FR-7.5.1**: Export analytics data to CSV format
- [x] **FR-7.5.2**: CSV includes meter type, date, value, consumption delta, and interpolation flag
- [x] **FR-7.5.3**: Export via system share sheet (share_plus)
- [x] **FR-7.5.4**: Support export for individual meter type or all meters combined

### FR-8: Interpolation Engine

#### FR-8.1: Core Interpolation
- [x] **FR-8.1.1**: Linear interpolation between two adjacent readings for continuous meters (electricity, gas, water)
- [x] **FR-8.1.2**: Step function interpolation option for non-continuous meters (heating)
- [x] **FR-8.1.3**: User-configurable interpolation method per meter type
- [x] **FR-8.1.4**: Generate interpolated values at monthly boundaries (1st of month, 00:00)
- [x] **FR-8.1.5**: Flag all interpolated values as such (isInterpolated = true)

#### FR-8.2: Edge Cases
- [x] **FR-8.2.1**: Handle single reading gracefully (no interpolation possible, display as-is)
- [x] **FR-8.2.2**: Handle readings spanning multiple months (interpolate each boundary)
- [x] **FR-8.2.3**: Handle sparse data (large gaps between readings)
- [x] **FR-8.2.4**: No extrapolation beyond first/last reading timestamps

### FR-9: Carry-Forward from Milestone 1

#### FR-9.1: Gas kWh Conversion
- [x] **FR-9.1.1**: Display optional kWh equivalent for gas readings
- [x] **FR-9.1.2**: Configurable conversion factor (default: 10.3 kWh/m³ for German natural gas)
- [x] **FR-9.1.3**: Show both m³ and kWh in gas analytics views

#### FR-9.2: Smart Plug Aggregation UI
- [x] **FR-9.2.1**: Smart plug consumption aggregated by plug (DAO exists from Phase 4)
- [x] **FR-9.2.2**: Smart plug consumption aggregated by room (DAO exists from Phase 4)
- [x] **FR-9.2.3**: Total smart plug consumption for household (DAO exists from Phase 4)

---

## Non-Functional Requirements

### NFR-5: Performance
- [x] **NFR-5.1**: Analytics queries complete within 500ms for up to 1,000 readings per meter type
- [x] **NFR-5.2**: Chart rendering completes within 1 second
- [x] **NFR-5.3**: Interpolation engine processes 100 readings in under 100ms

### NFR-6: Localization (Continuation)
- [x] **NFR-6.1**: All new analytics strings externalized to ARB files (EN + DE)
- [x] **NFR-6.2**: Date/number formatting in charts follows device locale
- [x] **NFR-6.3**: Chart axis labels and tooltips localized

### NFR-7: Testing (Continuation)
- [x] **NFR-7.1**: Unit tests for interpolation engine with edge cases
- [x] **NFR-7.2**: Unit tests for analytics DAO queries
- [x] **NFR-7.3**: Widget tests for analytics screens
- [x] **NFR-7.4**: Aim for 80%+ statement coverage on all new code

---

## User Acceptance Criteria

### UAC-M2-1: Monthly Consumption View — PASSED
### UAC-M2-2: Interpolated Values — PASSED
### UAC-M2-3: Year-Over-Year Comparison — PASSED
### UAC-M2-4: Smart Plug Breakdown — PASSED
### UAC-M2-5: CSV Export — PASSED
### UAC-M2-6: Analytics Navigation — PASSED
### UAC-M2-7: Custom Date Range — PASSED

---

## Requirements Traceability

| Requirement | Phase(s) | UAC | Outcome |
|-------------|----------|-----|---------|
| FR-7.1 (Monthly Analytics) | 9 | UAC-M2-1, UAC-M2-7 | Validated |
| FR-7.2 (Yearly Analytics) | 10 | UAC-M2-3 | Validated |
| FR-7.3 (Navigation) | 9 | UAC-M2-6 | Validated |
| FR-7.4 (Smart Plug Analytics) | 11 | UAC-M2-4 | Validated |
| FR-7.5 (CSV Export) | 10 | UAC-M2-5 | Validated |
| FR-8 (Interpolation) | 8 | UAC-M2-2 | Validated |
| FR-9.1 (Gas kWh) | 8 | — | Validated |
| FR-9.2 (Smart Plug Aggregation) | 11 | UAC-M2-4 | Validated |
