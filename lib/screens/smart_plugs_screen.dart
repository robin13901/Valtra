import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/room_provider.dart';
import '../providers/smart_plug_analytics_provider.dart';
import '../providers/smart_plug_provider.dart';
import '../services/number_format_service.dart';
import '../widgets/dialogs/smart_plug_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'rooms_screen.dart';
import 'smart_plug_analytics_screen.dart';
import 'smart_plug_consumption_screen.dart';

/// Screen displaying smart plugs organized by room with bottom navigation
/// for switching between Analyse and Liste tabs.
class SmartPlugsScreen extends StatefulWidget {
  const SmartPlugsScreen({super.key});

  @override
  State<SmartPlugsScreen> createState() => _SmartPlugsScreenState();
}

class _SmartPlugsScreenState extends State<SmartPlugsScreen> {
  int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmartPlugAnalyticsProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.smartPlugs,
        actions: [
          IconButton(
            icon: const Icon(Icons.meeting_room),
            onPressed: () => _navigateToRooms(context),
            tooltip: l10n.manageRooms,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildAnalyseTab(context),
          _buildListeTab(context),
        ],
      ),
      floatingActionButton: _currentTab == 1
          ? buildGlassFAB(
              context: context,
              icon: Icons.add,
              onPressed: () => _addSmartPlug(context),
            )
          : null,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: l10n.analysis,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: l10n.list,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyseTab(BuildContext context) {
    return const SmartPlugAnalyseTab();
  }

  Widget _buildListeTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<SmartPlugProvider>();
    final plugsByRoom = provider.plugsByRoom;

    if (plugsByRoom.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return _SmartPlugsList(plugsByRoom: plugsByRoom);
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.power_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSmartPlugs,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  void _navigateToRooms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RoomsScreen()),
    );
  }

  Future<void> _addSmartPlug(BuildContext context) async {
    final roomProvider = context.read<RoomProvider>();
    final smartPlugProvider = context.read<SmartPlugProvider>();
    final l10n = AppLocalizations.of(context)!;

    final rooms = roomProvider.rooms;
    if (rooms.isEmpty) {
      // Show snackbar suggesting to create a room first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noRooms),
          action: SnackBarAction(
            label: l10n.addRoom,
            onPressed: () => _navigateToRooms(context),
          ),
        ),
      );
      return;
    }

    final result = await SmartPlugFormDialog.show(context, rooms: rooms);
    if (result == null) return;

    await smartPlugProvider.addSmartPlug(result.name, result.roomId);
  }
}

class _SmartPlugsList extends StatelessWidget {
  final Map<String, List<SmartPlugWithRoom>> plugsByRoom;

  const _SmartPlugsList({required this.plugsByRoom});

  @override
  Widget build(BuildContext context) {
    final roomNames = plugsByRoom.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roomNames.length,
      itemBuilder: (context, index) {
        final roomName = roomNames[index];
        final plugs = plugsByRoom[roomName]!;
        return _RoomSection(roomName: roomName, plugs: plugs);
      },
    );
  }
}

class _RoomSection extends StatelessWidget {
  final String roomName;
  final List<SmartPlugWithRoom> plugs;

  const _RoomSection({required this.roomName, required this.plugs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.meeting_room,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                roomName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...plugs.map((plug) => _SmartPlugCard(plugWithRoom: plug)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SmartPlugCard extends StatefulWidget {
  final SmartPlugWithRoom plugWithRoom;

  const _SmartPlugCard({required this.plugWithRoom});

  @override
  State<_SmartPlugCard> createState() => _SmartPlugCardState();
}

class _SmartPlugCardState extends State<_SmartPlugCard> {
  SmartPlugConsumption? _latestConsumption;

  @override
  void initState() {
    super.initState();
    _loadLatestConsumption();
  }

  @override
  void didUpdateWidget(covariant _SmartPlugCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plugWithRoom.plug.id != widget.plugWithRoom.plug.id) {
      _loadLatestConsumption();
    }
  }

  Future<void> _loadLatestConsumption() async {
    final provider = context.read<SmartPlugProvider>();
    final consumption =
        await provider.getLatestConsumptionForPlug(widget.plugWithRoom.plug.id);
    if (mounted) {
      setState(() => _latestConsumption = consumption);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _navigateToConsumption(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.power,
                color: AppColors.electricityColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plugWithRoom.plug.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.plugWithRoom.roomName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_latestConsumption != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.lastEntry(
                          ValtraNumberFormat.consumption(_latestConsumption!.valueKwh, locale),
                          DateFormat.yMMM(locale).format(_latestConsumption!.month),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.electricityColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editSmartPlug(context);
                  } else if (value == 'delete') {
                    _deleteSmartPlug(context);
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

  void _navigateToConsumption(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SmartPlugConsumptionScreen(smartPlugId: widget.plugWithRoom.plug.id),
      ),
    );
  }

  Future<void> _editSmartPlug(BuildContext context) async {
    final roomProvider = context.read<RoomProvider>();
    final smartPlugProvider = context.read<SmartPlugProvider>();

    final rooms = roomProvider.rooms;
    if (rooms.isEmpty) return;

    final result = await SmartPlugFormDialog.show(
      context,
      plug: widget.plugWithRoom.plug,
      rooms: rooms,
    );
    if (result == null || !context.mounted) return;

    await smartPlugProvider.updateSmartPlug(
      widget.plugWithRoom.plug.id,
      result.name,
      result.roomId,
    );
  }

  Future<void> _deleteSmartPlug(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SmartPlugProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSmartPlug),
        content: Text(l10n.deleteSmartPlugConfirm),
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
      await provider.deleteSmartPlug(widget.plugWithRoom.plug.id);
    }
  }
}
