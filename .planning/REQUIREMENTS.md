# Valtra - Requirements

## Functional Requirements

### FR-1: Household Management
- **FR-1.1**: Create, edit, and delete households
- **FR-1.2**: Each household has a name and optional description
- **FR-1.3**: All meters and data are scoped to a household
- **FR-1.4**: User can switch between households in the app
- **FR-1.5**: Default household selection persists across sessions

### FR-2: Electricity Tracking
- **FR-2.1**: Log electricity meter readings with date/time and value (kWh)
- **FR-2.2**: Each household has exactly one main electricity meter
- **FR-2.3**: Display reading history with consumption deltas
- **FR-2.4**: Support editing and deleting historical readings

### FR-3: Smart Plug Management (Meros)
- **FR-3.1**: Create smart plugs with name and assigned room
- **FR-3.2**: Create and manage rooms within a household
- **FR-3.3**: Log consumption values for smart plugs with interval type (day/week/month/year)
- **FR-3.4**: Store interval start date and consumption value (kWh)
- **FR-3.5**: Aggregate consumption by plug, by room, and total
- **FR-3.6**: Calculate "Other" consumption (main meter - sum of smart plugs)

### FR-4: Water Tracking
- **FR-4.1**: Create multiple water meters per household (e.g., cold water, hot water, washing machine)
- **FR-4.2**: Each meter has name, type (cold/hot/other), and unit (m³)
- **FR-4.3**: Log readings with date/time and value
- **FR-4.4**: Display reading history per meter with consumption deltas

### FR-5: Gas Tracking
- **FR-5.1**: Log gas meter readings with date/time and value (m³)
- **FR-5.2**: Each household has exactly one gas meter
- **FR-5.3**: Optional: Display kWh equivalent (conversion factor configurable)
- **FR-5.4**: Display reading history with consumption deltas

### FR-6: Heating Meter Tracking
- **FR-6.1**: Create multiple heating consumption meters per household
- **FR-6.2**: Each meter has name and location (e.g., room name)
- **FR-6.3**: Log readings with date/time and value (unit-less consumption units)
- **FR-6.4**: Typical reading pattern: 1st of month, but arbitrary timestamps supported

### FR-7: Analytics & Visualization
- **FR-7.1**: Monthly view - navigate through months, show all meter consumptions
- **FR-7.2**: Yearly view - aggregate monthly data into yearly overview
- **FR-7.3**: Consumption graphs (line charts) showing trends over time
- **FR-7.4**: Pie charts for smart plug distribution (by plug and by room)
- **FR-7.5**: "Other" category in pie charts for untracked electricity

### FR-8: Interpolation
- **FR-8.1**: Interpolate meter values for 1st of month at 00:00
- **FR-8.2**: Linear interpolation between two surrounding readings
- **FR-8.3**: Mark interpolated values distinctly from actual readings
- **FR-8.4**: Use interpolated values for monthly/yearly comparisons

### FR-9: Data Entry
- **FR-9.1**: Date/time picker defaults to current time
- **FR-9.2**: Numeric input with appropriate decimal precision
- **FR-9.3**: Validation: new reading must be >= previous reading (for cumulative meters)
- **FR-9.4**: Quick entry mode for multiple readings in sequence

## Non-Functional Requirements

### NFR-1: Localization
- **NFR-1.1**: All UI strings externalized to ARB files
- **NFR-1.2**: Support for English (app_en.arb) and German (app_de.arb)
- **NFR-1.3**: Date/number formatting follows device locale

### NFR-2: Data Persistence
- **NFR-2.1**: All data stored locally using Drift/SQLite
- **NFR-2.2**: Database schema versioned with migrations
- **NFR-2.3**: App works fully offline

### NFR-3: Quality & Testing
- **NFR-3.1**: Unit tests for all business logic and DAOs
- **NFR-3.2**: Widget tests for key UI components
- **NFR-3.3**: Target: 80%+ code coverage
- **NFR-3.4**: CI pipeline runs tests on every push

### NFR-4: UI/UX
- **NFR-4.1**: LiquidGlass aesthetic for navigation and key UI elements
- **NFR-4.2**: Color scheme: Ultra Violet (#5F4A8B) primary, Lemon Chiffon (#FEFACD) accent
- **NFR-4.3**: Responsive layout for various phone sizes
- **NFR-4.4**: Material Design 3 components where LiquidGlass not applicable

### NFR-5: Performance
- **NFR-5.1**: App startup < 2 seconds
- **NFR-5.2**: Smooth scrolling (60fps) in list views
- **NFR-5.3**: Analytics calculations < 500ms

## Data Model Overview

```
Household
├── ElectricityMeter (1:1)
│   └── ElectricityReading (1:N)
├── GasMeter (1:1)
│   └── GasReading (1:N)
├── WaterMeter (1:N)
│   └── WaterReading (1:N)
├── HeatingMeter (1:N)
│   └── HeatingReading (1:N)
├── Room (1:N)
│   └── SmartPlug (1:N)
│       └── SmartPlugConsumption (1:N)
```

## User Acceptance Criteria

### UAC-1: Meter Reading Entry
- Given I am on the electricity screen
- When I tap "Add Reading" and enter date/value
- Then the reading is saved and appears in the list

### UAC-2: Smart Plug Room Assignment
- Given I have created a room "Living Room"
- When I create a smart plug and assign it to "Living Room"
- Then the plug appears under that room in the overview

### UAC-3: Monthly Analysis
- Given I have readings for March and April
- When I view the March monthly analysis
- Then I see interpolated values for March 1st and consumption totals

### UAC-4: Household Switching
- Given I have households "My Home" and "Parents"
- When I switch to "Parents"
- Then I only see meters and data for that household
