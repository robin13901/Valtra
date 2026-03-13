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

## Current Milestone: v0.5.0 - Visual & UX Polish

**Goal:** Polish the app's visual identity, fix UX issues, and align bottom navigation with XFin reference design.

**Target features:**
- New glassmorphism app icon + proper app name capitalization
- Native splash screen (no empty-state flicker on startup)
- Bottom nav bar matching XFin LiquidGlass design exactly
- Localized chart labels (month abbreviations, Y-axis units/currency)
- Home screen app bar cleanup (remove redundant title)
- Cost profile formatting fixes (remove "Aktiv" badge, German currency, date format)
- Heating cost profile removal (unitless consumption counters, percentage-only analysis)

## Current State

<details>
<summary>v0.4.0 - UX Overhaul (2026-03-09)</summary>

- 6 phases completed: Home Screen, Cost Settings, Electricity, Gas, Smart Plugs, Water & Heating
- 1077 tests passing, 78 source files (27,482 LOC), 81 test files (24,887 LOC), DB schema v3
- Unified Analyse/Liste bottom nav on all 5 meter screens (IndexedStack, LiquidGlass FAB)
- Per-household cost profile history with date-based lookup (Grundpreis pro Jahr, Arbeitspreis)
- kWh/€ (or m³/€) cost toggle on electricity, gas, water, and heating analysis pages
- Year comparison chart fixed (calendar month alignment)
- Dead code removed: CSV export, analytics hub, MonthlyAnalyticsScreen, YearlyAnalyticsScreen, QuickEntryMixin
- Global date format "dd.MM.yyyy, HH:mm Uhr" with locale support
</details>

<details>
<summary>v0.3.0 - Polish & Enhancement (2026-03-08)</summary>

- 5 phases completed: Settings, Cost Tracking, UI/UX Polish, Data Model Rework, Backup & Testing
- 1017 tests passing, 75% statement coverage, DB schema v3
- Theme toggle (light/dark/system), language toggle (DE/EN), cost tracking with tiered pricing
- LiquidGlass widgets on all screens, German locale formatting, umlaut fixes
- Interpolation rework (linear only, 1st-of-month boundaries, toggle visibility)
- Smart plug monthly entry, heating meter room assignment, gas analysis in m³
- Database backup/restore via file export/import
</details>

<details>
<summary>v0.2.0 - Analytics & Visualization (2026-03-07)</summary>

- 4 phases completed: Interpolation engine, analytics hub + monthly analytics, yearly analytics + CSV export, smart plug analytics
- 71 source files (21,131 LOC), 55 test files (14,156 LOC), 625 tests passing
- InterpolationService (linear + step), GasConversionService, AnalyticsProvider, SmartPlugAnalyticsProvider
- Analytics hub, monthly/yearly analytics screens, smart plug pie charts
- CSV export via share_plus, custom date ranges, year-over-year comparison
- Full EN/DE localization
</details>

<details>
<summary>v0.1.0 - Core Foundation (2026-03-07)</summary>

- 7 phases completed: Project setup, household management, and CRUD for all 5 meter types
- 44 source files (9,681 LOC), 35 test files (7,492 LOC), 313 tests passing
- 10 database tables, 7 DAOs, 8 providers, 8 screens, 10 form dialogs
- Full EN/DE localization (140 keys)
- Architecture: Drift DAOs -> Provider state management -> Material 3 + LiquidGlass UI
</details>

## Success Criteria
1. ~~All meter types can be recorded with timestamps~~ (v0.1.0)
2. ~~Smart plug data aggregates correctly by room with pie chart visualization~~ (v0.2.0)
3. ~~Interpolation produces accurate monthly boundary values with configurable methods~~ (v0.2.0)
4. ~~Multi-household data remains properly isolated~~ (v0.1.0)
5. ~~Analytics views show meaningful consumption insights with line/bar/pie charts~~ (v0.2.0)
6. ~~CSV export works for all meter types via system share sheet~~ (v0.2.0 — removed in v0.4.0)
7. ~~80%+ test coverage maintained~~ (v0.3.0 -- 75% achieved, limited by generated l10n files)
8. ~~Cost tracking shows accurate cost calculations with tiered pricing~~ (v0.3.0)
9. ~~Dark/light/system theme toggle works with full UI consistency~~ (v0.3.0)
10. ~~Database backup/restore works via file export/import~~ (v0.3.0)
11. ~~German locale: correct number formatting, umlauts, localized month names~~ (v0.3.0)
12. ~~Interpolation reworked: values at 1st of month 00:00, toggle visibility~~ (v0.3.0)
13. ~~Heating meters assigned to rooms with per-room energy ratio support~~ (v0.3.0)
14. ~~In-app language toggle (DE/EN) works independently of device locale~~ (v0.3.0)
15. ~~Every meter screen has unified list/analysis bottom navigation with LiquidGlass FAB~~ (v0.4.0)
16. ~~Per-household cost profile history with date-based lookup~~ (v0.4.0)
17. ~~kWh/€ (or m³/€) toggle on all meter analysis pages~~ (v0.4.0)
18. ~~Year comparison chart shows previous year data at correct month positions~~ (v0.4.0)
19. ~~Global date format "dd.MM.yyyy, HH:mm Uhr" with localized suffix~~ (v0.4.0)
20. New glassmorphism app icon with proper "Valtra" capitalization on home screen
21. Native splash screen persists until data loaded (no empty-state flicker)
22. Bottom nav matches XFin LiquidGlass reference design exactly
23. Chart month abbreviations localized (DE/EN), Y-axis shows units/currency
24. Home app bar shows only household selector + settings (no redundant title)
25. Cost profiles: no "Aktiv" badge, German currency always, dd.MM.yyyy date format
26. Heating has no cost profiles (unitless counters, percentage distribution only)

## Repository
- Location: c:\SAPDevelop\Privat\Valtra
- Branch Strategy: main (single branch for personal project)

## Reference Project
- XFin (C:\SAPDevelop\Privat\XFin) - for architecture patterns, LiquidGlass widgets, and CI/CD pipeline
