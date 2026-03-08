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

### Phase 17: Home Screen & Global UI Fixes
**Requirements**: FR-15 (Home Screen & Global UI Fixes)
**Dependencies**: Milestone 3 (v0.3.0 complete)
- [ ] Fix household dropdown text color in light mode (dark/black text on light background)
- [ ] Remove GlassBottomNav from home screen entirely
- [ ] Remove Analyse tile and AnalyticsScreen (analytics hub) — each meter has its own analysis now
- [ ] Reorder tiles: [Strom, Smart Home] [Gas, Heizung] [Wasser centered]
- [ ] Remove "Save & Continue" button from all form dialogs; Cancel and Save side-by-side only
- [ ] Remove QuickEntryMixin and related logic
- [ ] Global date/time format: "dd.MM.yyyy, HH:mm Uhr" with localized "Uhr" (DE="Uhr", EN="")
- [ ] Remove CSV export feature entirely (buttons, service, dead code)
- [ ] Localize all new/changed strings (EN + DE)
- [ ] Comprehensive tests for all changes

### Phase 18: Cost Settings & Household Configuration
**Requirements**: FR-16 (Cost Settings & Household Configuration)
**Dependencies**: Phase 17 (global UI fixes complete)
- [ ] Extend cost_configs to support multiple profiles per meter type per household (history)
- [ ] Rename fields: "Grundgebühr pro Monat" → "Grundpreis pro Jahr", "Preis pro Einheit" → "Arbeitspreis"
- [ ] Update cost calculation to use annual Grundpreis (÷12 for monthly)
- [ ] Field order in forms: Gültig ab, Grundpreis pro Jahr, Arbeitspreis
- [ ] Card design like water meters: main header per meter type, expandable sub-entries per cost profile
- [ ] Move cost configuration from general settings to household-specific settings
- [ ] Cost lookup by date: calculation uses correct profile for each time period
- [ ] Localize all new/changed strings (EN + DE)
- [ ] Comprehensive tests for cost profile CRUD and date-based lookup

### Phase 19: Electricity Screen Overhaul
**Requirements**: FR-17 (Electricity Screen Overhaul)
**Dependencies**: Phase 18 (cost profiles for kWh/€ toggle)
- [ ] Add LiquidGlass bottom nav: Analyse (left) | Liste (right), default Liste
- [ ] IndexedStack for tab content (preserve state when switching)
- [ ] LiquidGlass FAB (add reading) — visible on Liste tab only
- [ ] Remove app bar analysis icon (now in bottom nav)
- [ ] Consolidate to single analysis page (current yearly view → renamed "Analyse")
- [ ] Remove MonthlyAnalyticsScreen navigation for electricity
- [ ] Fix year comparison chart: previous year line starts at first month with data (not January)
- [ ] Add kWh/€ toggle (top of analysis or in app bar) — switches all charts & values
- [ ] Monthly consumption always from interpolated value deltas at month boundaries
- [ ] Localize all new strings (EN + DE)
- [ ] Tests for bottom nav switching, FAB visibility, toggle state, chart alignment

### Phase 20: Gas Screen Overhaul
**Requirements**: FR-18 (Gas Screen Overhaul)
**Dependencies**: Phase 19 (shared patterns established)
- [ ] Mirror electricity architecture exactly: bottom nav, FAB, single analysis
- [ ] m³/€ toggle (gas displays consumption in m³, cost in €)
- [ ] Fix year comparison chart month alignment
- [ ] Monthly consumption from interpolated deltas
- [ ] Remove app bar analysis icon
- [ ] Localize all new strings (EN + DE)
- [ ] Tests mirroring electricity screen tests

### Phase 21: Smart Plug Screen Overhaul
**Requirements**: FR-19 (Smart Plug Screen Overhaul)
**Dependencies**: Phase 19 (bottom nav pattern established)
- [ ] Add bottom nav: Analyse (left) | Liste (right), default Liste
- [ ] LiquidGlass FAB visible on Liste only
- [ ] Remove app bar analytics icon (pie_chart)
- [ ] Analysis page: monthly-only (no yearly option), month navigation with arrows
- [ ] Rename stats: Gesamtverbrauch, Davon erfasst, Nicht erfasst
- [ ] UI order: month nav → stats card → Verbrauch nach Raum (title, pie, list with %) → Verbrauch nach Steckdose (title, pie, list)
- [ ] Room list items show kWh value + percentage
- [ ] Reduced padding between list items
- [ ] Localize all new/changed strings (EN + DE)
- [ ] Tests for renamed stats, percentage display, UI order

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
- **Active Phase**: None (planning)
- **Next Phase**: 17 — Home Screen & Global UI Fixes
- **Blockers**: None
