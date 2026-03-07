# Valtra - Development Roadmap

## Milestone 1: Core Foundation (v0.1.0) - COMPLETED
7 phases (Setup, Households, Electricity, Smart Plugs, Water, Gas, Heating) | 313 tests | [Full details](milestones/v0.1.0-ROADMAP.md)

## Milestone 2: Analytics & Visualization (v0.2.0) - COMPLETED
4 phases (Interpolation, Analytics Hub, Yearly + CSV, Smart Plug Analytics) | 625 tests | [Full details](milestones/v0.2.0-ROADMAP.md)

---

## Milestone 3: Polish & Enhancement (v0.3.0)
**Goal**: Refine UI, add cost tracking, backup/restore, and ensure production quality

### Phase 12: Settings & Configuration
**Requirements**: FR-10 (Settings & Theme)
**Dependencies**: Milestone 2 (existing ThemeProvider, InterpolationSettingsProvider)
- [ ] Create SettingsScreen with sections: Theme, Meters, App Info
- [ ] Implement 3-way theme toggle (Light / Dark / System) with immediate preview
- [ ] Consolidate gas kWh conversion and interpolation settings into SettingsScreen
- [ ] Add settings navigation from home screen (gear icon)
- [ ] Audit all screens for dark mode compatibility (fix hardcoded colors)
- [ ] Ensure LiquidGlass widgets render correctly in dark theme
- [ ] Localize all new strings (EN + DE)
- [ ] Comprehensive tests for SettingsScreen and theme switching

### Phase 13: Cost Tracking
**Requirements**: FR-11 (Cost Configuration, Calculation, Display)
**Dependencies**: Phase 12 (SettingsScreen for configuration UI)
- [ ] Design cost configuration database tables (CostConfigs: meter type, household, price tiers, standing charge, valid-from date)
- [ ] Create CostConfigDao with CRUD operations and household isolation
- [ ] Build CostCalculationService: unit price × delta + standing charge + tiered pricing
- [ ] Create CostConfigProvider for state management
- [ ] Build cost configuration forms in settings (per meter type, per household)
- [ ] Display cost alongside consumption in MonthlyAnalyticsScreen
- [ ] Display cost in YearlyAnalyticsScreen with year-over-year cost comparison
- [ ] Add cost summary card to AnalyticsScreen hub
- [ ] Add optional cost column to CSV export
- [ ] Database migration: schema version 1 → 2 (add cost_configs table)
- [ ] Localize all new strings (EN + DE)
- [ ] Comprehensive tests for CostCalculationService (tiers, edge cases)

### Phase 14: UI/UX Polish & Localization
**Requirements**: FR-12 (UI/UX Polish & Localization)
**Dependencies**: Phase 12 (theme system), Phase 13 (cost display widgets)
**Plans:** 7 plans

Plans:
- [x] 14-01-PLAN.md — Foundations: LocaleProvider, ValtraNumberFormat, umlaut fixes, dark mode fix
- [x] 14-02-PLAN.md — Home screen rewrite with GlassBottomNav, LocaleProvider wiring
- [x] 14-03-PLAN.md — Glass widgets rollout to all 13 screens
- [ ] 14-04-PLAN.md — Number formatting cascade across all screens and charts
- [ ] 14-05-PLAN.md — UI element cleanup (badges, icons, hints, pickers, water/smart plug fixes)
- [ ] 14-06-PLAN.md — Analysis screen cleanup (remove daily view, custom range, rename tab)
- [ ] 14-07-PLAN.md — Language toggle in settings, full test suite verification

### Phase 15: Data Model & Analytics Rework
**Requirements**: FR-13 (Data Model & Analytics Rework)
**Dependencies**: Phase 14 (UI cleanup complete)
- [ ] Rework interpolation: calculate values for 1st of each month at 00:00 from nearest real readings
- [ ] Add toggle to show/hide interpolated values in readings list (default: hidden)
- [ ] Color-code interpolated values when visible in list
- [ ] Monthly consumption based on interpolated month-boundary differences
- [ ] Rework smart plug entry: month/year picker + value field (remove interval type + start date)
- [ ] Database migration: add room_id FK to heating meters, remove location field
- [ ] Heating meters: mandatory room assignment (like smart plugs), grouped by room
- [ ] Support two heating use-cases: own gas meter vs. central meter + per-room heating ratios
- [ ] Gas analysis: display in m³ (not kWh conversion)
- [ ] Yearly analysis: extrapolate to year-end, show previous year comparison, monthly breakdown
- [ ] Quick entry mode: batch-add readings without closing dialog
- [ ] Reading validation: new >= previous for cumulative meters
- [ ] Delete confirmation dialogs for readings
- [ ] Localize all new strings (EN + DE)
- [ ] Comprehensive tests for interpolation, smart plug entry, heating rework

### Phase 16: Backup, Testing & Documentation
**Requirements**: FR-14 (Backup & Restore), NFR-10 (Testing)
**Dependencies**: Phase 15 (all features complete)
- [ ] Implement database export: copy SQLite file → share via share_plus
- [ ] Implement database import: file picker → validate → backup current → replace → restart
- [ ] Add backup/restore section to SettingsScreen
- [ ] Achieve 80%+ statement coverage (Codecov integration)
- [ ] Add integration tests for critical flows (reading → analytics → cost)
- [ ] Fill test gaps identified by coverage report
- [ ] Final UI/UX review across light and dark themes
- [ ] Localize backup/restore strings (EN + DE)

---

## Phase Dependencies

```
Milestone 1 (v0.1.0) --> Milestone 2 (v0.2.0) --> Milestone 3 (v0.3.0)
                                                    |
                                    Phase 12 (Settings & Theme)
                                        |
                                    Phase 13 (Cost Tracking)
                                        |
                                    Phase 14 (UI/UX Polish & Localization)
                                      |-- Wave 1: Plan 01 (foundations)
                                      |-- Wave 2: Plan 02, 03 (home screen, glass widgets)
                                      |-- Wave 3: Plan 04, 05, 06 (formatting, cleanup, analytics)
                                      |-- Wave 4: Plan 07 (language toggle, final verification)
                                        |
                                    Phase 15 (Data Model & Analytics Rework)
                                        |
                                    Phase 16 (Backup, Testing & Docs)
```

## Current Status
- **Completed**: Milestone 1 (v0.1.0), Milestone 2 (v0.2.0)
- **Active Milestone**: 3 - Polish & Enhancement (v0.3.0)
- **Active Phase**: 14 - UI/UX Polish & Localization (IN PROGRESS — Plan 03/07 complete)
- **Blockers**: None
