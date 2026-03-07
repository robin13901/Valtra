# Phase 13 Plan — Cost Tracking

**Phase**: 13 of 15
**Milestone**: 3 — Polish & Enhancement (v0.3.0)
**Requirements**: FR-11 (Cost Configuration, Calculation, Display), NFR-9.1 (Performance), NFR-12.1 (Data Integrity)
**Goal**: Add cost tracking to the app — persist per-household cost configurations in the database (unit price, standing charge, tiered pricing, valid-from date), calculate costs from consumption deltas, display cost alongside consumption in monthly/yearly analytics and the analytics hub, and add an optional cost column to CSV export.

---

## Architecture Overview

```
Database Layer (new)
  ├── CostConfigs table (householdId, meterType, priceTiers JSON, standingCharge, validFrom)
  └── CostConfigDao (CRUD, household isolation, getActiveConfig)

Service Layer (new)
  └── CostCalculationService (pure business logic)
      ├── calculateMonthlyCost(consumption, config) → CostResult
      ├── calculateWithTiers(consumption, tiers) → double
      └── selectConfig(configs, date) → CostConfig? (valid-from matching)

Provider Layer (new)
  └── CostConfigProvider (ChangeNotifier)
      ├── Per-household cost configs (stream from DB)
      ├── getActiveConfig(MeterType, DateTime) → CostConfig?
      └── CRUD methods → CostConfigDao

Analytics Integration (modified)
  ├── AnalyticsProvider — calculates cost alongside consumption
  ├── MonthlyAnalyticsData — adds totalCost, periodCosts
  ├── YearlyAnalyticsData — adds totalCost, previousYearTotalCost
  ├── MeterTypeSummary — adds latestMonthCost
  └── CsvExportService — optional cost column

UI Layer (modified)
  ├── SettingsScreen — new "Cost Configuration" section
  ├── MonthlyAnalyticsScreen — cost display in summary card
  ├── YearlyAnalyticsScreen — cost in yearly summary + YoY comparison
  └── AnalyticsScreen (hub) — cost in overview cards
```

---

## Key Decisions

1. **Database table, not SharedPreferences** — Cost configs include tiered pricing, valid-from dates, and household isolation. This requires relational storage. Schema version 1 → 2 migration.
2. **JSON for price tiers** — Store up to 3 tiers as a JSON text column (`[{"limit": 100, "rate": 0.28}, {"limit": 300, "rate": 0.32}, {"rate": 0.35}]`). Simpler than a separate tiers table for max 3 entries.
3. **Valid-from date for price changes** — Each CostConfig has a `validFrom` date. When calculating cost for a month, select the config with the latest `validFrom` that is <= the period start. This supports price changes over time without modifying historical configs.
4. **CostCalculationService is pure** — No DB or UI dependencies. Takes consumption + config, returns cost. Easy to test exhaustively.
5. **Cost is computed, not stored** — Cost values are derived at query time from consumption × rate. No cost table needed. This avoids data sync issues when configs change.
6. **Currency is display-only** — Store currency symbol as a string in CostConfig (default "€"). No currency conversion logic. Localized formatting via `NumberFormat.currency()`.
7. **Cost display is optional** — If no cost config exists for a meter type, cost fields are null and UI shows consumption only (no "€0.00" noise).
8. **Heating excluded from cost** — Heating meters use unit-less readings. Cost configuration applies to electricity, gas, and water only (`CostMeterType` enum).
9. **Standing charge pro-rated** — For partial months (e.g., mid-month price change), standing charge is pro-rated by days in the period vs days in the month.

---

## Task Breakdown

### Task 1: Database — CostConfigs table + migration
**Files**: `lib/database/tables.dart`, `lib/database/app_database.dart`
**Dependencies**: None
**Effort**: Medium

