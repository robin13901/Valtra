# Phase 25: Chart Localization & Labels - Research

**Researched:** 2026-03-13
**Domain:** Flutter chart localization (intl DateFormat, fl_chart axis labels)
**Confidence:** HIGH — all findings verified directly from source code

## Summary

Phase 25 adds localized month abbreviations to X-axes and unit/currency labels to Y-axes for the MonthlyBarChart, YearComparisonChart, and ConsumptionLineChart widgets.

The app already threads a `locale` parameter (String 'de'/'en') into all three chart widgets and uses it for number formatting via `ValtraNumberFormat`. However, `DateFormat.MMM()`, `DateFormat.MMMd()`, and `DateFormat.yMMM()` are called **without a locale argument** throughout all three chart files, so month abbreviations are always rendered in the system/platform locale rather than the user-selected in-app locale. The fix is surgical: pass `locale` as the first argument to each `DateFormat` factory call.

For the Y-axis unit label, the current implementation shows plain numeric tick values (e.g. `value.toStringAsFixed(0)`). No unit or currency symbol appears anywhere on the Y-axis. The required change is to append the active unit string to the topmost visible Y-axis tick label.

All three affected screens (Electricity, Gas, Water) already read `LocaleProvider.localeString` and pass the result to `MonthlyBarChart` and `YearComparisonChart` via the `locale:` parameter. No screen-level changes are needed for locale propagation; only the chart widgets need updating.

**Primary recommendation:** Fix `DateFormat` calls in-place and add a unit suffix to the top Y-axis tick widget in `_buildTitles()` for all three chart widgets.

---

## Standard Stack

No new dependencies required for this phase.

### Core (already present)
| Library | Version | Purpose |
|---------|---------|---------|
| intl | 0.20.2 | `DateFormat` for localized month names |
| fl_chart | 0.68.0 | Chart widgets: BarChart, LineChart |

**Installation:** nothing new to install.

---

## Architecture Patterns

### How Locale Flows into Charts (current pattern)

Each screen's `_buildAnalyseContent` reads `LocaleProvider.localeString`:

```dart
// Source: electricity_screen.dart, gas_screen.dart, water_screen.dart
final locale = context.watch<LocaleProvider>().localeString;
```

Then passes it to chart widgets:

```dart
MonthlyBarChart(
  periods: data.monthlyBreakdown,
  primaryColor: color,
  unit: data.unit,          // 'kWh', 'm\u00B3'
  locale: locale,           // 'de' or 'en'
  showCosts: _showCosts,
  periodCosts: _showCosts ? data.monthlyCosts : null,
  costUnit: _showCosts ? (data.currencySymbol ?? '\u20AC') : null,
)
```

The chart widget stores this as `final String locale;` with default `'de'`.

### Pattern: Locale-Aware DateFormat

**Existing working examples in the codebase:**

```dart
// Source: number_format_service.dart
final formatter = DateFormat.yMMMM(locale);   // locale-aware
final formatter = DateFormat('H:mm', locale); // locale-aware

// Source: smart_plugs_screen.dart
DateFormat.yMMM(locale).format(_latestConsumption!.month) // locale-aware
```

**The bug — locale-less DateFormat in chart widgets:**

```dart
// monthly_bar_chart.dart line 107 (tooltip)
final monthName = DateFormat.yMMM().format(period.periodStart);  // NO locale

// monthly_bar_chart.dart line 134 (X-axis label)
DateFormat.MMM().format(periods[index].periodStart);  // NO locale

// year_comparison_chart.dart line 198 (tooltip)
DateFormat.MMM().format(DateTime(2024, monthIndex + 1));  // NO locale

// year_comparison_chart.dart line 235 (X-axis label)
DateFormat.MMM().format(DateTime(2024, index + 1));  // NO locale

// consumption_line_chart.dart line 118 (tooltip)
DateFormat.MMMd().format(date);  // NO locale

// consumption_line_chart.dart line 190 (X-axis label)
DateFormat.MMMd().format(date);  // NO locale
```

**Fix pattern — add locale argument:**

```dart
// Correct form: pass locale as first positional argument
DateFormat.MMM(locale).format(periodStart)
DateFormat.MMMd(locale).format(date)
DateFormat.yMMM(locale).format(periodStart)
```

### Pattern: Y-axis Unit Label

