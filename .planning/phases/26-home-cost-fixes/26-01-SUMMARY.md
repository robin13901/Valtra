---
phase: 26-home-cost-fixes
plan: 01
subsystem: ui
tags: [flutter, dart, cost-profiles, app-bar, number-format, date-format]

# Dependency graph
requires:
  - phase: 25-chart-localization
    provides: locale-aware chart widgets and number format patterns
provides:
  - Home screen app bar with empty title (no Valtra text in app bar)
  - Cost profile tiles without Aktiv/Active badge chip
  - Currency values hardcoded to German locale (de) on cost profile tiles
  - Zero-padded dd.MM.yyyy date display in cost profile form dialog
affects: [future cost profile work, home screen modifications]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "German currency hardcode: ValtraNumberFormat.currency(value, 'de') always, never dynamic locale"
    - "Zero-pad date: day.toString().padLeft(2, '0').month.toString().padLeft(2, '0') for dd.MM.yyyy"

key-files:
  created: []
  modified:
    - lib/main.dart
    - lib/screens/household_cost_settings_screen.dart
    - lib/widgets/dialogs/cost_profile_form_dialog.dart
    - test/widget_test.dart
    - test/screens/household_cost_settings_screen_test.dart
    - test/widgets/dialogs/cost_profile_form_dialog_test.dart

key-decisions:
  - "HOME-01: App bar title set to empty string '' -- Valtra text stays in hub body only"
  - "COST-01: Chip/Aktiv badge removed entirely from _buildProfileTile; activeConfig computation also removed"
  - "COST-02: LocaleProvider removed from HouseholdCostSettingsScreen; currency hardcoded to 'de'"
  - "COST-03: padLeft(2,'0') on day and month in dialog matches existing list tile format"

patterns-established:
  - "App bar title: empty string for screens that show branding only in body"
  - "Currency display: always 'de' locale regardless of app language setting (decision #57)"
  - "Date display: dd.MM.yyyy with zero-padding in all cost profile contexts"

# Metrics
duration: 8min
completed: 2026-03-13
---

# Phase 26 Plan 01: Home Screen & Cost Profile Fixes Summary

**Empty app bar title, removed Aktiv badge chip from cost tiles, hardcoded German currency, and zero-padded dd.MM.yyyy date in cost profile form dialog**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-13T16:44:07Z
- **Completed:** 2026-03-13T16:52:15Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- HOME-01: Home screen app bar now shows no title text (title: '')
- COST-01: Chip/Aktiv badge removed from _buildProfileTile; LocaleProvider dependency removed from screen
- COST-02: Currency formatting hardcoded to 'de' locale -- 123,45 format always, regardless of app language
- COST-03: Date in cost profile form dialog now shows dd.MM.yyyy (01.06.2024 not 1.6.2024)

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove app bar title + remove Aktiv badge + hardcode German currency** - `231af12` (feat)
2. **Task 2: Fix date format in cost profile form dialog to dd.MM.yyyy** - `9941ead` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `lib/main.dart` - buildGlassAppBar title changed from l10n.appTitle to ''
- `lib/screens/household_cost_settings_screen.dart` - Removed Chip block, LocaleProvider import, activeConfig computation; hardcoded 'de' in currency calls
- `lib/widgets/dialogs/cost_profile_form_dialog.dart` - Added padLeft(2,'0') to day and month in date display text
- `test/widget_test.dart` - Updated 'shows app title in AppBar' test to verify empty title, not 'Valtra'
- `test/screens/household_cost_settings_screen_test.dart` - Updated badge tests to assert Chip never shown (COST-01)
- `test/widgets/dialogs/cost_profile_form_dialog_test.dart` - Fixed date format assertions + added zero-padding test

## Decisions Made
- **App bar title empty**: The 'Valtra' branding text appears in the home hub body (headlineMedium text widget at ~line 366) and stays there; only the AppBar title is cleared. Test updated accordingly to assert the AppBar.title widget contains '' not 'Valtra'.
- **activeConfig computation removed**: Since the Aktiv badge is gone, the entire `activeConfig` loop in `_CostMeterTypeCardState.build()` was dead code and was also removed.
- **LocaleProvider import removed**: After hardcoding 'de', LocaleProvider was no longer referenced in the screen; import removed to keep the file clean.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The 'does not show Valtra title text in AppBar' test initially used `find.text('Valtra')` which found the body text widget (headlineMedium). Fixed by inspecting `AppBar.title` directly instead of searching the full widget tree.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 26-01 complete (4/4 fixes: HOME-01, COST-01, COST-02, COST-03)
- 1105 tests passing, zero new analyzer issues
- Ready for plan 26-02

---
*Phase: 26-home-cost-fixes*
*Completed: 2026-03-13*