**New table in `tables.dart`**:
```dart
/// Meter types that support cost tracking (heating excluded — unit-less)
enum CostMeterType { electricity, gas, water }

/// Cost configuration per meter type per household
@DataClassName('CostConfig')
class CostConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  IntColumn get meterType => intEnum<CostMeterType>()();
  RealColumn get unitPrice => real()(); // €/kWh or €/m³
  RealColumn get standingCharge => real().withDefault(const Constant(0.0))(); // monthly €
  TextColumn get priceTiers => text().nullable()(); // JSON: [{"limit": 100, "rate": 0.28}, ...]
  TextColumn get currencySymbol => text().withDefault(const Constant('€'))();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

**Changes in `app_database.dart`**:
- Add `CostConfigs` to `@DriftDatabase(tables: [...])` list
- Add `CostConfigDao` to `daos: [...]` list
- Bump `schemaVersion` to `2`
- Add migration from version 1 → 2: `CREATE TABLE cost_configs (...)`

**Migration strategy**:
```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => await m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.createTable(costConfigs);
    }
  },
);
```

Run `dart run build_runner build --delete-conflicting-outputs` after changes.

**Acceptance**: Schema version 2, `cost_configs` table created on fresh install and via migration from v1.

### Task 2: CostConfigDao — CRUD with household isolation
**File**: `lib/database/daos/cost_config_dao.dart` (new)
**Dependencies**: Task 1
**Effort**: Medium

```dart
@DriftAccessor(tables: [CostConfigs, Households])
class CostConfigDao extends DatabaseAccessor<AppDatabase> with _$CostConfigDaoMixin {
  CostConfigDao(super.db);

  /// Insert a new cost config.
  Future<int> insertConfig(CostConfigsCompanion config);

  /// Update an existing cost config.
  Future<bool> updateConfig(CostConfig config);

  /// Delete a cost config by ID.
  Future<int> deleteConfig(int id);

  /// Get all configs for a household (all meter types, ordered by validFrom DESC).
  Future<List<CostConfig>> getConfigsForHousehold(int householdId);

  /// Watch all configs for a household (reactive stream).
  Stream<List<CostConfig>> watchConfigsForHousehold(int householdId);

  /// Get configs for a specific meter type in a household.
  Future<List<CostConfig>> getConfigsForMeterType(int householdId, CostMeterType meterType);

  /// Get the active config for a meter type at a given date.
  /// Returns the config with the latest validFrom <= date.
  Future<CostConfig?> getActiveConfig(int householdId, CostMeterType meterType, DateTime date);
}
```

**Household isolation**: All queries filter by `householdId`, matching existing DAO pattern.

**Acceptance**: All CRUD methods work, `getActiveConfig` returns correct config based on `validFrom` date.

### Task 3: CostCalculationService — pure business logic
**File**: `lib/services/cost_calculation_service.dart` (new)
**Dependencies**: None (can be built in parallel with Tasks 1-2)
**Effort**: Medium

```dart
/// Result of a cost calculation for a period.
class CostResult {
  final double unitCost;      // consumption × rate (possibly tiered)
  final double standingCost;  // standing charge (possibly pro-rated)
  final double totalCost;     // unitCost + standingCost
  final String currencySymbol;

  const CostResult({...});
}

/// A single pricing tier.
class PriceTier {
  final double? limit;  // null = unlimited (last tier)
  final double rate;    // price per unit

  const PriceTier({this.limit, required this.rate});

  factory PriceTier.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

class CostCalculationService {
  const CostCalculationService();

  /// Calculate cost for a consumption period.
  CostResult calculateMonthlyCost({
    required double consumption,
    required double unitPrice,
    required double standingCharge,
    required String currencySymbol,
    List<PriceTier>? tiers,
    int daysInPeriod = 30,
    int daysInMonth = 30,
  });

  /// Apply tiered pricing to consumption.
  /// Tiers are cumulative: first X units at rate A, next Y at rate B, rest at rate C.
  double calculateWithTiers(double consumption, List<PriceTier> tiers);

  /// Parse price tiers from JSON string.
  List<PriceTier> parseTiers(String? tiersJson);

