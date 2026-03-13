# Valtra - Project Context

## Vision
Valtra is a personal utility meter tracking and analysis app for recording and analyzing energy and water consumption (electricity, gas, water) across multiple households, with consumption statistics, interpolation of measurements, and visualization down to room and device level.

## Problem Statement
Managing utility consumption across multiple households requires manual tracking of various meter types with different units and reading patterns. Users need to:
- Track electricity (kWh), gas (m3), and water (m3) meters
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
- **UI Components**: LiquidGlass widgets (liquid_glass_renderer) with glassmorphism effects
- **Localization**: Flutter intl (EN/DE)
- **Splash**: flutter_native_splash
- **Icons**: flutter_launcher_icons

## Design System
- **Primary Color**: Ultra Violet (#5F4A8B)
- **Accent Color**: Lemon Chiffon (#FEFACD)
- **UI Style**: LiquidGlass aesthetic with real liquid_glass_renderer effects (pill nav, squircle buttons)
- **App Icon**: Glassmorphism house + gauge design on Ultra Violet gradient

## Key Constraints
- Must work fully offline (local-first architecture)
- All strings must be localized (EN + DE)
- Comprehensive test coverage with Codecov integration
- GitHub Actions CI/CD pipeline
- Currency always displayed in German format regardless of app language

## Current State

**Last shipped:** v0.5.0 — Visual & UX Polish (2026-03-13)

- 56,003 LOC Dart (source + test), 1103 tests, DB schema v3
- 5 milestones shipped (v0.1.0 through v0.5.0), 26 phases completed
- Custom glassmorphism app icon, native splash screen, LiquidGlass bottom nav on all screens
- Locale-aware charts, clean home app bar, correct cost profile formatting
- Heating modeled as consumption-only (unitless counters, percentage distribution)

<details>
<summary>v0.4.0 - UX Overhaul (2026-03-09)</summary>

- 6 phases completed: Home Screen, Cost Settings, Electricity, Gas, Smart Plugs, Water & Heating
- 1077 tests passing, 78 source files (27,482 LOC), 81 test files (24,887 LOC), DB schema v3
- Unified Analyse/Liste bottom nav on all 5 meter screens (IndexedStack, LiquidGlass FAB)
- Per-household cost profile history with date-based lookup (Grundpreis pro Jahr, Arbeitspreis)
- kWh/EUR (or m3/EUR) cost toggle on electricity, gas, water, and heating analysis pages
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
- Smart plug monthly entry, heating meter room assignment, gas analysis in m3
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

## Requirements

### Validated
- ✓ All meter types can be recorded with timestamps — v0.1.0
- ✓ Smart plug data aggregates correctly by room with pie chart visualization — v0.2.0
- ✓ Interpolation produces accurate monthly boundary values — v0.2.0
- ✓ Multi-household data remains properly isolated — v0.1.0
- ✓ Analytics views show meaningful consumption insights with line/bar/pie charts — v0.2.0
- ✓ CSV export works for all meter types via system share sheet — v0.2.0 (removed in v0.4.0)
- ✓ 75%+ test coverage maintained — v0.3.0
- ✓ Cost tracking shows accurate cost calculations with tiered pricing — v0.3.0
- ✓ Dark/light/system theme toggle works with full UI consistency — v0.3.0
- ✓ Database backup/restore works via file export/import — v0.3.0
- ✓ German locale: correct number formatting, umlauts, localized month names — v0.3.0
- ✓ Interpolation reworked: values at 1st of month 00:00, toggle visibility — v0.3.0
- ✓ Heating meters assigned to rooms with per-room energy ratio support — v0.3.0
- ✓ In-app language toggle (DE/EN) works independently of device locale — v0.3.0
- ✓ Every meter screen has unified list/analysis bottom navigation with LiquidGlass FAB — v0.4.0
- ✓ Per-household cost profile history with date-based lookup — v0.4.0
- ✓ kWh/EUR (or m3/EUR) toggle on all meter analysis pages — v0.4.0
- ✓ Year comparison chart shows previous year data at correct month positions — v0.4.0
- ✓ Global date format "dd.MM.yyyy, HH:mm Uhr" with localized suffix — v0.4.0
- ✓ New glassmorphism app icon with proper "Valtra" capitalization on home screen — v0.5.0
- ✓ Native splash screen persists until data loaded (no empty-state flicker) — v0.5.0
- ✓ Bottom nav matches XFin LiquidGlass reference design exactly — v0.5.0
- ✓ Chart month abbreviations localized (DE/EN), Y-axis shows units/currency — v0.5.0
- ✓ Home app bar shows only household selector + settings (no redundant title) — v0.5.0
- ✓ Cost profiles: no "Aktiv" badge, German currency always, dd.MM.yyyy date format — v0.5.0
- ✓ Heating has no cost profiles (unitless counters, percentage distribution only) — v0.5.0

### Active
(None — next milestone not yet planned)

### Out of Scope
- Mobile app stores — development/personal use only (App Store requires alpha channel fix)
- Cloud sync — local-first architecture, deferred
- CSV export — removed in v0.4.0, not bringing back
- Heating cost calculation — no access to total building gas consumption; heating meters are unitless proportional counters
- Offline mode complexity — already local-first, no cloud to go offline from

## Context

Shipped v0.5.0 with 56,003 LOC Dart across 5 milestones.
Tech stack: Flutter, Drift (SQLite), Provider, fl_chart, liquid_glass_renderer.
App has custom glassmorphism icon, native splash, LiquidGlass pill nav on all 5 meter screens.
1103 tests passing, DB schema v3.
All v0.5.0 requirements met (16/16), audit passed.

## Key Decisions

| # | Decision | Outcome |
|---|----------|---------|
| 1 | Local-first architecture (Drift/SQLite) | ✓ Good — works offline, fast, no server dependency |
| 2 | LiquidGlass UI from XFin reference | ✓ Good — consistent design language, real glass effects |
| 3 | Ultra Violet + Lemon Chiffon color scheme | ✓ Good — distinctive brand identity |
| 4 | Provider for state management | ✓ Good — simple, sufficient for personal app |
| 5 | fl_chart for charts | ✓ Good — flexible, supports localization |
| 6 | Single main branch | ✓ Good — simple for personal project |
| 7 | German currency always hardcoded | ✓ Good — consistent UX, user is German |
| 8 | Heating as consumption-only | ✓ Good — correct model for unitless proportional counters |
| 9 | CSV export removed (v0.4.0) | — Pending — may revisit if needed |
| 10 | Deprecated GlassBottomNav kept (v0.5.0) | ⚠️ Revisit — clean up in v0.6.0 |

## Technical Debt
1. Deprecated GlassBottomNav/buildGlassFAB in liquid_glass_widgets.dart (remove in v0.6.0)
2. App icon alpha channel (RGBA) — needs remove_alpha_ios if submitting to App Store
3. Duplicate private widgets (_YearNavigationHeader, _YearlySummaryCard) in 4 meter screens
4. 8 info-level deprecation warnings in flutter analyze (deprecated widget refs in test file)

## Repository
- Location: c:\SAPDevelop\Privat\Valtra
- Branch Strategy: main (single branch for personal project)

## Reference Project
- XFin (C:\SAPDevelop\Privat\XFin) - for architecture patterns, LiquidGlass widgets, and CI/CD pipeline

---
*Last updated: 2026-03-13 after v0.5.0 milestone*