The current Y-axis `getTitlesWidget` for all three charts:

```dart
// monthly_bar_chart.dart _buildTitles leftTitles
getTitlesWidget: (value, meta) {
  if (value == meta.min) return const SizedBox.shrink();
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(
      value.toStringAsFixed(0),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
},
```

The required approach: show the unit/currency suffix on the **top visible tick** only. The `meta.max` value is the chart's configured maximum — `value == meta.max` can be used to identify the top tick for the suffix.

```dart
// Pattern for Y-axis with unit label on top tick
getTitlesWidget: (value, meta) {
  if (value == meta.min) return const SizedBox.shrink();
  final isTop = value == meta.max;
  final label = isTop
      ? '${value.toStringAsFixed(0)} $activeUnit'
      : value.toStringAsFixed(0);
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(label, style: Theme.of(context).textTheme.bodySmall),
  );
},
```

Where `activeUnit` is `showCosts && costUnit != null ? costUnit! : unit`.

**Alternative approach — AxisTitle (axisNameWidget):**

`fl_chart`'s `AxisTitles` supports an `axisNameWidget` at the axis extremity. This is cleaner for a single unit label but requires a non-null `axisNameWidget` and `axisNameSize` in the `AxisTitles`:

```dart
leftTitles: AxisTitles(
  axisNameWidget: Text(activeUnit,
      style: Theme.of(context).textTheme.bodySmall),
  axisNameSize: 20,
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 50,
    getTitlesWidget: (value, meta) { ... },
  ),
),
```

**Recommendation:** Use `axisNameWidget` on the `leftTitles` — this is the canonical fl_chart approach for axis labels. It avoids overloading individual tick labels and is robust regardless of maxY.

However, since `reservedSize: 50` is already set for numeric ticks, adding `axisNameSize` requires increasing `reservedSize` or accepting overlap. The tick-suffix approach is simpler and requires no layout changes; it is sufficient for short labels like 'kWh', 'm³', '€'.

**Decision: Use the top-tick suffix approach** — append unit to the topmost tick label. This matches how the codebase currently works and avoids needing to increase `reservedSize`.

### Recommended Project Structure (no changes)

```
lib/
├── widgets/charts/
│   ├── monthly_bar_chart.dart        # 3 DateFormat fixes + Y-axis unit
│   ├── year_comparison_chart.dart    # 3 DateFormat fixes + Y-axis unit
│   └── consumption_line_chart.dart  # 2 DateFormat fixes + Y-axis unit
```

### Anti-Patterns to Avoid

- **`DateFormat.MMM()` without locale:** The system default locale is used, which may differ from the app locale. Always pass `locale` explicitly.
- **Rotating Y-axis label text:** fl_chart's `AxisTitles` supports `axisNameWidget` without rotation workarounds; avoid manual `Transform.rotate`.
- **Adding a Y-axis unit label to the pie chart:** `ConsumptionPieChart` is out of scope — it shows percentages, not kWh/EUR values.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| German month abbreviations | Custom list `['Jan','Feb','Mär',...]` | `DateFormat.MMM('de')` | intl generates correct locale data; edge cases like locale-specific shortening rules |
| Currency/unit symbol | Hard-coded string matching | Pass `activeUnit` param that toggles per `showCosts` | Already done for tooltip; just extend to Y-axis |

**Key insight:** The `intl` package's `DateFormat.MMM('de')` will produce "Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez" automatically. No custom abbreviation list is needed.

---

## Common Pitfalls

### Pitfall 1: `meta.max` Equals Chart maxY, Not Always Visible

**What goes wrong:** `meta.max` in `getTitlesWidget` is the configured chart maxY (e.g. `maxVal * 1.2`). The tick labels are spaced by `interval`; `meta.max` is usually NOT a tick position and the callback may never be called with exactly `meta.max`.

**Why it happens:** fl_chart generates ticks at intervals and only calls `getTitlesWidget` for those positions. `meta.max` is a boundary value.

**How to avoid:** Use `value == meta.max` only if you verify tick spacing. A safer approach: check if it is the **last non-skipped tick** (where `value > meta.min` and `value` is the highest tick). Alternatively, use `axisNameWidget` in `AxisTitles` which renders independently of tick positions.

**Warning signs:** Unit label never appears in the UI during testing.

