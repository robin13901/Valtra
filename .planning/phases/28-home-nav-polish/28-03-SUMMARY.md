---
phase: 28-home-nav-polish
plan: 03
subsystem: ui
tags: [flutter, frosted-glass, BackdropFilter, PageView, carousel, household, personCount, l10n]

# Dependency graph
requires:
  - phase: 28-01
    provides: personCount field on Household model (schema v4)
  - phase: 28-02
    provides: LiquidGlassBottomNav with inline FAB (no left params)
provides:
  - HomeScreen as StatefulWidget with PageController
  - Horizontal PageView carousel for households (viewportFraction 0.92)
  - _HouseholdCard with BackdropFilter frosted glass, no gradient
  - personCount display (singular/plural) with people_outline icon
  - Reverse-sync: external HouseholdSelector scrolls carousel to card
  - person/persons l10n keys in EN and DE
  - 18 home screen tests covering carousel, glass styling, bento grid
affects: [29-analytics-screens, 30-household-management, home-screen-redesign]

# Tech tracking
tech-stack:
  added: [dart:ui (ImageFilter.blur)]
  patterns:
    - StatefulWidget with PageController for carousel bi-directional sync
    - BackdropFilter + ClipRRect for frosted glass card (no gradient)
    - Consumer<HouseholdProvider> in carousel builder with reverse-sync via addPostFrameCallback

key-files:
  created:
    - test/screens/home_screen_test.dart
  modified:
    - lib/main.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_de.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_de.dart

key-decisions:
  - "BackdropFilter sigmaX/Y=16 for frosted glass; no LinearGradient in household section"
  - "Reverse-sync uses addPostFrameCallback to avoid animating during build"
  - "Inline constants (BorderRadius.circular(20), padding 20) instead of missing Radii/Spacing/Shadows classes"
  - "AppColors.ultraViolet.withValues(alpha: 0.2) as border color since darkBorder/lightBorder not defined"

patterns-established:
  - "frosted-glass-card: ClipRRect + BackdropFilter + Container with semi-opaque surface color"
  - "carousel-sync: PageController in state, reverse-sync in Consumer builder via addPostFrameCallback"
  - "tester.runAsync wrapper for all widget tests involving Drift stream providers"

# Metrics
duration: 36min
completed: 2026-04-01
---

# Phase 28 Plan 03: Frosted Glass Household Carousel Summary

**Horizontal PageView carousel replacing text-only household display with BackdropFilter frosted glass cards showing personCount, bi-directional sync with HouseholdSelector**

## Performance

- **Duration:** 36 min
- **Started:** 2026-04-01T11:16:24Z
- **Completed:** 2026-04-01T11:52:29Z
- **Tasks:** 2
- **Files modified:** 7 (created 1)

## Accomplishments
- Converted HomeScreen from StatelessWidget to StatefulWidget with PageController (viewportFraction: 0.92)
- Created _HouseholdCard widget using BackdropFilter (sigma 16) for frosted glass - zero gradient
- Displayed personCount with people_outline icon and singular/plural l10n ("1 Person" / "N Persons")
- Added bi-directional carousel/selector sync: swiping updates selectedHouseholdId; external selector change animates carousel to new card
- Added empty state frosted glass card for no-households scenario
- Added person/persons l10n keys to app_en.arb (Person/Persons) and app_de.arb (Person/Personen)
- Created 18 test cases covering all plan requirements

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace gradient header with frosted glass household carousel** - `496f209` (feat)
2. **Task 2: Add tests for home screen household card and carousel** - `ac4100c` (test)

**Plan metadata:** (see final docs commit)

## Files Created/Modified
- `lib/main.dart` - HomeScreen → StatefulWidget, _HouseholdCard widget, carousel, empty state
- `lib/l10n/app_en.arb` - Added person/persons keys
- `lib/l10n/app_de.arb` - Added person/Personen keys
- `lib/l10n/app_localizations.dart` - Regenerated with person/persons getters
- `lib/l10n/app_localizations_en.dart` - Regenerated
- `lib/l10n/app_localizations_de.dart` - Regenerated
- `test/screens/home_screen_test.dart` - 18 tests (created)

## Decisions Made
- Used `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))` inside `ClipRRect` for the glass effect; no `LinearGradient` in household section
- Inline constants (`BorderRadius.circular(20)`, `padding: 20`) instead of missing `Radii`/`Spacing`/`Shadows` design system classes (these don't exist in this codebase yet)
- `AppColors.ultraViolet.withValues(alpha: 0.2)` as default border color since `AppColors.darkBorder`/`lightBorder` are not defined
- Reverse-sync uses `WidgetsBinding.instance.addPostFrameCallback` to avoid animating during active build cycle
- Tests use `tester.runAsync` pattern to handle Drift stream subscription pending timers

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Substituted missing design-system constants**
- **Found during:** Task 1 (implementing _HouseholdCard)
- **Issue:** Plan referenced `Radii.xlBR`, `Shadows.cardMedium`, `Spacing.space20/space4`, `AppColors.darkBorder/lightBorder` which are not defined anywhere in the codebase
- **Fix:** Used inline `BorderRadius.circular(20)`, `const EdgeInsets.all(20)`, `const EdgeInsets.symmetric(horizontal: 4, vertical: 8)`, and `AppColors.ultraViolet.withValues(alpha: 0.2)` as direct substitutes
- **Files modified:** lib/main.dart
- **Verification:** `flutter analyze` zero errors; visual result identical to plan description
- **Committed in:** 496f209 (Task 1 commit)

**2. [Rule 1 - Bug] Fixed test assertion for household name finding 2 widgets**
- **Found during:** Task 2 (running tests)
- **Issue:** `find.text('My Apartment')` found 2 widgets - one in _HouseholdCard (headlineMedium) and one in HouseholdSelector dropdown; `findsOneWidget` assertion failed
- **Fix:** Changed to `findsWidgets` for household name presence check, added more specific `fontWeight: w700` check to verify it's in the carousel card's headlineMedium slot
- **Files modified:** test/screens/home_screen_test.dart
- **Verification:** All 18 tests pass
- **Committed in:** ac4100c (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 missing constants, 1 test assertion fix)
**Impact on plan:** Both fixes necessary. Design system constants will be defined when the full design token system is introduced. Test fix accurately captures the intended behavior.

## Issues Encountered
- Pre-existing worktree was behind on 28-01 and 28-02 commits (merged from parallel branches before starting this plan)
- Initial test run hung indefinitely without `tester.runAsync` - applied the same pattern used throughout the codebase for Drift stream tests

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Home screen household section redesigned and tested
- PersonCount now visible on home screen (HOME-01, HH-01 display)
- No gradient - frosted glass pattern established for future use
- Phase 29+ analytics screens can consume carousel pattern

---
*Phase: 28-home-nav-polish*
*Completed: 2026-04-01*
