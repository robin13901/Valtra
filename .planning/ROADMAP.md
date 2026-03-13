# Valtra - Development Roadmap

## Milestone 1: Core Foundation (v0.1.0) - COMPLETED
7 phases (Setup, Households, Electricity, Smart Plugs, Water, Gas, Heating) | 313 tests | [Full details](milestones/v0.1.0/ROADMAP.md)

## Milestone 2: Analytics & Visualization (v0.2.0) - COMPLETED
4 phases (Interpolation, Analytics Hub, Yearly + CSV, Smart Plug Analytics) | 625 tests | [Full details](milestones/v0.2.0/ROADMAP.md)

## Milestone 3: Polish & Enhancement (v0.3.0) - COMPLETED
5 phases (Settings, Cost Tracking, UI/UX Polish, Data Model Rework, Backup & Testing) | 1017 tests | [Full details](milestones/v0.3.0/ROADMAP.md)

## Milestone 4: UX Overhaul (v0.4.0) - COMPLETED
6 phases (Home Screen, Cost Settings, Electricity, Gas, Smart Plugs, Water & Heating) | 1077 tests | [Full details](milestones/v0.4.0/ROADMAP.md)

## Milestone 5: Visual & UX Polish (v0.5.0) - ACTIVE

**Goal:** Polish the app's visual identity, fix UX issues, and align bottom navigation with XFin reference design.

### Phase 23: App Branding & Splash — COMPLETED

**Goal:** Set new app icon, capitalize app name on home screen, native splash until data loaded.

**Requirements:** BRAND-01, BRAND-02, LOAD-01

**Plans:** 2 plans

Plans:
- [x] 23-01-PLAN.md — App icon generation + app name capitalization (BRAND-01, BRAND-02)
- [x] 23-02-PLAN.md — Native splash screen with data-loading gate (LOAD-01)

**Success Criteria:**
1. App displays new glassmorphism house/gauge icon on Android & iOS
2. Device home screen shows "Valtra" with capital V
3. No empty home screen flicker on app startup — splash persists until households loaded

### Phase 24: Bottom Navigation Redesign — COMPLETED

**Goal:** Replicate XFin LiquidGlass bottom nav exactly on all meter screens.

**Requirements:** NAV-01, NAV-02, NAV-03, NAV-04

**Plans:** 3 plans

Plans:
- [x] 24-01-PLAN.md — Create LiquidGlassBottomNav widget + tests (NAV-01, NAV-03)
- [x] 24-02-PLAN.md — Migrate Smart Plugs + Gas screens to new nav (NAV-04)
- [x] 24-03-PLAN.md — Migrate Electricity + Water + Heating screens, deprecate old widgets (NAV-02, NAV-04)

**Success Criteria:**
1. Bottom nav shows pill shape with glass/blur effect matching XFin design
2. FAB (+button) appears only on Liste tab, hidden on Analyse tab
3. Correct rendering in both light and dark mode
4. All 5 meter screens use the new bottom nav (Strom, Gas, Wasser, Smart Plugs, Heizung)
5. Analyse tab on left, Liste tab on right (matching XFin layout)

### Phase 25: Chart Localization & Labels — COMPLETED

**Goal:** Charts display localized month abbreviations and show units/currency on Y-axis.

**Requirements:** CHART-01, CHART-02, CHART-03

**Plans:** 1 plan

Plans:
- [x] 25-01-PLAN.md — Localize DateFormat calls in MonthlyBarChart + YearComparisonChart; add Y-axis unit labels (CHART-01, CHART-02, CHART-03)

**Success Criteria:**
1. German month abbreviations shown when language=DE (Mar, Dez instead of Mar, Dec)
2. English month abbreviations shown when language=EN
3. Y-axis displays unit (kWh, m3) or currency (EUR) depending on active toggle
4. Applied to all analysis pages (Strom, Gas, Wasser)

### Phase 26: Home Screen & Cost Profile Fixes

**Goal:** Clean up home app bar, fix cost profile formatting, correct heating meter understanding.

**Requirements:** HOME-01, COST-01, COST-02, COST-03, COST-04, COST-05

**Success Criteria:**
1. Home screen app bar shows only household selector (left) and settings icon (right) — no "Valtra" title
2. No "Aktiv" badge on cost profile cards
3. Currency always displayed in German format (123,45 EUR) regardless of app language
4. "Gueltig ab" date formatted as dd.MM.yyyy (01.03.2026)
5. Heating not available as CostMeterType (no cost profiles for heating)
6. No kWh/EUR toggle on heating analysis page (unitless counters, percentage-only)

---

## Current Status
- **Completed**: Milestone 1 (v0.1.0), Milestone 2 (v0.2.0), Milestone 3 (v0.3.0), Milestone 4 (v0.4.0)
- **Active Milestone**: Milestone 5 — Visual & UX Polish (v0.5.0)
- **Next Phase**: Phase 26 — Home Screen & Cost Profile Fixes
