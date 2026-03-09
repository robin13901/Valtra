# Valtra v0.4.0 Requirements — UX Overhaul

**Milestone**: 4 — UX Overhaul (v0.4.0)
**Status**: IN PROGRESS
**Predecessor**: v0.3.0 — Polish & Enhancement (5 phases, 1017 tests)

---

## Functional Requirements

### FR-15: Home Screen & Global UI Fixes

#### FR-15.1: Household Dropdown Text Color
- [ ] **FR-15.1.1**: Fix household dropdown text in AppBar — dark/black text in light mode (currently white on white, unreadable)
- [ ] **FR-15.1.2**: Maintain current readable text color in dark mode

#### FR-15.2: Remove Home Screen Bottom Navigation
- [ ] **FR-15.2.1**: Remove the GlassBottomNav from the home screen entirely
- [ ] **FR-15.2.2**: Home screen is now a single scrollable page with the tile grid only

#### FR-15.3: Remove Global Analyse Tile & Screen
- [ ] **FR-15.3.1**: Remove the "Analyse" tile from the home screen grid
- [ ] **FR-15.3.2**: Remove the AnalyticsScreen (analytics hub) and all navigation to it
- [ ] **FR-15.3.3**: Clean up related routes, imports, and dead code

#### FR-15.4: Reorder Home Screen Tiles
- [ ] **FR-15.4.1**: Row 1 (left to right): Strom, Smart Home
- [ ] **FR-15.4.2**: Row 2 (left to right): Gas, Heizung
- [ ] **FR-15.4.3**: Row 3 (center): Wasser (single tile, centered)
- [ ] **FR-15.4.4**: Maintain existing tile design (GlassCard, icons, colors) — do NOT change visual design

#### FR-15.5: Remove "Save & Continue" from Forms
- [ ] **FR-15.5.1**: Remove "Save & Continue" / "Speichern und Weiter" button from all reading form dialogs
- [ ] **FR-15.5.2**: Keep only "Cancel" and "Save" buttons
- [ ] **FR-15.5.3**: Cancel and Save buttons must be side-by-side (horizontal), not stacked vertically
- [ ] **FR-15.5.4**: Remove QuickEntryMixin and related quick-entry logic

#### FR-15.6: Global Date/Time Format
- [ ] **FR-15.6.1**: All date/time displays must use format: "dd.MM.yyyy, HH:mm Uhr"
- [ ] **FR-15.6.2**: "Uhr" must be a localized string (DE = "Uhr", EN = "")
- [ ] **FR-15.6.3**: In English locale, format becomes "dd.MM.yyyy, HH:mm" (no suffix)
- [ ] **FR-15.6.4**: Apply consistently across all screens (reading lists, cards, charts, forms)

#### FR-15.7: Remove CSV Export Feature
- [ ] **FR-15.7.1**: Remove CSV export button from all analytics screens
- [ ] **FR-15.7.2**: Remove CSV export service/logic
- [ ] **FR-15.7.3**: Remove csv and share_plus dependencies (if only used for CSV — check backup uses share_plus)
- [ ] **FR-15.7.4**: Clean up related l10n keys, imports, and dead code

---

### FR-16: Cost Settings & Household Configuration

#### FR-16.1: Per-Household Cost Profile History
- [ ] **FR-16.1.1**: Support multiple cost configurations per meter type per household (history of price changes)
- [ ] **FR-16.1.2**: Each cost profile has a "valid from" date (Gültig ab)
- [ ] **FR-16.1.3**: Cost calculation uses the correct profile for each time period based on valid-from dates
- [ ] **FR-16.1.4**: Example: electricity Arbeitspreis 0.25 €/kWh from 25.07.2024, then 0.27 €/kWh from 01.01.2026

#### FR-16.2: Rename Cost Fields
- [ ] **FR-16.2.1**: "Grundgebühr pro Monat" → "Grundpreis pro Jahr" (base price per year, not per month)
- [ ] **FR-16.2.2**: "Preis pro Einheit" → "Arbeitspreis" (unit price → working price)
- [ ] **FR-16.2.3**: Update all l10n keys (EN + DE) accordingly
- [ ] **FR-16.2.4**: Update cost calculation to use annual base price (divide by 12 for monthly)

