# Requirements: Valtra v0.6.0 — Analytics Redesign

**Defined:** 2026-04-01
**Core Value:** Users can track and analyze utility consumption across multiple households with an intuitive, polished interface

## v0.6.0 Requirements

Requirements for Analytics Redesign milestone. Each maps to roadmap phases.

### Navigation

- [x] **NAV-01**: Month selector replaces year selector on all analytics screens (start at current month, scroll left/right through months)
- [x] **NAV-02**: Remove active dot indicator from bottom navigation bar
- [x] **NAV-03**: FAB integrated into bottom navigation bar (not floating above the pill)

### Home Screen

- [x] **HOME-01**: Redesign household name card replacing blue-purple gradient with frosted glass / liquid glass matching app theme

### Summary Card

- [x] **SUMM-01**: Monthly summary card shows total consumption for selected month with % change vs previous month
- [x] **SUMM-02**: Smart plug coverage line in electricity summary card (kWh + %) shown when smart plug data exists for the month

### Bar Chart

- [x] **BAR-01**: Monthly breakdown bar chart is horizontally scrollable (12 bars visible at a time, scroll for more months)
- [x] **BAR-02**: Current month bar highlighted with glowing edge effect
- [x] **BAR-03**: Past months in opaque meter color, future/extrapolated months in transparent meter color

### Year Comparison

- [x] **YCMP-01**: Previous year shown as dashed line with open points
- [x] **YCMP-02**: Current year shown as solid line with gradient fill underneath (reference: TAKTVERGLEICH style)

### Household Comparison

- [x] **HCMP-01**: New chart comparing consumption across all households as line chart
- [x] **HCMP-02**: Actual values as filled points + solid lines, interpolated/extrapolated as open points + dashed lines

### Axis Redesign

- [x] **AXIS-01**: Remove vertical Y-axis line from all charts
- [x] **AXIS-02**: Small translucent value labels with unit float inside chart area on dashed horizontal grid lines
- [x] **AXIS-03**: Chart content scrolls under fixed axis labels, equal padding on both chart sides

### Electricity Analytics

- [x] **ELEC-01**: Electricity analytics screen uses full new unified design (month nav, summary, bar, year comparison, household comparison)

### Water Analytics

- [ ] **WATR-01**: Water analytics screen uses new unified design with existing blue color scheme

### Gas Analytics

- [ ] **GAS-01**: Gas analytics screen uses new unified design with existing color scheme

### Smart Plug Analytics

- [ ] **SPLG-01**: Smart plug analytics uses new unified design (month nav, summary, bar, year comparison, household comparison)
- [ ] **SPLG-02**: Unified single-hue color scheme (shades of one color) for pie chart and list items
- [ ] **SPLG-03**: Per-plug pie chart + list consumption breakdown
- [ ] **SPLG-04**: Remove room-based consumption grouping (deferred to rooms feature)
- [ ] **SPLG-05**: Smart plug entries displayed in expandable cards with inline editing (same pattern as heating meters), not separate screen

### Heating Analytics

- [ ] **HEAT-01**: Heating analytics uses new unified design (month nav, summary, bar, year comparison, household comparison)
- [ ] **HEAT-02**: Per-heater pie chart + list for percentage distribution

### Household

- [x] **HH-01**: Define number of persons per household (stored in DB, editable in household settings)

### Tech Debt

- [ ] **DEBT-01**: Remove deprecated GlassBottomNav and buildGlassFAB from liquid_glass_widgets.dart
- [x] **DEBT-02**: Deduplicate _YearNavigationHeader and _YearlySummaryCard across meter screens

## Future Requirements

Deferred to later milestones. Tracked but not in current roadmap.

### Rooms Feature
- **ROOM-01**: Room-based smart plug grouping and per-room consumption analysis
- **ROOM-02**: Room assignment for smart plugs

### Per-Capita Analysis
- **PCAP-01**: Per-capita consumption normalization using household person count (requires HH-01 first)
- **PCAP-02**: Per-capita comparison across households

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cloud sync | Local-first architecture, deferred |
| CSV export | Removed in v0.4.0, not bringing back |
| Heating cost calculation | No access to building gas consumption; unitless counters |
| App Store submission | Requires alpha channel fix, personal use only |
| Room-based smart plug grouping | Deferred to rooms feature milestone |
| Per-capita analysis views | Requires HH-01 first, will build on top in future milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| NAV-01 | Phase 27 | Complete |
| NAV-02 | Phase 28 | Complete |
| NAV-03 | Phase 28 | Complete |
| HOME-01 | Phase 28 | Complete |
| SUMM-01 | Phase 27 | Complete |
| SUMM-02 | Phase 29 | Complete |
| BAR-01 | Phase 27 | Complete |
| BAR-02 | Phase 27 | Complete |
| BAR-03 | Phase 27 | Complete |
| YCMP-01 | Phase 27 | Complete |
| YCMP-02 | Phase 27 | Complete |
| HCMP-01 | Phase 27 | Complete |
| HCMP-02 | Phase 27 | Complete |
| AXIS-01 | Phase 27 | Complete |
| AXIS-02 | Phase 27 | Complete |
| AXIS-03 | Phase 27 | Complete |
| ELEC-01 | Phase 29 | Complete |
| WATR-01 | Phase 30 | Pending |
| GAS-01 | Phase 30 | Pending |
| SPLG-01 | Phase 31 | Pending |
| SPLG-02 | Phase 31 | Pending |
| SPLG-03 | Phase 31 | Pending |
| SPLG-04 | Phase 31 | Pending |
| SPLG-05 | Phase 31 | Pending |
| HEAT-01 | Phase 32 | Pending |
| HEAT-02 | Phase 32 | Pending |
| HH-01 | Phase 28 | Complete |
| DEBT-01 | Phase 32 | Pending |
| DEBT-02 | Phase 27 | Complete |

**Coverage:**
- v0.6.0 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0

**Phase distribution:**
- Phase 27: 13 requirements (NAV-01, SUMM-01, BAR-01/02/03, YCMP-01/02, HCMP-01/02, AXIS-01/02/03, DEBT-02)
- Phase 28: 4 requirements (HOME-01, NAV-02, NAV-03, HH-01)
- Phase 29: 2 requirements (ELEC-01, SUMM-02)
- Phase 30: 2 requirements (WATR-01, GAS-01)
- Phase 31: 5 requirements (SPLG-01/02/03/04/05)
- Phase 32: 3 requirements (HEAT-01, HEAT-02, DEBT-01)

---
*Requirements defined: 2026-04-01*
*Last updated: 2026-04-01 after Phase 29 completion*
