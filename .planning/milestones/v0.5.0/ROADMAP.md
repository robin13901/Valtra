# Milestone v0.5.0: Visual & UX Polish

**Status:** SHIPPED 2026-03-13
**Phases:** 23-26
**Total Plans:** 8

## Overview

Polish the app's visual identity, fix UX issues, and align bottom navigation with XFin reference design.

## Phases

### Phase 23: App Branding & Splash

**Goal**: Set new app icon, capitalize app name on home screen, native splash until data loaded.
**Depends on**: Phase 22 (v0.4.0 complete)
**Plans**: 2 plans

Plans:
- [x] 23-01: App icon generation + app name capitalization (BRAND-01, BRAND-02)
- [x] 23-02: Native splash screen with data-loading gate (LOAD-01)

**Details:**
- Custom 1024x1024 Ultra Violet glassmorphism icon generated via Python Pillow + flutter_launcher_icons
- App name "Valtra" (capital V) fixed in AndroidManifest.xml and iOS Info.plist
- Native splash screen with Ultra Violet (#5F4A8B) background on Android (pre-12 and 12+), iOS, and Web
- Splash persists until HouseholdProvider stream fires first event (no empty-screen flicker)
- 2 new tests for splash lifecycle

**Success Criteria:**
1. App displays new glassmorphism house/gauge icon on Android & iOS
2. Device home screen shows "Valtra" with capital V
3. No empty home screen flicker on app startup — splash persists until households loaded

### Phase 24: Bottom Navigation Redesign

**Goal**: Replicate XFin LiquidGlass bottom nav exactly on all meter screens.
**Depends on**: Phase 23
**Plans**: 3 plans

Plans:
- [x] 24-01: Create LiquidGlassBottomNav widget + tests (NAV-01, NAV-03)
- [x] 24-02: Migrate Smart Plugs + Gas screens to new nav (NAV-04)
- [x] 24-03: Migrate Electricity + Water + Heating screens, deprecate old widgets (NAV-02, NAV-04)

**Details:**
- LiquidGlassBottomNav widget using real liquid_glass_renderer (LiquidGlassLayer + LiquidGlass.grouped)
- buildLiquidCircleButton with LiquidRoundedSuperellipse shape
- liquidGlassSettings context-aware function (dark/light mode)
- Stack+Positioned overlay pattern for all 5 screens
- rightVisibleForIndices: {1} for FAB on Liste tab only
- Old GlassBottomNav and buildGlassFAB deprecated (remove in v0.6.0)
- 14 new widget tests + screen test updates
- Bug fix: key propagation in buildLiquidCircleButton when onTap is null

**Success Criteria:**
1. Bottom nav shows pill shape with glass/blur effect matching XFin design
2. FAB (+button) appears only on Liste tab, hidden on Analyse tab
3. Correct rendering in both light and dark mode
4. All 5 meter screens use the new bottom nav (Strom, Gas, Wasser, Smart Plugs, Heizung)
5. Analyse tab on left, Liste tab on right (matching XFin layout)

### Phase 25: Chart Localization & Labels

**Goal**: Charts display localized month abbreviations and show units/currency on Y-axis.
**Depends on**: Phase 24
**Plans**: 1 plan

Plans:
- [x] 25-01: Localize DateFormat calls in MonthlyBarChart + YearComparisonChart; add Y-axis unit labels (CHART-01, CHART-02, CHART-03)

**Details:**
- DateFormat.MMM(locale) on X-axis and tooltips (German: Jan/Feb/Mrz, English: Jan/Feb/Mar)
- axisNameWidget on leftTitles for Y-axis unit display (kWh, m3, EUR)
- displayUnit computed as: showCosts && costUnit != null ? costUnit! : unit
- 10 new locale/Y-axis tests (5 per chart)

**Success Criteria:**
1. German month abbreviations shown when language=DE
2. English month abbreviations shown when language=EN
3. Y-axis displays unit (kWh, m3) or currency (EUR) depending on active toggle
4. Applied to all analysis pages (Strom, Gas, Wasser)

### Phase 26: Home Screen & Cost Profile Fixes

**Goal**: Clean up home app bar, fix cost profile formatting, correct heating meter understanding.
**Depends on**: Phase 25
**Plans**: 2 plans

Plans:
- [x] 26-01: Remove app bar title, Aktiv badge, hardcode German currency, fix date padding (HOME-01, COST-01, COST-02, COST-03)
- [x] 26-02: Remove CostMeterType.heating and cost toggle from heating screen (COST-04, COST-05)

**Details:**
- Home screen app bar title set to empty string (branding in hub body only)
- Aktiv badge chip + activeConfig computation removed from cost profile tiles
- Currency formatting hardcoded to German locale ('de') regardless of app language
- Date display zero-padded: dd.MM.yyyy (01.03.2026 not 1.3.2026)
- CostMeterType enum reduced to 3 values (electricity, gas, water) — heating removed
- Heating screen consumption-only: no _showCosts, no _buildCostToggle, charts receive showCosts=false
- _toCostMeterType returns null for heating (no cost calculation)
- Net -2 tests (3 heating cost toggle tests removed, 1 new no-toggle assertion added)

**Success Criteria:**
1. Home screen app bar shows only household selector (left) and settings icon (right) — no "Valtra" title
2. No "Aktiv" badge on cost profile cards
3. Currency always displayed in German format (123,45 EUR) regardless of app language
4. "Gueltig ab" date formatted as dd.MM.yyyy (01.03.2026)
5. Heating not available as CostMeterType (no cost profiles for heating)
6. No kWh/EUR toggle on heating analysis page (unitless counters, percentage-only)

---

## Milestone Summary

**Key Decisions:**
- Icon generated via Python Pillow (ImageMagick unavailable on Windows)
- Splash logo reuses app icon (dedicated splash asset deferred)
- android_12 splash block mandatory for modern Android
- LiquidGlassBottomNav uses real liquid_glass_renderer (not CSS-style glassmorphism)
- Chart DateFormat locale always explicit (never rely on system locale)
- German currency format always hardcoded (decision #57)
- CostMeterType.heating removed permanently (DB-safe, no production data)

**Issues Resolved:**
- Empty-screen flicker on app startup (splash lifecycle)
- Inconsistent bottom nav across meter screens (unified LiquidGlassBottomNav)
- System-locale chart labels (now explicit locale parameter)
- Redundant "Valtra" title in app bar (removed)
- Aktiv badge visual clutter (removed)
- Inconsistent date formatting (zero-padded)
- Incorrect heating cost model (heating is unitless, consumption-only)

**Issues Deferred:**
- Deprecated GlassBottomNav/buildGlassFAB removal (v0.6.0)
- App icon alpha channel removal for Apple App Store submission
- Dedicated splash logo design

**Technical Debt Incurred:**
- GlassBottomNav and buildGlassFAB remain in liquid_glass_widgets.dart with @Deprecated annotations (8 info-level warnings in flutter analyze)
- App icon PNG has alpha channel (RGBA) — needs remove_alpha_ios: true for App Store

---

_For current project status, see .planning/ROADMAP.md_
