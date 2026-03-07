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

### FR-12: UI/UX Polish & Localization

#### FR-12.1: Home Screen Cleanup
- [x] **FR-12.1.1**: Remove divider before Analyse button (direct placement)
- [x] **FR-12.1.2**: Remove non-functional FAB on home screen
- [x] **FR-12.1.3**: Apply GlassBottomNav as primary navigation (replacing current home screen chips)
- [x] **FR-12.1.4**: Apply buildGlassFAB to all screens with floating action buttons
- [x] **FR-12.1.5**: Apply GlassCard to all list items and summary cards
- [x] **FR-12.1.6**: Apply buildGlassAppBar to all screens

#### FR-12.2: Number & Date Formatting (German Locale)
- [x] **FR-12.2.1**: German number format everywhere: comma as decimal separator, dot as thousands separator (e.g., "1.234,5 kWh")
- [x] **FR-12.2.2**: Time display with "Uhr" suffix (e.g., "9:43 Uhr")
- [x] **FR-12.2.3**: Month names localized to device language (German: "Marz" not "March")
- [x] **FR-12.2.4**: Fix umlaut encoding everywhere — use a/o/u, never ae/oe/ue (Uber, Zahler, jahrlich, etc.)

#### FR-12.3: UI Element Cleanup
- [x] **FR-12.3.1**: Remove unit badges (kWh, m³) from all app bar headers (unit shown with each value already)
- [x] **FR-12.3.2**: Remove all non-clickable info icons (settings "Über" section, smart plug "Sonstige" kWh)
- [x] **FR-12.3.3**: Remove too-long hints in meter reading input fields (no hint needed)
- [x] **FR-12.3.4**: Style date/time picker fields as outlined input fields (matching meter reading field styling)
- [x] **FR-12.3.5**: No pre-selected room when adding new smart plug
- [x] **FR-12.3.6**: No hint text in smart plug name field
- [x] **FR-12.3.7**: Remove interpolation method setting from settings (only linear, remove step function)

#### FR-12.4: Dark Mode Fixes
- [x] **FR-12.4.1**: Black text on Lemon Chiffon accent backgrounds (white text unreadable)
- [ ] **FR-12.4.2**: Ensure all glass effects render correctly in both light and dark themes
- [x] **FR-12.4.3**: Smart plug detail: room subtitle readable in light theme (currently too small/thin)

#### FR-12.5: Water Screen Fixes
- [x] **FR-12.5.1**: Use filled icons everywhere (header AND entries) — cold water blue, hot water red, other gray
- [x] **FR-12.5.2**: Replace water type SegmentedButton with Dropdown (text wraps badly: "Kaltwe-/asar")

#### FR-12.6: Analysis Screen Cleanup
- [x] **FR-12.6.1**: Remove "Tagesverlauf" (daily view) from all analysis screens (monthly readings only)
- [x] **FR-12.6.2**: Remove custom date range feature (calendar icon in app bar) from all analysis screens
- [x] **FR-12.6.3**: Remove "Benutzerdefiniert" tab from smart plug analysis
- [x] **FR-12.6.4**: Rename "Monatsvergleich" to "Monatsverlauf"
- [x] **FR-12.6.5**: Analysis screens default to current month (not arbitrary past month)

#### FR-12.7: Language Setting
- [x] **FR-12.7.1**: Add language toggle (Deutsch / English) to settings screen
- [x] **FR-12.7.2**: Persist language selection across app restarts
- [x] **FR-12.7.3**: Language change applies immediately without app restart

### FR-13: Data Model & Analytics Rework

#### FR-13.1: Interpolation Rework
- [ ] **FR-13.1.1**: Calculate interpolated values for the 1st of each month at 00:00, from the two nearest real readings
- [ ] **FR-13.1.2**: Only create interpolated value when real readings exist both before and after the month boundary
- [ ] **FR-13.1.3**: Monthly consumption = difference between interpolated values at consecutive month starts
- [ ] **FR-13.1.4**: Toggle in readings list to show/hide interpolated values (default: hidden)
- [ ] **FR-13.1.5**: Interpolated values visually distinct (different color) when shown in list
- [ ] **FR-13.1.6**: Remove step function interpolation entirely (only linear)

