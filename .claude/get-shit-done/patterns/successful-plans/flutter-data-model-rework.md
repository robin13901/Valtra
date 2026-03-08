---
name: flutter-data-model-rework
domain: db, service, ui, analytics
tech: [flutter, dart, drift, provider, fl_chart, intl, mocktail]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-08
---

## Context
Use this pattern when reworking an existing data model that spans multiple layers (database, DAO, provider, UI, analytics) with schema migration. Applies to scenarios like: simplifying enum columns, replacing text fields with FK relationships, adding computed/display-only data (interpolation toggle, extrapolation), and consolidating DB migrations.

## Pattern

### Phase Structure (8 plans, 4 waves)

| Wave | Plans | Theme |
|------|-------|-------|
| 1 | Service rework (interpolation cleanup) | Foundation: clean up legacy code before building on it |
| 2a | Data layer A + Data layer B (parallel) | Schema + DAO + Provider changes for independent features |
| 2b | UI layer A + UI layer B (parallel) | Screen rework using new data layer from 2a |
| 3 | Analytics fix + Entry enhancements (parallel) | Cross-cutting concerns that touch multiple screens |
| 4 | DB migration + Integration | Single migration for all schema changes, full test verification |

### Key Architectural Decisions

1. **Defer DB migration to final plan**: Change `tables.dart` in individual plans but write the single combined migration in the last plan. Avoids intermediate migration states and ensures all schema changes are atomic.

2. **Data layer before UI layer**: Always complete DAO + Provider changes before touching screens. This allows compilation checks and test verification at each layer.

3. **Parallel data layer plans**: When two features touch independent tables (e.g., smart plugs vs heating meters), plan them as parallel Wave 2a tasks. Each can be developed independently.

4. **ReadingDisplayItem wrapper model**: When adding display-only computed values (interpolated entries) to reading lists, create a wrapper model that contains either real data or computed data with a discriminator flag (`isInterpolated`). Providers expose a `displayItems` getter. Screens render differently based on the flag.

5. **Toggle state in provider, not screen**: Boolean toggles (show/hide interpolated values) live in the provider, not in screen widget state. This allows the toggle to persist across screen rebuilds and be tested independently.

6. **Schema simplification via table recreation**: SQLite doesn't support DROP COLUMN (older versions). Use the CREATE-INSERT-DROP-RENAME pattern:
   ```sql
   CREATE TABLE new_table (...);
   INSERT INTO new_table SELECT ... FROM old_table;
   DROP TABLE old_table;
   ALTER TABLE new_table RENAME TO old_table;
   ```

7. **Duplicate handling in migration**: When consolidating rows (e.g., multiple interval types → single month), use GROUP BY + aggregate (SUM) to merge duplicates in the migration SQL.

8. **Location-to-FK migration**: When replacing a text field with a FK relationship:
   - Step 1: INSERT OR IGNORE into target table from DISTINCT source values
   - Step 2: JOIN back to get new FK IDs
   - Step 3: Recreate source table with FK column
   - Use COALESCE(value, 'Default') for NULL text fields

9. **Extrapolation as separate from interpolation**: Extrapolation (projecting future values) is distinct from interpolation (estimating between known values). Add `extrapolateYearEnd()` as a separate method. Only apply to current year. Mark extrapolated data with `isExtrapolated` flag for distinct visual treatment (lighter opacity + dashed borders).

10. **Shared UI widgets for cross-cutting concerns**: Extract repeated patterns (delete confirmation dialog, quick entry mixin) into shared widgets. Apply via mixin for behavior (QuickEntryMixin) and static factory for dialogs (ConfirmDeleteDialog.show()).

### Task Structure Per Data-Layer Plan

```
T1: Update table definitions (tables.dart) — NO migration code
T2: Update DAO (queries, ordering, new methods)
T3: Update Provider (state management, API simplification)
T4: Update dependent providers (analytics, etc.)
T5: Tests (DAO, provider, analytics)
```

### Task Structure Per UI-Layer Plan

```
T1: Rework form dialog (new inputs, remove old fields)
T2: Rework screen (new layout, grouping, display format)
T3: Localize new strings (EN + DE)
T4: Tests (form, screen, verify no old UI elements)
```

### Task Structure for Migration Plan

```
T1: Write migration SQL (CREATE-INSERT-DROP-RENAME for each table)
T2: Migration tests (data preservation, edge cases, duplicates)
T3: Run code generation (build_runner)
T4: Full integration verification (flutter test + flutter analyze)
T5: Update project tracking documents
```

### Common Pitfalls

1. **Enum removal cascades widely**: Removing an enum from `tables.dart` breaks form dialogs, screens, providers, and tests simultaneously. Fix compilation errors in the same plan rather than deferring.

2. **DateFormat initialization**: `DateFormat.yMMMM(locale)` requires `initializeDateFormatting()` called before first use. Add to `setUpAll` in tests and `main()` in app.

3. **Drift DateTime storage**: Drift stores DateTime as local-time epoch seconds. SQLite's `unixepoch` modifier interprets as UTC. For migration SQL that groups by year-month, compute timezone offset in Dart and apply to SQL.

4. **Month-based entries need duplicate detection**: When switching from flexible intervals to month-based, add a duplicate check method to the DAO (`getConsumptionForMonth()`). Return -1 or show inline warning rather than silently overwriting.

5. **Room FK requires room existence**: When a form requires room selection via FK, guard the FAB/add button with a "no rooms" check and show a message directing users to create rooms first.

6. **Conditional form fields**: When a selector (e.g., heating type) controls visibility of another field (e.g., ratio), use AnimatedSwitcher or simple conditional rendering. Ensure the hidden field's value is null/cleared when switching away.

7. **Analytics ratio application**: Apply ratios AFTER interpolation, not before. Ratios scale the final consumption value, not the raw meter readings.

8. **Extrapolation guard**: Only extrapolate for the current year when `monthlyBreakdown.length < 12`. Past years with partial data should NOT be extrapolated.

9. **Chart visual distinction for computed data**: Use `alpha: 0.3` for lighter bars and `borderDashArray: [6, 3]` for dashed borders to visually distinguish extrapolated/projected data from actual data.

10. **QuickEntryMixin state**: Track entry count and show in dialog title. On "Save & Next": save, clear value field, show brief SnackBar, increment counter. On "Save": save and close.

### Wave Structure

```
Wave 1: Foundation service cleanup
  └── Plan 01: Remove legacy code, add display models
Wave 2a: Parallel data layers (independent tables)
  ├── Plan 02: Table A rework (DAO + Provider)
  └── Plan 04: Table B rework (DAO + Provider)
Wave 2b: Parallel UI layers (depend on 2a)
  ├── Plan 03: Screen A rework (form + display)
  └── Plan 05: Screen B rework (form + display)
Wave 3: Cross-cutting features (depend on Wave 1)
  ├── Plan 06: Analytics fixes + extrapolation
  └── Plan 07: Shared widgets + entry enhancements
Wave 4: Integration (depend on ALL above)
  └── Plan 08: DB migration + full verification
```

### Metrics

- **Phase duration**: 8 plans across 4 waves
- **Tests added**: 90 (765 → 855)
- **UACs verified**: 6/6 PASS
- **Schema version**: v2 → v3
- **Deviations**: 2 minor auto-fixes (compilation cascade from enum removal, DateFormat init in tests)
