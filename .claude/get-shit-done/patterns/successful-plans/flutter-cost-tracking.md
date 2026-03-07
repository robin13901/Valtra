---
name: flutter-cost-tracking
domain: service, db, ui, settings
tech: [flutter, dart, drift, provider, mocktail]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-07
---

## Context
When adding cost/pricing tracking to a consumption-based app:
- Per-entity cost configuration (unit price, standing charge, tiered pricing)
- Valid-from date for price history
- Cost calculation as pure business logic (no DB/UI deps)
- Cost display alongside existing analytics
- Cost config UI in settings screen
- Optional cost column in CSV export

## Pattern

### Architecture (4-layer)
```
Database:   CostConfigs table (FK to parent, meter type, price tiers JSON, standing charge, validFrom)
Service:    CostCalculationService (pure functions — flat rate, tiered, pro-rating)
Provider:   CostConfigProvider (ChangeNotifier, reactive stream from DAO)
UI:         Settings form + analytics display integration
```

### Tasks (13 tasks, 6 waves)

**Wave 1 — No dependencies (parallel):**
1. Database table + migration (schema version bump, createTable in onUpgrade)
2. Pure calculation service (no DB/UI imports)
3. Localization strings (EN + DE)
4. Extend analytics models with nullable cost fields

**Wave 2 — Depends on DB table:**
5. DAO with CRUD + getActiveConfig(householdId, meterType, date)
6. Drift code generation (build_runner)

**Wave 3 — Depends on DAO:**
7. Provider (ChangeNotifier, stream subscription, household-scoped)

**Wave 4 — Depends on provider (parallel):**
8. Analytics provider integration (calculate cost per period)
9. Settings screen cost config UI (form per meter type)
10. CSV export optional cost column
11. Wire provider into main.dart

**Wave 5 — Depends on analytics integration:**
12. Cost display in analytics screens

**Wave 6 — Depends on all:**
13. Comprehensive tests + flutter test + flutter analyze

### Key Decisions

1. **Database table over SharedPreferences** — Relational storage needed for household isolation, price tiers, validFrom dates
2. **JSON text column for price tiers** — Up to 3 tiers as `[{"limit": 100, "rate": 0.28}, {"rate": 0.35}]`. Simpler than separate tiers table
3. **ValidFrom date for price changes** — Latest config with validFrom <= query date wins. Historical configs preserved
4. **Pure CostCalculationService** — No DB/UI deps. Takes consumption + config → returns CostResult. Exhaustively testable
5. **Cost is computed, not stored** — Derived from consumption × rate at query time. No data sync issues
6. **Optional nullable cost fields on models** — Fully backward compatible. UI shows cost only when configured
7. **Heating excluded** — Unit-less readings, no cost tracking. Use separate CostMeterType enum
8. **Standing charge pro-rated** — `standingCharge * (daysInPeriod / daysInMonth)` for partial months

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| PriceTier.fromJson fails with integer JSON values | Use `(json['limit'] as num?)?.toDouble()` not `as double?` |
| Adding provider breaks existing widget tests | Must add mock provider to test's MultiProvider tree |
| Settings screen cost section pushes About section off-viewport | Use `scrollUntilVisible` instead of fixed `tester.drag` offset |
| `any()` matcher in mocktail needs fallback values for custom types | `registerFallbackValue(CostMeterType.electricity)` in setUpAll |
| Drift isNull/isNotNull conflicts with flutter_test | `import 'package:drift/drift.dart' hide isNull, isNotNull;` |
| Watch stream test flaky with expectLater | Use manual subscription + Future.delayed + emission list verification |
| Gas cost calculated on wrong unit | Gas consumption already converted to kWh before reaching cost calc |
| Unused variable in test (unused configId from insert) | Remove assignment or prefix with underscore |
| CostConfig type not resolved | Import `app_database.dart` (generated data class), not just `tables.dart` |

### Wave Structure
```
Wave 1: [Table, Service, L10n, Models]     — 4 parallel
Wave 2: [DAO, CodeGen]                      — sequential
Wave 3: [Provider]                          — single
Wave 4: [Analytics, Settings, CSV, Main]   — 4 parallel
Wave 5: [Screen Display]                    — single
Wave 6: [Tests]                             — single
```

### Test Counts
| Area | Tests | Focus |
|------|-------|-------|
| CostCalculationService | 27 | Flat rate, tiers, pro-rating, JSON parse/serialize, edge cases |
| CostConfigDao | 12 | CRUD, isolation, getActiveConfig scenarios, stream, defaults |
| Settings screen | 23 | Rendering, scroll, new provider mock |
| Analytics provider | ~6 | MockCostConfigProvider in existing test files |
| **Total new/modified** | **~68** | |
