# Phase 21: Smart Plug Screen Overhaul — Context

## Phase Goal
Overhaul the Smart Plug screen to match the unified list/analysis bottom navigation pattern established in Phase 19 (Electricity) and Phase 20 (Gas). The smart plug analytics are unique — they show monthly-only pie chart breakdowns (no yearly option), with stats renamed and percentages added to breakdown lists.

## Requirements (from ROADMAP.md — FR-19)

### Bottom Navigation
- Add GlassBottomNav: Analyse (left, icon: analytics) | Liste (right, icon: list), default Liste
- Use IndexedStack for tab content (preserve state when switching)
- LiquidGlass FAB (add smart plug) — visible on Liste tab only
- Remove app bar analytics icon (pie_chart) — now in bottom nav

### Analysis Page (Analyse tab)
- Monthly-only analysis (remove yearly/SegmentedButton period selector)
- Month navigation with left/right arrows (same pattern as existing _MonthNavigation)
- Rename stats:
  - "totalTracked" → "Gesamtverbrauch" (total consumption from electricity meter interpolation)
  - "totalElectricity" → "Davon erfasst" (of which tracked by smart plugs)
  - "otherConsumption" → "Nicht erfasst" (not tracked by smart plugs)
- UI order: month nav → stats card → "Verbrauch nach Raum" (title, pie chart, list with %) → "Verbrauch nach Steckdose" (title, pie chart, list)
- Room list items show kWh value + percentage (e.g., "12,5 kWh (34%)")
- Reduced padding between list items (use dense ListTile or custom)

### Localization
- Localize all new/changed strings (EN + DE)
- New l10n keys: totalConsumption, trackedByPlugs, notTracked, consumptionByRoomTitle, consumptionByPlugTitle, etc.

### Tests
- Tests for bottom nav switching, FAB visibility on Liste only
- Tests for renamed stats labels
- Tests for percentage display in room breakdown
- Tests for UI order (sections appear in correct sequence)
- Tests for monthly-only mode (no yearly selector)

## Established Patterns (from Phase 19/20)

### Bottom Nav Pattern (ElectricityScreen / GasScreen)
```dart
// StatefulWidget with _currentTab = 1 (default Liste)
body: IndexedStack(
  index: _currentTab,
  children: [_buildAnalyseTab(context), _buildListeTab(context)],
),
floatingActionButton: _currentTab == 1 ? buildGlassFAB(...) : null,
bottomNavigationBar: GlassBottomNav(
  currentIndex: _currentTab,
  onTap: (index) => setState(() => _currentTab = index),
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.analytics), label: l10n.analysis),
    BottomNavigationBarItem(icon: Icon(Icons.list), label: l10n.list),
  ],
),
```

### Key Differences from Electricity/Gas
1. Smart plug screen is a **plug list** (by room), not a meter readings list
2. Analysis is **monthly-only** — no yearly tab, no SegmentedButton
3. Analysis uses **pie charts** (by room + by plug), not bar/line charts
4. Stats relate to **tracked vs untracked electricity** rather than meter reading deltas
5. No kWh/€ toggle (smart plugs don't have cost configs)
6. The Rooms management button stays in the app bar

## Source Files to Modify
- `lib/screens/smart_plugs_screen.dart` — Add bottom nav, IndexedStack, move FAB logic
- `lib/screens/smart_plug_analytics_screen.dart` — Refactor into Analyse tab content (inline), remove standalone Scaffold/AppBar
- `lib/providers/smart_plug_analytics_provider.dart` — Remove yearly period support, simplify to monthly-only
- `lib/services/analytics/analytics_models.dart` — May remove AnalyticsPeriod enum if unused after cleanup
- `lib/l10n/app_en.arb` / `lib/l10n/app_de.arb` — New/renamed l10n keys

## Test Files to Modify/Create
- `test/screens/smart_plugs_screen_test.dart` — Add bottom nav + FAB visibility tests
- `test/screens/smart_plug_analytics_screen_test.dart` — Rename stats, percentage, UI order tests

## Dependencies
- Phase 19 completed (bottom nav pattern established via GlassBottomNav widget)
- SmartPlugAnalyticsProvider already has month navigation
- ConsumptionPieChart widget already exists
