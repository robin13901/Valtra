# Phase 8 Plan — Interpolation Engine & Gas kWh Conversion

**Phase**: 8 of 14
**Milestone**: 2 — Analytics & Visualization (v0.2.0)
**Requirements**: FR-8 (Interpolation), FR-9.1 (Gas kWh Conversion)
**Goal**: Build the interpolation engine and gas kWh conversion service — the data foundation for all analytics screens.

---

## Architecture Overview

```
InterpolationService (pure Dart, no dependencies)
  ├── interpolateAt() — single point interpolation
  ├── getMonthlyBoundaries() — boundary values for date range
  └── getMonthlyConsumption() — consumption deltas per month

GasConversionService (pure Dart)
  └── toKwh() / toKwhConsumption() — m³ → kWh with configurable factor

InterpolationSettingsProvider (SharedPreferences)
  └── per-meter-type InterpolationMethod preference

DAO Additions (per meter type)
  └── getReadingsForRange() — efficient range query + surrounding readings
```

No UI in this phase. Analytics screens (Phase 9+) will consume these services.

---

## Task Breakdown

### Task 1: Data Models
**File**: `lib/services/interpolation/models.dart` (new)
**Dependencies**: None

Create the shared data models used by the interpolation engine:

```dart
// Interpolation method enum
enum InterpolationMethod { linear, step }

// Generic reading point (meter-type agnostic)
typedef ReadingPoint = ({DateTime timestamp, double value});

// A value at a point in time, possibly interpolated
class TimestampedValue {
  final DateTime timestamp;
  final double value;
  final bool isInterpolated;
  const TimestampedValue({required this.timestamp, required this.value, required this.isInterpolated});
}

// Consumption for a period (derived from two boundary values)
class PeriodConsumption {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double startValue;
  final double endValue;
  final double consumption;  // endValue - startValue
  final bool startInterpolated;
  final bool endInterpolated;
  const PeriodConsumption({...});
}
```

**Test file**: `test/services/interpolation/models_test.dart`
- Test equality, toString, construction
- Test PeriodConsumption consumption calculation

---

### Task 2: InterpolationService — Core
**File**: `lib/services/interpolation/interpolation_service.dart` (new)
**Dependencies**: Task 1

Implement the pure-logic interpolation engine:

```dart
class InterpolationService {
  /// Single-point interpolation between two readings.
  double interpolateAt({
    required DateTime timeA, required double valueA,
    required DateTime timeB, required double valueB,
    required DateTime targetTime,
    InterpolationMethod method = InterpolationMethod.linear,
  });
  // Linear: fraction = (target - tA) / (tB - tA); result = vA + fraction * (vB - vA)
  // Step: returns valueA (previous reading holds until next)

  /// Generate boundary values at 1st of each month in range.
  /// Readings must be sorted ascending by timestamp.
  /// No extrapolation: boundaries outside reading range are skipped.
  List<TimestampedValue> getMonthlyBoundaries({
    required List<ReadingPoint> readings,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    InterpolationMethod method = InterpolationMethod.linear,
  });

  /// Calculate consumption per month from boundary values.
  List<PeriodConsumption> getMonthlyConsumption({
    required List<ReadingPoint> readings,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    InterpolationMethod method = InterpolationMethod.linear,
  });
}
```

**Algorithm for `getMonthlyBoundaries`**:
1. Sort readings by timestamp (defensive)
2. Remove duplicate timestamps (keep last)
3. Generate target dates: 1st of each month between rangeStart and rangeEnd using `DateTime(year, month, 1)` (local time)
4. For each target:
   - If exact reading exists → use it, `isInterpolated: false`
   - If before AND after readings exist → interpolate, `isInterpolated: true`
   - If only before or only after → skip (no extrapolation)
5. Return list of `TimestampedValue`

**Test file**: `test/services/interpolation/interpolation_service_test.dart`
Tests (aim 100% coverage):
- `interpolateAt` linear: midpoint, quarter point, endpoints
- `interpolateAt` step: always returns valueA
- `getMonthlyBoundaries`: standard case (2 readings spanning 3 months)
- `getMonthlyBoundaries`: exact boundary reading (isInterpolated=false)
- `getMonthlyBoundaries`: no readings → empty
- `getMonthlyBoundaries`: single reading → only if on boundary
- `getMonthlyBoundaries`: sparse data (6-month gap)
- `getMonthlyBoundaries`: readings out of order → sorts first
- `getMonthlyBoundaries`: duplicate timestamps → keeps last
- `getMonthlyBoundaries`: no extrapolation past edges
- `getMonthlyConsumption`: derives from boundaries correctly
- `getMonthlyConsumption`: empty readings → empty result
- `getMonthlyConsumption`: single month consumption

