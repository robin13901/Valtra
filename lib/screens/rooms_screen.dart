import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/room_provider.dart';
import '../widgets/dialogs/room_form_dialog.dart';

/// Screen displaying rooms with add/edit/delete functionality.
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RoomProvider>();
    final rooms = provider.rooms;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rooms),
      ),
      body: rooms.isEmpty
          ? _buildEmptyState(context, l10n)
          : _RoomsList(rooms: rooms),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRoom(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noRooms,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _addRoom(BuildContext context) async {
    final provider = context.read<RoomProvider>();

    final result = await RoomFormDialog.show(context);
    if (result == null) return;

    await provider.addRoom(result.name);
  }
}

class _RoomsList extends StatelessWidget {
  final List<Room> rooms;

  const _RoomsList({required this.rooms});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _RoomCard(room: room);
      },
    );
  }
}

class _RoomCard extends StatefulWidget {
  final Room room;

  const _RoomCard({required this.room});

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  int? _plugCount;

  @override
  void initState() {
    super.initState();
    _loadPlugCount();
  }

  @override
  void didUpdateWidget(covariant _RoomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id) {
      _loadPlugCount();
    }
  }

  Future<void> _loadPlugCount() async {
    final provider = context.read<RoomProvider>();
    final count = await provider.getSmartPlugCount(widget.room.id);
    if (mounted) {
      setState(() => _plugCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editRoom(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.meeting_room,
                color: AppColors.electricityColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _plugCount != null
                          ? l10n.smartPlugCount(_plugCount!)
                          : '...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editRoom(context);
                  } else if (value == 'delete') {
                    _deleteRoom(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.delete,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editRoom(BuildContext context) async {
    final provider = context.read<RoomProvider>();
    final l10n = AppLocalizations.of(context)!;

    final result = await RoomFormDialog.show(context, room: widget.room);
    if (result == null || !context.mounted) return;

    final success = await provider.updateRoom(widget.room.id, result.name);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noData)),
      );
    }
  }

  Future<void> _deleteRoom(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<RoomProvider>();

    // Check if room has smart plugs
    final plugCount = await provider.getSmartPlugCount(widget.room.id);
    if (!context.mounted) return;

    String content = l10n.deleteRoomConfirm;
    if (plugCount > 0) {
      content = '${l10n.deleteRoomConfirm}\n\n${l10n.roomHasSmartPlugs(plugCount)}';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRoom),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteRoom(widget.room.id);
    }
  }
}
