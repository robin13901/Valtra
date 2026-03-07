# Valtra - Project Context

## Vision
Valtra is a personal utility meter tracking and analysis app for recording and analyzing energy and water consumption (electricity, gas, water) across multiple households, with consumption statistics, interpolation of measurements, and visualization down to room and device level.

## Problem Statement
Managing utility consumption across multiple households requires manual tracking of various meter types with different units and reading patterns. Users need to:
- Track electricity (kWh), gas (m³), and water (m³) meters
- Monitor smart plug consumption at device/room level
- Compare consumption patterns over time
- Interpolate values for consistent monthly comparisons
- Maintain separate data for different households

## Target Users
- Primary: Personal use for the developer
- Secondary: Family members managing their own household meters

## Technical Stack
- **Framework**: Flutter (Dart)
- **Platforms**: iOS & Android (mobile-first)
- **Database**: Drift (SQLite) - local-first with offline capability
- **State Management**: Provider
- **Charts**: fl_chart
- **UI Components**: LiquidGlass widgets (from XFin reference)
- **Localization**: Flutter intl (EN/DE)

## Design System
- **Primary Color**: Ultra Violet (#5F4A8B)
- **Accent Color**: Lemon Chiffon (#FEFACD)
- **UI Style**: Modern LiquidGlass aesthetic with glassmorphism effects

## Key Constraints
- Must work fully offline (local-first architecture)
- All strings must be localized (EN + DE)
- Comprehensive test coverage with Codecov integration
- GitHub Actions CI/CD pipeline

## Current State

### Shipped: v0.1.0 - Core Foundation (2026-03-07)
- 7 phases completed: Project setup, household management, and CRUD for all 5 meter types
- 44 source files (9,681 LOC), 35 test files (7,492 LOC), 313 tests passing
- 10 database tables, 7 DAOs, 8 providers, 8 screens, 10 form dialogs
- Full EN/DE localization (140 keys)
- Architecture: Drift DAOs -> Provider state management -> Material 3 + LiquidGlass UI

### Active: v0.2.0 - Analytics & Visualization
- **Phase 8**: Interpolation engine (linear + step, configurable per meter) + gas kWh conversion
- **Phase 9**: Analytics hub (home access) + monthly analytics with line/bar charts + custom date ranges
- **Phase 10**: Yearly analytics with year-over-year comparison + CSV export (share_plus)
- **Phase 11**: Smart plug analytics with pie charts (by plug, by room, "Other")
- **Carry-forward**: Gas kWh display (FR-5.3), smart plug aggregation UI (FR-3.5/3.6)
- **New dependencies**: csv, share_plus packages

## Success Criteria
1. ~~All meter types can be recorded with timestamps~~ (v0.1.0)
2. Smart plug data aggregates correctly by room with pie chart visualization (v0.2.0)
3. Interpolation produces accurate monthly boundary values with configurable methods (v0.2.0)
4. ~~Multi-household data remains properly isolated~~ (v0.1.0)
5. Analytics views show meaningful consumption insights with line/bar/pie charts (v0.2.0)
6. CSV export works for all meter types via system share sheet (v0.2.0)
7. 80%+ test coverage maintained (v0.3.0)

## Repository
- Location: c:\SAPDevelop\Privat\Valtra
- Branch Strategy: main (single branch for personal project)

## Reference Project
- XFin (C:\SAPDevelop\Privat\XFin) - for architecture patterns, LiquidGlass widgets, and CI/CD pipeline