---

### Task 3: GasConversionService
**File**: `lib/services/gas_conversion_service.dart` (new)
**Dependencies**: Task 1

```dart
class GasConversionService {
  static const double defaultFactor = 10.3; // kWh per m³ (German natural gas)

  /// Convert m³ to kWh
  double toKwh(double cubicMeters, {double factor = defaultFactor}) =>
    cubicMeters * factor;

  /// Convert PeriodConsumption m³ values to kWh
  PeriodConsumption toKwhConsumption(
    PeriodConsumption period, {double factor = defaultFactor}
  );

  /// Convert a list of PeriodConsumptions
  List<PeriodConsumption> toKwhConsumptions(
    List<PeriodConsumption> periods, {double factor = defaultFactor}
  );
}
```

**Test file**: `test/services/gas_conversion_service_test.dart`
- Default factor (10.3 kWh/m³)
- Custom factor
- Zero value
- Conversion of PeriodConsumption preserves dates and flags
- Batch conversion

---

### Task 4: DAO Range Queries
**Files** (modify existing):
- `lib/database/daos/electricity_dao.dart`
- `lib/database/daos/gas_dao.dart`
- `lib/database/daos/water_dao.dart`
- `lib/database/daos/heating_dao.dart`
**Dependencies**: None

Add `getReadingsForRange` method to each DAO. This fetches all readings within a date range PLUS the immediately surrounding readings (one before rangeStart, one after rangeEnd), enabling efficient bulk interpolation with exactly 3 queries instead of 2*N.

**Electricity/Gas pattern** (household-scoped):
```dart
Future<List<ElectricityReading>> getReadingsForRange(
  int householdId, DateTime rangeStart, DateTime rangeEnd,
) async {
  final before = await getPreviousReading(householdId, rangeStart);
  final after = await getNextReading(householdId, rangeEnd);
  final inRange = await (select(electricityReadings)
    ..where((r) => r.householdId.equals(householdId) &
        r.timestamp.isBiggerOrEqualValue(rangeStart) &
        r.timestamp.isSmallerOrEqualValue(rangeEnd))
    ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
    .get();
  return [if (before != null) before, ...inRange, if (after != null) after];
}
```

**Water/Heating pattern** (meter-scoped):
```dart
Future<List<WaterReading>> getReadingsForRange(
  int waterMeterId, DateTime rangeStart, DateTime rangeEnd,
) async {
  // Same pattern but scoped to waterMeterId instead of householdId
}
```

**Test files** (modify existing):
- `test/database/daos/electricity_dao_test.dart` — add range query tests
- `test/database/daos/gas_dao_test.dart` — add range query tests
- `test/database/daos/water_dao_test.dart` — add range query tests
- `test/database/daos/heating_dao_test.dart` — add range query tests

Tests per DAO (4 each):
- Range with readings inside, before, and after
- Range with no readings → empty list
- Range with readings only before (gets before + empty)
- Range with exact boundary reading included

---

### Task 5: Reading-to-ReadingPoint Converters
**File**: `lib/services/interpolation/reading_converters.dart` (new)
**Dependencies**: Task 1, Task 4 (uses model types and DAO entity types)

Convert from meter-specific reading types to generic `ReadingPoint`:

```dart
List<ReadingPoint> fromElectricityReadings(List<ElectricityReading> readings) =>
  readings.map((r) => (timestamp: r.timestamp, value: r.valueKwh)).toList();

List<ReadingPoint> fromGasReadings(List<GasReading> readings) =>
  readings.map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters)).toList();

List<ReadingPoint> fromWaterReadings(List<WaterReading> readings) =>
  readings.map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters)).toList();

List<ReadingPoint> fromHeatingReadings(List<HeatingReading> readings) =>
  readings.map((r) => (timestamp: r.timestamp, value: r.value)).toList();
```

**Test file**: `test/services/interpolation/reading_converters_test.dart`
- Each converter maps fields correctly
- Empty list → empty list
- Preserves order

---

### Task 6: InterpolationSettingsProvider
**File**: `lib/providers/interpolation_settings_provider.dart` (new)
**Dependencies**: Task 1

Store user's preferred interpolation method per meter type using SharedPreferences:

