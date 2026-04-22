# Phase 15: Data Model & Analytics Rework — Context

## Requirements
- FR-13.1: Interpolation Rework (boundary values at 1st of month 00:00, toggle visibility, color-code)
- FR-13.2: Smart Plug Entry Rework (month/year picker, remove interval type + start date)
- FR-13.3: Heating Meter Rework (room assignment, remove location, DB migration)
- FR-13.4: Gas Analysis Fix (display m³ not kWh)
- FR-13.5: Yearly Analysis Rework (extrapolation, previous year comparison, monthly breakdown)
- FR-13.6: Data Entry Enhancements (quick entry, validation, delete confirmation)

## UACs
- UAC-M3-6: New reading >= previous for cumulative meters, validation shown in form
- UAC-M3-11: Interpolation boundaries at month starts, toggle, distinct color
- UAC-M3-12: Smart plug month/year picker (no interval type, no start date)
- UAC-M3-13: Heating meters mandatory room, no location field, grouped by room
- UAC-M3-14: Gas analysis in m³
- UAC-M3-15: Yearly analysis with extrapolation, previous year, monthly breakdown

## Dependencies
- Phase 14 COMPLETE (7/7 plans, 765 tests)
- Current: 78 source files, 62 test files, ~765 tests passing
- DB schema version 2 (added cost_configs in Phase 13)

## Current Architecture (Relevant Parts)
- InterpolationService: Pure-logic, calculates on-the-fly, no persistence
  - getMonthlyBoundaries(): Already generates 1st-of-month boundaries
  - getMonthlyConsumption(): Already uses boundary differences
  - No extrapolation policy (skips boundaries outside reading range)
- AnalyticsProvider: Orchestrates DAOs + interpolation + gas conversion
  - _loadYearlyData(): Fetches 12 monthly boundaries, compares years
  - Gas conversion applied at display layer (m³ → kWh via factor)
- Smart Plug: intervalType enum (daily/weekly/monthly/yearly) + intervalStart date
- Heating Meter: flat list per household, optional location text field, no room FK
- Rooms: Only used by smart plugs currently
- Delete: Inline AlertDialog confirmation exists for all meter types
- Reading validation: Already validates >= previous for cumulative meters
