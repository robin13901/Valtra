---
name: flutter-cost-settings-household-config
domain: settings, db, ui
tech: [flutter, dart, drift, provider, material3, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-09
---

## Context
Use this pattern when restructuring configuration data from global settings to entity-scoped settings with history (multiple profiles per entity). Applicable to any Flutter app that needs per-entity config with date-based lookup.

## Pattern

### Tasks

#### Wave 1: Calculation Logic & Localization (parallel)
- Update cost/calculation logic for new unit (annual→monthly conversion: ÷12)
- Rename localization strings (Grundgebühr→Grundpreis, unit_price→energy_price)
- Defer removal of old ARB keys until consuming widget is deleted

#### Wave 2: Form Dialog + Settings Screen
- Create profile form dialog (date picker + numeric fields, Cancel + Save)
- Create expandable card UI per category (header always visible, +add button, expand to show profile list)
- Active profile badge (latest validFrom ≤ now)
- PopupMenuButton for edit/delete per profile

#### Wave 3: Integration
- Move config section from global settings to entity-specific settings
- Add navigation ListTile in original settings location
- Clean up old ARB keys
- Update DAO @DriftAccessor to include new table access

#### Wave 4: Analytics Integration
- Verify cost calculation flows through updated path
- Update "configure in Settings" strings to reference new location

#### Wave 5: Verification

### Key Decisions
1. **No DB migration needed**: user re-enters annual values (personal app, few entries)
2. **Expandable card state**: local `_isExpanded` in StatefulWidget, no provider needed
3. **Profile ordering**: `validFrom DESC` — most recent first
4. **Active badge logic**: latest `validFrom ≤ DateTime.now()` gets "Aktiv" chip
5. **Annual→monthly conversion**: caller's responsibility (÷12), not the calculation service

### Common Pitfalls
- Adding table to `@DriftAccessor(tables: [...])` requires `build_runner` to regenerate DAO mixin
- ARB key renames: update all `l10n.oldKey` usages in the same commit or tests break
- Date picker with `InkWell + InputDecorator` for consistent field aesthetics (not a raw button)
- `intEnum` column: adding new enum value at end preserves existing ordinals — no migration

### Wave Structure
```
Wave 1 (parallel): Calculation logic, localization
Wave 2 (sequential): Form dialog, settings screen
Wave 3: Integration (move from global to entity-scoped)
Wave 4: Analytics label update
Wave 5: Verification
```