#### FR-16.3: Cost Form Field Order
- [ ] **FR-16.3.1**: Field order in cost config form: 1) Gültig ab (date), 2) Grundpreis pro Jahr, 3) Arbeitspreis

#### FR-16.4: Cost Config Card Design
- [ ] **FR-16.4.1**: Card design like water meter cards — main item header (e.g., "Strom") with expandable sub-entries for each cost profile
- [ ] **FR-16.4.2**: Each sub-entry shows valid-from date, Grundpreis, Arbeitspreis
- [ ] **FR-16.4.3**: Support add/edit/delete of individual cost profiles within the card

#### FR-16.5: Move to Household Settings
- [ ] **FR-16.5.1**: Cost configuration moves from general settings to household-specific settings
- [ ] **FR-16.5.2**: Each household has its own cost profiles for electricity, gas, and water
- [ ] **FR-16.5.3**: Accessible via household management or a dedicated household settings section

---

### FR-17: Electricity Screen Overhaul

#### FR-17.1: Bottom Navigation (List/Analysis)
- [ ] **FR-17.1.1**: Add LiquidGlass bottom navigation bar (like XFin Assets screen pattern)
- [ ] **FR-17.1.2**: Left nav item = "Analyse", Right nav item = "Liste"
- [ ] **FR-17.1.3**: Default view = Liste (right tab)
- [ ] **FR-17.1.4**: Use IndexedStack for tab content (preserves state when switching)

#### FR-17.2: LiquidGlass FAB
- [ ] **FR-17.2.1**: Add button uses LiquidGlass FAB style (like XFin buildCircleButton)
- [ ] **FR-17.2.2**: FAB only visible when on Liste tab (rightVisibleForIndices pattern)
- [ ] **FR-17.2.3**: FAB hidden when on Analyse tab

#### FR-17.3: Remove App Bar Analysis Navigation
- [ ] **FR-17.3.1**: Remove analytics icon from electricity screen app bar (now accessible via bottom nav)

#### FR-17.4: Single Analysis Page
- [ ] **FR-17.4.1**: Remove monthly analytics view — only keep yearly-style analysis
- [ ] **FR-17.4.2**: Rename from "Jahresanalyse" to simply "Analyse"
- [ ] **FR-17.4.3**: Analysis page content: year navigation, summary card, monthly bar chart, year comparison chart

#### FR-17.5: Fix Year Comparison Chart
- [ ] **FR-17.5.1**: Previous year line must start at the correct month (first month with data), not month 1
- [ ] **FR-17.5.2**: Example: if previous year data starts July, the line starts at July position (not shifted to January)
- [ ] **FR-17.5.3**: Months without data should have no line segment (gap or null)

#### FR-17.6: kWh/Euro Toggle
- [ ] **FR-17.6.1**: Toggle switch at top of analysis page or in app bar to switch between kWh and Euro (€) views
- [ ] **FR-17.6.2**: When toggled to €: all charts and summary values show cost instead of consumption
- [ ] **FR-17.6.3**: Cost calculated using household-specific cost profiles (FR-16) for the correct time period
- [ ] **FR-17.6.4**: Toggle label: "kWh" / "€" (or localized equivalent)

#### FR-17.7: Monthly Values from Interpolation
- [ ] **FR-17.7.1**: Monthly consumption values always calculated from interpolated value differences
- [ ] **FR-17.7.2**: Monthly value = interpolated value at end-of-month boundary minus interpolated value at start-of-month boundary

---

### FR-18: Gas Screen Overhaul

#### FR-18.1: Mirror Electricity Architecture
- [ ] **FR-18.1.1**: Exact same bottom navigation pattern (Analyse left, Liste right, default Liste)
- [ ] **FR-18.1.2**: LiquidGlass FAB visible on Liste only
- [ ] **FR-18.1.3**: Remove app bar analysis icon
- [ ] **FR-18.1.4**: Single analysis page (renamed to "Analyse")
- [ ] **FR-18.1.5**: Fix year comparison chart month alignment (same as FR-17.5)
- [ ] **FR-18.1.6**: m³/€ toggle (gas displays in m³, not kWh)
- [ ] **FR-18.1.7**: Monthly values from interpolated deltas

---

### FR-19: Smart Plug Screen Overhaul

