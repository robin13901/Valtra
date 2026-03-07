# Valtra v0.3.0 Requirements — Polish & Enhancement

**Milestone**: 3 — Polish & Enhancement (v0.3.0)
**Status**: IN PROGRESS
**Predecessor**: v0.2.0 — Analytics & Visualization (4 phases, 625 tests)

---

## Functional Requirements

### FR-10: Settings & Configuration

#### FR-10.1: Theme Management
- [ ] **FR-10.1.1**: Provide 3-way theme toggle: Light / Dark / System (default: System)
- [ ] **FR-10.1.2**: Persist theme selection across app restarts (SharedPreferences)
- [ ] **FR-10.1.3**: Dark theme uses Ultra Violet/Lemon Chiffon palette with inverted contrast
- [ ] **FR-10.1.4**: All screens and components render correctly in both light and dark modes
- [ ] **FR-10.1.5**: Theme changes apply immediately without app restart

#### FR-10.2: Settings Screen
- [ ] **FR-10.2.1**: Dedicated settings screen accessible from home screen
- [ ] **FR-10.2.2**: Theme toggle section with visual preview
- [ ] **FR-10.2.3**: Gas kWh conversion factor configuration (currently in InterpolationSettingsProvider — move to settings)
- [ ] **FR-10.2.4**: Interpolation method configuration per meter type
- [ ] **FR-10.2.5**: App version and about section

### FR-11: Cost Tracking

#### FR-11.1: Cost Configuration
- [ ] **FR-11.1.1**: Configure price per unit for each meter type (electricity: €/kWh, gas: €/kWh or €/m³, water: €/m³)
- [ ] **FR-11.1.2**: Configure monthly standing charge per meter type (Grundgebühr)
- [ ] **FR-11.1.3**: Support tiered pricing with up to 3 tiers (e.g., first 100 kWh at rate A, next 200 at rate B, rest at rate C)
- [ ] **FR-11.1.4**: Persist cost configuration per household
- [ ] **FR-11.1.5**: Allow different pricing for different time periods (e.g., price change on 2026-01-01)

#### FR-11.2: Cost Calculation
- [ ] **FR-11.2.1**: Calculate monthly cost from consumption delta × price per unit + standing charge
- [ ] **FR-11.2.2**: Apply tiered pricing correctly (cumulative tiers per billing period)
- [ ] **FR-11.2.3**: Handle gas cost in both m³ and kWh modes (using existing GasConversionService)
- [ ] **FR-11.2.4**: CostCalculationService as pure business logic with no UI dependencies

#### FR-11.3: Cost Display
- [ ] **FR-11.3.1**: Show cost alongside consumption in monthly analytics (e.g., "245 kWh — €78.50")
- [ ] **FR-11.3.2**: Show cost in yearly analytics with year-over-year cost comparison
- [ ] **FR-11.3.3**: Cost summary card on analytics hub showing total monthly/yearly costs
- [ ] **FR-11.3.4**: Cost column in CSV export (optional, when pricing configured)

### FR-12: UI/UX Polish

#### FR-12.1: LiquidGlass Enhancement
- [ ] **FR-12.1.1**: Apply GlassBottomNav as primary navigation (replacing current home screen chips)
- [ ] **FR-12.1.2**: Apply buildGlassFAB to all floating action buttons throughout the app
- [ ] **FR-12.1.3**: Apply GlassCard styling to all list items and summary cards
- [ ] **FR-12.1.4**: Apply buildGlassAppBar to all screens
- [ ] **FR-12.1.5**: Ensure consistent glass effect rendering in both light and dark themes

#### FR-12.2: Data Entry Enhancements
- [ ] **FR-12.2.1**: Quick entry mode: batch-add multiple readings in sequence without closing dialog
- [ ] **FR-12.2.2**: Reading validation: new reading must be >= previous reading for cumulative meters
- [ ] **FR-12.2.3**: Improve date/time picker UX: default to current date/time, show relative date
- [ ] **FR-12.2.4**: Show last reading value and date as hint in entry form
- [ ] **FR-12.2.5**: Confirmation dialog before deleting readings

### FR-13: Backup & Restore

#### FR-13.1: Database Export
- [ ] **FR-13.1.1**: Export full SQLite database file via system share sheet
- [ ] **FR-13.1.2**: Export filename includes timestamp (e.g., valtra_backup_20260307_143000.sqlite)
- [ ] **FR-13.1.3**: Export accessible from settings screen
- [ ] **FR-13.1.4**: Show export progress and success/failure feedback

#### FR-13.2: Database Import
- [ ] **FR-13.2.1**: Import database file from device file picker
- [ ] **FR-13.2.2**: Validate imported file is a valid Valtra database before replacing
- [ ] **FR-13.2.3**: Confirm import with warning that current data will be replaced
- [ ] **FR-13.2.4**: Restart app state after successful import (re-initialize providers)
- [ ] **FR-13.2.5**: Automatic backup of current database before import (safety net)

