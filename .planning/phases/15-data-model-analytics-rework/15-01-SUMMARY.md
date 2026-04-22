# Phase 15 Plan 01: Interpolation Rework & Visibility Toggle Summary

## One-liner
Remove step interpolation, add toggle to show/hide interpolated 1st-of-month boundary values in reading lists with Ultra Violet color-coding.

## Completed Tasks

| Task | Description | Status |
|------|-------------|--------|
| T1 | Clean up step interpolation remnants | Done |
| T2 | Add interpolated values to reading list providers | Done |
| T3 | Add interpolation toggle UI to reading screens | Done |
| T4 | Localize new strings | Done |
| T5 | Tests | Done |

## Changes Made

### T1: Step Interpolation Removal
- Removed `InterpolationMethod.step` from enum (now linear-only)
- Removed step-function branch from `interpolateAt()`
- Removed `method` parameter from `interpolateAt()`, `getMonthlyBoundaries()`, `getMonthlyConsumption()`
- Removed `getMethodForMeterType()` and `setMethodForMeterType()` from `InterpolationSettingsProvider`
- Cleaned up all callers in `AnalyticsProvider` (3 methods), `SmartPlugAnalyticsProvider` (1 method)
- Removed `settingsProvider` dependency from `SmartPlugAnalyticsProvider` constructor

### T2: Provider Display Items
- Added `ReadingDisplayItem` wrapper model to `models.dart` (timestamp, value, isInterpolated, delta, readingId)
- Added `showInterpolatedValues` boolean + `toggleInterpolatedValues()` to all 4 providers
- Added `displayItems` getter to `ElectricityProvider` and `GasProvider`
- Added `getDisplayItems(meterId)` to `WaterProvider` and `HeatingProvider`
- Interpolated boundaries computed via `InterpolationService.getMonthlyBoundaries()` and merged sorted newest-first

### T3: Screen UI Updates
- Added eye icon toggle button to all 4 reading screen app bars
- `_InterpolatedReadingCard` widget for electricity/gas (GlassCard with Ultra Violet 10% tint)
- ListTile with `tileColor` for water/heating interpolated entries
- "Interpoliert"/"Interpolated" label badge on all interpolated entries
- Interpolated entries have no edit/delete menu (non-editable)
- Added `color` parameter to `GlassCard` widget

### T4: Localization
- Added 3 new l10n keys: `interpolatedValue`, `showInterpolatedValues`, `hideInterpolatedValues`
- EN: "Interpolated value", "Show interpolated values", "Hide interpolated values"
- DE: "Interpolierter Wert", "Interpolierte Werte anzeigen", "Interpolierte Werte ausblenden"

### T5: Tests
- Updated `models_test.dart`: step enum test replaced with linear-only + ReadingDisplayItem tests
- Updated `interpolation_service_test.dart`: removed 3 step tests, added linear-only verification
- Updated `interpolation_settings_provider_test.dart`: removed method tests, kept gas factor tests
- Updated `analytics_provider_test.dart` and `analytics_provider_yearly_test.dart`: removed all `getMethodForMeterType` stubs and `method:` mock parameters
- Updated `smart_plug_analytics_provider_test.dart`: removed settings provider dependency
- Added 6 new tests to `electricity_provider_test.dart`: toggle state, notify listeners, display items with/without toggle

## Key Files Modified
- `lib/services/interpolation/models.dart` - InterpolationMethod enum, ReadingDisplayItem class
- `lib/services/interpolation/interpolation_service.dart` - Removed method params
- `lib/providers/interpolation_settings_provider.dart` - Removed method methods
- `lib/providers/electricity_provider.dart` - Toggle + displayItems
- `lib/providers/gas_provider.dart` - Toggle + displayItems
- `lib/providers/water_provider.dart` - Toggle + getDisplayItems
- `lib/providers/heating_provider.dart` - Toggle + getDisplayItems
- `lib/providers/analytics_provider.dart` - Removed method usage
- `lib/providers/smart_plug_analytics_provider.dart` - Removed settingsProvider
- `lib/screens/electricity_screen.dart` - Toggle UI + interpolated cards
- `lib/screens/gas_screen.dart` - Toggle UI + interpolated cards
- `lib/screens/water_screen.dart` - Toggle UI + interpolated list tiles
- `lib/screens/heating_screen.dart` - Toggle UI + interpolated list tiles
- `lib/widgets/liquid_glass_widgets.dart` - GlassCard color param
- `lib/l10n/app_en.arb` - 3 new keys
- `lib/l10n/app_de.arb` - 3 new keys
- `lib/main.dart` - Removed settingsProvider from SmartPlugAnalyticsProvider

## Deviations from Plan
None - plan executed exactly as written.

## Verification Results
- [x] Step interpolation fully removed (no `InterpolationMethod.step` anywhere in lib or test)
- [x] Interpolated values appear at 1st of month 00:00 when toggle is ON
- [x] Interpolated values visually distinct (Ultra Violet tint + label)
- [x] Interpolated values are not editable/deletable
- [x] Toggle persists within session (not across restarts)
- [x] Analytics calculations unchanged
- [x] All existing tests pass + new tests added: 771 total (was 765)

## Commit
`942f2f5` feat(15-01): interpolation rework -- remove step, add toggle, color-code