  /// Serialize price tiers to JSON string.
  String? serializeTiers(List<PriceTier>? tiers);
}
```

**Tiered pricing logic**:
```
Tier 1: first 100 kWh at €0.28/kWh → max €28.00
Tier 2: next 200 kWh at €0.32/kWh → max €64.00
Tier 3: remaining at €0.35/kWh → unlimited
For 350 kWh: (100 × 0.28) + (200 × 0.32) + (50 × 0.35) = 28 + 64 + 17.50 = €109.50
```

**Standing charge pro-rating**: `standingCharge * (daysInPeriod / daysInMonth)`. Full month = no pro-rating.

**Edge cases**:
- Zero consumption → standingCost only
- No tiers → use flat unitPrice
- Negative consumption (shouldn't happen, but clamp to 0)
- Null/empty tiers JSON → fall back to unitPrice

**Acceptance**: All tier calculations correct, edge cases handled, pure functions testable without mocking.

### Task 4: CostConfigProvider — state management
**File**: `lib/providers/cost_config_provider.dart` (new)
**Dependencies**: Task 1, Task 2
**Effort**: Medium

```dart
class CostConfigProvider extends ChangeNotifier {
  final CostConfigDao _costConfigDao;
  final CostCalculationService _costCalculationService;

  int? _householdId;
  List<CostConfig> _configs = [];
  StreamSubscription<List<CostConfig>>? _configsSubscription;

  // Getters
  List<CostConfig> get configs => _configs;

  void setHouseholdId(int? id);  // Subscribe to watchConfigsForHousehold

  /// Get the active config for a meter type at a given date.
  CostConfig? getActiveConfig(CostMeterType meterType, DateTime date);

  /// Check if cost tracking is configured for any meter type.
  bool get hasCostConfigs => _configs.isNotEmpty;

  /// Calculate cost for a consumption period using active config.
  CostResult? calculateCost({
    required CostMeterType meterType,
    required double consumption,
    required DateTime periodStart,
    required DateTime periodEnd,
  });

  // CRUD
  Future<int> addConfig(CostConfigsCompanion config);
  Future<bool> updateConfig(CostConfig config);
  Future<void> deleteConfig(int id);

  @override
  void dispose() {
    _configsSubscription?.cancel();
    super.dispose();
  }
}
```

**Pattern**: Follows `ElectricityProvider` pattern — household-scoped, reactive stream subscription, `notifyListeners()` on data change.

**Acceptance**: Provider loads/caches configs, `getActiveConfig` returns correct config, CRUD operations trigger stream updates.

### Task 5: Localization — all new cost strings (EN + DE)
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
**Dependencies**: None (can be built in parallel)
**Effort**: Small

New keys:

| Key | EN | DE |
|-----|----|----|
| `costConfiguration` | `"Cost Configuration"` | `"Kosteneinstellungen"` |
| `costTracking` | `"Cost Tracking"` | `"Kostenverfolgung"` |
| `unitPrice` | `"Unit Price"` | `"Preis pro Einheit"` |
| `standingCharge` | `"Standing Charge"` | `"Grundgebühr"` |
| `standingChargePerMonth` | `"Standing Charge (per month)"` | `"Grundgebühr (pro Monat)"` |
| `priceTiers` | `"Price Tiers"` | `"Preisstufen"` |
| `tier` | `"Tier"` | `"Stufe"` |
| `tierLimit` | `"Up to {limit} {unit}"` | `"Bis {limit} {unit}"` |
| `tierUnlimited` | `"Remaining"` | `"Rest"` |
| `tierRate` | `"Rate"` | `"Tarif"` |
| `addTier` | `"Add Tier"` | `"Stufe hinzufügen"` |
| `removeTier` | `"Remove Tier"` | `"Stufe entfernen"` |
| `maxTiersReached` | `"Maximum 3 tiers"` | `"Maximal 3 Stufen"` |
| `validFrom` | `"Valid From"` | `"Gültig ab"` |
| `currency` | `"Currency"` | `"Währung"` |
| `estimatedCost` | `"Estimated Cost"` | `"Geschätzte Kosten"` |
| `monthlyCost` | `"Monthly Cost"` | `"Monatliche Kosten"` |
| `yearlyCost` | `"Yearly Cost"` | `"Jährliche Kosten"` |
| `totalCost` | `"Total Cost"` | `"Gesamtkosten"` |
| `costValue` | `"{value}"` | `"{value}"` |
| `noCostConfig` | `"No pricing configured"` | `"Keine Preise konfiguriert"` |
| `addCostConfig` | `"Configure Pricing"` | `"Preise konfigurieren"` |
| `editCostConfig` | `"Edit Pricing"` | `"Preise bearbeiten"` |
| `deleteCostConfig` | `"Delete Pricing"` | `"Preise löschen"` |
| `deleteCostConfigConfirm` | `"Delete cost configuration for {meterType}?"` | `"Kosteneinstellung für {meterType} löschen?"` |
| `costSummary` | `"Cost Summary"` | `"Kostenübersicht"` |
| `costComparison` | `"{change}% vs last year"` | `"{change}% gg. Vorjahr"` |
| `pricePerKwh` | `"€/kWh"` | `"€/kWh"` |
| `pricePerCubicMeter` | `"€/m³"` | `"€/m³"` |
| `costNotConfigured` | `"Configure pricing in Settings to see costs"` | `"Preise in Einstellungen konfigurieren, um Kosten zu sehen"` |

Run `flutter gen-l10n` after editing.

**Acceptance**: All new strings in both ARB files, `flutter gen-l10n` succeeds.

### Task 6: Extend analytics models with cost fields
**File**: `lib/services/analytics/analytics_models.dart`
**Dependencies**: None
**Effort**: Small

Add optional cost fields to existing models:

```dart
class MeterTypeSummary {
  // ... existing fields ...
  final double? latestMonthCost;    // NEW: null if no cost config
  final String? currencySymbol;      // NEW: "€"

