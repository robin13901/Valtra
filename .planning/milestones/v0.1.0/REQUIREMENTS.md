# Valtra v0.1.0 Requirements - Archived

**Milestone**: Core Foundation (v0.1.0)
**Status**: All milestone 1 requirements validated

---

## Functional Requirements (Milestone 1 Scope)

### FR-1: Household Management - VALIDATED
- [x] **FR-1.1**: Create, edit, and delete households
- [x] **FR-1.2**: Each household has a name and optional description
- [x] **FR-1.3**: All meters and data are scoped to a household
- [x] **FR-1.4**: User can switch between households in the app
- [x] **FR-1.5**: Default household selection persists across sessions

### FR-2: Electricity Tracking - VALIDATED
- [x] **FR-2.1**: Log electricity meter readings with date/time and value (kWh)
- [x] **FR-2.2**: Each household has exactly one main electricity meter
- [x] **FR-2.3**: Display reading history with consumption deltas
- [x] **FR-2.4**: Support editing and deleting historical readings

### FR-3: Smart Plug Management - PARTIALLY VALIDATED
- [x] **FR-3.1**: Create smart plugs with name and assigned room
- [x] **FR-3.2**: Create and manage rooms within a household
- [x] **FR-3.3**: Log consumption values for smart plugs with interval type
- [x] **FR-3.4**: Store interval start date and consumption value (kWh)
- [ ] **FR-3.5**: Aggregate consumption by plug, by room, and total (DAO exists, UI deferred to Phase 11)
- [ ] **FR-3.6**: Calculate "Other" consumption (deferred to Phase 11)

### FR-4: Water Tracking - VALIDATED
- [x] **FR-4.1**: Create multiple water meters per household
- [x] **FR-4.2**: Each meter has name, type (cold/hot/other), and unit (m3)
- [x] **FR-4.3**: Log readings with date/time and value
- [x] **FR-4.4**: Display reading history per meter with consumption deltas

### FR-5: Gas Tracking - PARTIALLY VALIDATED
- [x] **FR-5.1**: Log gas meter readings with date/time and value (m3)
- [x] **FR-5.2**: Each household has exactly one gas meter
- [ ] **FR-5.3**: Optional: Display kWh equivalent (deferred)
- [x] **FR-5.4**: Display reading history with consumption deltas

### FR-6: Heating Meter Tracking - VALIDATED
- [x] **FR-6.1**: Create multiple heating consumption meters per household
- [x] **FR-6.2**: Each meter has name and location
- [x] **FR-6.3**: Log readings with date/time and value (unit-less)
- [x] **FR-6.4**: Arbitrary timestamps supported

---

## Non-Functional Requirements (Milestone 1 Scope)

### NFR-1: Localization - VALIDATED
- [x] **NFR-1.1**: All UI strings externalized to ARB files (140 keys)
- [x] **NFR-1.2**: Support for English and German (100% parity)
- [x] **NFR-1.3**: Date/number formatting follows device locale

### NFR-2: Data Persistence - VALIDATED
- [x] **NFR-2.1**: All data stored locally using Drift/SQLite (10 tables)
- [x] **NFR-2.2**: Database schema versioned with migrations
- [x] **NFR-2.3**: App works fully offline

### NFR-3: Quality & Testing - PARTIALLY VALIDATED
- [x] **NFR-3.1**: Unit tests for all business logic and DAOs (313 tests)
- [x] **NFR-3.2**: Widget tests for key UI components (simplified for some screens)
- [ ] **NFR-3.3**: Target: 80%+ code coverage (not measured yet)
- [x] **NFR-3.4**: CI pipeline runs tests on every push

### NFR-4: UI/UX - VALIDATED
- [x] **NFR-4.1**: LiquidGlass aesthetic for navigation and key UI elements
- [x] **NFR-4.2**: Color scheme: Ultra Violet primary, Lemon Chiffon accent
- [x] **NFR-4.4**: Material Design 3 components

---

## Requirements NOT in Milestone 1 Scope (Carry-Forward)
- FR-7: Analytics & Visualization (Milestone 2)
- FR-8: Interpolation (Milestone 2)
- FR-9: Data Entry Enhancements (Milestone 3)
- NFR-5: Performance (Milestone 3)

## User Acceptance Criteria Outcomes

| UAC | Description | Result |
|-----|-------------|--------|
| UAC-1 | Meter Reading Entry | VALIDATED (Phase 3) |
| UAC-2 | Smart Plug Room Assignment | VALIDATED (Phase 4) |
| UAC-3 | Monthly Analysis | NOT IN SCOPE (Milestone 2) |
| UAC-4 | Household Switching | VALIDATED (Phase 2) |
