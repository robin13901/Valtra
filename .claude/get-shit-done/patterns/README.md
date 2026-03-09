# GSD Patterns

This directory contains learned patterns from successful project executions.

## Directory Structure

```
patterns/
├── successful-plans/     # Plan→implementation patterns by domain
│   ├── flutter-project-setup.md
│   ├── drift-database-schema.md
│   ├── flutter-theme-system.md
│   ├── flutter-household-crud.md
│   ├── flutter-meter-reading-crud.md
│   ├── flutter-smart-plug-room-crud.md
│   ├── flutter-multi-meter-tracking.md
│   ├── flutter-interpolation-service.md
│   ├── flutter-analytics-hub.md
│   ├── flutter-yearly-analytics-csv.md
│   ├── flutter-smart-plug-analytics.md
│   ├── flutter-settings-dark-mode-audit.md
│   ├── flutter-cost-tracking.md
│   ├── flutter-ui-ux-polish-localization.md
│   ├── flutter-data-model-rework.md
│   ├── flutter-home-screen-cleanup.md
│   ├── flutter-cost-settings-household-config.md
│   └── flutter-meter-screen-bottom-nav-overhaul.md
├── conventions-learned/  # Project-specific conventions (JSON)
│   └── valtra.json
└── routing-history.json  # Agent/model performance tracking
```

## Usage

### Apply patterns to new projects

```
/gsd:apply-patterns
```

### Update patterns after successful phases

```
/gsd:learn
/gsd:learn --phase 2
/gsd:learn --all
```

## Pattern Types

### successful-plans/
Contains markdown files with:
- **Context**: When to use the pattern
- **Tasks**: Task structure from successful plans
- **Key Decisions**: Important choices made
- **Common Pitfalls**: Issues encountered and solutions
- **Wave Structure**: Dependency ordering

### conventions-learned/
JSON files with project conventions:
- Naming patterns (files, classes, variables)
- Directory structure
- Testing patterns
- CI/CD configuration

### routing-history.json
Tracks which models work best for which task types:
- Task type → best model mapping
- Success rates
- Common deviations/edge cases

## Captured Patterns

| Pattern | Domain | Tech Stack | Success Rate | Uses |
|---------|--------|------------|--------------|------|
| flutter-project-setup | setup | flutter, drift, provider | 100% | 1 |
| drift-database-schema | db | dart, drift, sqlite | 100% | 1 |
| flutter-theme-system | ui | flutter, material3 | 100% | 1 |
| flutter-household-crud | crud | flutter, drift, provider, sharedpreferences | 100% | 1 |
| flutter-meter-reading-crud | crud | flutter, drift, provider, intl | 100% | 2 |
| flutter-smart-plug-room-crud | crud | flutter, drift, provider, intl | 100% | 1 |
| flutter-multi-meter-tracking | crud | flutter, drift, provider, intl | 100% | 2 |
| flutter-interpolation-service | service | flutter, dart, drift, provider, sharedpreferences | 100% | 1 |
| flutter-analytics-hub | analytics | flutter, dart, fl_chart, provider, drift, intl | 100% | 1 |
| flutter-yearly-analytics-csv | analytics | flutter, fl_chart, csv, share_plus, path_provider, provider | 100% | 1 |
| flutter-smart-plug-analytics | analytics | flutter, fl_chart, provider, drift, intl | 100% | 1 |
| flutter-settings-dark-mode-audit | ui, settings | flutter, provider, shared_preferences, package_info_plus, material3 | 100% | 1 |
| flutter-cost-tracking | service, db, ui, settings | flutter, dart, drift, provider, mocktail | 100% | 1 |
| flutter-ui-ux-polish-localization | ui, localization, polish | flutter, dart, intl, provider, shared_preferences, material3 | 100% | 1 |
| flutter-data-model-rework | db, service, ui, analytics | flutter, dart, drift, provider, fl_chart, intl, mocktail | 100% | 1 |
| flutter-home-screen-cleanup | ui, cleanup | flutter, dart, material3, provider, intl | 100% | 1 |
| flutter-cost-settings-household-config | settings, db, ui | flutter, dart, drift, provider, material3, intl | 100% | 1 |
| flutter-meter-screen-bottom-nav-overhaul | ui, navigation, analytics | flutter, dart, provider, fl_chart, material3, intl | 100% | 5 |

---

*Last updated: 2026-03-09 (Milestone 4 / Phases 17-22 captured)*