  const MeterTypeSummary({
    // ... existing ...
    this.latestMonthCost,
    this.currencySymbol,
  });
}

class MonthlyAnalyticsData {
  // ... existing fields ...
  final double? totalCost;          // NEW: total cost for selected month
  final String? currencySymbol;      // NEW
  final List<double?>? periodCosts;  // NEW: cost per period (parallel to recentMonths)

  const MonthlyAnalyticsData({
    // ... existing ...
    this.totalCost,
    this.currencySymbol,
    this.periodCosts,
  });
}

class YearlyAnalyticsData {
  // ... existing fields ...
  final double? totalCost;              // NEW
  final double? previousYearTotalCost;  // NEW: for YoY comparison
  final String? currencySymbol;          // NEW

  const YearlyAnalyticsData({
    // ... existing ...
    this.totalCost,
    this.previousYearTotalCost,
    this.currencySymbol,
  });
}
```

All new fields are nullable with no default — fully backward compatible.

**Acceptance**: Models compile, existing code unaffected, new fields accessible.

### Task 7: Integrate cost calculation into AnalyticsProvider
**File**: `lib/providers/analytics_provider.dart`
**Dependencies**: Tasks 3, 4, 6
**Effort**: Large

**Changes**:
1. Add `CostConfigProvider` as a constructor dependency
2. In `_loadOverview()`: After computing `currentConsumption`, get active cost config and calculate cost → set `latestMonthCost` on `MeterTypeSummary`
3. In `_loadMonthlyData()`: After computing `monthlyConsumption`, calculate cost per period → set `totalCost` and `periodCosts` on `MonthlyAnalyticsData`
4. In `_loadYearlyData()`: After computing yearly totals, calculate total cost + previous year total cost → set on `YearlyAnalyticsData`

**MeterType to CostMeterType mapping**:
```dart
CostMeterType? _toCostMeterType(MeterType type) {
  switch (type) {
    case MeterType.electricity: return CostMeterType.electricity;
    case MeterType.gas: return CostMeterType.gas;
    case MeterType.water: return CostMeterType.water;
    case MeterType.heating: return null; // no cost tracking
  }
}
```

**Cost calculation per period**:
```dart
double? _calculatePeriodCost(PeriodConsumption period, CostConfig? config) {
  if (config == null) return null;
  final tiers = _costCalculationService.parseTiers(config.priceTiers);
  final result = _costCalculationService.calculateMonthlyCost(
    consumption: period.consumption,
    unitPrice: config.unitPrice,
    standingCharge: config.standingCharge,
    currencySymbol: config.currencySymbol,
    tiers: tiers.isNotEmpty ? tiers : null,
    daysInPeriod: period.periodEnd.difference(period.periodStart).inDays,
    daysInMonth: DateUtils.getDaysInMonth(period.periodStart.year, period.periodStart.month),
  );
  return result.totalCost;
}
```

**Acceptance**: Analytics data includes cost values when cost config exists, null when not configured.

### Task 8: Cost configuration UI in SettingsScreen
**Files**: `lib/screens/settings_screen.dart`
**Dependencies**: Tasks 4, 5
**Effort**: Large

Add a new "Cost Configuration" section between Meter Settings and About:

```
SettingsScreen
  ├── Section: Appearance (existing)
  ├── Section: Meter Settings (existing)
  ├── Section: Cost Configuration (NEW)
  │   ├── Card per meter type (Electricity, Gas, Water)
  │   │   ├── Meter type icon + label
  │   │   ├── Unit price input (€/kWh or €/m³)
  │   │   ├── Standing charge input (€/month)
  │   │   ├── Tiered pricing toggle + tier rows (max 3)
  │   │   ├── Valid from date picker
  │   │   └── Save / Delete buttons
  │   └── "Configure Pricing" button if no config exists
  └── Section: About (existing)
```

**Key UI components**:

1. **`_CostConfigSection`** — Iterates over 3 CostMeterTypes, shows a card for each
2. **`_CostConfigCard`** (StatefulWidget) — Form for one meter type's cost config
   - TextFields: unitPrice, standingCharge (reuse `_GasConversionField` pattern)
   - Tiered pricing: expandable section with up to 3 tier rows (limit + rate fields)
   - DatePicker for validFrom (default: 1st of current month)
   - Save button → `costConfigProvider.addConfig()` or `updateConfig()`
   - Delete button (if config exists) → confirm dialog → `deleteConfig()`

**Input validation**:
- Unit price: must be positive number
- Standing charge: must be >= 0
- Tier limits: must be positive, ascending
- Tier rates: must be positive
- Valid from: required date

**Suffix text mapping**:
- Electricity: `€/kWh`
- Gas: `€/kWh` (uses kWh conversion)
- Water: `€/m³`

**Acceptance**: Can create/edit/delete cost configs for each meter type, validates input, persists to database.

### Task 9: Cost display in analytics screens
**Files**: `lib/screens/monthly_analytics_screen.dart`, `lib/screens/yearly_analytics_screen.dart`, `lib/screens/analytics_screen.dart`
**Dependencies**: Tasks 6, 7
**Effort**: Medium

**MonthlyAnalyticsScreen**:
- `_ConsumptionSummaryCard`: Below total consumption, show total cost if available: `"245 kWh — €78.50"`
- Bar chart tooltips: Show cost alongside consumption if available

**YearlyAnalyticsScreen**:
- `_YearlySummaryCard`: Show total yearly cost below consumption total
- YoY comparison: Show cost comparison (`"€950 → €1,020 (+7.4%)"`) if both years have cost data

**AnalyticsScreen (hub)**:
- `_MeterOverviewCard`: Show cost below consumption: `"245 kWh"` + `"~€78.50"` on second line

**Formatting**:
- Use `NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2)` for consistent currency display
- Cost is prefixed with "~" (approximate) since it's based on interpolated consumption

**Acceptance**: Cost values display correctly when configured, hidden when not configured, formatted with currency symbol.

### Task 10: Optional cost column in CSV export
**File**: `lib/services/csv_export_service.dart`
**Dependencies**: Tasks 3, 4
**Effort**: Small

**Changes to export methods**:

```dart
String exportMonthlyData(MonthlyAnalyticsData data) {
  final hasCost = data.totalCost != null;
  final rows = <List<dynamic>>[
    ['Month', 'Consumption', 'Unit', 'Interpolated', if (hasCost) 'Cost (${data.currencySymbol})'],
  ];
  // ... add cost column to each row if hasCost ...
}

