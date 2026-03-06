---
name: flutter-household-crud
domain: crud
tech: [flutter, drift, provider, sharedpreferences]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-06
---

## Context

Use this pattern when implementing CRUD operations for a domain entity in Flutter with:
- Drift database for persistence
- Provider for state management
- SharedPreferences for user preferences
- Reactive streams for live updates
- Form dialogs for create/edit
- Selector widgets for active entity selection

## Pattern

### Task Structure (10 tasks, ~2-3h)

1. **Create DAO** (no deps)
   - Extend `DatabaseAccessor` with mixin
   - Implement: insert, getById, getAll, watchAll, update, delete
   - Add relation check method (`hasRelatedData`)

2. **Register DAO** (deps: 1)
   - Add to `@DriftDatabase(daos: [...])` annotation
   - Create getter: `EntityDao get entityDao => EntityDao(this);`
   - Run `dart run build_runner build --delete-conflicting-outputs`

3. **Create Provider** (deps: 1, 2)
   - Extend `ChangeNotifier`
   - Stream subscription to DAO watch
   - Persist selection to SharedPreferences
   - Auto-select first if none selected
   - Clear selection if selected deleted

4. **Create List Screen** (deps: 3)
   - ListView.builder for entity cards
   - FAB for add
   - Tap for edit
   - Long-press for delete (with confirmation)
   - Block delete if `hasRelatedData()`

5. **Create Form Dialog** (no deps)
   - TextFormField with validation
   - Cancel/Save buttons
   - Edit mode pre-fills fields
   - Returns form data or null

6. **Create Selector Widget** (deps: 3)
   - PopupMenuButton with entity list
   - Current selection display
   - "Manage" option to navigate to list screen
   - "Add" button when empty

7. **Integrate in Main** (deps: 3, 6)
   - Add provider to MultiProvider
   - Add selector to AppBar actions

8. **Add Localization** (no deps)
   - Entity name (singular, plural)
   - CRUD action strings
   - Validation messages
   - Confirmation dialogs

9. **Run Tests** (deps: all)
   - `flutter test`

10. **Run Analysis** (deps: 9)
    - `flutter analyze`

### Wave Structure

```
Wave 1 (parallel):  Task 1, Task 5, Task 8
Wave 2 (serial):    Task 2
Wave 3 (serial):    Task 3
Wave 4 (parallel):  Task 4, Task 6
Wave 5 (serial):    Task 7
Wave 6 (serial):    Task 9, Task 10
```

### Key Decisions

1. **DAO Pattern**: Use Drift `@DriftAccessor` for type-safe queries
2. **Stream Watching**: Use `watchAll()` for reactive UI updates
3. **Selection Persistence**: Use SharedPreferences key `selected_{entity}_id`
4. **Auto-selection**: Auto-select first entity if none persisted
5. **Deletion Safety**: Check for related data before allowing delete

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| Drift matcher conflicts | Import with `hide isNotNull, isNull` |
| Widget tests timeout with streams | Use `pump()` instead of `pumpAndSettle()`, or add `await tester.pumpWidget(Container())` at end |
| Value.absent check | Use `entry.id.present` not `entry.id.value == null` |
| Stream not emitting in tests | Add `await Future.delayed(Duration(milliseconds: 100))` |

### Test Coverage

- **DAO Tests**: insert, getAll, watch, update, delete, hasRelatedData
- **Provider Tests**: init, select, create, update, delete, persistence, auto-select
- **Form Dialog Tests**: validation, submit, cancel, edit mode
- **Screen/Widget Tests**: Can be simplified due to stream timing issues

### File Structure

```
lib/
├── database/daos/{entity}_dao.dart
├── providers/{entity}_provider.dart
├── screens/{entity}s_screen.dart
├── widgets/
│   ├── dialogs/{entity}_form_dialog.dart
│   └── {entity}_selector.dart
└── l10n/app_{lang}.arb (modified)

test/
├── database/{entity}_dao_test.dart
├── providers/{entity}_provider_test.dart
├── screens/{entity}s_screen_test.dart
└── widgets/
    ├── {entity}_form_dialog_test.dart
    └── {entity}_selector_test.dart
```