#### FR-19.1: Bottom Navigation
- [x] **FR-19.1.1**: Add bottom navigation (Analyse left, Liste right, default Liste)
- [x] **FR-19.1.2**: LiquidGlass FAB visible on Liste only
- [x] **FR-19.1.3**: Remove app bar analytics icon (pie_chart)

#### FR-19.2: Monthly-Only Analysis
- [x] **FR-19.2.1**: No yearly/monthly tab choice — only monthly view
- [x] **FR-19.2.2**: Start on current month
- [x] **FR-19.2.3**: Month navigation with arrow buttons (previous/next)

#### FR-19.3: Rename Statistics
- [x] **FR-19.3.1**: "Gesamtstrom" → "Gesamtverbrauch" (total consumption from main meter)
- [x] **FR-19.3.2**: "Gesamt erfasst" → "Davon erfasst" (of which captured)
- [x] **FR-19.3.3**: "Sonstiger nicht erfasst" → "Nicht erfasst" (not captured)

#### FR-19.4: UI Element Order
- [x] **FR-19.4.1**: Order from top to bottom:
  1. Month navigation (arrows + month label)
  2. Statistics card (Gesamtverbrauch, Davon erfasst, Nicht erfasst)
  3. Section title "Verbrauch nach Raum"
  4. Pie chart (by room)
  5. Room list with consumption values + percentage
  6. Section title "Verbrauch nach Steckdose"
  7. Pie chart (by plug)
  8. Plug list with consumption values

#### FR-19.5: List Enhancements
- [x] **FR-19.5.1**: Room breakdown list shows both kWh value and percentage (e.g., "12.5 kWh — 35%")
- [x] **FR-19.5.2**: Reduced padding between list items for denser layout

---

### FR-20: Water Screen Overhaul

#### FR-20.1: Bottom Navigation Pattern
- [ ] **FR-20.1.1**: Add bottom navigation (Analyse left, Liste right, default Liste)
- [ ] **FR-20.1.2**: LiquidGlass FAB visible on Liste only
- [ ] **FR-20.1.3**: Analysis page with same pattern as electricity (year nav, summary, charts, comparison)

#### FR-20.2: Analysis Features
- [ ] **FR-20.2.1**: m³/€ toggle for consumption vs. cost view
- [ ] **FR-20.2.2**: Year comparison chart with correct month alignment
- [ ] **FR-20.2.3**: Monthly values from interpolated deltas at month boundaries

---

### FR-21: Heating Screen Overhaul

#### FR-21.1: Bottom Navigation Pattern
- [ ] **FR-21.1.1**: Add bottom navigation (Analyse left, Liste right, default Liste)
- [ ] **FR-21.1.2**: LiquidGlass FAB visible on Liste only
- [ ] **FR-21.1.3**: Analysis page with same pattern as electricity (year nav, summary, charts, comparison)

#### FR-21.2: Analysis Features
- [ ] **FR-21.2.1**: kWh/€ toggle for consumption vs. cost view
- [ ] **FR-21.2.2**: Year comparison chart with correct month alignment
- [ ] **FR-21.2.3**: Monthly values from interpolated deltas at month boundaries

---

## Non-Functional Requirements

### NFR-13: Design Preservation
- [ ] **NFR-13.1**: Do NOT change any visual design elements unless explicitly requested
- [ ] **NFR-13.2**: Maintain existing GlassCard, color scheme, and layout patterns
- [ ] **NFR-13.3**: New bottom navigation follows XFin LiquidGlass pattern exactly

### NFR-14: Localization
- [ ] **NFR-14.1**: All new strings externalized to ARB files (EN + DE)
- [ ] **NFR-14.2**: "Uhr" time suffix is a localized string (DE = "Uhr", EN = "")
- [ ] **NFR-14.3**: Renamed cost field labels localized in both languages
- [ ] **NFR-14.4**: Smart plug stat labels localized in both languages

### NFR-15: Testing
- [ ] **NFR-15.1**: All existing 1017 tests continue to pass
- [ ] **NFR-15.2**: New tests for bottom navigation switching behavior
- [ ] **NFR-15.3**: New tests for cost profile history CRUD
- [ ] **NFR-15.4**: New tests for kWh/€ toggle state management
- [ ] **NFR-15.5**: New tests for date format changes
- [ ] **NFR-15.6**: Maintain 75%+ statement coverage