String exportYearlyData(YearlyAnalyticsData data) {
  // Same pattern: optional cost column
}

String exportAllMeters({
  required int year,
  required Map<MeterType, List<PeriodConsumption>> dataByType,
  Map<MeterType, List<double?>>? costsByType,  // NEW optional parameter
  String? currencySymbol,
}) {
  // Add cost column if costsByType provided
}
```

**Acceptance**: CSV includes cost column when cost data is available, omits it when not configured.

### Task 11: Wire CostConfigProvider into app
**File**: `lib/main.dart`
**Dependencies**: Tasks 1-4
**Effort**: Small

Changes:
1. Import `CostConfigProvider` and `CostCalculationService`
2. Add `ChangeNotifierProvider<CostConfigProvider>` to `MultiProvider` in app root
3. Pass `CostConfigProvider` to `AnalyticsProvider` constructor
4. Sync `CostConfigProvider.setHouseholdId()` when household selection changes (same as other providers)

**Acceptance**: `CostConfigProvider` available throughout widget tree, household context synced.

### Task 12: Run Drift code generation
**File**: Generated files (`*.g.dart`)
**Dependencies**: Tasks 1, 2
**Effort**: Small

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Acceptance**: All generated files compile, no build errors.

### Task 13: Comprehensive tests
**Files**: Multiple test files (new + modified)
**Dependencies**: Tasks 1-11
**Effort**: Large

| Test File | Focus | Est. Tests |
|-----------|-------|------------|
| `test/services/cost_calculation_service_test.dart` (new) | Flat rate, tiered pricing (2/3 tiers), edge cases (zero, negative), standing charge, pro-rating | ~20 |
| `test/database/daos/cost_config_dao_test.dart` (new) | CRUD, household isolation, getActiveConfig with validFrom logic, multiple configs per type | ~15 |
| `test/providers/cost_config_provider_test.dart` (new) | setHouseholdId, stream updates, getActiveConfig, calculateCost, CRUD operations | ~12 |
| `test/providers/analytics_provider_test.dart` (modified) | Add tests for cost fields in monthly/yearly/overview data | ~8 |
| `test/services/csv_export_service_test.dart` (modified) | Add tests for optional cost column in all export methods | ~6 |
| `test/screens/settings_screen_test.dart` (modified) | Add tests for cost config section rendering and interaction | ~10 |
| **Total** | | **~71** |

**CostCalculationService test details**:
- Flat rate: 100 kWh × €0.30 = €30.00
- Flat rate + standing charge: €30.00 + €12.50 = €42.50
- 2-tier pricing: first 100 at €0.28, rest at €0.35
- 3-tier pricing: first 100 at €0.28, next 200 at €0.32, rest at €0.35
- Zero consumption: only standing charge
- Tier boundary exact (consumption = tier limit exactly)
- Pro-rated standing charge: 15 days of 30 = half charge
- Empty/null tiers: falls back to flat rate
- JSON parse/serialize round-trip for tiers

**CostConfigDao test details**:
- Insert + retrieve config
- Update existing config
- Delete config
- Household isolation: config from household A not visible in household B
- getActiveConfig: one config, returns it
- getActiveConfig: two configs with different validFrom dates, returns correct one
- getActiveConfig: config validFrom in future, returns null
- watchConfigsForHousehold: stream updates on insert/delete

**Acceptance**: All tests pass, `flutter test` green, `flutter analyze` clean.

---

## Wave Execution Plan

```
Wave 1 (Parallel — no deps):
  ├── Task 1: Database table + migration (tables.dart, app_database.dart)
  ├── Task 3: CostCalculationService (pure logic, no DB dependency)
  ├── Task 5: Localization (EN + DE ARB files)
  └── Task 6: Extend analytics models (add cost fields)