```dart
class InterpolationSettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  InterpolationSettingsProvider(this._prefs);

  // Keys: 'interpolation_electricity', 'interpolation_gas', etc.
  static const _prefix = 'interpolation_';

  InterpolationMethod getMethodForMeterType(String meterType) {
    final value = _prefs.getString('$_prefix$meterType');
    return value == 'step' ? InterpolationMethod.step : InterpolationMethod.linear;
  }

  Future<void> setMethodForMeterType(String meterType, InterpolationMethod method) async {
    await _prefs.setString('$_prefix$meterType', method.name);
    notifyListeners();
  }

  // Gas kWh conversion factor
  static const _gasFactorKey = 'gas_kwh_factor';
  double get gasKwhFactor => _prefs.getDouble(_gasFactorKey) ?? GasConversionService.defaultFactor;

  Future<void> setGasKwhFactor(double factor) async {
    await _prefs.setDouble(_gasFactorKey, factor);
    notifyListeners();
  }
}
```

**Test file**: `test/providers/interpolation_settings_provider_test.dart`
- Default method is linear for all meter types
- Set and get method for each meter type
- Default gas factor is 10.3
- Set and get custom gas factor
- notifyListeners called on changes
- Uses SharedPreferences mock (`SharedPreferences.setMockInitialValues({})`)

---

### Task 7: Register Provider in main.dart
**File**: `lib/main.dart` (modify)
**Dependencies**: Task 6

Add `InterpolationSettingsProvider` to the `MultiProvider` in `main.dart`:

```dart
// In _initializeApp():
final interpolationSettingsProvider = InterpolationSettingsProvider(prefs);

// In MultiProvider:
ChangeNotifierProvider(create: (_) => interpolationSettingsProvider),
```

No test needed for this task (integration wiring only).

---

### Task 8: Localization
**Files**:
- `lib/l10n/app_en.arb` (modify)
- `lib/l10n/app_de.arb` (modify)
**Dependencies**: None

Add localization keys for interpolation and gas kWh:

**English (app_en.arb)**:
```json
"interpolation": "Interpolation",
"interpolationMethod": "Interpolation Method",
"linear": "Linear",
"step": "Step",
"interpolated": "Interpolated",
"actual": "Actual",
"gasKwhConversion": "Gas kWh Conversion",
"gasConversionFactor": "Conversion Factor",
"gasKwhPerCubicMeter": "{value} kWh/m³",
"gasValueKwh": "{value} kWh",
"gasConsumptionKwh": "+{value} kWh since previous",
"defaultGasConversionFactor": "Default: 10.3 kWh/m³ (German natural gas)"
```

**German (app_de.arb)**:
```json
"interpolation": "Interpolation",
"interpolationMethod": "Interpolationsmethode",
"linear": "Linear",
"step": "Stufenfunktion",
"interpolated": "Interpoliert",
"actual": "Tatsächlich",
"gasKwhConversion": "Gas kWh-Umrechnung",
"gasConversionFactor": "Umrechnungsfaktor",
"gasKwhPerCubicMeter": "{value} kWh/m³",
"gasValueKwh": "{value} kWh",
"gasConsumptionKwh": "+{value} kWh seit vorheriger Ablesung",
"defaultGasConversionFactor": "Standard: 10,3 kWh/m³ (deutsches Erdgas)"
```

**Test**: Run `flutter gen-l10n` to verify ARB files parse correctly.

---

### Task 9: Tests & Verification
**Dependencies**: All previous tasks

1. Run `flutter test` — all tests must pass (existing 313 + new ~50-60)
2. Run `flutter analyze` — zero issues
3. Verify test counts per component:

| Component | Expected Tests |
|-----------|---------------|
| InterpolationService | ~15 (core algorithm + edge cases) |
| GasConversionService | ~6 (conversions + batch) |
| DAO range queries (4 DAOs × 4 tests) | ~16 |
| Reading converters | ~5 |
| InterpolationSettingsProvider | ~8 |
| Models | ~4 |
| **Total new** | **~54** |

---

## Wave Execution Plan

```
Wave 1 (Parallel — no dependencies):
  ├── Task 1: Data models
  ├── Task 8: Localization (EN + DE)
  └── Task 4: DAO range queries (all 4 DAOs)

Wave 2 (Parallel — depends on Task 1):
  ├── Task 2: InterpolationService core
  ├── Task 3: GasConversionService
  └── Task 5: Reading converters

Wave 3 (Sequential — depends on Wave 2):
  └── Task 6: InterpolationSettingsProvider

Wave 4 (Sequential — depends on Task 6):
  └── Task 7: Register provider in main.dart

Wave 5 (Sequential — depends on all):
  └── Task 9: Run tests + analyze
```

