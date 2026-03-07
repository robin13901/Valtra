# Research: Linear Interpolation & CSV Export for Valtra

**Researched:** 2026-03-07
**Overall confidence:** HIGH (interpolation is pure math, CSV is well-established ecosystem)

---

## Topic 1: Linear Interpolation for Meter Readings

### 1.1 The Core Problem

Utility meters are read at irregular intervals (e.g., Jan 15, Mar 3, May 22). For meaningful
monthly analytics, we need estimated values at month boundaries (1st of each month at 00:00).
This allows calculating consistent "consumption per month" even when readings don't align with
calendar months.

### 1.2 Linear Interpolation Formula

Given two readings:
- Reading A: `(timestamp_a, value_a)`
- Reading B: `(timestamp_b, value_b)` where `timestamp_b > timestamp_a`

The interpolated value at any target time `t` where `timestamp_a <= t <= timestamp_b`:

```
fraction = (t - timestamp_a) / (timestamp_b - timestamp_a)
interpolated_value = value_a + fraction * (value_b - value_a)
```

In Dart, timestamps should be converted to millisecondsSinceEpoch for the arithmetic:

```dart
double linearInterpolate({
  required DateTime timeA,
  required double valueA,
  required DateTime timeB,
  required double valueB,
  required DateTime targetTime,
}) {
  final tA = timeA.millisecondsSinceEpoch.toDouble();
  final tB = timeB.millisecondsSinceEpoch.toDouble();
  final tTarget = targetTime.millisecondsSinceEpoch.toDouble();

  final fraction = (tTarget - tA) / (tB - tA);
  return valueA + fraction * (valueB - valueA);
}
```

**Confidence: HIGH** - This is standard mathematics, no library needed.

### 1.3 Step Function Alternative

