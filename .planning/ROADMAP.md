# Valtra - Development Roadmap

## Milestone 1: Core Foundation (v0.1.0) - COMPLETED
7 phases (Setup, Households, Electricity, Smart Plugs, Water, Gas, Heating) | 313 tests | [Full details](milestones/v0.1.0/ROADMAP.md)

## Milestone 2: Analytics & Visualization (v0.2.0) - COMPLETED
4 phases (Interpolation, Analytics Hub, Yearly + CSV, Smart Plug Analytics) | 625 tests | [Full details](milestones/v0.2.0/ROADMAP.md)

## Milestone 3: Polish & Enhancement (v0.3.0) - COMPLETED
5 phases (Settings, Cost Tracking, UI/UX Polish, Data Model Rework, Backup & Testing) | 1017 tests | [Full details](milestones/v0.3.0/ROADMAP.md)

## Milestone 4: UX Overhaul (v0.4.0) - COMPLETED
6 phases (Home Screen, Cost Settings, Electricity, Gas, Smart Plugs, Water & Heating) | 1077 tests | [Full details](milestones/v0.4.0/ROADMAP.md)

## Milestone 5: Visual & UX Polish (v0.5.0) - COMPLETED
4 phases (App Branding & Splash, Bottom Nav Redesign, Chart Localization, Home & Cost Fixes) | 1103 tests | [Full details](milestones/v0.5.0/ROADMAP.md)

---

## Milestone 6: Analytics Redesign (v0.6.0) - IN PROGRESS

**Milestone Goal:** Redesign all analytics screens with month-based navigation, scrollable bar charts, refined year/household comparisons, unified axis styling, and screen-specific features (smart plug pie charts, heating distribution, expandable cards).

### Phases

- [x] **Phase 27: Shared Chart Infrastructure** - Reusable chart widgets and month navigation that all analytics screens depend on
- [x] **Phase 28: Home & Nav Polish** - Household card redesign, FAB integration, person count, nav cleanup
- [ ] **Phase 29: Electricity Analytics** - First screen on new shared widgets, establishing the full pattern
- [ ] **Phase 30: Water & Gas Analytics** - Apply unified design to water and gas (same behavior, different colors)
- [ ] **Phase 31: Smart Plug Overhaul** - Analytics redesign + pie chart + expandable cards + unified colors
- [ ] **Phase 32: Heating Analytics & Cleanup** - Heating analytics + distribution pie chart + deprecated widget removal

## Phase Details

### Phase 27: Shared Chart Infrastructure
**Goal**: All reusable chart components and navigation widgets exist and are tested in isolation, ready for screen integration
**Depends on**: Nothing (first phase of milestone)
**Requirements**: NAV-01, SUMM-01, BAR-01, BAR-02, BAR-03, YCMP-01, YCMP-02, HCMP-01, HCMP-02, AXIS-01, AXIS-02, AXIS-03, DEBT-02
**Success Criteria** (what must be TRUE):
  1. Month selector widget navigates backward/forward through months and defaults to current month
  2. Bar chart displays 12 bars at a time, scrolls horizontally, highlights current month with glow, and distinguishes past (opaque) from future (transparent) bars
  3. Year comparison chart renders previous year as dashed line with open points and current year as solid line with gradient fill
  4. Household comparison chart renders actual values as solid lines with filled points and interpolated values as dashed lines with open points
  5. All charts render without vertical Y-axis line, show translucent value labels inside the chart area on grid lines, and scroll content under fixed labels with equal padding
**Plans:** 4 plans
Plans:
- [x] 27-01-PLAN.md -- Chart axis style + month selector + monthly summary card
- [x] 27-02-PLAN.md -- Refactor MonthlyBarChart (scrolling, glow, opacity)
- [x] 27-03-PLAN.md -- Refactor YearComparisonChart + ConsumptionLineChart axis style
- [x] 27-04-PLAN.md -- New HouseholdComparisonChart widget