---

## Files Created (New)

| File | Type |
|------|------|
| `lib/services/interpolation/models.dart` | Data models |
| `lib/services/interpolation/interpolation_service.dart` | Core engine |
| `lib/services/interpolation/reading_converters.dart` | Type converters |
| `lib/services/gas_conversion_service.dart` | Gas m³→kWh |
| `lib/providers/interpolation_settings_provider.dart` | Settings persistence |
| `test/services/interpolation/models_test.dart` | Tests |
| `test/services/interpolation/interpolation_service_test.dart` | Tests |
| `test/services/interpolation/reading_converters_test.dart` | Tests |
| `test/services/gas_conversion_service_test.dart` | Tests |
| `test/providers/interpolation_settings_provider_test.dart` | Tests |

## Files Modified

| File | Change |
|------|--------|
| `lib/database/daos/electricity_dao.dart` | Add `getReadingsForRange()` |
| `lib/database/daos/gas_dao.dart` | Add `getReadingsForRange()` |
| `lib/database/daos/water_dao.dart` | Add `getReadingsForRange()` |
| `lib/database/daos/heating_dao.dart` | Add `getReadingsForRange()` |
| `lib/main.dart` | Register `InterpolationSettingsProvider` |
| `lib/l10n/app_en.arb` | Add ~12 interpolation/gas keys |
| `lib/l10n/app_de.arb` | Add ~12 interpolation/gas keys |
| `test/database/daos/electricity_dao_test.dart` | Add range query tests |
| `test/database/daos/gas_dao_test.dart` | Add range query tests |
| `test/database/daos/water_dao_test.dart` | Add range query tests |
| `test/database/daos/heating_dao_test.dart` | Add range query tests |

---

## Key Design Decisions

1. **No database storage for interpolated values** — computed on-demand. Simpler, no stale data.
2. **Local time for boundaries** — `DateTime(year, month, 1)` uses local time. Users think in local time, not UTC.
3. **Generic ReadingPoint typedef** — keeps InterpolationService decoupled from Drift entities.
4. **3-query DAO pattern** — `getReadingsForRange` uses before + in-range + after to avoid N+1.
5. **SharedPreferences for settings** — follows existing pattern (ThemeProvider, HouseholdProvider).
6. **Default linear interpolation** — step is available but linear is correct for cumulative meters.
7. **No extrapolation** — boundaries outside reading range are silently skipped.

---

## Acceptance Criteria

- [ ] `InterpolationService.getMonthlyBoundaries()` returns correct boundary values for readings spanning multiple months
- [ ] `InterpolationService.getMonthlyBoundaries()` marks exact-boundary readings as `isInterpolated: false`
- [ ] No extrapolation: boundaries before first or after last reading are not generated
- [ ] Step interpolation returns previous reading value (not linear)
- [ ] Edge cases handled: zero readings, single reading, sparse data, out-of-order, duplicates
- [ ] All 4 DAOs have working `getReadingsForRange()` methods
- [ ] `GasConversionService.toKwh()` converts correctly with default (10.3) and custom factors
- [ ] `InterpolationSettingsProvider` persists method per meter type and gas factor
- [ ] All new strings in EN + DE ARB files
- [ ] `flutter test` passes (313+ existing + ~54 new)
- [ ] `flutter analyze` reports zero issues

---

## Executor Notes (from plan verification)

1. **electricity_dao_test.dart does not exist** — Task 4 must CREATE this test file, not modify it. All other DAO test files exist.
2. **SharedPreferences in main.dart** — Existing providers (ThemeProvider, HouseholdProvider) use self-init pattern (call `SharedPreferences.getInstance()` internally). Either: (a) match this pattern in `InterpolationSettingsProvider`, or (b) add `final prefs = await SharedPreferences.getInstance()` to `main()`. Option (a) recommended for consistency.
3. **Task 6 implicit dependency on Task 3** — `InterpolationSettingsProvider` references `GasConversionService.defaultFactor`. Wave order already handles this (Wave 3 after Wave 2), but noted for clarity.

## Verification

**Plan check result**: PASS
**Checker**: All FR-8.x and FR-9.1.x requirements covered. Edge cases comprehensive. Wave dependencies valid. Architecture fits existing patterns.

---

## Commit Message
```
Implement Phase 8: Interpolation engine with linear/step methods, gas kWh conversion, and DAO range queries
```
