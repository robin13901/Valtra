# Valtra - Development Roadmap

## Milestone 1: Core Foundation (v0.1.0) - COMPLETED
7 phases (Setup, Households, Electricity, Smart Plugs, Water, Gas, Heating) | 313 tests | [Full details](milestones/v0.1.0-ROADMAP.md)

---

## Milestone 2: Analytics & Visualization (v0.2.0)
**Goal**: Implement all analytics views with charts and interpolation

### Phase 8: Interpolation Engine
**Requirements**: FR-8
- [ ] Create InterpolationService for linear interpolation
- [ ] Implement interpolated value calculation for any timestamp
- [ ] Add "isInterpolated" flag to reading display
- [ ] Build monthly boundary interpolation (1st of month 00:00)

### Phase 9: Monthly Analytics View
**Requirements**: FR-7.1, FR-7.3
- [ ] Create MonthlyAnalyticsScreen with month navigation
- [ ] Build consumption summary cards for each meter type
- [ ] Implement line chart for consumption trends
- [ ] Show interpolated vs actual values with visual distinction

### Phase 10: Yearly Analytics View
**Requirements**: FR-7.2
- [ ] Create YearlyAnalyticsScreen with year navigation
- [ ] Aggregate monthly data into yearly totals
- [ ] Build year-over-year comparison chart
- [ ] Show monthly breakdown within year view

### Phase 11: Smart Plug Analytics
**Requirements**: FR-7.4, FR-7.5
- [ ] Create SmartPlugAnalyticsScreen
- [ ] Build pie chart for consumption by individual plug
- [ ] Build pie chart for consumption by room
- [ ] Calculate and display "Other" (untracked) consumption
- [ ] Add list view with detailed breakdown

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
**Requirements**: FR-9
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
                                                     ▼
Phase 8 (Interpolation) ───► Phase 9 (Monthly Analytics)
                                        │
                                        ▼
                             Phase 10 (Yearly Analytics)

Phase 11 (Smart Plug Analytics) ───────► Phase 12 (UI Polish)
                                                 │
                                                 ▼
                                         Phase 13 (Data Entry)
                                                 │
                                                 ▼
                                         Phase 14 (Testing)
```

## Current Status
- **Completed**: Milestone 1 (v0.1.0) - Core Foundation
- **Active Milestone**: 2 - Analytics & Visualization
- **Next Phase**: Phase 8 - Interpolation Engine (requires `/gsd:new-milestone` for requirements)
- **Blockers**: None
