---
name: flutter-meter-screen-bottom-nav-overhaul
domain: ui, navigation, analytics
tech: [flutter, dart, provider, fl_chart, material3, intl]
success_rate: 100%
times_used: 5
source_project: valtra
captured_at: 2026-03-09
---

## Context
Use this pattern when converting a meter/entity screen from simple list to tabbed list+analysis with bottom navigation. Applied successfully to 5 screens in Valtra v0.4.0: electricity (phase 19), gas (phase 20), smart plugs (phase 21), water (phase 22), heating (phase 22). This is the most reused pattern in the project.

## Pattern

### Architecture
```
StatefulWidget
├── _currentTab (0=Analyse, 1=Liste, default=1)
├── _showCosts (unit/€ toggle, default=false)
├── Scaffold
│   ├── appBar: buildGlassAppBar
│   │   └── actions: [visibility toggle (Liste only), cost toggle (Analyse only)]
│   ├── body: IndexedStack
│   │   ├── index 0: _buildAnalyseTab() — inline yearly analytics
│   │   └── index 1: _buildListeTab() — existing reading list
│   ├── floatingActionButton: _currentTab == 1 ? buildGlassFAB(...) : null
│   └── bottomNavigationBar: GlassBottomNav
│       ├── item 0: Icons.analytics + l10n.analysis
│       └── item 1: Icons.list + l10n.list
```

### Tasks

#### Wave 1: Data Layer (parallel with localization)
- Extend analytics data model with per-month costs (`monthlyCosts`, `previousYearMonthlyCosts`)
- Fix chart month alignment (use `periodStart.month - 1` as X-axis, not array index)
- Add cost mode support to chart widgets (optional `showCosts`, `periodCosts` params)

#### Wave 2: Screen Refactoring
- Convert StatelessWidget → StatefulWidget
- Add `_currentTab = 1` and `_showCosts = false` state
- `initState` → `addPostFrameCallback` to set meter type + year in AnalyticsProvider
- Extract existing body into `_buildListeTab()`
- Create `_buildAnalyseTab()` with year nav, summary, bar chart, comparison chart
- Create `_buildCostToggle()` — hidden when no cost config, toggles icon (meter-specific / euro)
- Move reading CRUD helpers into State class
- Duplicate `_YearNavigationHeader` + `_YearlySummaryCard` per file (no shared extraction yet)

#### Wave 3: Cost Toggle Integration
- Wire `_showCosts` flag to all chart widgets
- Summary card switches between total consumption and total cost
- Charts accept both consumption and cost data, switch based on flag

#### Wave 4: Tests
- Bottom nav tests: renders labels, default tab, tab switching
- FAB visibility: visible on Liste, hidden on Analyse
- Cost toggle: shown with config, hidden without, toggles icon
- Keep all existing reading list tests (Liste is default, so they still pass)

#### Wave 5: Cleanup + Verification
- Remove app bar analytics icon
- Remove MonthlyAnalyticsScreen import
- Delete dead screens after all consumers removed
- `flutter test` + `flutter analyze`

### Key Decisions
1. **IndexedStack over PageView**: preserves scroll position, simpler state management
2. **Default tab = Liste (index 1)**: users primarily add readings, not analyze
3. **Duplicate private widgets per file**: each screen evolves independently; shared extraction is future cleanup
4. **Cost toggle in app bar, not as separate control**: saves vertical space
5. **addPostFrameCallback for data load**: prevents build-phase provider mutations
6. **Chart cost params default to false/null**: backward compatibility for existing callers
7. **Smart plugs are monthly-only**: no yearly toggle, no year navigation (different from electricity/gas/water/heating)

### Replication Recipe (for new meter screen)
1. Copy electricity_screen.dart as template
2. Replace: MeterType, Provider class, color, unit, icon, l10n title
3. Replace: CostMeterType, cost toggle icon (meter-specific icon vs euro)
4. Replace: `_buildListeTab()` content with existing screen body
5. Keep: `_buildAnalyseTab()`, `_buildCostToggle()`, `_YearNavigationHeader`, `_YearlySummaryCard` (adjust labels)
6. Copy electricity_screen_test.dart, update provider setup and assertions

### Common Pitfalls
- StatelessWidget → StatefulWidget: `const` constructor preserved on outer widget, tests still pump correctly
- IndexedStack keeps both tabs in widget tree — analytics data loads even when on Liste tab
- Multi-meter screens (water, heating) have _addMeter FAB, not _addReading FAB
- Heating screen has extra room management icon in app bar — conditional on Liste tab
- Smart plug provider is separate (SmartPlugAnalyticsProvider) — different data flow than AnalyticsProvider
- Cost toggle icon: use meter-specific icon when showing consumption (electric_bolt, fire, water_drop, thermostat), euro when showing costs
- When user deletes cost config while in € mode: toggle stays true but costs are null — charts fall back to consumption display gracefully
- Year comparison chart fix is global (one widget) — all screens benefit from single fix
- Test provider setup: AnalyticsProvider needs ALL DAOs (electricity, gas, water, heating) even when testing single meter screen

### Wave Structure
```
Phase 19 (Electricity): Full pattern established — data layer + chart fix + screen refactor + tests
Phase 20 (Gas): Mirror electricity (1 task: screen refactor, 1 task: tests, 1 task: verify)
Phase 21 (Smart Plugs): Variant — monthly-only analytics, separate provider, no cost toggle
Phase 22 (Water + Heating): Parallel execution, plus dead code cleanup (delete old analytics screens)
```

### Parallelization Opportunity
After the first screen establishes the pattern (Phase 19), subsequent screens can run in parallel:
- Phase 20 (gas), Phase 21 (smart plugs), Phase 22 (water + heating) are all independent
- Phase 22 combined two screens into one phase since they share the same pattern and dead code cleanup
