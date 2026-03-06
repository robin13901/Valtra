---
name: flutter-smart-plug-room-crud
domain: crud
tech: [flutter, drift, provider, intl]
success_rate: 100%
times_used: 1
source_project: valtra
captured_at: 2026-03-06
---

## Context

Use this pattern when implementing:
- Hierarchical entity management (parent → child → detail records)
- Room/container management with sub-entity assignment
- Interval-based consumption or time-series tracking
- Grouped list views organized by category
- Cascade delete with user warnings

## Pattern

### Entity Relationships

```
Household (1) ──► Room (many) ──► SmartPlug (many) ──► Consumption (many)
```

Key characteristics:
- Parent entity scopes child queries (household → rooms)
- Child entity indirectly linked to grandparent via JOIN (household → smartplugs via rooms)
- Leaf entities store time-series data with interval types

### Tasks Structure

**Wave 1 (Parallel - Data Layer + UI Components)**:
- DAO for parent entity (Room) - independent CRUD operations
- DAO for child entity (SmartPlug + Consumption) - nested CRUD
- Form dialog for parent entity - no dependencies
- Form dialog for leaf entity (Consumption) - no dependencies
- Localization strings - no dependencies

**Wave 2 (Sequential - Integration)**:
- Register DAOs in AppDatabase
- Run build_runner to regenerate

**Wave 3 (Parallel - Providers)**:
- Provider for parent entity
- Provider for child entity (with grouping logic)

**Wave 4 (Parallel - Screens)**:
- Parent management screen (list of rooms)
- Child management screen (grouped by parent)
- Form dialog for child entity (needs parent list)

**Wave 5 (Sequential)**:
- Detail screen for leaf entity (consumption entries)

**Wave 6 (Parallel - Integration)**:
- Provider integration in main.dart
- Navigation setup

**Wave 7 (Sequential - Verification)**:
- Run all tests
- Run static analysis

### DAO Pattern for Hierarchical Entities

```dart
// Parent DAO with cascade delete
@DriftAccessor(tables: [Rooms, SmartPlugs, SmartPlugConsumptions])
class RoomDao extends DatabaseAccessor<AppDatabase> {
  // Cascade delete in transaction
  Future<void> deleteRoom(int id) async {
    await transaction(() async {
      final plugIds = await (select(smartPlugs)
        ..where((p) => p.roomId.equals(id)))
        .map((p) => p.id)
        .get();

      for (final plugId in plugIds) {
        await (delete(smartPlugConsumptions)
          ..where((c) => c.smartPlugId.equals(plugId))).go();
      }
      await (delete(smartPlugs)..where((p) => p.roomId.equals(id))).go();
      await (delete(rooms)..where((r) => r.id.equals(id))).go();
    });
  }

  // Check for dependent entities
  Future<bool> roomHasSmartPlugs(int roomId) async {
    final count = await (select(smartPlugs)
      ..where((p) => p.roomId.equals(roomId)))
      .get()
      .then((list) => list.length);
    return count > 0;
  }
}

// Child DAO with indirect household query
@DriftAccessor(tables: [SmartPlugs, SmartPlugConsumptions, Rooms])
class SmartPlugDao extends DatabaseAccessor<AppDatabase> {
  // Query via JOIN for indirect relationship
  Stream<List<SmartPlug>> watchSmartPlugsForHousehold(int householdId) {
    final query = select(smartPlugs).join([
      innerJoin(rooms, rooms.id.equalsExp(smartPlugs.roomId)),
    ]);
    query.where(rooms.householdId.equals(householdId));
    query.orderBy([OrderingTerm.asc(smartPlugs.name)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(smartPlugs)).toList());
  }
}
```

### Provider Pattern for Grouped Display

```dart
class SmartPlugWithRoom {
  final SmartPlug plug;
  final String roomName;
  SmartPlugWithRoom({required this.plug, required this.roomName});
}

class SmartPlugProvider extends ChangeNotifier {
  List<SmartPlugWithRoom> _plugs = [];

  // Grouped getter for UI
  Map<String, List<SmartPlugWithRoom>> get plugsByRoom {
    final result = <String, List<SmartPlugWithRoom>>{};
    for (final plug in _plugs) {
      result.putIfAbsent(plug.roomName, () => []).add(plug);
    }
    return result;
  }
}
```

### Screen Pattern for Grouped ListView

```dart
class _GroupedListView extends StatelessWidget {
  final Map<String, List<Item>> itemsByGroup;

  @override
  Widget build(BuildContext context) {
    final groupNames = itemsByGroup.keys.toList()..sort();
    return ListView.builder(
      itemCount: groupNames.length,
      itemBuilder: (context, index) {
        final groupName = groupNames[index];
        final items = itemsByGroup[groupName]!;
        return _GroupSection(groupName: groupName, items: items);
      },
    );
  }
}
```

### Cascade Delete with Warning Dialog

```dart
Future<void> _deleteParent(BuildContext context) async {
  final childCount = await provider.getChildCount(parent.id);

  String content = l10n.deleteConfirm;
  if (childCount > 0) {
    content = '${l10n.deleteConfirm}\n\n${l10n.hasChildren(childCount)}';
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.delete),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await provider.deleteParent(parent.id);
  }
}
```

### Key Decisions

1. **Indirect household filtering** - SmartPlugs don't have direct householdId; query via Room JOIN
2. **Cascade delete in transaction** - Ensures atomicity when deleting parent with children
3. **Warning before cascade** - Check child count and show warning to prevent accidental data loss
4. **Grouped UI display** - Group items by parent category for better organization
5. **Interval-based tracking** - Use enum for interval types (daily/weekly/monthly/yearly)
6. **Stream-based updates** - Watch queries auto-refresh UI when data changes

### Common Pitfalls

| Issue | Solution |
|-------|----------|
| JOIN query returns wrong type | Use `r.readTable(entity)` to extract correct table from join result |
| Cascade delete incomplete | Wrap in `transaction()` and delete in correct order (grandchild → child → parent) |
| Grouped list not updating | Use `watch()` stream and rebuild map in stream listener |
| Form dialog missing parent list | Pass required parent entities as dialog parameter |
| Room selector empty | Check rooms.isEmpty before showing dialog, show snackbar with navigation action |

### UAT Criteria

1. **Create parent** - FAB → Dialog → Save → Appears in list
2. **Create child** - FAB → Dialog with parent dropdown → Save → Grouped under parent
3. **Create detail record** - Navigate to child → FAB → Dialog with interval/date/value
4. **Delete parent with children** - Warning shows child count → Confirm → All deleted
5. **View grouped display** - Items grouped by parent with section headers