For some meter types, a step function may be more appropriate (e.g., "the value stays at A until
the next reading"):

```dart
double stepInterpolate({
  required double valueA,
  required double valueB,  // unused in pure step, but available
  // ...
}) {
  return valueA;  // Value stays at the previous reading
}
```

**When to use step vs linear:**
- **Linear**: Best for electricity, gas, water meters. Consumption is roughly continuous.
- **Step**: Best for discrete values or when consumption is very bursty. Rarely needed for utility meters.

**Recommendation:** Default to linear for all utility meter types. Offer step as a configurable
option per meter type, but don't prioritize it for MVP. Linear is the correct default for
cumulative meter readings.

### 1.4 Monthly Boundary Interpolation Algorithm

The core algorithm for generating monthly boundary values:

```
Input:  List<Reading> readings (sorted by timestamp ascending)
        DateTime rangeStart, DateTime rangeEnd
Output: List<MonthlyBoundary> (value at 1st of each month in range)

1. Generate target timestamps: [rangeStart, 1st of next month, 1st of month after, ..., rangeEnd]
   Each target = DateTime(year, month, 1, 0, 0, 0) in UTC or local

2. For each target timestamp:
   a. Find the reading immediately BEFORE target (or exactly at target)
   b. Find the reading immediately AFTER target (or exactly at target)
   c. If exact reading exists at target: use actual value, mark as isInterpolated=false
   d. If both before and after exist: interpolate, mark as isInterpolated=true
   e. If only before exists (target after last reading): cannot interpolate, skip or extrapolate
   f. If only after exists (target before first reading): cannot interpolate, skip or extrapolate
   g. If no readings at all: skip
```

**Important design decision: Never extrapolate.** Only interpolate between known readings.
Extrapolation (predicting beyond the data range) is unreliable and misleading for utility data.

### 1.5 Data Model for Interpolated Values

Interpolated values should NOT be stored in the database. They are computed on-demand.

```dart
/// Represents a value at a point in time, possibly interpolated.
class TimestampedValue {
  final DateTime timestamp;
  final double value;
  final bool isInterpolated;

  const TimestampedValue({
    required this.timestamp,
    required this.value,
    required this.isInterpolated,
  });
}

/// Consumption for a period (derived from two boundary values).
class PeriodConsumption {
  final DateTime periodStart;  // e.g., 2026-03-01
  final DateTime periodEnd;    // e.g., 2026-04-01
  final double startValue;     // meter reading at start
  final double endValue;       // meter reading at end
  final double consumption;    // endValue - startValue
  final bool startInterpolated;
  final bool endInterpolated;

  const PeriodConsumption({
    required this.periodStart,
    required this.periodEnd,
    required this.startValue,
    required this.endValue,
    required this.consumption,
    required this.startInterpolated,
    required this.endInterpolated,
  });
}
```

### 1.6 InterpolationService Design

```dart
enum InterpolationMethod { linear, step }

class InterpolationService {
  /// Interpolate a value at a specific target time given surrounding readings.
  double interpolateAt({
    required DateTime timeA,
    required double valueA,
    required DateTime timeB,
    required double valueB,
    required DateTime targetTime,
    InterpolationMethod method = InterpolationMethod.linear,
  });

  /// Generate boundary values at the 1st of each month within a date range.
  /// Readings must be sorted ascending by timestamp.
  List<TimestampedValue> getMonthlyBoundaries({
    required List<({DateTime timestamp, double value})> readings,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    InterpolationMethod method = InterpolationMethod.linear,
  });

  /// Calculate consumption per month from monthly boundaries.
  List<PeriodConsumption> getMonthlyConsumption({
    required List<({DateTime timestamp, double value})> readings,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    InterpolationMethod method = InterpolationMethod.linear,
  });
}
```

### 1.7 Edge Cases and How to Handle Them

| Edge Case | Behavior | Rationale |
|-----------|----------|-----------|
| **Zero readings** | Return empty list | Nothing to interpolate |
| **Single reading** | Return that reading if it falls on a boundary, otherwise empty | Cannot interpolate with one point |
| **Two readings, same month** | Both included in that month, boundary calculated if possible | Standard case |
| **Readings spanning multiple months with gaps** | Interpolate all boundaries between reading pairs; skip months outside reading range | Linear assumption holds for reasonable gaps |
| **Very sparse data** (e.g., 6-month gap) | Still interpolate linearly, but flag with `isInterpolated=true` | UI can warn user about low-confidence estimates |
| **Reading exactly on boundary** | Use actual value, `isInterpolated=false` | Exact data preferred |
| **Target before first reading** | Skip (do not extrapolate) | Extrapolation unreliable |
| **Target after last reading** | Skip (do not extrapolate) | Extrapolation unreliable |
| **Readings out of order** | Sort by timestamp first | Defensive programming |
| **Duplicate timestamps** | Use the last one (latest entry wins) | User corrected a reading |
| **Negative consumption** | Allow it - meter may have been replaced/reset | Log/flag for user review |

### 1.8 Efficient DAO Queries for Interpolation

The existing DAOs already have `getPreviousReading` and `getNextReading` methods. For bulk
interpolation across many months, a more efficient approach:

```dart
/// In DAO: Get all readings within a date range (plus one before and one after).
/// This avoids N+1 queries for N monthly boundaries.
Future<List<ElectricityReading>> getReadingsForRange(
  int householdId,
  DateTime rangeStart,
  DateTime rangeEnd,
) async {
  // Get reading just before range start
  final before = await getPreviousReading(householdId, rangeStart);
  // Get reading just after range end
  final after = await getNextReading(householdId, rangeEnd);

  // Get all readings in range
  final inRange = await (select(electricityReadings)
    ..where((r) =>
        r.householdId.equals(householdId) &
        r.timestamp.isBiggerOrEqualValue(rangeStart) &
        r.timestamp.isSmallerOrEqualValue(rangeEnd))
    ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]))
    .get();

  // Combine: [before] + inRange + [after]
  return [
    if (before != null) before,
    ...inRange,
    if (after != null) after,
  ];
}
```

This ensures all interpolation for a given range can be done with exactly 3 queries instead of
2*N queries (where N is the number of monthly boundaries).

### 1.9 Generic Approach Across Meter Types

All meter types (electricity, gas, water, heating) share the same interpolation logic. The
difference is only in how data is fetched. Use a generic reading representation:

```dart
/// Abstract reading for interpolation (meter-type agnostic).
typedef ReadingPoint = ({DateTime timestamp, double value});

/// Convert from any meter type to generic reading points:
List<ReadingPoint> fromElectricity(List<ElectricityReading> readings) =>
    readings.map((r) => (timestamp: r.timestamp, value: r.valueKwh)).toList();

List<ReadingPoint> fromGas(List<GasReading> readings) =>
    readings.map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters)).toList();

List<ReadingPoint> fromWater(List<WaterReading> readings) =>
    readings.map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters)).toList();

List<ReadingPoint> fromHeating(List<HeatingReading> readings) =>
    readings.map((r) => (timestamp: r.timestamp, value: r.value)).toList();
```

This keeps the InterpolationService completely independent of database types.

### 1.10 No External Library Needed

Linear interpolation is trivial arithmetic. There is no need for an external interpolation
library. Dart's built-in `DateTime` and `double` types handle everything. The `intl` package
(already in pubspec) handles date formatting for display.

**Confidence: HIGH** - Pure Dart implementation, no dependencies.

---

## Topic 2: CSV Export in Flutter

### 2.1 Package Recommendation: `csv`

**Package:** `csv` (pub.dev)
**Latest compatible version:** 6.0.0 (resolved by pub), 7.2.0 available
**Use version:** `^6.0.0` (compatible with current SDK constraint `^3.10.0`)

The `csv` package is the de facto standard for CSV operations in Dart/Flutter. It handles:
- Converting `List<List<dynamic>>` to CSV strings
- Proper quoting of fields containing commas, newlines, or quotes
- Configurable field separator (comma, semicolon, tab)
- Configurable text delimiter and end of line
- Both encoding (list-to-CSV) and decoding (CSV-to-list)

**Confidence: HIGH** - Package verified via `dart pub add --dry-run`. The `csv` package is the
standard choice; there are no serious competitors for this task in the Dart ecosystem.

### 2.2 CSV Generation Pattern

```dart
import 'package:csv/csv.dart';

String generateCsv(List<PeriodConsumption> data, String meterType) {
  const converter = ListToCsvConverter();

  // Header row
  final rows = <List<dynamic>>[
    ['Month', 'Start Value', 'End Value', 'Consumption', 'Unit', 'Interpolated'],
  ];

  // Data rows
  for (final period in data) {
    final monthLabel = DateFormat('yyyy-MM').format(period.periodStart);
    final unit = _unitForMeterType(meterType); // 'kWh', 'm3', etc.
    final interpolated = (period.startInterpolated || period.endInterpolated) ? 'Yes' : 'No';

    rows.add([
      monthLabel,
      period.startValue.toStringAsFixed(2),
      period.endValue.toStringAsFixed(2),
      period.consumption.toStringAsFixed(2),
      unit,
      interpolated,
    ]);
  }

  return converter.convert(rows);
}
```

### 2.3 Locale-Aware CSV Considerations

German users expect semicolons as CSV delimiters (because comma is the decimal separator in
German locale). Consider:

```dart
String generateCsv(List<PeriodConsumption> data, {String fieldDelimiter = ','}) {
  final converter = ListToCsvConverter(fieldDelimiter: fieldDelimiter);
  // ...
}
```

For Valtra (EN/DE localization), use:
- `,` delimiter for English locale
- `;` delimiter for German locale

Or always use `;` since the primary user is German. Excel on German systems auto-detects
semicolons correctly.

**Recommendation:** Default to `;` (semicolon) delimiter. German locale is the primary use case,
and semicolons work universally (Excel, LibreOffice, Numbers all handle them).

### 2.4 File Sharing: `share_plus`

**Package:** `share_plus`
**Latest compatible version:** 12.0.1
**Platforms:** Android, iOS, macOS, Windows, Linux, Web

The `share_plus` package provides the native share sheet on each platform. For sharing files:

```dart
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> exportAndShareCsv(String csvContent, String filename) async {
  // 1. Write CSV to temporary file
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsString(csvContent);

  // 2. Share via native share sheet
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: 'Valtra Export - $filename',
  );
}
```

**Key API (share_plus v12):**
- `Share.shareXFiles(List<XFile> files, {String? subject, String? text})` - Share files
- `Share.share(String text, {String? subject})` - Share text (not recommended for CSV)
- `XFile(String path, {String? mimeType, String? name})` - File wrapper

**Confidence: HIGH** - `share_plus` is the official Flutter Community Plus package for sharing.
Version 12.0.1 confirmed via `dart pub add --dry-run`. Already-installed `path_provider` (v2.1.3)
provides temporary directory access.

### 2.5 Platform Differences

| Platform | Behavior | Notes |
|----------|----------|-------|
| **Android** | Native share sheet (Intent.ACTION_SEND) | Works with all apps that accept files |
| **iOS** | UIActivityViewController | AirDrop, Files, Mail, etc. |
| **macOS** | NSSharingServicePicker | If building for macOS later |

**Important:** The `shareXFiles` API handles platform differences internally. No platform-specific
code is needed.

**File cleanup:** Temporary files in `getTemporaryDirectory()` are automatically cleaned up by the
OS. No manual cleanup needed, but consider deleting after share completes for good hygiene.

### 2.6 Complete Export Flow

```
User taps "Export" button
  -> Select export scope (month, year, all, specific meter)
  -> Generate CSV string via InterpolationService + csv package
  -> Write to temp file via path_provider
  -> Share via share_plus native sheet
  -> User picks destination (email, Files, Drive, etc.)
```

### 2.7 CSV Column Designs for Each Export Type

**Monthly Consumption Export (per meter type):**
```
Month;Start Reading;End Reading;Consumption;Unit;Interpolated
2026-01;12345.67;12456.78;111.11;kWh;No
2026-02;12456.78;12543.21;86.43;kWh;Yes
```

**All Meters Summary Export:**
```
Month;Electricity (kWh);Gas (m3);Water Cold (m3);Water Hot (m3);Heating (units)
2026-01;111.11;23.45;4.56;2.34;12.5
2026-02;86.43;31.22;5.12;2.67;15.3
```

**Raw Readings Export (for backup/audit):**
```
Meter Type;Meter Name;Timestamp;Value;Unit
Electricity;Main;2026-01-15 10:30:00;12345.67;kWh
Gas;Main;2026-01-15 10:32:00;4567.89;m3
Water;Kitchen Cold;2026-01-15 10:35:00;234.56;m3
```

### 2.8 Filename Convention

```dart
String generateFilename(String householdName, String exportType, DateTime date) {
  final sanitized = householdName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  final dateStr = DateFormat('yyyy-MM').format(date);
  return 'valtra_${sanitized}_${exportType}_$dateStr.csv';
}
// Example: valtra_Main_House_monthly_2026-03.csv
```

### 2.9 Dependencies Summary

| Package | Version | Already in pubspec? | Purpose |
|---------|---------|---------------------|---------|
| `csv` | ^6.0.0 | No - ADD | CSV string generation |
| `share_plus` | ^12.0.0 | No - ADD | Native file sharing |
| `path_provider` | ^2.1.3 | YES | Temp directory for file writing |
| `intl` | ^0.20.2 | YES | Date formatting in exports |

**Only 2 new dependencies needed.** Both are well-maintained, widely used Flutter packages.

---

## Implementation Recommendations

### Phase 8 (Interpolation Engine) Implementation Order

1. **Create data models first:** `TimestampedValue`, `PeriodConsumption`, `ReadingPoint` typedef
2. **Implement InterpolationService** with `interpolateAt()` and `getMonthlyBoundaries()`
3. **Add DAO range query method** (`getReadingsForRange`) to all reading DAOs
4. **Create InterpolationProvider** that bridges DAOs to InterpolationService
5. **Write comprehensive tests** - interpolation is pure logic, 100% testable without mocking

### CSV Export Implementation Order (Phase 9 or 10)

1. **Add `csv` and `share_plus` to pubspec.yaml**
2. **Create CsvExportService** with methods for each export type
3. **Create ExportProvider** wrapping the service
4. **Add export button to analytics screens**
5. **Test CSV generation** (string output testing, no device needed)

### Testing Strategy

**Interpolation (100% unit testable):**
- Pure math functions: exact expected values for known inputs
- Edge cases: empty list, single reading, exact boundary readings
- Multi-month spans: verify all boundaries generated correctly
- Step vs linear: verify different results for same inputs

**CSV Export (mostly unit testable):**
- CSV string generation: verify header, row content, delimiter, quoting
- Filename generation: verify sanitization
- Integration: `share_plus` calls are side effects, mock the file system and share call

### Pitfalls to Watch

1. **Timezone handling:** Always use local time for month boundaries (users think in local time).
   `DateTime(2026, 3, 1)` creates local time. Do NOT use `DateTime.utc()` for boundary generation
   unless you want midnight UTC (which is 1:00 AM CET or 2:00 AM CEST).

2. **Floating point precision:** Meter readings may have many decimal places. Use
   `toStringAsFixed(2)` for display/CSV but keep full precision in calculations.

3. **Month boundary generation:** Be careful with `DateTime(year, month + 1, 1)` - Dart handles
   month overflow correctly (month 13 becomes January next year), so this is safe.

4. **Large date ranges:** For yearly views with many meter types, fetching all readings can be
   slow. Consider caching interpolation results in the provider, invalidated when readings change.

5. **CSV encoding:** Write files with UTF-8 BOM (`\uFEFF` prefix) for Excel compatibility with
   special characters (German umlauts in household/meter names):
   ```dart
   await file.writeAsString('\uFEFF$csvContent');
   ```

6. **share_plus file path:** On iOS, the file must be in a directory the app has access to.
   `getTemporaryDirectory()` always works. Do NOT use `getApplicationDocumentsDirectory()` for
   share - iOS sandboxing may prevent other apps from accessing it.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Linear interpolation algorithm | HIGH | Pure mathematics, well-understood |
| Monthly boundary generation | HIGH | Standard DateTime arithmetic in Dart |
| Edge case handling | HIGH | Enumerable, testable cases |
| `csv` package | HIGH | Verified via `dart pub add --dry-run`, standard choice |
| `share_plus` package | HIGH | Verified via `dart pub add --dry-run`, Flutter Community Plus |
| Platform sharing behavior | MEDIUM | Based on training data; iOS/Android share sheets are stable APIs |
| CSV locale conventions (semicolon) | HIGH | Well-known DE locale convention |

## Sources

- Package resolution: `dart pub add csv --dry-run` (resolved 6.0.0, 7.2.0 available)
- Package resolution: `dart pub add share_plus --dry-run` (resolved 12.0.1)
- Existing codebase: `lib/database/tables.dart` (data model), `lib/database/daos/*.dart` (DAO patterns)
- Project context: `.planning/PROJECT.md`, `.planning/ROADMAP.md`
- Linear interpolation: standard mathematical formula (no external source needed)
