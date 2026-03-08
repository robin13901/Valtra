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
- [x] 14-04-PLAN.md -- Number formatting cascade across all screens and charts
- [x] 14-05-PLAN.md -- UI element cleanup (badges, icons, hints, pickers, water/smart plug fixes)
- [x] 14-06-PLAN.md -- Analysis screen cleanup (remove daily view, custom range, rename tab)
- [x] 14-07-PLAN.md -- Language toggle in settings, full test suite verification (765 tests, 0 failures)

### Phase 15: Data Model & Analytics Rework
**Requirements**: FR-13 (Data Model & Analytics Rework)
**Dependencies**: Phase 14 (UI cleanup complete)
**Plans:** 8 plans

Plans:
- [x] 15-01-PLAN.md — Interpolation rework: cleanup step function, toggle visibility, color-code interpolated values
- [x] 15-02-PLAN.md — Smart plug data layer: remove interval type, month-based schema, DAO + provider updates
- [x] 15-03-PLAN.md — Smart plug UI layer: month/year picker form, consumption screen rework
- [x] 15-04-PLAN.md — Heating meter data layer: room FK, heating type + ratio, DAO + provider + analytics
- [x] 15-05-PLAN.md — Heating meter UI layer: room dropdown, heating type selector, group-by-room screen
- [x] 15-06-PLAN.md — Gas analysis fix (m3 not kWh) & yearly analysis rework (extrapolation, previous year)
- [x] 15-07-PLAN.md — Data entry enhancements: quick entry mode, real-time validation, shared delete confirmation
- [x] 15-08-PLAN.md — DB migration v2→v3 consolidation, integration testing, project state update

### Phase 16: Backup, Testing & Documentation
**Requirements**: FR-14 (Backup & Restore), NFR-10 (Testing)
**Dependencies**: Phase 15 (all features complete)
**Plans:** 4 plans

Plans:
- [x] 16-01-PLAN.md -- BackupRestoreService + unit tests (TDD): export, import, validation, sharing
- [x] 16-02-PLAN.md -- UI integration: provider, settings screen section, localization (EN + DE), app restart
- [x] 16-03-PLAN.md -- Coverage analysis + test gap filling (75% coverage, 146 new tests)
- [x] 16-04-PLAN.md -- Integration tests for critical flows + final verification + project state update

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
                                      |-- Wave 1: Plan 01 (interpolation rework)
                                      |-- Wave 2a: Plan 02, 04 (smart plug + heating data layer)
                                      |-- Wave 2b: Plan 03, 05 (smart plug + heating UI layer)
                                      |-- Wave 3: Plan 06, 07 (gas/yearly analysis + data entry)
                                      |-- Wave 4: Plan 08 (DB migration, integration, cleanup)
                                        |
                                    Phase 16 (Backup, Testing & Docs)
                                      |-- Wave 1: Plan 01 (service TDD), Plan 03 (coverage)
                                      |-- Wave 2: Plan 02 (UI integration)
                                      |-- Wave 3: Plan 04 (integration tests, final verification)
```

## Current Status
- **Completed**: Milestone 1 (v0.1.0), Milestone 2 (v0.2.0), Milestone 3 (v0.3.0)
- **Active Milestone**: None (all milestones complete)
- **Active Phase**: None
- **Next Phase**: None planned
- **Blockers**: None
