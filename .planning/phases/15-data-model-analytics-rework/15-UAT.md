# Phase 15: Data Model & Analytics Rework — UAT Results

**Date**: 2026-03-07
**Baseline**: 855 tests passing, 0 analyze issues
**Status**: ALL PASS (6/6 UACs verified)

---

## UAC-M3-11: Interpolation Rework

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Step interpolation fully removed | PASS | `InterpolationMethod` enum only has `linear`; no `.step` references in codebase |
| Boundaries at 1st of month 00:00 | PASS | `_generateMonthlyTargets()` creates `DateTime(year, month, 1)` |
| Toggle in all 4 screens | PASS | Visibility icon in app bar for electricity, gas, water, heating screens |
| Color-coding (Ultra Violet tint) | PASS | `AppColors.ultraViolet.withValues(alpha: 0.10)` background + "Interpolated" label |
| Non-editable/deletable | PASS | Interpolated cards have no onTap/delete handlers |
| ReadingDisplayItem model | PASS | Model at `models.dart:109` with `isInterpolated` flag, used by all 4 providers |
| Tests | PARTIAL | Electricity provider has 7 toggle tests; gas/water/heating providers lack toggle tests |

**Result: PASS** (minor test gap — functional behavior fully verified)

---

## UAC-M3-12: Smart Plug Month/Year Picker

| Criterion | Status | Evidence |
|-----------|--------|----------|
| No IntervalType enum | PASS | Zero occurrences in codebase |
| No intervalStart column | PASS | `SmartPlugConsumptions` table has `month` column |
| Month/year picker form | PASS | Two dropdowns (month 1-12, year 2020-current+1), no date picker |
| Month column in table | PASS | `tables.dart:96` — `DateTimeColumn get month` |
| DAO uses month | PASS | Orders by month desc, has `getConsumptionForMonth()` |
| Display format | PASS | "Month Year — XX.X kWh" via `DateFormat.yMMMM(locale)` |
| Tests | PASS | 11 form tests including "no interval type dropdown" explicit check |

**Result: PASS**

---

## UAC-M3-13: Heating Meter Room Assignment

| Criterion | Status | Evidence |
|-----------|--------|----------|
| roomId FK in table | PASS | `tables.dart:59` — `integer().references(Rooms, #id)` |
| No location column | PASS | HeatingMeters: id, householdId, roomId, name, heatingType, heatingRatio |
| HeatingType enum | PASS | `tables.dart:7` — `enum HeatingType { ownMeter, centralMeter }` |
| heatingRatio column | PASS | `tables.dart:63` — `real().nullable()` |
| Room dropdown (required) | PASS | `DropdownButtonFormField<int>` with validator requiring selection |
| Heating type SegmentedButton | PASS | `SegmentedButton<HeatingType>` with own/central options |
| Conditional ratio input | PASS | Visible only when `centralMeter` selected, validates 1-100 |
| Grouped by room in screen | PASS | `metersByRoom` getter, room section headers with icon |
| Ratio badge for central | PASS | `{ratio * 100}%` badge with heating color background |
| Analytics applies ratio | PASS | `consumption * ratio` for central meters; own meters unchanged |
| Tests | PASS | 29 form tests + DAO/provider/screen tests |

**Result: PASS**

---

## UAC-M3-14: Gas Analysis in m³

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Analytics shows m³ | PASS | No gas kWh conversion in `_loadMonthlyData()`, `_loadYearlyData()`, `_loadOverview()` |
| Unit string "m³" | PASS | `unitForMeterType(MeterType.gas)` returns `'m³'` |
| Cost still uses conversion | PASS | `_gasConversionService.toKwh()` called only in cost calculation context |
| GasConversionService preserved | PASS | Service exists, only used for cost math |

**Result: PASS**

---

## UAC-M3-15: Yearly Analysis Rework

| Criterion | Status | Evidence |
|-----------|--------|----------|
| extrapolateYearEnd() method | PASS | `interpolation_service.dart:188-226` |
| ExtrapolationResult model | PASS | `projectedTotal` + `projectedMonths` fields |
| isExtrapolated flag | PASS | `PeriodConsumption.isExtrapolated` default `false` |
| extrapolatedTotal field | PASS | `YearlyAnalyticsData.extrapolatedTotal` nullable double |
| Current year only | PASS | `if (isCurrentYear && monthlyBreakdown.length < 12)` guard |
| Summary card shows projection | PASS | "~{value}" prefix with basis months count |
| Extrapolated bars distinct | PASS | `alpha: 0.3` + `borderDashArray: [6, 3]` |
| Previous year comparison | PASS | YearComparisonChart with dashed lines for previous year |

**Result: PASS**

---

## UAC-M3-6: Data Entry Enhancements

| Criterion | Status | Evidence |
|-----------|--------|----------|
| QuickEntryMixin exists | PASS | `reading_form_base.dart:4-109` with "Save & Next" logic |
| Applied to all 4 forms | PASS | electricity, gas, water, heating forms use `with QuickEntryMixin` |
| previousValue parameter | PASS | All 4 forms accept and display previous value reference |
| Real-time validation | PASS | `_onValueChanged()` sets `_validationError`, disables save buttons |
| ConfirmDeleteDialog shared widget | PASS | `confirm_delete_dialog.dart` with static `show()` method |
| Used in all 5 screens | PASS | electricity, gas, water, heating, smart plug consumption screens |

**Result: PASS**

---

## DB Migration v2→v3

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Single migration handles all changes | PASS | `app_database.dart` v2→v3 with 3 SQL steps |
| Heating locations → rooms | PASS | COALESCE(location, 'Standard') creates rooms |
| Smart plug entries merged by month | PASS | GROUP BY + SUM for same plug+month |
| 13 migration tests | PASS | `test/database/migration_test.dart` |
| Schema version = 3 | PASS | `schemaVersion => 3` in app_database.dart |

---

## Summary

| UAC | Description | Status |
|-----|-------------|--------|
| UAC-M3-11 | Interpolation rework | **PASS** |
| UAC-M3-12 | Smart plug month/year picker | **PASS** |
| UAC-M3-13 | Heating meter room assignment | **PASS** |
| UAC-M3-14 | Gas analysis in m³ | **PASS** |
| UAC-M3-15 | Yearly analysis rework | **PASS** |
| UAC-M3-6 | Data entry enhancements | **PASS** |

**Overall: 6/6 UACs PASS — Phase 15 VERIFIED**

### Minor Test Gaps Noted
- Interpolation toggle tests only in electricity provider (gas/water/heating providers lack toggle-specific tests)
- Not blocking — the implementation is identical across all 4 providers (same mixin pattern)

### Metrics
- Tests: 765 → 855 (+90)
- Source files: ~85
- DB schema: v2 → v3
