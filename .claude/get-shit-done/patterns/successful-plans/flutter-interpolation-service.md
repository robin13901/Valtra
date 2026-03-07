---
name: flutter-interpolation-service
domain: service
tech: [flutter, dart, drift, provider, sharedpreferences]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-07
validated_phases: [8-interpolation-gas-kwh]
---

## Context
Use this pattern when building a pure-logic computation service layer that:
- Performs time-series interpolation between data points
- Converts units (e.g., m³ → kWh)
- Needs user-configurable algorithm settings
- Has NO UI — consumed by analytics screens in later phases
- Works across multiple meter/entity types via generic abstractions

## Pattern

### Tasks

| # | Task | File | Dependencies |
|---|------|------|--------------|
| 1 | Data models | `lib/services/{domain}/models.dart` | None |
| 2 | Core service | `lib/services/{domain}/{domain}_service.dart` | Task 1 |
| 3 | Conversion service | `lib/services/{conversion}_service.dart` | Task 1 |
| 4 | DAO range queries | Modify existing `*_dao.dart` files | None |
| 5 | Entity→Generic converters | `lib/services/{domain}/reading_converters.dart` | Task 1 |
| 6 | Settings provider | `lib/providers/{domain}_settings_provider.dart` | Task 1, 3 |
| 7 | Register provider | `lib/main.dart` | Task 6 |
| 8 | Localization | `lib/l10n/app_*.arb` | None |
| 9 | Tests + Analysis | `flutter test` + `flutter analyze` | All |

### Wave Structure

```
Wave 1 (Parallel — no deps):
  ├── Task 1: Data models
  ├── Task 8: Localization
  └── Task 4: DAO range queries

Wave 2 (Parallel — depends on Task 1):
  ├── Task 2: Core service
  ├── Task 3: Conversion service
  └── Task 5: Entity converters

Wave 3 (Sequential — depends on Wave 2):
  └── Task 6: Settings provider

Wave 4 (Sequential — depends on Task 6):
  └── Task 7: Register provider

Wave 5 (Sequential — depends on all):
  └── Task 9: Tests + analyze
```

### Key Components

#### Generic ReadingPoint typedef
```dart
// Decouple service from Drift entities
typedef ReadingPoint = ({DateTime timestamp, double value});
```

#### Interpolation algorithm
```dart
class InterpolationService {
  double interpolateAt({...}) {
    if (method == InterpolationMethod.step) return valueA;
    final fraction = targetMs / totalMs;
    return valueA + fraction * (valueB - valueA);
  }

  List<TimestampedValue> getMonthlyBoundaries({...}) {
    // 1. Sort + deduplicate readings
    // 2. Generate 1st-of-month targets
    // 3. For each target: exact match → use it, else interpolate, else skip
  }

  List<PeriodConsumption> getMonthlyConsumption({...}) {
    // Derive from consecutive boundary pairs
  }
}
```

#### DAO range query (3-query pattern)
```dart
Future<List<Reading>> getReadingsForRange(
  int scopeId, DateTime rangeStart, DateTime rangeEnd,
) async {
  final before = await getPreviousReading(scopeId, rangeStart);
  final after = await getNextReading(scopeId, rangeEnd);
  final inRange = await (select(table)
    ..where((r) => r.scopeId.equals(scopeId) &
        r.timestamp.isBiggerOrEqualValue(rangeStart) &
        r.timestamp.isSmallerOrEqualValue(rangeEnd))
    ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
    .get();
  return [?before, ...inRange, ?after];
}
```

#### Settings provider (self-init pattern)
```dart
class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  // Use _prefs?.getString() with null-safe access
}
```

### Key Decisions
1. **Pure service layer, no UI** — Service phase ships independently from UI phase
2. **No database storage for computed values** — Interpolated values computed on-demand (no stale data)
3. **Local time for boundaries** — `DateTime(year, month, 1)` uses local time (users think locally)
4. **Generic typedef not class** — `ReadingPoint` as record typedef keeps it lightweight
5. **No extrapolation** — Boundaries outside reading range silently skipped
6. **3-query DAO pattern** — before + in-range + after avoids N+1 queries
7. **Self-init provider** — Matches ThemeProvider pattern with `init()` + `SharedPreferences.getInstance()`
8. **Millisecond precision** — Interpolation uses `inMilliseconds` for accuracy across DST boundaries
9. **Null-aware elements** — Use `[?before, ...inRange, ?after]` instead of `if (x != null) x`

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| Day-based interpolation test precision | Use `inMilliseconds` in both code and tests for consistency |
| `use_null_aware_elements` lint | Use `[?x]` syntax instead of `[if (x != null) x]` |
| Provider references service constant | Ensure Wave ordering: service before provider |
| ARB placeholder syntax | Always add `@key` metadata block for parameterized strings |
| Self-init timing | Call `await provider.init()` in `main()` before `runApp()` |

### Test Coverage

| Component | Test Count | Coverage |
|-----------|------------|----------|
| Data models | 7 | Construction, equality, toString |
| InterpolationService | 21 | Linear/step, boundaries, edge cases, consumption |
| GasConversionService | 8 | Default/custom factor, batch, preservation |
| DAO range queries (4 DAOs) | 16 | In-range, empty, before-only, boundary |
| Reading converters | 9 | All 4 types, empty, order preservation |
| Settings provider | 8 | Defaults, set/get, independence, notifyListeners |
| **Total** | **69+** | Full statement coverage |

### Edge Cases Tested
- Zero readings → empty result
- Single reading on/off boundary
- Sparse data (6-month gaps)
- Out-of-order readings → defensive sort
- Duplicate timestamps → keep last
- No extrapolation past first/last reading
- Step vs linear interpolation mode

### Localization Template

```json
{
  "interpolation": "Interpolation",
  "interpolationMethod": "Interpolation Method",
  "linear": "Linear",
  "step": "Step",
  "interpolated": "Interpolated",
  "actual": "Actual",
  "{unit}Conversion": "{Unit} Conversion",
  "{unit}ConversionFactor": "Conversion Factor",
  "{unit}PerUnit": "{value} {targetUnit}/{sourceUnit}",
  "default{Unit}ConversionFactor": "Default: {value} {targetUnit}/{sourceUnit}"
}
```

### Adaptation Notes
- Replace `InterpolationService` with domain-specific service name
- The `ReadingPoint` typedef works for any timestamped numeric reading
- `GasConversionService` pattern generalizes to any unit conversion (multiply by factor)
- DAO range query pattern works for both household-scoped and meter-scoped entities
- Settings provider pattern works for any per-category preference storage
