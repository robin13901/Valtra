# Valtra v0.4.0 Roadmap — UX Overhaul (ARCHIVED)

**Milestone**: 4 — UX Overhaul (v0.4.0)
**Status**: COMPLETED (2026-03-09)
**Goal**: Overhaul navigation and screen architecture — unified list/analysis bottom nav on all meter screens, cost profile history per household, remove redundancies, consistent date formatting

## Stats
- **Phases**: 6 (17-22)
- **Commits**: 43
- **Tests**: 1077 (up from 1017)
- **Source**: 78 files (27,482 LOC)
- **Test Files**: 81 files (24,887 LOC)

---

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

### Phase 21: Smart Plug Screen Overhaul - COMPLETED
**Requirements**: FR-19 (Smart Plug Screen Overhaul)
**Dependencies**: Phase 19 (bottom nav pattern established)
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

### Phase 22: Water & Heating Screen Overhaul - COMPLETED
**Requirements**: FR-20 (Water), FR-21 (Heating)
**Dependencies**: Phase 19 (bottom nav pattern), Phase 18 (cost profiles for toggle)
- [x] Water: add bottom nav (Analyse | Liste), default Liste, FAB on Liste only
- [x] Water analysis: year nav, summary, monthly bar chart, year comparison chart, m³/€ toggle
- [x] Water monthly values from interpolated deltas at month boundaries
- [x] Heating: add bottom nav (Analyse | Liste), default Liste, FAB on Liste only
- [x] Heating analysis: year nav, summary, monthly bar chart, year comparison chart, kWh/€ toggle
- [x] Heating monthly values from interpolated deltas at month boundaries
- [x] Fix year comparison chart month alignment for both
- [x] Remove dead MonthlyAnalyticsScreen and YearlyAnalyticsScreen
- [x] Localize all new strings (EN + DE)
- [x] Tests for both screens: nav, toggle, chart alignment

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

## Key Accomplishments
1. Unified bottom nav (Analyse/Liste) on all 5 meter screens with IndexedStack state preservation
2. Per-household cost profile history with date-based lookup (Grundpreis pro Jahr + Arbeitspreis)
3. kWh/€ (or m³/€) cost toggle on 4 meter analysis pages
4. Year comparison chart fixed — calendar month alignment instead of array index
5. Dead code removal — CSV export, analytics hub, MonthlyAnalyticsScreen, YearlyAnalyticsScreen, QuickEntryMixin
6. Global date format "dd.MM.yyyy, HH:mm Uhr" with locale support
