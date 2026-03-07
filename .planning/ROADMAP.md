# Valtra - Development Roadmap

## Milestone 1: Core Foundation (v0.1.0) - COMPLETED
7 phases (Setup, Households, Electricity, Smart Plugs, Water, Gas, Heating) | 313 tests | [Full details](milestones/v0.1.0-ROADMAP.md)

---

## Milestone 2: Analytics & Visualization (v0.2.0)
**Goal**: Implement interpolation engine, analytics views with charts, smart plug breakdown, CSV export, and carry-forward items (gas kWh, smart plug aggregation UI)

### Phase 8: Interpolation Engine & Gas kWh Conversion
**Requirements**: FR-8, FR-9.1
**Dependencies**: Milestone 1 (all meter DAOs)
- [ ] Create `InterpolationService` with linear interpolation for continuous meters (electricity, gas, water)
- [ ] Add step function interpolation for non-continuous meters (heating)
- [ ] Implement user-configurable interpolation method per meter type (setting stored locally)
- [ ] Build monthly boundary interpolation (1st of month, 00:00) across all meter types
- [ ] Add `isInterpolated` flag to interpolated values for display distinction
- [ ] Handle edge cases: single reading, multi-month spans, sparse data, no extrapolation
- [ ] Add gas kWh conversion service with configurable factor (default 10.3 kWh/m³)
- [ ] Comprehensive unit tests for interpolation and gas conversion
- [ ] Localize all new strings (EN + DE)

### Phase 9: Analytics Hub & Monthly Analytics
**Requirements**: FR-7.1, FR-7.3
**Dependencies**: Phase 8 (interpolation service)
- [ ] Create `AnalyticsScreen` hub accessible from home screen (analytics icon/button)
- [ ] Build cross-meter overview cards showing latest consumption summaries
- [ ] Create `MonthlyAnalyticsScreen` with month navigation (forward/back)
- [ ] Build line chart for daily consumption trends within selected month (fl_chart)
- [ ] Build bar chart comparing consumption across recent months
- [ ] Visually distinguish interpolated vs actual values (dashed/solid, markers)
- [ ] Add custom date range picker for analytics filtering
- [ ] Wire per-meter analytics buttons on each meter type screen
- [ ] Add analytics provider(s) for data aggregation
- [ ] Comprehensive widget and unit tests
- [ ] Localize all new strings (EN + DE)

### Phase 10: Yearly Analytics & CSV Export
**Requirements**: FR-7.2, FR-7.5
**Dependencies**: Phase 9 (analytics infrastructure, charts)
- [ ] Create `YearlyAnalyticsScreen` with year navigation
- [ ] Build bar chart of monthly breakdown within selected year
- [ ] Build year-over-year comparison chart when multi-year data exists
- [ ] Aggregate monthly interpolated values into yearly totals
- [ ] Implement CSV export service (using `csv` package)
- [ ] Add share functionality via `share_plus` for generated CSV files
- [ ] Support per-meter and all-meters CSV export options
- [ ] CSV columns: meter type, date, value, delta, interpolated flag
- [ ] Add export button to analytics screens
- [ ] Comprehensive unit and widget tests
- [ ] Localize all new strings (EN + DE)

### Phase 11: Smart Plug Analytics
**Requirements**: FR-7.4, FR-9.2
**Dependencies**: Phase 9 (analytics infrastructure), Phase 4 DAO aggregation methods
**Plans:** 2 plans

Plans:
- [x] 11-01-PLAN.md — Data models, SmartPlugAnalyticsProvider, ConsumptionPieChart widget (Wave 1)
- [x] 11-02-PLAN.md — SmartPlugAnalyticsScreen, navigation wiring, localization, provider registration (Wave 2)

---

## Milestone 3: Polish & Enhancement (v0.3.0)
**Goal**: Refine UI, add convenience features, ensure production quality

### Phase 12: LiquidGlass UI Polish
**Requirements**: NFR-4
- [ ] Implement LiquidGlassBottomNav for main navigation
- [ ] Add LiquidGlass FAB for quick actions
- [ ] Style dialogs and forms with glass aesthetic
- [ ] Ensure consistent theming throughout app

### Phase 13: Data Entry Enhancements
**Requirements**: FR-10 (TBD)
- [ ] Implement quick entry mode for batch readings
- [ ] Add validation (reading >= previous)
- [ ] Improve date/time picker UX
- [ ] Add recently used values suggestions

### Phase 14: Testing & Documentation
**Requirements**: NFR-3
- [ ] Achieve 80%+ code coverage
- [ ] Add integration tests for critical flows
- [ ] Document codebase (README, architecture)
- [ ] Final UI/UX review and fixes

---

## Phase Dependencies

```
Milestone 1 (v0.1.0) ──────────────────────────────┐
  Phases 1-7 COMPLETED                              │
                                                     v
Phase 8 (Interpolation + Gas kWh) ───► Phase 9 (Analytics Hub + Monthly)
                                                     │
                                          ┌──────────┤
                                          v          v
                             Phase 10 (Yearly+CSV)  Phase 11 (Smart Plug Analytics)

Phase 12 (UI Polish) ───► Phase 13 (Data Entry) ───► Phase 14 (Testing)
```

## Current Status
- **Completed**: Milestone 1 (v0.1.0), Phases 8-11 (Interpolation, Analytics Hub, Yearly + CSV, Smart Plug Analytics)
- **Active Milestone**: 2 - Analytics & Visualization (v0.2.0) - COMPLETED
- **Active Phase**: None - Milestone 2 complete
- **Blockers**: None
