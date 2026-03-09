# Valtra - Development Roadmap

## Milestone 1: Core Foundation (v0.1.0) - COMPLETED
7 phases (Setup, Households, Electricity, Smart Plugs, Water, Gas, Heating) | 313 tests | [Full details](milestones/v0.1.0/ROADMAP.md)

## Milestone 2: Analytics & Visualization (v0.2.0) - COMPLETED
4 phases (Interpolation, Analytics Hub, Yearly + CSV, Smart Plug Analytics) | 625 tests | [Full details](milestones/v0.2.0/ROADMAP.md)

## Milestone 3: Polish & Enhancement (v0.3.0) - COMPLETED
5 phases (Settings, Cost Tracking, UI/UX Polish, Data Model Rework, Backup & Testing) | 1017 tests | [Full details](milestones/v0.3.0/ROADMAP.md)

---

## Milestone 4: UX Overhaul (v0.4.0)
**Goal**: Overhaul navigation and screen architecture — unified list/analysis bottom nav on all meter screens, cost profile history per household, remove redundancies, consistent date formatting

### Phase 17: Home Screen & Global UI Fixes - COMPLETED
**Requirements**: FR-15 (Home Screen & Global UI Fixes)
**Dependencies**: Milestone 3 (v0.3.0 complete)
- [x] Fix household dropdown text color in light mode (dark/black text on light background)
- [x] Remove GlassBottomNav from home screen entirely
- [x] Remove Analyse tile and AnalyticsScreen (analytics hub) — each meter has its own analysis now
- [x] Reorder tiles: [Strom, Smart Home] [Gas, Heizung] [Wasser centered]
- [x] Remove "Save & Continue" button from all form dialogs; Cancel and Save side-by-side only
- [x] Remove QuickEntryMixin and related logic
- [x] Global date/time format: "dd.MM.yyyy, HH:mm Uhr" with localized "Uhr" (DE="Uhr", EN="")
- [x] Remove CSV export feature entirely (buttons, service, dead code)
- [x] Localize all new/changed strings (EN + DE)
- [x] Comprehensive tests for all changes

### Phase 18: Cost Settings & Household Configuration - COMPLETED
**Requirements**: FR-16 (Cost Settings & Household Configuration)
**Dependencies**: Phase 17 (global UI fixes complete)
- [x] Extend cost_configs to support multiple profiles per meter type per household (history)
- [x] Rename fields: "Grundgebühr pro Monat" → "Grundpreis pro Jahr", "Preis pro Einheit" → "Arbeitspreis"
- [x] Update cost calculation to use annual Grundpreis (÷12 for monthly)
- [x] Field order in forms: Gültig ab, Grundpreis pro Jahr, Arbeitspreis
- [x] Card design like water meters: main header per meter type, expandable sub-entries per cost profile
- [x] Move cost configuration from general settings to household-specific settings
- [x] Cost lookup by date: calculation uses correct profile for each time period
- [x] Localize all new/changed strings (EN + DE)
- [x] Comprehensive tests for cost profile CRUD and date-based lookup

### Phase 19: Electricity Screen Overhaul - COMPLETED
**Requirements**: FR-17 (Electricity Screen Overhaul)
**Dependencies**: Phase 18 (cost profiles for kWh/€ toggle)
- [x] Add LiquidGlass bottom nav: Analyse (left) | Liste (right), default Liste
- [x] IndexedStack for tab content (preserve state when switching)
- [x] LiquidGlass FAB (add reading) — visible on Liste tab only
- [x] Remove app bar analysis icon (now in bottom nav)
- [x] Consolidate to single analysis page (current yearly view → renamed "Analyse")
- [x] Remove MonthlyAnalyticsScreen navigation for electricity
- [x] Fix year comparison chart: previous year line starts at first month with data (not January)
- [x] Add kWh/€ toggle (top of analysis or in app bar) — switches all charts & values
- [x] Monthly consumption always from interpolated value deltas at month boundaries
- [x] Localize all new strings (EN + DE)
- [x] Tests for bottom nav switching, FAB visibility, toggle state, chart alignment

### Phase 20: Gas Screen Overhaul - COMPLETED
**Requirements**: FR-18 (Gas Screen Overhaul)
**Dependencies**: Phase 19 (shared patterns established)
- [x] Mirror electricity architecture exactly: bottom nav, FAB, single analysis
- [x] m³/€ toggle (gas displays consumption in m³, cost in €)
- [x] Fix year comparison chart month alignment
- [x] Monthly consumption from interpolated deltas
- [x] Remove app bar analysis icon
- [x] Localize all new strings (EN + DE)
- [x] Tests mirroring electricity screen tests

### Phase 21: Smart Plug Screen Overhaul (COMPLETE)
**Requirements**: FR-19 (Smart Plug Screen Overhaul)
**Dependencies**: Phase 19 (bottom nav pattern established)
**Plans:** 1 plan (1/1 complete)
Plans:
- [x] 21-01-PLAN.md — Bottom nav, inline monthly-only analysis, renamed stats, percentages, localization, tests
- [x] Add bottom nav: Analyse (left) | Liste (right), default Liste
- [x] LiquidGlass FAB visible on Liste only
- [x] Remove app bar analytics icon (pie_chart)
- [x] Analysis page: monthly-only (no yearly option), month navigation with arrows
- [x] Rename stats: Gesamtverbrauch, Davon erfasst, Nicht erfasst
- [x] UI order: month nav → stats card → Verbrauch nach Raum (title, pie, list with %) → Verbrauch nach Steckdose (title, pie, list)
- [x] Room list items show kWh value + percentage
- [x] Reduced padding between list items
- [x] Localize all new/changed strings (EN + DE)
- [x] Tests for renamed stats, percentage display, UI order

### Phase 22: Water & Heating Screen Overhaul
**Requirements**: FR-20 (Water), FR-21 (Heating)
**Dependencies**: Phase 19 (bottom nav pattern), Phase 18 (cost profiles for toggle)
- [ ] Water: add bottom nav (Analyse | Liste), default Liste, FAB on Liste only
- [ ] Water analysis: year nav, summary, monthly bar chart, year comparison chart, m³/€ toggle
- [ ] Water monthly values from interpolated deltas at month boundaries
- [ ] Heating: add bottom nav (Analyse | Liste), default Liste, FAB on Liste only
- [ ] Heating analysis: year nav, summary, monthly bar chart, year comparison chart, kWh/€ toggle
- [ ] Heating monthly values from interpolated deltas at month boundaries
- [ ] Fix year comparison chart month alignment for both
- [ ] Localize all new strings (EN + DE)
- [ ] Tests for both screens: nav, toggle, chart alignment

---

## Phase Dependencies

```
Milestone 3 (v0.3.0) --> Milestone 4 (v0.4.0)
                           |
           Phase 17 (Home Screen & Global UI Fixes)
               |
           Phase 18 (Cost Settings & Household Config)
               |
           Phase 19 (Electricity Screen Overhaul)
             /    \
      Phase 20   Phase 21       Phase 22
      (Gas)    (Smart Plugs)  (Water & Heating)

      Phase 20, 21, 22 can be parallelized after Phase 19
```

## Current Status
- **Completed**: Milestone 1 (v0.1.0), Milestone 2 (v0.2.0), Milestone 3 (v0.3.0)
- **Active Milestone**: 4 — UX Overhaul (v0.4.0)
- **Active Phase**: 22 — Water & Heating Screen Overhaul
- **Next Phase**: —
- **Blockers**: None
