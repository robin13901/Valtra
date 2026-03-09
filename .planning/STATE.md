# Valtra - Project State

## Current Status
- **Milestone**: 4 - UX Overhaul (v0.4.0)
- **Last Shipped**: v0.3.0 (2026-03-08)
- **Current Phase**: 21 - Smart Plug Screen Overhaul (complete)
- **Current Plan**: —
- **Last Updated**: 2026-03-09

## Completed Milestones
- **Milestone 1**: Core Foundation (v0.1.0) -- 7 phases, 313 tests
- **Milestone 2**: Analytics & Visualization (v0.2.0) -- 4 phases, 625 tests
- **Milestone 3**: Polish & Enhancement (v0.3.0) -- 5 phases, 1017 tests

## Completed (this milestone)
- **17-01**: Fix household dropdown text color (onSurface theme-aware colors)
- **18**: Cost settings & household configuration (annual Grundpreis, expandable profile cards, household-scoped settings)
- **19**: Electricity screen overhaul (bottom nav, IndexedStack, inline analysis, chart month-alignment fix, kWh/€ toggle)
- **21-01**: Smart Plug screen overhaul (bottom nav Analyse/Liste, monthly-only inline analytics, renamed stats, room percentages, 1070 tests)

## Blocked
_None_

## Session History
| Date | Phase | Action | Notes |
|------|-------|--------|-------|
| 2026-03-08 | — | Milestone 4 initialized | Created REQUIREMENTS.md, updated ROADMAP.md, reset STATE.md. 6 phases planned (17-22). Archived v0.3.0 docs. |
| 2026-03-09 | 17 | Completed 17-01 | Fixed household dropdown text/icon colors for light/dark theme. 5 new tests added. |
| 2026-03-09 | 19 | Phase complete | Electricity screen overhaul: bottom nav (Analyse/Liste), IndexedStack, inline analysis, year chart month-alignment fix, kWh/€ toggle, per-month costs. 1057 tests, 0 analyze issues. |
| 2026-03-09 | 21 | 21-01 complete | Smart Plug screen overhaul: GlassBottomNav, monthly-only inline analytics, renamed stats, room percentages, dense list items. 1070 tests, 0 analyze issues. |

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
14. **Analytics navigation** - Per-meter bottom nav switching (replaces analytics hub + app bar icons)
15. **CSV export removed** - Feature removed in v0.4.0 (was via csv + share_plus)
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
27. **Home hub grid layout** - 2-column GridView of GlassCards, no bottom nav bar (removed in v0.4.0)
28. **Consumer2 for dual providers** - MaterialApp wrapped in Consumer2<ThemeProvider, LocaleProvider> for reactive theme + locale binding
29. **Glass widget title combining** - smart_plug_consumption_screen combines plug name + room name into single title string because buildGlassAppBar has no bottom: parameter
30. **Provider validation returns raw doubles** - validateReading() returns double? instead of formatted String?; screen layer formats with locale context via ValtraNumberFormat
31. **Chart locale parameter with default** - Chart widgets accept optional locale param defaulting to 'de' for backward compatibility
32. **Water type colors** - Cold=blue, Hot=red, Other=grey using Colors.* (not AppColors) for intuitive water type distinction
33. **Interpolation UI removed** - Settings screen no longer exposes interpolation method selection (linear-only decision enforced in code)
34. **Shared MockLocaleProvider test helper** - Defaults to 'en' locale for consistent English-format test assertions
35. **Interpolation toggle in reading lists** - Eye icon in app bar toggles showing/hiding interpolated 1st-of-month boundary values; interpolated entries use Ultra Violet tint + label, non-editable
36. **Month/year dropdown selectors** - Form dialog uses two DropdownButtonFormField<int> (month 1-12, year 2020-current+1) instead of date picker; locale-aware month names via DateFormat.MMMM
37. **Duplicate month warning pattern** - DuplicateMonthChecker callback from screen to provider, inline warning text in error color, allows overwrite
38. **DB migration timezone handling** - Drift stores DateTime as local-time epoch seconds; SQLite 'unixepoch' interprets as UTC. Migration computes Dart timezone offset and applies it to SQL for correct year-month grouping.
39. **Backup service constructor injection** - BackupRestoreService takes `Future<Directory> Function()` params for DB and temp directories, defaulting to path_provider; enables fast deterministic tests without platform channels
40. **Backup validation via sqlite3 package** - Direct sqlite3.open + PRAGMA user_version check for schema version, not Drift overhead
41. **Import = file copy only** - BackupRestoreService.importDatabase copies file but does not manage DB close/reconnect; provider layer handles connection lifecycle
42. **backupExportSuccess l10n key** - Named differently from existing `exportSuccess` (CSV) to avoid collision; backup-specific success message
43. **CircularProgressIndicator test workaround** - Use tester.drag + pump instead of scrollUntilVisible + pumpAndSettle for tests with loading indicators (infinite animation prevents settle)
44. **XFin bottom nav pattern** - LiquidGlassBottomNav with IndexedStack, rightVisibleForIndices for conditional FAB, buildCircleButton for glass FAB
45. **Form dialogs: Cancel + Save only** - "Save & Continue" removed; Cancel and Save buttons side-by-side horizontally
46. **Global date format** - "dd.MM.yyyy, HH:mm Uhr" with localized "Uhr" suffix (DE="Uhr", EN="")
47. **Per-household cost profiles** - Multiple cost configs per meter type per household with valid-from dates; Grundpreis pro Jahr, Arbeitspreis
48. **Electricity screen bottom nav** - Analyse/Liste tabs with IndexedStack; FAB on Liste only; kWh/€ toggle on Analyse only; inline yearly analytics (no separate screen navigation)
49. **Smart plug screen bottom nav** - Analyse/Liste tabs with IndexedStack; FAB on Liste only; inline monthly-only analytics (no separate screen navigation, no yearly period)
50. **Smart plug analytics monthly-only** - Provider simplified: period/year fields removed, always monthly date range
51. **Smart plug stats renamed** - Gesamtverbrauch (totalElectricity), Davon erfasst (totalSmartPlug), Nicht erfasst (otherConsumption)
52. **Room breakdown percentages** - Room items show "X.X kWh (YY%)" format, calculated as room/totalSmartPlug*100

## Technical Debt
1. **LiquidGlass integration** - Using standard Flutter glass-style widgets instead of full liquid_glass_renderer integration
2. ~~**NFR-3.3**: Test coverage not measured with Codecov yet~~ (achieved 75% in v0.3.0)

## Next Actions
_Plan Phase 22 or continue with remaining phases for v0.4.0_
