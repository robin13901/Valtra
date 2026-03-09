# Phase 18 Context — Cost Settings & Household Configuration

## Phase Goal
Restructure cost configuration to support per-household, per-meter-type cost profile history with date-based lookup, rename pricing fields to German energy conventions, and move cost settings from global settings into household-specific settings.

## Requirements Coverage
- **FR-16.1**: Extend cost_configs to support multiple profiles per meter type per household (history)
- **FR-16.2**: Rename fields: "Grundgebühr pro Monat" → "Grundpreis pro Jahr", "Preis pro Einheit" → "Arbeitspreis"
- **FR-16.3**: Update cost calculation to use annual Grundpreis (÷12 for monthly)
- **FR-16.4**: Field order in forms: Gültig ab, Grundpreis pro Jahr, Arbeitspreis
- **FR-16.5**: Card design like water meters: main header per meter type, expandable sub-entries per cost profile
- **FR-16.6**: Move cost configuration from general settings to household-specific settings
- **FR-16.7**: Cost lookup by date: calculation uses correct profile for each time period
- **NFR-14**: Localization (EN + DE) for all changes
- **NFR-15**: Comprehensive tests for cost profile CRUD and date-based lookup

## UAC Traceability
| UAC | Description |
|-----|-------------|
| UAC-M4-2 | Cost profiles: multiple per meter type per household, date-based history |
| UAC-M4-3 | Field labels: "Grundpreis pro Jahr" and "Arbeitspreis" (DE); "Annual Base Price" and "Energy Price" (EN) |
| UAC-M4-4 | Cost calculation: annual Grundpreis ÷ 12, pro-rated for partial months |
| UAC-M4-5 | Form field order: Gültig ab → Grundpreis pro Jahr → Arbeitspreis |
| UAC-M4-6 | Card UI: expandable per-meter-type header with cost profile sub-entries |
| UAC-M4-7 | Cost config moved to household settings (not global settings) |
| UAC-M4-8 | Date-based cost lookup: correct profile used for each time period |

## Key Codebase Findings

### Database Schema (lib/database/tables.dart)
- CostConfigs table (lines 104-118): already supports multiple profiles per household+meterType via householdId FK + validFrom date
- Fields: id, householdId, meterType (enum), unitPrice, standingCharge (default 0.0), priceTiers (JSON nullable), currencySymbol (default €), validFrom, createdAt
- **No schema migration needed** — existing table already supports history
- Current schema: v3 (app_database.dart line 41)

### Cost DAO (lib/database/daos/cost_config_dao.dart)
- `getActiveConfig(householdId, meterType, date)` — already implements date-based lookup (latest validFrom ≤ date)
- `getConfigsForMeterType(householdId, meterType)` — returns all profiles ordered by validFrom DESC
- `watchConfigsForHousehold(householdId)` — reactive stream for all configs
- CRUD: insertConfig, updateConfig, deleteConfig — all functional
- **No DAO changes needed** for core functionality

### Cost Calculation Service (lib/services/cost_calculation_service.dart)
- `calculateMonthlyCost()` (lines 43-74): currently treats `standingCharge` as monthly value
- Pro-ration: `standingCharge * (daysInPeriod / daysInMonth)` — works for partial months
- **Must change**: standingCharge field now stores annual Grundpreis → divide by 12 before pro-ration
- PriceTier, CostResult classes — no changes needed

### Cost Config Provider (lib/providers/cost_config_provider.dart)
- Already household-scoped (setHouseholdId method)
- `calculateCost()` (lines 69-92): passes config.standingCharge directly to service
- **Must update**: pass `config.standingCharge / 12` to service instead of raw value
- Or alternatively: handle conversion in the service itself

### Settings Screen (lib/screens/settings_screen.dart)
- `_buildCostConfigSection()` (lines 189-209): currently shows one card per meter type with ONLY the active config
- `_CostConfigCard` (lines 452-711): inline form with unitPrice, standingCharge, validFrom fields
  - Field labels: "Preis pro Einheit" / "Grundgebühr (pro Monat)" — need renaming
  - Field order: unitPrice → standingCharge → validFrom — must reverse to: validFrom → standingCharge → unitPrice
  - No expandable design, no profile history
  - Save button inline per card, delete via icon button in header
- **Must completely rework**: remove from settings, create new household cost settings screen

### Household DAO (lib/database/daos/household_dao.dart)
- `hasRelatedData()` (lines 59-91): checks ElectricityReadings, GasReadings, WaterMeters, HeatingMeters, Rooms
- **Does NOT check CostConfigs** — should be added for data integrity

### Water Screen Card Pattern (lib/screens/water_screen.dart)
- `_WaterMeterCard` (lines 120-785): expandable card with GlassCard wrapper, InkWell header, expand/collapse toggle
- Header: icon + name + type badge + expand icon + popup menu
- Expanded: divider + content list
- **Template for cost profile cards**: header per meter type, expandable list of profiles

### Localization (lib/l10n/app_en.arb, app_de.arb)
- Existing cost strings: unitPrice, standingChargePerMonth, validFrom, costConfiguration, etc.
- Need new strings: annualBasePrice, energyPrice, costProfile, addCostProfile, editCostProfile, noCostProfiles, perYear, householdCostSettings
- Need renamed strings: unitPrice → energyPrice, standingChargePerMonth → annualBasePrice

### Existing Tests
- cost_config_dao_test.dart (325 lines): comprehensive CRUD + date-based lookup + stream + isolation tests
- cost_config_provider_test.dart (267 lines): state management + calculation + CRUD delegation tests
- settings_screen_test.dart: tests cost config section rendering + interactions

## Dependencies
- Phase 17 complete (global UI fixes, form button pattern)
- No schema migration needed (existing table supports requirements)
- Provider already household-scoped

## Constraints
- Do NOT change existing database schema (no migration needed)
- Preserve all existing cost calculation behavior (only change standing charge interpretation)
- All existing tests must continue to pass after field rename adjustments
- Zero flutter analyze issues
