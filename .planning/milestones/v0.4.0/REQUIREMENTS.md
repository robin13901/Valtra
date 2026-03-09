# Valtra v0.4.0 Requirements — UX Overhaul (ARCHIVED)

**Milestone**: 4 — UX Overhaul (v0.4.0)
**Status**: COMPLETED (2026-03-09)
**Predecessor**: v0.3.0 — Polish & Enhancement (5 phases, 1017 tests)

---

## Functional Requirements

### FR-15: Home Screen & Global UI Fixes — COMPLETED (Phase 17)
- [x] FR-15.1: Household dropdown text color fixed (onSurface theme-aware)
- [x] FR-15.2: Home screen bottom navigation removed
- [x] FR-15.3: Analyse tile and AnalyticsScreen removed
- [x] FR-15.4: Tiles reordered: [Strom, Smart Home] [Gas, Heizung] [Wasser centered]
- [x] FR-15.5: "Save & Continue" removed; Cancel + Save side-by-side only
- [x] FR-15.6: Global date format "dd.MM.yyyy, HH:mm Uhr" with localized suffix
- [x] FR-15.7: CSV export feature removed entirely

### FR-16: Cost Settings & Household Configuration — COMPLETED (Phase 18)
- [x] FR-16.1: Per-household cost profile history with valid-from dates
- [x] FR-16.2: Fields renamed: Grundpreis pro Jahr + Arbeitspreis
- [x] FR-16.3: Form field order: Gültig ab, Grundpreis pro Jahr, Arbeitspreis
- [x] FR-16.4: Expandable card UI per meter type with cost profile sub-entries
- [x] FR-16.5: Cost config moved to household-specific settings

### FR-17: Electricity Screen Overhaul — COMPLETED (Phase 19)
- [x] FR-17.1: Bottom nav (Analyse/Liste) with IndexedStack, default Liste
- [x] FR-17.2: LiquidGlass FAB on Liste only
- [x] FR-17.3: App bar analysis icon removed
- [x] FR-17.4: Single analysis page (consolidated yearly view)
- [x] FR-17.5: Year comparison chart month alignment fixed
- [x] FR-17.6: kWh/€ toggle on analysis page
- [x] FR-17.7: Monthly values from interpolated deltas

### FR-18: Gas Screen Overhaul — COMPLETED (Phase 20)
- [x] FR-18.1: Mirrors electricity architecture (bottom nav, FAB, single analysis, m³/€ toggle, chart fix, interpolated deltas)

### FR-19: Smart Plug Screen Overhaul — COMPLETED (Phase 21)
- [x] FR-19.1: Bottom nav (Analyse/Liste), FAB on Liste only, analytics icon removed
- [x] FR-19.2: Monthly-only analysis with month navigation
- [x] FR-19.3: Stats renamed (Gesamtverbrauch, Davon erfasst, Nicht erfasst)
- [x] FR-19.4: UI order standardized (month nav → stats → room section → plug section)
- [x] FR-19.5: Room breakdown with kWh + percentage, reduced padding

### FR-20: Water Screen Overhaul — COMPLETED (Phase 22)
- [x] FR-20.1: Bottom nav, FAB on Liste only, inline analysis
- [x] FR-20.2: m³/€ toggle, chart month alignment, interpolated deltas

### FR-21: Heating Screen Overhaul — COMPLETED (Phase 22)
- [x] FR-21.1: Bottom nav, FAB on Liste only, inline analysis
- [x] FR-21.2: kWh/€ toggle, chart month alignment, interpolated deltas

---

## Non-Functional Requirements

### NFR-13: Design Preservation — VALIDATED
- [x] Visual design elements preserved; GlassCard, color scheme, layout patterns maintained
- [x] New bottom nav follows XFin LiquidGlass pattern

### NFR-14: Localization — VALIDATED
- [x] All new strings in EN + DE ARB files
- [x] "Uhr" suffix localized; cost field labels localized; smart plug stat labels localized

### NFR-15: Testing — VALIDATED
- [x] 1077 tests passing (60 new tests added, up from 1017)
- [x] Bottom nav, cost toggle, chart alignment, cost profile CRUD all tested

### NFR-16: Code Quality — VALIDATED
- [x] All dead code removed (CSV export, analytics hub, QuickEntryMixin, MonthlyAnalyticsScreen, YearlyAnalyticsScreen)
- [x] Bottom nav pattern reused across 5 meter screens
- [x] Zero flutter analyze issues

---

## User Acceptance Criteria — ALL PASSED

| UAC | Description | Status |
|-----|-------------|--------|
| UAC-M4-1 | Home screen: dark dropdown, no bottom nav, 5 tiles reordered | Passed |
| UAC-M4-2 | Electricity: bottom nav Analyse/Liste, FAB on Liste only | Passed |
| UAC-M4-3 | Electricity analysis: single page, kWh/€ toggle | Passed |
| UAC-M4-4 | Year comparison chart: previous year starts at correct month | Passed |
| UAC-M4-5 | Gas: mirrors electricity architecture, m³/€ toggle | Passed |
| UAC-M4-6 | Smart plugs: monthly-only, renamed stats, percentages | Passed |
| UAC-M4-7 | Water: bottom nav, m³/€ toggle, interpolated deltas | Passed |
| UAC-M4-8 | Heating: bottom nav, kWh/€ toggle, interpolated deltas | Passed |
| UAC-M4-9 | Form dialogs: Cancel + Save only, no "Save & Continue" | Passed |
| UAC-M4-10 | Date format: "dd.MM.yyyy, HH:mm Uhr" (DE) | Passed |
| UAC-M4-11 | Cost config: expandable cards, profile history, household-scoped | Passed |
| UAC-M4-12 | CSV export: fully removed | Passed |