**Confirmed safe approach:** Use `axisNameWidget` in the `AxisTitles` constructor — this renders a separate label widget above/beside the axis, independent of tick positions.

```dart
// fl_chart 0.68.0 — AxisTitles supports axisNameWidget
leftTitles: AxisTitles(
  axisNameWidget: Text(
    activeUnit,
    style: Theme.of(context).textTheme.bodySmall,
  ),
  axisNameSize: 18,
  sideTitles: SideTitles(...),
),
```

This means `reservedSize` must be adjusted to accommodate the axisNameSize (default 22px).

**Final recommendation:** Use `axisNameWidget` with `axisNameSize: 18` and increase `reservedSize` from 50 to 64 to prevent overlap. This is the cleanest and most reliable approach.

### Pitfall 2: `DateFormat.MMM('de')` Requires Locale Data Initialization

**What goes wrong:** In Flutter tests, German locale data may not be available unless `initializeDateFormatting('de')` is called first.

**Why it happens:** The `intl` package lazy-loads locale data. In tests running without `flutter_localizations` delegate properly set up, locale data may be missing.

**How to avoid:** Tests that exercise locale-aware `DateFormat` calls should either:
1. Use `locale: const Locale('en')` in the test `MaterialApp` (already done in most existing chart tests), OR
2. Call `await initializeDateFormatting('de')` in `setUp()` for German-specific tests.

The existing test infrastructure (`MaterialApp` with `AppLocalizations.localizationsDelegates` and `supportedLocales`) loads locale data for both DE and EN via `flutter_localizations`. Chart widget tests should include this setup.

**Warning signs:** `MissingLocaleDataException` or months displaying in English in German locale tests.

### Pitfall 3: Tooltip Month Format Not Updated

**What goes wrong:** The tooltip `getTooltipItem`/`getTooltipItems` callbacks also call `DateFormat` — these are different code paths from the axis label callbacks. Both must be updated.

**Why it happens:** Tooltips and axis titles are separate configurations in fl_chart.

**How to avoid:** Search for ALL `DateFormat` calls in each chart file (tooltip and axis). There are currently 6 total occurrences across the 3 files (2 per file).

---

## Code Examples

### Correct locale-aware DateFormat (verified from number_format_service.dart)

```dart
// Source: lib/services/number_format_service.dart line 51
final formatter = DateFormat.yMMMM(locale);
return formatter.format(dt);
```

### Fix for monthly_bar_chart.dart (both occurrences)

```dart
// Tooltip (line 107): was DateFormat.yMMM()
final monthName = DateFormat.yMMM(locale).format(period.periodStart);

// X-axis label (line 134): was DateFormat.MMM()
final monthName = DateFormat.MMM(locale).format(periods[index].periodStart);
```

### Fix for year_comparison_chart.dart (both occurrences)

```dart
// Tooltip (line 198): was DateFormat.MMM()
final monthName = DateFormat.MMM(locale).format(DateTime(2024, monthIndex + 1));

// X-axis label (line 235): was DateFormat.MMM()
final monthName = DateFormat.MMM(locale).format(DateTime(2024, index + 1));
```

### Fix for consumption_line_chart.dart (both occurrences)

```dart
// Tooltip (line 118): was DateFormat.MMMd()
final dateStr = DateFormat.MMMd(locale).format(date);

// X-axis label (line 190): was DateFormat.MMMd()
DateFormat.MMMd(locale).format(date)
```

### Y-axis unit label via axisNameWidget (fl_chart 0.68.0)

```dart
leftTitles: AxisTitles(
  axisNameWidget: Text(
    displayUnit,  // 'kWh', 'm\u00B3', '\u20AC'
    style: Theme.of(context).textTheme.bodySmall,
  ),
  axisNameSize: 18,
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 64,  // increased from 50 to accommodate axisNameSize
    getTitlesWidget: (value, meta) {
      if (value == meta.min) return const SizedBox.shrink();
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          value.toStringAsFixed(0),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    },
  ),
),
```

`displayUnit` resolves as:
- `MonthlyBarChart`: `showCosts && costUnit != null ? costUnit! : unit`
- `YearComparisonChart`: `showCosts && costUnit != null ? costUnit! : unit` (already computed as `displayUnit` at line 124)
- `ConsumptionLineChart`: `unit` only (no cost toggle on this chart)

