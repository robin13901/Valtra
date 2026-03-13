# Requirements: Valtra v0.5.0 — Visual & UX Polish

**Defined:** 2026-03-13
**Core Value:** Users can track and analyze utility consumption across multiple households with an intuitive, polished interface

## v0.5.0 Requirements

### Branding

- [x] **BRAND-01**: App uses new glassmorphism house/gauge icon (provided image asset)
- [x] **BRAND-02**: App name on device home screen shows "Valtra" with capital V

### Loading

- [x] **LOAD-01**: Native splash screen remains visible until households are fully loaded (no empty-state flicker on startup)

### Navigation

- [x] **NAV-01**: Bottom nav bar matches XFin LiquidGlass design exactly (pill shape, glass effect, icon+label tabs)
- [x] **NAV-02**: FAB (+button) visible only on Liste tab, hidden on Analyse tab
- [x] **NAV-03**: Bottom nav renders correctly in both light and dark mode
- [x] **NAV-04**: Bottom nav applied consistently to all 5 meter screens (Strom, Gas, Wasser, Smart Plugs, Heizung)

### Charts

- [ ] **CHART-01**: Month abbreviations on X-axis are localized per app language (DE: Jan, Feb, Mär, Apr, Mai, Jun, Jul, Aug, Sep, Okt, Nov, Dez / EN: Jan, Feb, Mar...)
- [ ] **CHART-02**: Y-axis displays unit or currency label (€, kWh, m³) depending on active toggle mode
- [ ] **CHART-03**: Chart localization applied to Strom, Gas, and Wasser analysis pages

### Home Screen

- [ ] **HOME-01**: Home screen app bar shows only household selector (left) and settings icon (right) — no "Valtra" title text

### Cost Profiles

- [ ] **COST-01**: "Aktiv" badge removed from currently active cost profile card
- [ ] **COST-02**: German currency format always used (123,45 €) regardless of selected app language
- [ ] **COST-03**: "Gültig ab" date field formatted as dd.MM.yyyy (e.g., 01.03.2026, not 1.3.2026)
- [ ] **COST-04**: Heating removed from CostMeterType — no cost profiles for heating meters
- [ ] **COST-05**: kWh/€ cost toggle removed from heating analysis page (unitless consumption counters show only percentage distribution)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Heating cost calculation | No access to total building gas consumption; heating meters are unitless proportional counters |
| New meter types | Not in this polish milestone |
| Cloud sync | Local-first architecture, deferred |
| CSV export resurrection | Removed in v0.4.0, not bringing back |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRAND-01 | Phase 23 | Complete |
| BRAND-02 | Phase 23 | Complete |
| LOAD-01 | Phase 23 | Complete |
| NAV-01 | Phase 24 | Complete |
| NAV-02 | Phase 24 | Complete |
| NAV-03 | Phase 24 | Complete |
| NAV-04 | Phase 24 | Complete |
| CHART-01 | Phase 25 | Pending |
| CHART-02 | Phase 25 | Pending |
| CHART-03 | Phase 25 | Pending |
| HOME-01 | Phase 26 | Pending |
| COST-01 | Phase 26 | Pending |
| COST-02 | Phase 26 | Pending |
| COST-03 | Phase 26 | Pending |
| COST-04 | Phase 26 | Pending |
| COST-05 | Phase 26 | Pending |

**Coverage:**
- v0.5.0 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-13*
*Last updated: 2026-03-13 after phase 24 completion*
