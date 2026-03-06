---
name: flutter-project-setup
domain: setup
tech: [flutter, dart, drift, provider, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-06
---

## Context
Use this pattern when initializing a new Flutter project with local-first architecture, requiring database, state management, theming, and localization from the start.

## Pattern

### Tasks

1. **Configure Dependencies (pubspec.yaml)**
   - Add all dependencies upfront to avoid version conflicts later
   - Include `flutter_localizations` SDK dependency
   - Enable `generate: true` in flutter section for l10n

2. **Setup Localization Infrastructure**
   - Create `l10n.yaml` with arb-dir, template-arb-file, output-localization-file
   - Create initial ARB files with common strings (app title, CRUD verbs, units)
   - Support EN + DE from start (easy to add more later)

3. **Create App Theme**
   - Define `AppColors` class with brand colors and light/dark variants
   - Define `AppTheme` class with `lightTheme` and `darkTheme` getters
   - Include utility colors for domain-specific UI elements
   - Use Material 3 with `useMaterial3: true`

4. **Create Database Schema (tables.dart)**
   - Define enums first (used by tables)
   - One file for all tables using Drift annotations
   - Use `@DataClassName` for singular entity names
   - Use `.references()` for foreign keys

5. **Create Database Class (app_database.dart)**
   - Single `@DriftDatabase` annotation with all tables
   - Extend `_$AppDatabase` (generated)
   - Define `schemaVersion` and `migration` strategy

6. **Create Database Connection (native.dart)**
   - Platform-specific connection in `connection/` subfolder
   - Use `sqlite3_flutter_libs` + `path_provider` for native
   - `shared.dart` for common interface

7. **Create Theme Provider**
   - Persist theme mode in SharedPreferences
   - ChangeNotifier for reactive updates
   - Provide `isDark` helper

8. **Update main.dart**
   - Initialize binding first
   - Create database instance
   - Wrap app in MultiProvider
   - Configure MaterialApp with localization delegates

9. **Setup Test Infrastructure**
   - `test/helpers/test_database.dart` - in-memory database factory
   - `test/helpers/test_utils.dart` - common utilities
   - Basic schema validation tests

10. **Copy/Adapt UI Components**
    - Adapt from reference projects with new theme colors
    - Keep components in `widgets/` directory

### Key Decisions

1. **Local-first architecture** - Using Drift/SQLite ensures offline capability
2. **Single tables file** - Easier to maintain relationships, generates one .g.dart
3. **Theme separation** - AppColors for values, AppTheme for ThemeData construction
4. **In-memory test database** - Fast tests without file I/O

### Common Pitfalls

1. **Missing `generate: true`** in pubspec.yaml breaks localization generation
2. **Build runner not run** after tables change - always run `dart run build_runner build`
3. **Drift version mismatch** - Keep `drift` and `drift_dev` on same version
4. **Missing test sqlite3** - Add `sqlite3: ^2.4.4` as dependency for tests

### Wave Structure

```
Wave 1: pubspec.yaml → flutter pub get
Wave 2: l10n.yaml + ARB files + app_theme.dart (parallel)
Wave 3: tables.dart → app_database.dart → connection files → build_runner
Wave 4: providers → main.dart → widgets
Wave 5: test infrastructure → verification
```

### Dependencies (pubspec.yaml template)

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  drift: ^2.19.0
  sqlite3_flutter_libs: ^0.5.24
  sqlite3: ^2.4.4
  path_provider: ^2.1.3
  path: ^1.9.0
  provider: ^6.1.2
  intl: ^0.20.2
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_lints: ^6.0.0
  drift_dev: ^2.19.0
  build_runner: ^2.4.10
  test: ^1.25.2
  mocktail: ^0.3.0
```

### Success Criteria

- [ ] `flutter pub get` completes without errors
- [ ] `dart run build_runner build` generates .g.dart files
- [ ] `flutter gen-l10n` generates localization classes
- [ ] `flutter analyze` passes with zero issues
- [ ] `flutter test` passes
- [ ] App launches with themed UI