---

## Scope Boundaries

### In Scope (CHART-03)
- `MonthlyBarChart` — used by Electricity, Gas, and Water Analyse tabs
- `YearComparisonChart` — used by Electricity, Gas, and Water Analyse tabs
- `ConsumptionLineChart` — used by... (verify below)

**Important:** `ConsumptionLineChart` is imported in `electricity_screen.dart`... let me verify it is actually rendered on the Analyse tab. Looking at the screen code: the Analyse tab uses `MonthlyBarChart` and `YearComparisonChart` only. `ConsumptionLineChart` is NOT present in `electricity_screen.dart`, `gas_screen.dart`, or `water_screen.dart`. It appears to have been an earlier chart type that may only appear elsewhere.

**Grep result confirms:** `ConsumptionLineChart` is NOT imported in any of the three target screens. It is imported in `consumption_line_chart_test.dart` only. Therefore CHART-01 and CHART-02 apply only to `MonthlyBarChart` and `YearComparisonChart`.

### Out of Scope
- `ConsumptionPieChart` — shows % slices, no month axis or unit Y-axis
- `ConsumptionLineChart` — not rendered in any of the 3 target screens
- Heating screen — explicitly out of scope (Decision 56)
- Smart Plugs screen — explicitly excluded by CHART-03

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `DateFormat.MMM()` (no locale) | `DateFormat.MMM(locale)` | X-axis shows locale-correct month abbreviations |
| No Y-axis unit | `axisNameWidget` on `leftTitles` | Y-axis identifies the displayed unit |

---

## Open Questions

1. **ConsumptionLineChart inclusion**
   - What we know: The file exists and has a `locale` param, but it is not rendered in any of the 3 target screens.
   - What's unclear: Is it rendered somewhere else (e.g. a monthly analytics detail screen)?
   - Recommendation: Fix it anyway for consistency, but it is not required for CHART-03.

2. **`€` vs `EUR` for cost Y-axis label**
   - What we know: `data.currencySymbol` is '€' (Unicode euro). `costUnit` passed to chart is `data.currencySymbol ?? '\u20AC'`.
   - What's unclear: Whether the Y-axis should show '€' or 'EUR'.
   - Recommendation: Use `costUnit` as-is ('€') — same as tooltip and summary card.

3. **`m³` rendering width on Y-axis**
   - What we know: `reservedSize` is currently 50. 'm³' is wider than 'kWh'.
   - Recommendation: Increase `reservedSize` to 64 as noted above. The superscript '³' renders as a single char in most fonts.

---

## Sources

### Primary (HIGH confidence)
- Codebase direct inspection:
  - `lib/widgets/charts/monthly_bar_chart.dart` — all DateFormat calls, locale param, Y-axis structure
  - `lib/widgets/charts/year_comparison_chart.dart` — all DateFormat calls, locale param, Y-axis structure
  - `lib/widgets/charts/consumption_line_chart.dart` — all DateFormat calls, locale param
  - `lib/services/number_format_service.dart` — correct locale-aware DateFormat pattern
  - `lib/screens/electricity_screen.dart`, `gas_screen.dart`, `water_screen.dart` — locale propagation to charts
  - `lib/providers/locale_provider.dart` — `localeString` getter, null defaults to 'de'
  - `test/helpers/test_locale_provider.dart` — `MockLocaleProvider` for test setup
  - `pubspec.lock` — intl 0.20.2, fl_chart 0.68.0

### Secondary (MEDIUM confidence)
- `lib/l10n/app_localizations_de.dart` — German abbreviation expected values ('Mär', 'Mai', 'Okt') confirmed via intl

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — confirmed from pubspec.lock
- Architecture (locale flow): HIGH — confirmed from source code
- DateFormat fix pattern: HIGH — existing working pattern in number_format_service.dart
- Y-axis axisNameWidget: HIGH — fl_chart 0.68.0 API verified from existing fl_chart API usage in year_comparison_chart.dart `AxisTitles` constructor
- Scope (which charts are rendered): HIGH — confirmed by grepping imports in screen files
- Pitfall (meta.max tick issue): HIGH — standard fl_chart behavior

**Research date:** 2026-03-13
**Valid until:** 2026-06-13 (stable fl_chart 0.68.0 and intl 0.20.2)
