# Requirements Archive: v0.5.0 Visual & UX Polish

**Archived:** 2026-03-13
**Status:** SHIPPED

This is the archived requirements specification for v0.5.0.
For current requirements, see `.planning/REQUIREMENTS.md` (created for next milestone).

---

# Requirements: Valtra v0.5.0 — Visual & UX Polish

**Defined:** 2026-03-13
**Core Value:** Users can track and analyze utility consumption across multiple households with an intuitive, polished interface

## v0.5.0 Requirements

### Branding

- [x] **BRAND-01**: App uses new glassmorphism house/gauge icon (provided image asset) — Validated: custom icon generated via Pillow + flutter_launcher_icons
- [x] **BRAND-02**: App name on device home screen shows "Valtra" with capital V — Validated: fixed in AndroidManifest.xml + Info.plist

### Loading

- [x] **LOAD-01**: Native splash screen remains visible until households are fully loaded (no empty-state flicker on startup) — Validated: flutter_native_splash with HouseholdProvider stream gate

### Navigation

- [x] **NAV-01**: Bottom nav bar matches XFin LiquidGlass design exactly (pill shape, glass effect, icon+label tabs) — Validated: LiquidGlassBottomNav using liquid_glass_renderer
- [x] **NAV-02**: FAB (+button) visible only on Liste tab, hidden on Analyse tab — Validated: rightVisibleForIndices: {1}
- [x] **NAV-03**: Bottom nav renders correctly in both light and dark mode — Validated: liquidGlassSettings context-aware function
- [x] **NAV-04**: Bottom nav applied consistently to all 5 meter screens (Strom, Gas, Wasser, Smart Plugs, Heizung) — Validated: Stack+Positioned pattern on all screens

### Charts

- [x] **CHART-01**: Month abbreviations on X-axis are localized per app language (DE: Jan, Feb, Mrz... / EN: Jan, Feb, Mar...) — Validated: DateFormat.MMM(locale)
- [x] **CHART-02**: Y-axis displays unit or currency label (EUR, kWh, m3) depending on active toggle mode — Validated: axisNameWidget on leftTitles
- [x] **CHART-03**: Chart localization applied to Strom, Gas, and Wasser analysis pages — Validated: both chart widgets accept locale parameter

### Home Screen

- [x] **HOME-01**: Home screen app bar shows only household selector (left) and settings icon (right) — no "Valtra" title text — Validated: title set to empty string

### Cost Profiles

- [x] **COST-01**: "Aktiv" badge removed from currently active cost profile card — Validated: Chip + activeConfig computation removed
- [x] **COST-02**: German currency format always used (123,45 EUR) regardless of selected app language — Validated: hardcoded 'de' locale
- [x] **COST-03**: "Gultig ab" date field formatted as dd.MM.yyyy (e.g., 01.03.2026, not 1.3.2026) — Validated: padLeft(2,'0') on day and month
- [x] **COST-04**: Heating removed from CostMeterType — no cost profiles for heating meters — Validated: enum reduced to 3 values
- [x] **COST-05**: kWh/EUR cost toggle removed from heating analysis page (unitless consumption counters show only percentage distribution) — Validated: _showCosts/_buildCostToggle removed

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
| CHART-01 | Phase 25 | Complete |
| CHART-02 | Phase 25 | Complete |
| CHART-03 | Phase 25 | Complete |
| HOME-01 | Phase 26 | Complete |
| COST-01 | Phase 26 | Complete |
| COST-02 | Phase 26 | Complete |
| COST-03 | Phase 26 | Complete |
| COST-04 | Phase 26 | Complete |
| COST-05 | Phase 26 | Complete |

**Coverage:**
- v0.5.0 requirements: 16 total
- Shipped: 16
- Dropped: 0
- Adjusted: 0

---

## Milestone Summary

**Shipped:** 16 of 16 v0.5.0 requirements
**Adjusted:** None — all requirements implemented as originally specified
**Dropped:** None

---
*Archived: 2026-03-13 as part of v0.5.0 milestone completion*
