---
name: flutter-ui-ux-polish-localization
domain: ui, localization, polish
tech: [flutter, dart, intl, provider, shared_preferences, material3]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-07
phase: 14
plans: 7
waves: 4
tests_final: 765
---

## Context

Use this pattern when performing a comprehensive UI/UX polish pass over a Flutter app that includes:
- Adding in-app localization (language toggle)
- Centralizing number/date formatting for locale awareness
- Applying a custom widget library (glass widgets) across all screens
- Cleaning up UI inconsistencies from first device testing
- Removing over-engineered features (daily views, custom date ranges)

## Wave Structure

The key insight: **foundation first, then fan out, then integrate.**

```
Wave 1: Foundation utilities (locale provider, number format service, l10n fixes)
Wave 2: Navigation rewrite + widget rollout (parallel — different file sets)
Wave 3: Formatting cascade + UI cleanup + analytics cleanup (parallel — some overlap, ran sequentially)
Wave 4: Final integration (language toggle UI, fix all broken tests)
```

### Wave Dependencies
- Wave 1 creates LocaleProvider + ValtraNumberFormat that everything else uses
- Wave 2 wires LocaleProvider into MaterialApp and applies glass widgets
- Wave 3 uses ValtraNumberFormat everywhere and cleans up UI
- Wave 4 is the integration wave — defers ALL test fixes to one plan

## Pattern: Deferred Test Fixes

**Critical pattern for multi-plan phases that touch test dependencies:**

When plans 02-06 introduce changes that break screen tests (e.g., adding ThemeProvider/LocaleProvider dependency to glass widgets), do NOT fix tests in each plan. Instead:
- Track test failures per plan in summaries
- Defer ALL test fixes to a final integration plan (Plan 07)
- The integration plan creates a shared mock helper and fixes all tests in one pass

**Why this works:**
- Plans 02-06 would fight over the same test files (merge conflicts)
- Test fixes compound — a fix in Plan 03 might be invalidated by Plan 04
- One comprehensive fix pass is faster than 5 incremental ones
- The final plan has complete context of ALL changes

**Risk:** If the final plan fails, you have 80+ broken tests. Mitigation: the final plan is dedicated entirely to this task.

## Pattern: Centralized Formatting Service

```dart
class ValtraNumberFormat {
  static String consumption(double value, String locale);  // 1 decimal
  static String waterReading(double value, String locale); // 3 decimals
  static String currency(double value, String locale);     // 2 decimals
  static String time(DateTime dt, String locale);          // DE: "9:43 Uhr"
  static String date(DateTime dt, String locale);          // intl DateFormat
  static String monthYear(DateTime dt, String locale);     // intl DateFormat
}
```

**Usage in screens:** `final locale = context.watch<LocaleProvider>().localeString;`
**Usage in chart widgets:** Add `final String locale` parameter with default value

**Key decision:** Providers return raw `double?` from validation, screens format with locale context. This keeps providers locale-independent.

## Pattern: Bottom Nav Shortcut Bar (Option B)

For apps where sub-screens have their own Scaffold+AppBar, avoid nested Scaffolds by using the bottom nav as a shortcut bar:
- Index 0 = home hub (always visible)
- Items 1-4 push screens via `Navigator.push`
- Index resets to 0 after navigation returns
- Home hub shows GlassCard grid for all categories

## Pattern: Glass Widget Systematic Rollout

When applying a custom widget library across all screens:
1. Define the replacement mapping: `AppBar → buildGlassAppBar`, `FAB → buildGlassFAB`, `Card → GlassCard`
2. Process screens in two batches: meter screens (Task 1) + analytics/settings (Task 2)
3. Grep-verify zero remaining instances of old widgets
4. Special cases: widgets without full API parity (e.g., no `bottom:` parameter) need title combining

## Pattern: Feature Removal Pass

When simplifying analytics after device testing:
1. Remove from screens first (UI layer) — commit
2. Remove from providers/models second (data layer) — commit
3. Remove from ARB files last (l10n) — regenerate
4. Remove from tests (update assertions, delete obsolete tests)
5. Grep-verify zero remaining references

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Null locale = follow device, 'de' fallback | Sensible default for German app |
| Consumer2 for dual provider binding | Both theme and locale need reactive MaterialApp rebuild |
| Chart locale param with 'de' default | Backward compatibility without breaking callers |
| Water type colors: blue/red/grey | Intuitive semantic colors for cold/hot/other |
| SegmentedButton for language toggle | Material 3 standard for binary choice |
| InputDecorator for date pickers | Visual consistency with text input fields |
| DropdownButtonFormField over SegmentedButton | Avoids text wrapping issues with long labels |

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Glass widgets need ThemeProvider in tests | Create shared MockThemeProvider + MockLocaleProvider helpers |
| buildGlassAppBar has no `bottom:` param | Combine title + subtitle into single string |
| DateFormat requires initializeDateFormatting() | Call in test setUpAll and app initialization |
| Card→GlassCard breaks `find.byType(Card)` tests | Update finders to `find.byType(GlassCard)` |
| SegmentedButton→Dropdown changes test interaction | Must tap dropdown first, then tap `.last` of target text |
| Removing pre-selected room breaks "save" tests | Add explicit room selection step in tests |
| Providers returning formatted strings couples locale | Return raw doubles, format in screen layer |

## Metrics

| Plan | Duration | Files Modified | Tests Impact |
|------|----------|---------------|--------------|
| 01 Foundation | 8m | 7 | +52 new |
| 02 Home Screen | 16m | 7 | +18 new |
| 03 Glass Rollout | 6m | 13 | 0 (widget only) |
| 04 Number Format | 29m | 23 | 5 updated |
| 05 UI Cleanup | 15m | 16 | -5 obsolete, 6 updated |
| 06 Analytics | 8m | 16 | -10 obsolete |
| 07 Integration | 20m | 12 | +6 new, 81 fixed |
| **Total** | **~102m** | **~50 unique** | **765 final** |
