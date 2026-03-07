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

### Phase 14: UI/UX Polish & Data Entry
**Requirements**: FR-12 (LiquidGlass, Data Entry)
**Dependencies**: Phase 12 (theme system), Phase 13 (cost display widgets)
- [ ] Replace home screen chip navigation with GlassBottomNav
- [ ] Apply buildGlassFAB to all screens with floating action buttons
- [ ] Apply GlassCard to all list items and summary cards
- [ ] Apply buildGlassAppBar to all screens
- [ ] Implement quick entry mode: batch-add readings without closing dialog
- [ ] Add reading validation (new reading >= previous for cumulative meters)
- [ ] Improve date/time picker: default to now, show last reading as hint
- [ ] Add delete confirmation dialogs for readings
- [ ] Ensure all glass effects work in both light and dark themes
- [ ] Localize all new strings (EN + DE)
- [ ] Widget tests for updated navigation and form enhancements

### Phase 15: Backup, Testing & Documentation
**Requirements**: FR-13 (Backup & Restore), NFR-10 (Testing)
**Dependencies**: Phase 14 (all features complete)
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
Milestone 1 (v0.1.0) ─► Milestone 2 (v0.2.0) ─► Milestone 3 (v0.3.0)
                                                    │
                                    Phase 12 (Settings & Theme)
                                        │
                                    Phase 13 (Cost Tracking)
                                        │
                                    Phase 14 (UI/UX Polish & Data Entry)
                                        │
                                    Phase 15 (Backup, Testing & Docs)
```

## Current Status
- **Completed**: Milestone 1 (v0.1.0), Milestone 2 (v0.2.0)
- **Active Milestone**: 3 - Polish & Enhancement (v0.3.0)
- **Next Phase**: 12 - Settings & Configuration
- **Blockers**: None
