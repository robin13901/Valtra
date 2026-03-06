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
│   └── flutter-multi-meter-tracking.md
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
| flutter-multi-meter-tracking | crud | flutter, drift, provider, intl | 100% | 1 |

---

*Last updated: 2026-03-06*
