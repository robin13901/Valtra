---
phase: 7
title: Heating Meter Tracking
date: 2026-03-07
result: PASS (7/7)
---

# Phase 7 UAT: Heating Meter Tracking

## Summary

| # | Criterion | Result |
|---|-----------|--------|
| H1 | Create Heating Meter | PASS |
| H2 | Create Meter Without Location | PASS |
| H3 | Add First Reading | PASS |
| H4 | Add Subsequent Reading | PASS |
| H5 | Delete Meter Cascade | PASS |
| H6 | Validation Error | PASS |
| H7 | Navigation | PASS |

## Test Details

### UAC-H1: Create Heating Meter — PASS
- FAB on HeatingScreen calls `_addMeter()` → opens `HeatingMeterFormDialog`
- Dialog has name (required) + location (optional) fields
- `_onSave()` returns `HeatingMeterFormData(name, location)`
- Provider calls `_dao.insertMeter()` with `HeatingMetersCompanion.insert()`
- Stream subscription on `watchMetersForHousehold()` updates UI
- Card shows meter name + location with `Icons.location_on` icon

### UAC-H2: Create Meter Without Location — PASS
- Location field has no validator (optional)
- `_onSave()` returns `location: location.isEmpty ? null : location`
- DB schema: `text().nullable()` in tables.dart
- UI: `if (widget.meter.location != null)` — conditionally renders location row

### UAC-H3: Add First Reading — PASS
- `getReadingsWithDeltas()`: for single reading, `previous = null`, so `delta = null`
- Screen: `if (delta != null) ... else Text(l10n.firstReading)` — shows "First reading"

### UAC-H4: Add Subsequent Reading — PASS
- Delta: `current.value - previous.value` = 1050.5 - 1000.0 = 50.5
- Formatter: `NumberFormat('#,##0.0', 'en').format(50.5)` = "50.5"
- l10n: `heatingConsumptionSince` = "+{value} units since previous" → "+50.5 units since previous"

### UAC-H5: Delete Meter Cascade — PASS
- `_deleteMeter()` calls `getReadingCountForMeter()` before dialog
- Dialog shows `heatingMeterHasReadings(count)` = "This meter has 3 reading(s). They will also be deleted."
- DAO `deleteMeter()` wraps in `transaction()`: deletes readings first, then meter

### UAC-H6: Validation Error — PASS
- `validateReading()`: previous=1000.0, value=950.0, 950 < 1000 → returns `NumberFormat('#,##0.0').format(1000.0)` = "1,000.0"
- Screen shows `heatingReadingMustBeGreaterOrEqual("1,000.0")` = "Value must be >= 1,000.0"

### UAC-H7: Navigation — PASS
- Home screen heating chip has `onTap: () => _navigateToHeating(context)`
- Method checks household selection, shows snackbar if null, pushes `HeatingScreen` if valid

## Test Coverage

- 313 tests pass (0 failures)
- 0 flutter analyze issues
- New tests: 61 (20 DAO + 18 provider + 10 screen + 7 meter dialog + 6 reading dialog)