### Phase 28: Home & Nav Polish
**Goal**: Home screen and navigation bar match the refreshed visual identity, and household person count is stored and editable
**Depends on**: Phase 27 (month selector widget)
**Requirements**: HOME-01, NAV-02, NAV-03, HH-01
**Success Criteria** (what must be TRUE):
  1. Household name card on home screen uses frosted/liquid glass styling (no blue-purple gradient)
  2. Bottom navigation bar has no active dot indicator
  3. FAB is integrated into the bottom navigation bar (not floating above the pill)
  4. User can set and edit number of persons per household in household settings, value persists in database
**Plans:** 3 plans
Plans:
- [x] 28-01-PLAN.md -- Person count data model (DB schema v4, migration, DAO, provider, form dialog)
- [x] 28-02-PLAN.md -- Nav bar polish (remove dot indicator, integrate FAB into pill)
- [x] 28-03-PLAN.md -- Home screen redesign (frosted glass household cards, horizontal carousel)

### Phase 29: Electricity Analytics
**Goal**: Electricity analytics screen uses the complete new unified design, serving as the reference implementation for all other meter screens
**Depends on**: Phase 27 (shared chart widgets), Phase 28 (nav integration)
**Requirements**: ELEC-01, SUMM-02
**Success Criteria** (what must be TRUE):
  1. Electricity analytics screen displays month navigation, monthly summary card, scrollable bar chart, year comparison, and household comparison using shared widgets
  2. Monthly summary card shows total kWh for selected month with % change vs previous month
  3. Smart plug coverage line appears in electricity summary when smart plug data exists for the selected month, showing kWh and percentage of total electricity
**Plans**: TBD

### Phase 30: Water & Gas Analytics
**Goal**: Water and gas analytics screens use the new unified design with their respective color schemes
**Depends on**: Phase 29 (proven pattern from electricity)
**Requirements**: WATR-01, GAS-01
**Success Criteria** (what must be TRUE):
  1. Water analytics screen displays full unified design (month nav, summary, bar chart, year comparison, household comparison) with blue color scheme
  2. Gas analytics screen displays full unified design with existing gas color scheme
  3. Both screens show monthly summary with total consumption and % change vs previous month
**Plans**: TBD

### Phase 31: Smart Plug Overhaul
**Goal**: Smart plug screen uses new analytics design plus unique features: per-plug pie chart, expandable editing cards, and unified color scheme
**Depends on**: Phase 29 (proven pattern from electricity)
**Requirements**: SPLG-01, SPLG-02, SPLG-03, SPLG-04, SPLG-05
**Success Criteria** (what must be TRUE):
  1. Smart plug analytics displays month nav, summary, scrollable bar chart, year comparison, and household comparison using shared widgets
  2. Per-plug pie chart shows consumption breakdown with a unified single-hue color scheme (shades of one color, not rainbow)
  3. Per-plug list breakdown shows each plug's consumption for the selected month
  4. Smart plug entries are displayed in expandable cards with inline editing (same pattern as heating meters), not navigating to a separate screen
  5. Room-based consumption grouping is removed from the UI
**Plans**: TBD

### Phase 32: Heating Analytics & Cleanup
**Goal**: Heating analytics uses new design with percentage distribution, and deprecated widgets are removed from the codebase
**Depends on**: Phase 29 (proven pattern), Phase 31 (expandable card pattern already built)
**Requirements**: HEAT-01, HEAT-02, DEBT-01
**Success Criteria** (what must be TRUE):
  1. Heating analytics displays month nav, summary, scrollable bar chart, year comparison, and household comparison using shared widgets
  2. Per-heater pie chart and list show percentage distribution of unitless counter readings across heaters
  3. Deprecated GlassBottomNav and buildGlassFAB are fully removed from liquid_glass_widgets.dart with no remaining references in the codebase
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 27. Shared Chart Infrastructure | 4/4 | Complete | 2026-04-01 |
| 28. Home & Nav Polish | 3/3 | Complete | 2026-04-01 |
| 29. Electricity Analytics | 0/TBD | Not started | - |
| 30. Water & Gas Analytics | 0/TBD | Not started | - |
| 31. Smart Plug Overhaul | 0/TBD | Not started | - |
| 32. Heating Analytics & Cleanup | 0/TBD | Not started | - |