### NFR-16: Code Quality
- [ ] **NFR-16.1**: Remove all dead code from CSV export removal
- [ ] **NFR-16.2**: Remove all dead code from analytics hub removal
- [ ] **NFR-16.3**: Shared bottom nav pattern reused across all 5 meter screens
- [ ] **NFR-16.4**: Zero flutter analyze issues

---

## User Acceptance Criteria

### UAC-M4-1: Home Screen
**Given** the app opens on the home screen
**When** viewing in light mode
**Then** household dropdown text is dark/black and readable; no bottom navigation bar exists; 5 tiles shown (no Analyse) in order: [Strom, Smart Home] [Gas, Heizung] [Wasser centered]

### UAC-M4-2: Electricity List/Analysis Navigation
**Given** the user taps "Strom" on the home screen
**When** the electricity screen opens
**Then** a LiquidGlass bottom nav shows "Analyse" (left) and "Liste" (right); default view is Liste; FAB is visible on Liste and hidden on Analyse

### UAC-M4-3: Electricity Analysis Page
**Given** the user switches to Analysis tab on electricity
**When** viewing the analysis
**Then** a single analysis page shows year navigation, monthly bar chart, year comparison chart; a kWh/€ toggle switches all values between consumption and cost

### UAC-M4-4: Year Comparison Chart Fix
**Given** previous year data starts in July (no data Jan-Jun)
**When** viewing the year comparison chart
**Then** the previous year line begins at July position, not January

### UAC-M4-5: Gas Screen
**Given** the user taps "Gas" on the home screen
**Then** same architecture as electricity: bottom nav, single analysis, m³/€ toggle, correct chart alignment

### UAC-M4-6: Smart Plug Analysis
**Given** the user switches to Analysis on smart plugs
**Then** monthly-only view with month navigation; stats show "Gesamtverbrauch", "Davon erfasst", "Nicht erfasst"; room breakdown with pie chart + list with percentages; plug breakdown with pie chart + list

### UAC-M4-7: Water Screen
**Given** the user taps "Wasser" on the home screen
**Then** bottom nav with Liste/Analyse; analysis with m³/€ toggle; monthly values from interpolated deltas

### UAC-M4-8: Heating Screen
**Given** the user taps "Heizung" on the home screen
**Then** bottom nav with Liste/Analyse; analysis with kWh/€ toggle; monthly values from interpolated deltas

### UAC-M4-9: Form Dialogs
**Given** the user opens any reading form dialog
**Then** only "Cancel" and "Save" buttons shown side-by-side; no "Save & Continue" button

### UAC-M4-10: Date/Time Format
**Given** any date/time displayed in the app
**When** locale is German
**Then** format is "dd.MM.yyyy, HH:mm Uhr"
**When** locale is English
**Then** format is "dd.MM.yyyy, HH:mm"

### UAC-M4-11: Cost Configuration
**Given** a user in household settings
**When** configuring electricity costs
**Then** they see a card with "Strom" header and sub-entries for each cost profile; each profile shows Gültig ab, Grundpreis pro Jahr, Arbeitspreis; multiple profiles can be added with different valid-from dates

### UAC-M4-12: CSV Export Removed
**Given** any screen in the app
**Then** no CSV export button or functionality exists

---

## Requirements Traceability

| Requirement | Phase(s) | UAC | Priority |
|-------------|----------|-----|----------|
| FR-15 (Home Screen & Global UI Fixes) | 17 | UAC-M4-1, UAC-M4-9, UAC-M4-10, UAC-M4-12 | High |
| FR-16 (Cost Settings & Household Config) | 18 | UAC-M4-11 | High |
| FR-17 (Electricity Screen Overhaul) | 19 | UAC-M4-2, UAC-M4-3, UAC-M4-4 | High |
| FR-18 (Gas Screen Overhaul) | 20 | UAC-M4-5 | High |
| FR-19 (Smart Plug Screen Overhaul) | 21 | UAC-M4-6 | High |
| FR-20 (Water Screen Overhaul) | 22 | UAC-M4-7 | High |
| FR-21 (Heating Screen Overhaul) | 22 | UAC-M4-8 | High |
| NFR-13 (Design Preservation) | All | — | Critical |
| NFR-14 (Localization) | All | UAC-M4-10 | High |
| NFR-15 (Testing) | All | — | High |
| NFR-16 (Code Quality) | 17 | UAC-M4-12 | Medium |
