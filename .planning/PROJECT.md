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
- **CSV Export**: csv + share_plus
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

### Shipped: v0.2.0 - Analytics & Visualization (2026-03-07)
- 4 phases completed: Interpolation engine, analytics hub + monthly analytics, yearly analytics + CSV export, smart plug analytics
- 71 source files (21,131 LOC), 55 test files (14,156 LOC), 625 tests passing
- InterpolationService (linear + step), GasConversionService, AnalyticsProvider, SmartPlugAnalyticsProvider
- Analytics hub, monthly/yearly analytics screens, smart plug pie charts
- CSV export via share_plus, custom date ranges, year-over-year comparison
- Full EN/DE localization

<details>
<summary>v0.1.0 - Core Foundation (2026-03-07)</summary>

- 7 phases completed: Project setup, household management, and CRUD for all 5 meter types
- 44 source files (9,681 LOC), 35 test files (7,492 LOC), 313 tests passing
- 10 database tables, 7 DAOs, 8 providers, 8 screens, 10 form dialogs
- Full EN/DE localization (140 keys)
- Architecture: Drift DAOs -> Provider state management -> Material 3 + LiquidGlass UI
</details>

### Next: v0.3.0 - Polish & Enhancement
- Phase 12: Settings & Configuration (theme toggle, cost configuration, app preferences) -- COMPLETE
- Phase 13: Cost Tracking (price models, cost calculations, cost display in analytics) -- COMPLETE
- Phase 14: UI/UX Polish & Localization (LiquidGlass, German formatting, umlaut fixes, cleanup) -- COMPLETE
- Phase 15: Data Model & Analytics Rework (interpolation rework, smart plug entry, heating rooms, yearly analysis) -- COMPLETE (855 tests, DB schema v3)
- Phase 16: Backup, Testing & Documentation (DB export/import, 80%+ coverage, README)

## Success Criteria
1. ~~All meter types can be recorded with timestamps~~ (v0.1.0)
2. ~~Smart plug data aggregates correctly by room with pie chart visualization~~ (v0.2.0)
3. ~~Interpolation produces accurate monthly boundary values with configurable methods~~ (v0.2.0)
4. ~~Multi-household data remains properly isolated~~ (v0.1.0)
5. ~~Analytics views show meaningful consumption insights with line/bar/pie charts~~ (v0.2.0)
6. ~~CSV export works for all meter types via system share sheet~~ (v0.2.0)
7. 80%+ test coverage maintained (v0.3.0)
8. Cost tracking shows accurate cost calculations with tiered pricing (v0.3.0)
9. Dark/light/system theme toggle works with full UI consistency (v0.3.0)
10. Database backup/restore works via file export/import (v0.3.0)
11. German locale: correct number formatting, umlauts, localized month names (v0.3.0)
12. Interpolation reworked: values at 1st of month 00:00, toggle visibility (v0.3.0)
13. Heating meters assigned to rooms with per-room energy ratio support (v0.3.0)
14. In-app language toggle (DE/EN) works independently of device locale (v0.3.0)

## Repository
- Location: c:\SAPDevelop\Privat\Valtra
- Branch Strategy: main (single branch for personal project)

## Reference Project
- XFin (C:\SAPDevelop\Privat\XFin) - for architecture patterns, LiquidGlass widgets, and CI/CD pipeline