#### FR-13.2: Smart Plug Entry Rework
- [ ] **FR-13.2.1**: Remove interval type selection from smart plug reading entry
- [ ] **FR-13.2.2**: Remove start date field from smart plug reading entry
- [ ] **FR-13.2.3**: Add month/year picker (e.g., "März 2026") as the only date input
- [ ] **FR-13.2.4**: Entry flow: select month → enter kWh value → save (monthly consumption for that plug)

#### FR-13.3: Heating Meter Rework
- [ ] **FR-13.3.1**: Remove optional "Standort" (location) text field from heating meters
- [ ] **FR-13.3.2**: Add mandatory room assignment (like smart plugs — select from room list)
- [ ] **FR-13.3.3**: Heating meters organized by room (same UI pattern as smart plugs)
- [ ] **FR-13.3.4**: Database migration: add room_id FK to heating meters, remove location field
- [ ] **FR-13.3.5**: Support use-case 1: own gas meter → direct monthly readings for household
- [ ] **FR-13.3.6**: Support use-case 2: central gas meter (shared building) + per-room heating meters showing percentage/ratio of total heating energy

#### FR-13.4: Gas Analysis Fix
- [ ] **FR-13.4.1**: Display gas consumption in m³ (as entered) instead of converting to kWh in analysis

#### FR-13.5: Yearly Analysis Rework
- [ ] **FR-13.5.1**: For current year: extrapolate consumption to end of year based on data so far
- [ ] **FR-13.5.2**: Show previous year's consumption alongside current year for comparison
- [ ] **FR-13.5.3**: Monthly breakdown within the displayed year (bar chart with 12 months)

#### FR-13.6: Data Entry Enhancements
- [ ] **FR-13.6.1**: Quick entry mode: batch-add multiple readings without closing dialog
- [ ] **FR-13.6.2**: Reading validation: new reading >= previous for cumulative meters
- [ ] **FR-13.6.3**: Confirmation dialog before deleting readings

### FR-14: Backup & Restore

#### FR-14.1: Database Export
- [ ] **FR-14.1.1**: Export full SQLite database file via system share sheet
- [ ] **FR-14.1.2**: Export filename includes timestamp (e.g., valtra_backup_20260307_143000.sqlite)
- [ ] **FR-14.1.3**: Export accessible from settings screen
- [ ] **FR-14.1.4**: Show export progress and success/failure feedback

#### FR-14.2: Database Import
- [ ] **FR-14.2.1**: Import database file from device file picker
- [ ] **FR-14.2.2**: Validate imported file is a valid Valtra database before replacing
- [ ] **FR-14.2.3**: Confirm import with warning that current data will be replaced
- [ ] **FR-14.2.4**: Restart app state after successful import (re-initialize providers)
- [ ] **FR-14.2.5**: Automatic backup of current database before import (safety net)

---

## Non-Functional Requirements

### NFR-8: Theme Consistency
- [ ] **NFR-8.1**: All screens render correctly in light, dark, and system-follow modes
- [ ] **NFR-8.2**: No hardcoded colors — all colors from Theme.of(context) or AppColors
- [ ] **NFR-8.3**: Charts (fl_chart) adapt colors to current theme
- [ ] **NFR-8.4**: Glass effects maintain visual quality in both themes
- [ ] **NFR-8.5**: Text on accent-colored backgrounds must be black (not white) for readability

### NFR-9: Performance
- [ ] **NFR-9.1**: Cost calculations complete within 100ms for 12 months of data
- [ ] **NFR-9.2**: Database export completes within 5 seconds
- [ ] **NFR-9.3**: Database import + restart completes within 10 seconds
- [ ] **NFR-9.4**: Theme switching is instantaneous (no visible delay)
- [ ] **NFR-9.5**: Interpolation calculations complete within 100ms for 24 months of data

### NFR-10: Testing
- [ ] **NFR-10.1**: Achieve 80%+ statement coverage across the codebase
- [ ] **NFR-10.2**: Unit tests for CostCalculationService including all tier scenarios
- [ ] **NFR-10.3**: Widget tests for settings screen, cost display, and backup/restore flows
- [ ] **NFR-10.4**: Integration tests for critical user flows (add reading → view analytics → see cost)
- [ ] **NFR-10.5**: All existing 707 tests continue to pass