Wave 2 (Depends on Task 1):
  └── Task 2: CostConfigDao (depends on Task 1)
      └── Task 12: Drift code generation (run as final step of Task 2)

Wave 3 (Depends on Wave 2):
  └── Task 4: CostConfigProvider (depends on Tasks 1, 2, 3)

Wave 4 (Depends on Wave 3):
  ├── Task 7: Analytics integration (depends on Tasks 3, 4, 6)
  ├── Task 8: Cost config UI in SettingsScreen (depends on Tasks 4, 5)
  ├── Task 10: CSV export cost column (depends on Tasks 3, 4)
  └── Task 11: Wire provider into main.dart (depends on Tasks 1-4)

Wave 5 (Depends on Wave 4):
  └── Task 9: Cost display in analytics screens (depends on Tasks 6, 7)

Wave 6 (Depends on all):
  └── Task 13: Tests + flutter test + flutter analyze
```

---

## Common Pitfalls

| Issue | Solution |
|-------|----------|
| Drift schema migration fails on existing installs | Test migration from v1 → v2 explicitly. Use `m.createTable(costConfigs)` in `onUpgrade` |
| JSON tier parsing throws on malformed data | Wrap in try/catch, return empty list on parse failure. Validate tier structure on save |
| Gas cost calculated on m³ instead of kWh | Gas consumption is already converted to kWh before reaching cost calculation. Verify display unit matches |
| Adding CostConfigProvider breaks existing tests | All analytics model changes are additive (nullable fields). Existing tests don't need updating for compilation |
| SegmentedButton in cost config card conflicts with theme section | Use separate form key per meter type to avoid state conflicts |
| Drift watcher subscription leak in CostConfigProvider | Cancel `_configsSubscription` in `dispose()` and `setHouseholdId()` (same pattern as ElectricityProvider) |
| validFrom date picker shows wrong format | Use `DateFormat.yMMMd(locale)` for localized date display |
| Cost display wraps on small screens | Use `FittedBox` or `Flexible` for cost text in overview cards |
| Standing charge applied to months with zero consumption | Intentional — standing charge is always billed. Only skip if no config exists |
| Currency formatting ignores locale | Use `NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: config.currencySymbol)` |

---

## Requirements Traceability

| Requirement | Task(s) | Verification |
|-------------|---------|--------------|
| FR-11.1.1 (Price per unit per meter type) | 1, 2, 8 | CostConfig table stores unitPrice per meterType per household |
| FR-11.1.2 (Monthly standing charge) | 1, 3, 8 | standingCharge field + CostCalculationService adds it to total |
| FR-11.1.3 (Tiered pricing up to 3 tiers) | 1, 3, 8 | priceTiers JSON column, tier UI with max 3 validation |
| FR-11.1.4 (Per household cost config) | 1, 2 | householdId FK on CostConfigs, DAO filters by household |
| FR-11.1.5 (Different pricing for different periods) | 1, 2, 7 | validFrom date, getActiveConfig selects correct config |
| FR-11.2.1 (Monthly cost = delta × price + standing) | 3 | CostCalculationService.calculateMonthlyCost() |
| FR-11.2.2 (Tiered pricing applied correctly) | 3 | CostCalculationService.calculateWithTiers() |
| FR-11.2.3 (Gas cost in m³ and kWh modes) | 7 | Gas consumption already converted to kWh in AnalyticsProvider before cost calc |
| FR-11.2.4 (CostCalculationService — pure business logic) | 3 | No UI or DB imports in service class |
| FR-11.3.1 (Cost alongside consumption in monthly) | 9 | MonthlyAnalyticsScreen summary card shows cost |
| FR-11.3.2 (Cost in yearly with YoY comparison) | 9 | YearlyAnalyticsScreen shows cost totals + YoY delta |
| FR-11.3.3 (Cost summary card on analytics hub) | 9 | AnalyticsScreen overview cards show cost per meter type |
| FR-11.3.4 (Cost column in CSV export) | 10 | Optional cost column when pricing configured |
| NFR-9.1 (Cost calc < 100ms for 12 months) | 3 | Pure math, no DB calls during calculation |
| NFR-11.1 (Strings localized EN + DE) | 5 | All new cost strings in both ARB files |
| NFR-12.1 (Cost configs stored with household isolation) | 1, 2 | householdId FK + DAO filtering |
