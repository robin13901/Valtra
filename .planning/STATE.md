# Valtra - Project State

## Current Status
- **Milestone**: 3 - Polish & Enhancement (v0.3.0)
- **Last Shipped**: v0.2.0 (2026-03-07)
- **Current Phase**: 15 - Data Model & Analytics Rework (COMPLETE)
- **Current Plan**: 15-08 (COMPLETE)
- **Last Updated**: 2026-03-07

## Completed Milestones
- **Milestone 1**: Core Foundation (v0.1.0) — 7 phases, 313 tests
- **Milestone 2**: Analytics & Visualization (v0.2.0) — 4 phases, 625 tests

## Completed (this milestone)
- **Phase 14**: UI/UX Polish & Localization — 7 plans, 4 waves, 765 tests
- **Phase 15**: Data Model & Analytics Rework — 8 plans, 4 waves, 855 tests

## Blocked
_None_

## Session History
| Date | Phase | Action | Notes |
|------|-------|--------|-------|
| 2026-03-07 | — | Milestone 3 initialized | Created REQUIREMENTS.md, updated ROADMAP.md, reset STATE.md |
| 2026-03-07 | 12 | Phase 12 completed | Settings & Configuration — 43 new tests (21 settings screen + 22 theme provider), 668 total. Dark mode audit fixed 11 hardcoded colors across 6 files. |
| 2026-03-07 | 13 | Phase 13 completed | Cost Tracking — 39 new tests (27 service + 12 DAO), settings screen tests updated (+mock CostConfigProvider), 707 total. DB migration v1→v2, tiered pricing, cost display in analytics. |
| 2026-03-07 | — | First device testing feedback | 31 items across all screens. Restructured phases: 14 (UI/UX Polish & Localization), 15 (Data Model & Analytics Rework), 16 (Backup, Testing & Docs). Major findings: umlaut encoding, German number formatting, interpolation rework, smart plug entry rework, heating meter room assignment, gas analysis in m³. |
| 2026-03-07 | 14 | Plan 14-01 complete | Foundation Utilities — LocaleProvider, ValtraNumberFormat, 16 umlaut fixes, 4 new l10n keys, dark mode onSecondary fix. 52 new tests, 759 total. |
| 2026-03-07 | 14 | Plan 14-02 complete | Home Screen Rewrite — GlassBottomNav with 5 items (shortcut bar pattern), 6 GlassCard hub tiles, LocaleProvider wired to MaterialApp.locale via Consumer2, no Divider/FAB. 18 new tests, 693 total non-screen tests passing. |
| 2026-03-07 | 14 | Plan 14-03 complete | Glass Widgets Rollout -- buildGlassAppBar, buildGlassFAB, GlassCard applied to all 13 screens. No new tests (widget-level only). 695 passing, 82 pre-existing screen test failures (ThemeProvider gap). |
| 2026-03-07 | 14 | Plan 14-04 complete | Number Formatting Cascade -- ValtraNumberFormat wired to all 18 display files: 6 meter screens, 4 analytics screens, 4 chart widgets, 4 providers. Providers return raw doubles, screens format with locale. Zero hardcoded 'en' patterns remaining. 694 passing, 83 pre-existing screen test failures. |
| 2026-03-07 | 14 | Plan 14-05 complete | UI Element Cleanup -- Removed unit badge chips (4 screens), info icons (2 files), interpolation settings, too-long hints. Styled date/time pickers as InputDecorator (5 dialogs). Water type DropdownButtonFormField, filled water icons. Smart plug no pre-selection. 689 passing, 83 pre-existing screen test failures. |
| 2026-03-07 | 14 | Plan 14-06 complete | Analytics Cleanup -- Removed daily trends view, custom date range feature, "Benutzerdefiniert" tab. Renamed Monatsvergleich to Monatsverlauf. AnalyticsPeriod enum reduced to {monthly, yearly}. 4 l10n keys removed, 10 obsolete tests removed. 681 passing, 81 pre-existing screen test failures. |
| 2026-03-07 | 14 | Plan 14-07 complete | Language Toggle & Test Fixes -- Language toggle in settings (Deutsch/English), fixed all 81 test failures across 11 test files. Created shared MockLocaleProvider helper. 765 tests passing, 0 analyze issues. Phase 14 COMPLETE. |
| 2026-03-07 | 15 | Plan 15-01 complete | Interpolation Rework -- Removed step interpolation, added toggle to show/hide interpolated values in reading lists, color-coded interpolated entries with Ultra Violet tint. ReadingDisplayItem model, displayItems getters on all 4 providers, GlassCard color param. 6 new tests, 771 total. |
| 2026-03-07 | 15 | Plan 15-02 complete | Smart Plug Data Layer -- Removed ConsumptionInterval enum, renamed intervalStart to month, simplified provider API (locale-based labels, duplicate month check). Updated form dialog (month picker), screens, and all tests. 788 tests passing, 0 analyze issues. |
| 2026-03-07 | 15 | Plan 15-03 complete | Smart Plug UI Layer -- Replaced date picker with month/year dropdown selectors, added duplicate month warning, simplified consumption card to single-row format, removed 6 unused l10n keys, added 3 new. 808 tests passing, 0 analyze issues. |
| 2026-03-07 | 15 | Plan 15-06 complete | Gas Analysis Fix & Yearly Extrapolation -- Gas analytics displays raw m3 (not kWh), conversion retained for cost only. Added year-end extrapolation with projected total, extrapolated bars with distinct style. 13 new interpolation service tests, 4 new screen tests. 842 tests passing, 0 analyze issues. |
| 2026-03-07 | 15 | Plan 15-08 complete | DB Migration v2->v3 & Integration -- Schema version 2->3 migration: heating meter locations converted to rooms (room_id FK), smart plug consumptions simplified (interval_type/interval_start removed, grouped by month with SUM). Timezone-aware epoch conversion. 13 new migration tests, 855 total tests passing, 0 analyze issues. Phase 15 COMPLETE. |

