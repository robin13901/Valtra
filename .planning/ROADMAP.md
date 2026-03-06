# Valtra - Development Roadmap

## Milestone 1: Core Foundation (v0.1.0)
**Goal**: Establish app architecture, database, and basic CRUD for all meter types

### Phase 1: Project Setup & Architecture
**Requirements**: NFR-1, NFR-2, NFR-3, NFR-4
- [ ] Configure pubspec.yaml with all dependencies (Drift, Provider, fl_chart, liquid_glass_renderer, intl)
- [ ] Setup l10n.yaml and create app_en.arb / app_de.arb with initial strings
- [ ] Create app theme with Ultra Violet (#5F4A8B) and Lemon Chiffon (#FEFACD)
- [ ] Setup Drift database with tables schema
- [ ] Create GitHub Actions workflow (flutter-tests.yml)
- [ ] Setup test infrastructure with test helpers

### Phase 2: Household Management
**Requirements**: FR-1
- [ ] Create Household model and DAO
- [ ] Implement HouseholdProvider for state management
- [ ] Build Household list/create/edit screens
- [ ] Add household selector widget
- [ ] Persist selected household in SharedPreferences

### Phase 3: Electricity Tracking
**Requirements**: FR-2
- [ ] Create ElectricityMeter and ElectricityReading models/tables
- [ ] Implement ElectricityDao with CRUD operations
- [ ] Build Electricity screen with reading list
- [ ] Create AddElectricityReadingDialog
- [ ] Display consumption deltas between readings

### Phase 4: Smart Plug & Room Management
**Requirements**: FR-3
- [ ] Create Room model and DAO
- [ ] Create SmartPlug and SmartPlugConsumption models/tables
- [ ] Implement SmartPlugDao with interval-based consumption logging
- [ ] Build Room management screen
- [ ] Build SmartPlug management screen with room assignment
- [ ] Create SmartPlugConsumption entry form (interval selector + value)

### Phase 5: Water Tracking
**Requirements**: FR-4
- [ ] Create WaterMeter (with type: cold/hot/other) and WaterReading models
- [ ] Implement WaterDao with multi-meter support
- [ ] Build Water screen with meter tabs/list
- [ ] Create AddWaterMeterDialog and AddWaterReadingDialog

### Phase 6: Gas Tracking
**Requirements**: FR-5
- [ ] Create GasMeter and GasReading models/tables
- [ ] Implement GasDao with CRUD operations
- [ ] Build Gas screen with reading list
- [ ] Create AddGasReadingDialog
- [ ] Optional: Add kWh conversion display

### Phase 7: Heating Meter Tracking
**Requirements**: FR-6
- [ ] Create HeatingMeter and HeatingReading models/tables
- [ ] Implement HeatingDao with multi-meter support
- [ ] Build Heating screen with meter management
- [ ] Create AddHeatingMeterDialog and AddHeatingReadingDialog

---

## Milestone 2: Analytics & Visualization (v0.2.0)
**Goal**: Implement all analytics views with charts and interpolation

### Phase 8: Interpolation Engine
**Requirements**: FR-8
- [ ] Create InterpolationService for linear interpolation
- [ ] Implement interpolated value calculation for any timestamp
- [ ] Add "isInterpolated" flag to reading display
- [ ] Build monthly boundary interpolation (1st of month 00:00)

### Phase 9: Monthly Analytics View
**Requirements**: FR-7.1, FR-7.3
- [ ] Create MonthlyAnalyticsScreen with month navigation
- [ ] Build consumption summary cards for each meter type
- [ ] Implement line chart for consumption trends
- [ ] Show interpolated vs actual values with visual distinction

### Phase 10: Yearly Analytics View
**Requirements**: FR-7.2
- [ ] Create YearlyAnalyticsScreen with year navigation
- [ ] Aggregate monthly data into yearly totals
- [ ] Build year-over-year comparison chart
- [ ] Show monthly breakdown within year view

### Phase 11: Smart Plug Analytics
**Requirements**: FR-7.4, FR-7.5
- [ ] Create SmartPlugAnalyticsScreen
- [ ] Build pie chart for consumption by individual plug
- [ ] Build pie chart for consumption by room
- [ ] Calculate and display "Other" (untracked) consumption
- [ ] Add list view with detailed breakdown

---

## Milestone 3: Polish & Enhancement (v0.3.0)
**Goal**: Refine UI, add convenience features, ensure production quality

### Phase 12: LiquidGlass UI Polish
**Requirements**: NFR-4
- [ ] Implement LiquidGlassBottomNav for main navigation
- [ ] Add LiquidGlass FAB for quick actions
- [ ] Style dialogs and forms with glass aesthetic
- [ ] Ensure consistent theming throughout app

### Phase 13: Data Entry Enhancements
**Requirements**: FR-9
- [ ] Implement quick entry mode for batch readings
- [ ] Add validation (reading >= previous)
- [ ] Improve date/time picker UX
- [ ] Add recently used values suggestions

### Phase 14: Testing & Documentation
**Requirements**: NFR-3
- [ ] Achieve 80%+ code coverage
- [ ] Add integration tests for critical flows
- [ ] Document codebase (README, architecture)
- [ ] Final UI/UX review and fixes

---

## Phase Dependencies

```
Phase 1 (Setup) ─────────────────────────────────────┐
                                                     │
Phase 2 (Households) ────────────────────────────────┼─► Phase 8 (Interpolation)
                                                     │           │
Phase 3 (Electricity) ───────────────────────────────┤           ▼
                                                     │   Phase 9 (Monthly Analytics)
Phase 4 (Smart Plugs) ───────────────────────────────┤           │
                                                     │           ▼
Phase 5 (Water) ─────────────────────────────────────┤   Phase 10 (Yearly Analytics)
                                                     │
Phase 6 (Gas) ───────────────────────────────────────┤   Phase 11 (Smart Plug Analytics)
                                                     │           │
Phase 7 (Heating) ───────────────────────────────────┘           ▼
                                                         Phase 12 (UI Polish)
                                                                 │
                                                                 ▼
                                                         Phase 13 (Data Entry)
                                                                 │
                                                                 ▼
                                                         Phase 14 (Testing)
```

## Estimated Effort

| Phase | Complexity | Estimated Hours |
|-------|------------|-----------------|
| 1. Project Setup | Medium | 4-6h |
| 2. Households | Low | 2-3h |
| 3. Electricity | Medium | 3-4h |
| 4. Smart Plugs | High | 5-6h |
| 5. Water | Medium | 3-4h |
| 6. Gas | Low | 2-3h |
| 7. Heating | Medium | 3-4h |
| 8. Interpolation | Medium | 3-4h |
| 9. Monthly Analytics | High | 5-6h |
| 10. Yearly Analytics | Medium | 3-4h |
| 11. Smart Plug Analytics | High | 4-5h |
| 12. UI Polish | Medium | 4-5h |
| 13. Data Entry | Low | 2-3h |
| 14. Testing | Medium | 4-5h |
| **Total** | | **~47-62h** |

## Current Status
- **Active Phase**: Phase 1 - Project Setup & Architecture (PLANNED)
- **Next Phase**: Phase 2 - Household Management
- **Blockers**: None
