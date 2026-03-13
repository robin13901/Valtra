# Valtra - Project State

## Current Status
- **Milestone**: 5 - Visual & UX Polish (v0.5.0)
- **Last Shipped**: v0.4.0 (2026-03-09)
- **Current Phase**: 24 - Bottom Navigation Redesign (in progress)
- **Current Plan**: 24-01 complete
- **Last Updated**: 2026-03-13
- **Tests**: 1093

Progress: ███░░░░░░░░░░░░░░░░░░░░░░ (3/? plans in milestone)

## Completed Milestones
- **Milestone 1**: Core Foundation (v0.1.0) -- 7 phases, 313 tests
- **Milestone 2**: Analytics & Visualization (v0.2.0) -- 4 phases, 625 tests
- **Milestone 3**: Polish & Enhancement (v0.3.0) -- 5 phases, 1017 tests
- **Milestone 4**: UX Overhaul (v0.4.0) -- 6 phases, 1077 tests

## Completed (this milestone)
- **23-01**: App icon generated (flutter_launcher_icons), app name capitalized to "Valtra" on Android + iOS
- **23-02**: Native splash screen with Ultra Violet (#5F4A8B) background; persists until HouseholdProvider stream fires; eliminates empty-screen flicker
- **24-01**: LiquidGlassBottomNav widget + buildLiquidCircleButton + liquidGlassSettings added to liquid_glass_widgets.dart; 14 new tests; old widgets preserved

## Blocked
_None_

## Session History
| Date | Phase | Action | Notes |
|------|-------|--------|-------|
| 2026-03-13 | 24-01 | Completed plan 01 | LiquidGlassBottomNav + buildLiquidCircleButton + liquidGlassSettings added; key-on-SizedBox fix; 14 new tests; 1093 total. |
| 2026-03-13 | 23-02 | Completed plan 02 | Native splash screen generated (Android pre-12, 12+, iOS, Web); FlutterNativeSplash preserve/remove lifecycle wired in main.dart; 2 new tests. |
| 2026-03-13 | 23-01 | Completed plan 01 | Custom icon generated, app name "Valtra" capitalized on both platforms. |
| 2026-03-13 | — | Milestone 5 initialized | Created REQUIREMENTS.md (16 reqs), updated PROJECT.md, ROADMAP.md with 4 phases (23-26). |

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
53. **Water/heating bottom nav** - Same Analyse/Liste pattern as electricity/gas; water uses m³/€ toggle, heating uses kWh/€ toggle
54. **CostMeterType.heating** - Added as ordinal 3 to intEnum; no DB migration needed (appended at end)
55. **Dead analytics screens removed** - MonthlyAnalyticsScreen and YearlyAnalyticsScreen deleted after all consumers migrated to inline tabs
56. **Heating meters are unitless** - Consumption counters for central heating; show only percentage distribution per room, no cost calculation possible (no access to total building gas consumption)
57. **German currency format always** - Cost displays use German format (123,45 €) regardless of app language setting
58. **Icon source at assets/icon/icon.png** - flutter_launcher_icons reads it directly from filesystem; no flutter.assets declaration needed; regenerate with python assets/icon/generate_icon.py + dart run flutter_launcher_icons
59. **Icon RGBA alpha channel** - Generated PNG has alpha channel; acceptable for development; set remove_alpha_ios: true in pubspec.yaml if submitting to Apple App Store
60. **Splash logo = icon copy** - assets/splash/splash_logo.png copied from assets/icon/icon.png; update later when dedicated brand asset is ready
61. **Splash test listener order** - In testWidgets, removeSplashWhenReady must be called BEFORE tester.pumpWidget; pumpWidget drains the Drift stream event queue, consuming the notification before the listener is added
62. **android_12 splash block mandatory** - flutter_native_splash requires explicit android_12: config block in pubspec.yaml to generate values-v31/styles.xml; without it, Android 12+ shows white flash

63. **LiquidGlassBottomNav key fix** - buildLiquidCircleButton places key on SizedBox when onTap is null (no GestureDetector wrapping); key propagates correctly for testability and widget identification

## Technical Debt
1. ~~**LiquidGlass integration** - Using standard Flutter glass-style widgets instead of full liquid_glass_renderer integration~~ (resolved in 24-01: LiquidGlassBottomNav uses real liquid_glass_renderer)
2. ~~**NFR-3.3**: Test coverage not measured with Codecov yet~~ (achieved 75% in v0.3.0)
3. **Duplicate private widgets** - _YearNavigationHeader and _YearlySummaryCard duplicated in 4 meter screens (electricity, gas, water, heating) — could be extracted to shared widgets

## Next Actions
_Execute phase 24 plan 02: Migrate electricity and smart plug screens to LiquidGlassBottomNav._
