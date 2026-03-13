# Project Milestones: Valtra

## v0.5.0 Visual & UX Polish (Shipped: 2026-03-13)

**Delivered:** Polished visual identity with custom app icon, native splash screen, LiquidGlass bottom navigation, localized chart labels, and cost profile fixes.

**Phases completed:** 23-26 (8 plans total)

**Key accomplishments:**
- Custom glassmorphism app icon (Ultra Violet gradient, house + gauge design) with "Valtra" capitalization on both platforms
- Native splash screen persists until household data loaded, eliminating empty-screen flicker
- LiquidGlassBottomNav using real liquid_glass_renderer deployed to all 5 meter screens with conditional FAB
- Locale-aware chart labels: German/English month abbreviations on X-axis, unit/currency labels on Y-axis
- Home screen app bar cleaned up (no redundant title), cost profiles fixed (German currency, zero-padded dates, no Aktiv badge)
- Heating correctly modeled as consumption-only (unitless counters, no cost profiles, percentage distribution only)

**Stats:**
- 132 files created/modified (+6,987 / -667 lines)
- 56,003 lines of Dart (total codebase)
- 4 phases, 8 plans, 38 commits
- 1103 tests (up from 1077, net +26)
- Single day (2026-03-13)

**Git range:** `docs(23)` → `docs(26)`

**What's next:** TBD — next milestone via `/gsd:new-milestone`

---

## v0.4.0 UX Overhaul (Shipped: 2026-03-09)

**Delivered:** Unified Analyse/Liste bottom nav on all 5 meter screens with per-household cost profiles and year comparison charts.

**Phases completed:** 17-22 (6 phases) | 1077 tests | [Full details](milestones/v0.4.0/ROADMAP.md)

---

## v0.3.0 Polish & Enhancement (Shipped: 2026-03-08)

**Delivered:** Settings, cost tracking, UI/UX polish, data model rework, and backup/restore.

**Phases completed:** 12-16 (5 phases) | 1017 tests | [Full details](milestones/v0.3.0/ROADMAP.md)

---

## v0.2.0 Analytics & Visualization (Shipped: 2026-03-07)

**Delivered:** Interpolation engine, analytics hub, yearly analytics, CSV export, and smart plug analytics.

**Phases completed:** 8-11 (4 phases) | 625 tests | [Full details](milestones/v0.2.0/ROADMAP.md)

---

## v0.1.0 Core Foundation (Shipped: 2026-03-07)

**Delivered:** Project setup, household management, and CRUD for all 5 meter types.

**Phases completed:** 1-7 (7 phases) | 313 tests | [Full details](milestones/v0.1.0/ROADMAP.md)

---