### NFR-11: Localization (Continuation)
- [ ] **NFR-11.1**: All new strings externalized to ARB files (EN + DE)
- [ ] **NFR-11.2**: Number formatting follows device locale (German: 1.234,5 — English: 1,234.5)
- [ ] **NFR-11.3**: Currency formatting follows device locale (€ for DE, user-configurable)
- [ ] **NFR-11.4**: Settings labels, cost terminology, backup messages all localized
- [ ] **NFR-11.5**: Umlauts rendered correctly everywhere (ä/ö/ü, never ae/oe/ue)
- [ ] **NFR-11.6**: Month names, weekdays localized via intl package
- [ ] **NFR-11.7**: In-app language toggle (DE/EN) independent of device locale

### NFR-12: Data Integrity
- [ ] **NFR-12.1**: Cost configurations stored in database with household isolation
- [ ] **NFR-12.2**: Backup file contains complete database state (all tables, all households)
- [ ] **NFR-12.3**: Import validates schema compatibility before replacing database
- [ ] **NFR-12.4**: Heating meter room assignments maintain referential integrity (FK to rooms table)

---

## User Acceptance Criteria

### UAC-M3-1: Theme Switching
**Given** a user on any screen
**When** they change theme in settings (Light → Dark → System)
**Then** the entire app updates immediately with correct colors, glass effects, and chart styling — text on accent backgrounds is always readable

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

### UAC-M3-5: German Number Formatting
**Given** the app language is set to Deutsch
**When** viewing any meter reading or consumption value
**Then** numbers use comma as decimal separator, dot as thousands separator (e.g., "1.234,5 kWh"), time shows "Uhr" suffix

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
**Then** they see theme toggle, language toggle, cost configuration, gas conversion factor, backup/restore, and app info (no interpolation method, no non-clickable icons)

### UAC-M3-10: Test Coverage
**Given** all new code from Milestone 3
**Then** Codecov reports 80%+ statement coverage with all tests passing

### UAC-M3-11: Monthly Interpolation
**Given** meter readings on 1.12.2025 and 1.1.2026 and 1.2.2026
**When** viewing the readings list with interpolation toggle ON
**Then** interpolated values for 1.1.2026 00:00 and 1.2.2026 00:00 are shown in a distinct color, and monthly consumption in analytics uses these interpolated boundaries

### UAC-M3-12: Smart Plug Monthly Entry
**Given** a user adding smart plug consumption
**When** they tap the add button
**Then** they see a month/year picker and a value field (no interval type, no start date)

### UAC-M3-13: Heating Meter Rooms
**Given** a user adding a heating meter
**When** they fill the form
**Then** they must select a room (mandatory) — no "Standort" text field; heating meters are grouped by room like smart plugs

### UAC-M3-14: Gas Analysis in m³
**Given** gas meter readings entered in m³
**When** viewing gas analysis
**Then** consumption is displayed in m³ (not converted to kWh)

### UAC-M3-15: Yearly Analysis
**Given** readings for the current year
**When** viewing yearly analysis
**Then** extrapolated consumption to year-end is shown, with previous year comparison and monthly breakdown

### UAC-M3-16: Language Toggle
**Given** a user in settings
**When** they switch language from Deutsch to English (or vice versa)
**Then** the entire app updates immediately to the selected language

---

## Requirements Traceability

| Requirement | Phase(s) | UAC | Priority |
|-------------|----------|-----|----------|
| FR-10 (Settings & Theme) | 12 | UAC-M3-1, UAC-M3-9 | High |
| FR-11 (Cost Tracking) | 13 | UAC-M3-2, UAC-M3-3 | High |
| FR-12 (UI/UX Polish & Localization) | 14 | UAC-M3-4, UAC-M3-5, UAC-M3-9, UAC-M3-16 | High |
| FR-13 (Data Model & Analytics Rework) | 15 | UAC-M3-11, UAC-M3-12, UAC-M3-13, UAC-M3-14, UAC-M3-15 | High |
| FR-14 (Backup & Restore) | 16 | UAC-M3-7, UAC-M3-8 | Medium |
| NFR-8 (Theme Consistency) | 12, 14 | UAC-M3-1 | High |
| NFR-9 (Performance) | 13, 15, 16 | — | Medium |
| NFR-10 (Testing) | 16 | UAC-M3-10 | High |
| NFR-11 (Localization) | 14-16 | UAC-M3-5, UAC-M3-16 | High |
| NFR-12 (Data Integrity) | 13, 15, 16 | UAC-M3-8, UAC-M3-13 | High |