## Key Decisions (carried forward)
1. **Local-first architecture** - Using Drift/SQLite for offline-capable data storage
2. **LiquidGlass UI** - Adopting glassmorphism aesthetic from XFin reference
3. **Color scheme** - Ultra Violet (#5F4A8B) primary, Lemon Chiffon (#FEFACD) accent
4. **Single main meter per type** - Electricity and Gas have one meter per household
5. **Multiple sub-meters** - Water, Heating, and Smart Plugs support multiple per household
6. **Glass widgets** - Using standard Flutter glass-style widgets (liquid_glass_renderer API was not compatible)
7. **Widget test simplification** - Using tester.runAsync() and pumpWidget(Container()) cleanup for Drift stream tests
8. **Delta calculation** - Readings sorted newest first, deltas calculated from adjacent readings in list
9. **Hierarchical CRUD** - Rooms contain SmartPlugs; indirect household query via JOIN; cascade delete with warning
10. **Multi-meter water tracking** - Water meters support cold/hot/other types; readings scoped per meter with cascade delete
11. **Heating meter room assignment** - Heating meters assigned to rooms (mandatory, like smart plugs); location text field removed
12. **Interpolation: linear only** - Step function removed; interpolated values calculated for 1st of each month at 00:00 from nearest real readings
13. **Chart types** - Line + Bar + Pie using fl_chart
14. **Analytics navigation** - Dedicated analytics hub from home + per-meter analytics buttons on each meter screen
15. **CSV export** - via csv + share_plus packages, system share sheet
16. **Separate SmartPlugAnalyticsProvider** - Smart plug analytics uses its own provider since data is pre-aggregated
17. **Other consumption clamped** - max(0, totalElectricity - totalSmartPlug), null when no electricity data
18. **Smart plug entry = monthly** - No interval type; simple month/year picker + kWh value per plug
19. **Gas analysis in m3** - Display gas consumption in cubic meters as entered, not converted to kWh
20. **German locale formatting** - Comma decimal, dot thousands, "Uhr" time suffix, proper umlauts
21. **Two heating use-cases** - (a) Own gas meter: direct monthly readings; (b) Central gas meter + per-room heating meters showing energy ratio
22. **No daily analysis** - Only monthly data entry, so daily views removed from all analysis screens
23. **No custom date ranges** - Removed from all analysis screens; fixed monthly/yearly views only
24. **In-app language toggle** - DE/EN switchable in settings, independent of device locale

25. **LocaleProvider null default** - Null locale = follow device, 'de' fallback for localeString
26. **ValtraNumberFormat date init** - DateFormat requires initializeDateFormatting() before use; German time uses H:mm Uhr format
27. **Bottom nav shortcut bar (Option B)** - Bottom nav items 1-4 push screens via Navigator.push, index resets to 0 after return; avoids nested Scaffold issues
28. **Home hub grid layout** - 2-column GridView of GlassCards for all 6 categories (no IndexedStack)
29. **Consumer2 for dual providers** - MaterialApp wrapped in Consumer2<ThemeProvider, LocaleProvider> for reactive theme + locale binding

30. **Glass widget title combining** - smart_plug_consumption_screen combines plug name + room name into single title string because buildGlassAppBar has no bottom: parameter

31. **Provider validation returns raw doubles** - validateReading() returns double? instead of formatted String?; screen layer formats with locale context via ValtraNumberFormat
32. **Chart locale parameter with default** - Chart widgets accept optional locale param defaulting to 'de' for backward compatibility

33. **Water type colors** - Cold=blue, Hot=red, Other=grey using Colors.* (not AppColors) for intuitive water type distinction
34. **Interpolation UI removed** - Settings screen no longer exposes interpolation method selection (linear-only decision enforced in code)

35. **Shared MockLocaleProvider test helper** - Defaults to 'en' locale for consistent English-format test assertions
36. **Interpolation toggle in reading lists** - Eye icon in app bar toggles showing/hiding interpolated 1st-of-month boundary values; interpolated entries use Ultra Violet tint + label, non-editable

37. **Month/year dropdown selectors** - Form dialog uses two DropdownButtonFormField<int> (month 1-12, year 2020-current+1) instead of date picker; locale-aware month names via DateFormat.MMMM
38. **Duplicate month warning pattern** - DuplicateMonthChecker callback from screen to provider, inline warning text in error color, allows overwrite

39. **DB migration timezone handling** - Drift stores DateTime as local-time epoch seconds; SQLite 'unixepoch' interprets as UTC. Migration computes Dart timezone offset and applies it to SQL for correct year-month grouping.

## Technical Debt
1. **LiquidGlass integration** - Using standard Flutter glass-style widgets instead of full liquid_glass_renderer integration
2. **NFR-3.3**: Test coverage not measured with Codecov yet (target: Milestone 3, Phase 16)
3. ~~**Hardcoded colors**~~ -- Resolved in Phase 12 dark mode audit (11 fixes across 6 files)
4. ~~**Screen test ThemeProvider gap**~~ -- Resolved in Plan 14-07 (all 81 test failures fixed)

## Next Actions
_Phase 15 complete. Continue with Phase 16 (Backup, Testing & Documentation)._