---

## Non-Functional Requirements

### NFR-8: Theme Consistency
- [ ] **NFR-8.1**: All screens render correctly in light, dark, and system-follow modes
- [ ] **NFR-8.2**: No hardcoded colors — all colors from Theme.of(context) or AppColors
- [ ] **NFR-8.3**: Charts (fl_chart) adapt colors to current theme
- [ ] **NFR-8.4**: Glass effects maintain visual quality in both themes

### NFR-9: Performance
- [ ] **NFR-9.1**: Cost calculations complete within 100ms for 12 months of data
- [ ] **NFR-9.2**: Database export completes within 5 seconds
- [ ] **NFR-9.3**: Database import + restart completes within 10 seconds
- [ ] **NFR-9.4**: Theme switching is instantaneous (no visible delay)

### NFR-10: Testing
- [ ] **NFR-10.1**: Achieve 80%+ statement coverage across the codebase
- [ ] **NFR-10.2**: Unit tests for CostCalculationService including all tier scenarios
- [ ] **NFR-10.3**: Widget tests for settings screen, cost display, and backup/restore flows
- [ ] **NFR-10.4**: Integration tests for critical user flows (add reading → view analytics → see cost)
- [ ] **NFR-10.5**: All existing 625 tests continue to pass

### NFR-11: Localization (Continuation)
- [ ] **NFR-11.1**: All new strings externalized to ARB files (EN + DE)
- [ ] **NFR-11.2**: Currency formatting follows device locale (€ for DE, user-configurable)
- [ ] **NFR-11.3**: Settings labels, cost terminology, backup messages all localized

### NFR-12: Data Integrity
- [ ] **NFR-12.1**: Cost configurations stored in database with household isolation
- [ ] **NFR-12.2**: Backup file contains complete database state (all tables, all households)
- [ ] **NFR-12.3**: Import validates schema compatibility before replacing database

---

## User Acceptance Criteria

### UAC-M3-1: Theme Switching
**Given** a user on any screen
**When** they change theme in settings (Light → Dark → System)
**Then** the entire app updates immediately with correct colors, glass effects, and chart styling

### UAC-M3-2: Cost Configuration
**Given** a user with electricity readings
**When** they configure €0.30/kWh base rate + €12.50/month standing charge + tiered pricing
**Then** the monthly analytics shows correct cost breakdown alongside consumption

### UAC-M3-3: Cost in Analytics
**Given** configured pricing for electricity and gas
**When** viewing yearly analytics
**Then** cost totals and year-over-year cost comparison are displayed accurately

### UAC-M3-4: LiquidGlass Navigation
**Given** the app is open
**When** navigating between sections
**Then** GlassBottomNav provides smooth navigation with glass effects in both themes

### UAC-M3-5: Quick Entry
**Given** a user adding multiple meter readings
**When** they use quick entry mode
**Then** they can submit multiple readings without re-opening the dialog each time

### UAC-M3-6: Reading Validation
**Given** a meter with a previous reading of 1000 kWh
**When** the user enters a new reading of 950 kWh
**Then** a validation error is shown (reading cannot decrease for cumulative meters)

### UAC-M3-7: Database Backup
**Given** a user with data across multiple households
**When** they export the database from settings
**Then** a .sqlite file is shared via system share sheet with all data intact

### UAC-M3-8: Database Restore
**Given** a user with a backup file
**When** they import it via settings
**Then** the app replaces the current database, restarts state, and shows the restored data

### UAC-M3-9: Settings Screen
**Given** a user on the home screen
**When** they navigate to settings
**Then** they see theme toggle, cost configuration, interpolation settings, backup/restore, and app info

### UAC-M3-10: Test Coverage
**Given** all new code from Milestone 3
**Then** Codecov reports 80%+ statement coverage with all tests passing

---

## Requirements Traceability

| Requirement | Phase(s) | UAC | Priority |
|-------------|----------|-----|----------|
| FR-10 (Settings & Theme) | 12 | UAC-M3-1, UAC-M3-9 | High |
| FR-11 (Cost Tracking) | 13 | UAC-M3-2, UAC-M3-3 | High |
| FR-12 (UI/UX Polish) | 14 | UAC-M3-4, UAC-M3-5, UAC-M3-6 | Medium |
| FR-13 (Backup & Restore) | 15 | UAC-M3-7, UAC-M3-8 | Medium |
| NFR-8 (Theme Consistency) | 12, 14 | UAC-M3-1 | High |
| NFR-9 (Performance) | 13, 15 | — | Medium |
| NFR-10 (Testing) | 15 | UAC-M3-10 | High |
| NFR-11 (Localization) | 12-15 | — | Medium |
| NFR-12 (Data Integrity) | 13, 15 | UAC-M3-8 | High |
