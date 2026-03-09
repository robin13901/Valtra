# Phase 17 Context — Home Screen & Global UI Fixes

## Phase Goal
Remove unused features, fix UI inconsistencies, and clean up the home screen — establishing a clean baseline for the Milestone 4 UX overhaul.

## Requirements Coverage
- **FR-15.1**: Fix household dropdown text color (dark text in light mode)
- **FR-15.2**: Remove GlassBottomNav from home screen
- **FR-15.3**: Remove Analyse tile and AnalyticsScreen hub
- **FR-15.4**: Reorder home tiles: [Strom, Smart Home] [Gas, Heizung] [Wasser centered]
- **FR-15.5**: Remove "Save & Continue" from all forms; remove QuickEntryMixin
- **FR-15.6**: Global date/time format "dd.MM.yyyy, HH:mm Uhr" with localized suffix
- **FR-15.7**: Remove CSV export feature entirely
- **NFR-13**: Design preservation — do NOT change visual design
- **NFR-14**: Localization (EN + DE) for all changes
- **NFR-15**: All 1017 existing tests must pass + new tests
- **NFR-16**: Remove dead code, zero flutter analyze issues

## UAC Traceability
| UAC | Description |
|-----|-------------|
| UAC-M4-1 | Home screen: dark dropdown text, no bottom nav, 5 tiles in correct order |
| UAC-M4-9 | Form dialogs: only Cancel + Save side-by-side |
| UAC-M4-10 | Date format: "dd.MM.yyyy, HH:mm Uhr" (DE) / "dd.MM.yyyy, HH:mm" (EN) |
| UAC-M4-12 | No CSV export anywhere |

## Key Codebase Findings

### Home Screen (lib/main.dart)
- HomeScreen at lines 268-547, `_HomeScreenState` with bottom nav logic
- GlassBottomNav at lines 366-391 with 5 nav items
- Tile grid at lines 396-477 using `GridView.count(crossAxisCount: 2)` with 6 tiles
- Analyse tile is 6th tile (lines 465-472), navigates to AnalyticsScreen
- `_onBottomNavTap()` at lines 284-324 handles nav index routing

### Household Selector (lib/widgets/household_selector.dart)
- PopupMenuButton at lines 93-111
- Text has no explicit color: `TextStyle(fontWeight: FontWeight.w500)` — inherits theme
- Icon + Text + arrow_drop_down in Row

### Form Dialogs — QuickEntryMixin (lib/widgets/dialogs/reading_form_base.dart)
- Mixin at lines 12-109 provides `buildQuickEntryActions()` and `handlePostSave()`
- Used by: electricity, gas, water, heating, smart plug reading form dialogs
- Produces 3 buttons in add mode: Cancel | Save & Next | Save
- In edit mode: Cancel | Save

### Date/Time Formatting (lib/services/number_format_service.dart)
- `ValtraNumberFormat.time()` at lines 36-45: DE="H:mm Uhr", EN="HH:mm"
- `ValtraNumberFormat.date()` at lines 49-53: uses `DateFormat.yMMMM(locale)`
- No `dateTime()` combined method exists yet
- Multiple inconsistent DateFormat patterns across screens

### CSV Export
- **csv_export_service.dart**: 3 export methods (monthly, yearly, all meters)
- **share_service.dart**: `shareCsvFile()` uses `share_plus`
- Export buttons on: MonthlyAnalyticsScreen, YearlyAnalyticsScreen, AnalyticsScreen
- Backup also uses share_plus — cannot remove share_plus dependency

### AnalyticsScreen (lib/screens/analytics_screen.dart)
- Hub screen with MeterType overview cards + SmartPlugAnalytics card
- Has export all button, imports CsvExportService + ShareService
- Referenced from main.dart nav index 4 and Analyse tile

### LiquidGlass Components (lib/widgets/liquid_glass_widgets.dart)
- GlassBottomNav, buildCircleButton, buildGlassFAB, buildGlassAppBar, GlassCard
- All theme-aware via ThemeProvider

## Dependencies
- Milestone 3 complete (v0.3.0) — no code dependencies within M4
- share_plus must be KEPT (used by backup)
- AnalyticsProvider stays (used by meter-specific screens)

## Constraints
- Do NOT change any visual design elements (NFR-13)
- All 1017 existing tests must continue to pass
- Zero flutter analyze issues
