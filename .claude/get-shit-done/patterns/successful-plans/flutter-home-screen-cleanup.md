---
name: flutter-home-screen-cleanup
domain: ui, cleanup
tech: [flutter, dart, material3, provider, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-09
---

## Context
Use this pattern when removing features (CSV export, analytics hub, quick entry), simplifying UI (removing bottom nav, reordering tiles), and standardizing global formatting (date/time format with locale). Applicable to any Flutter app undergoing a UX cleanup phase.

## Pattern

### Tasks

#### Wave 1: Independent Cleanup (parallel)
- Fix theme-dependent colors (use `Theme.of(context).colorScheme.onSurface`)
- Remove dead feature (QuickEntryMixin, Save & Continue → Cancel + Save only)
- Remove dead feature (CSV export: service, buttons, dependency, ARB keys)

#### Wave 2: Screen Overhaul (sequential)
- Remove navigation elements (bottom nav bar, tiles)
- Delete unused screens + tests
- Reorder remaining tiles/cards

#### Wave 3: Global Formatting
- Add locale-aware dateTime formatter to utility class
- Replace all DateFormat usages in screens with centralized formatter
- Handle locale suffix ("Uhr" in DE, empty in EN) via hardcoded locale check (simpler than ARB)

#### Wave 4: Verification
- `flutter pub run build_runner build --delete-conflicting-outputs` after ARB changes
- `flutter test` + `flutter analyze`
- grep for dead imports/references

### Key Decisions
1. **Feature removal order**: UI (screens/buttons) → providers → ARB keys → tests
2. **ARB key removal**: defer keys still referenced by other screens; remove in the phase that deletes the last consumer
3. **Date format**: hardcode locale check in utility rather than ARB key — keeps service layer l10n-dependency-free
4. **Grid tile centering**: Column of Rows > GridView for odd-count grids (avoids left-aligned last tile)

### Common Pitfalls
- Removing pubspec dependency (csv) while keeping share_plus (still used by backup) — verify each dep's consumers
- ARB key removal requires `build_runner` before tests — stale generated l10n files cause false failures
- QuickEntryMixin may be mixed into multiple dialogs — search all `with QuickEntryMixin` not just the first hit
- `DateFormat('dd.MM.yyyy', locale)` always uses dots regardless of locale — safe for consistent format

### Wave Structure
```
Wave 1 (parallel): Theme fix, QuickEntry removal, CSV removal
Wave 2 (sequential): Home screen overhaul (depends on CSV removal for clean import graph)
Wave 3 (independent): Global date format
Wave 4: Verification
```
