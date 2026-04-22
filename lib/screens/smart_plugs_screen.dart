import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/room_provider.dart';
import '../providers/smart_plug_analytics_provider.dart';
import '../providers/smart_plug_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/number_format_service.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/smart_plug_consumption_form_dialog.dart';
import '../widgets/dialogs/smart_plug_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'rooms_screen.dart';
import 'smart_plug_analytics_screen.dart';

/// Screen displaying smart plugs with bottom navigation
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
      final analyticsProvider = context.read<AnalyticsProvider>();
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      analyticsProvider.setSelectedMeterType(MeterType.electricity);
      analyticsProvider.setSelectedMonth(previousMonth);
      analyticsProvider.setSelectedYear(previousMonth.year);
      context.read<SmartPlugAnalyticsProvider>().setSelectedMonth(previousMonth);
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
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTab,
            children: [
              _buildAnalyseTab(context),
              _buildListeTab(context),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 8,
            right: 8,
            child: LiquidGlassBottomNav(
              icons: const [Icons.analytics, Icons.list],
              labels: [l10n.analysis, l10n.list],
              keys: const [
                Key('smart_plugs_nav_analyse'),
                Key('smart_plugs_nav_liste'),
              ],
              currentIndex: _currentTab,
              onTap: (index) => setState(() => _currentTab = index),
              rightIcon: Icons.add,
              onRightTap: () => _addSmartPlug(context),
              rightVisibleForIndices: const {1},
            ),
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
    final plugs = provider.plugs;

    if (plugs.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: plugs.length,
      itemBuilder: (context, index) {
        return _SmartPlugExpandableCard(plugWithRoom: plugs[index]);
      },
    );
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

class _SmartPlugExpandableCard extends StatefulWidget {
  final SmartPlugWithRoom plugWithRoom;

  const _SmartPlugExpandableCard({required this.plugWithRoom});

  @override
  State<_SmartPlugExpandableCard> createState() =>
      _SmartPlugExpandableCardState();
}

class _SmartPlugExpandableCardState extends State<_SmartPlugExpandableCard> {
  bool _isExpanded = false;
  SmartPlugConsumption? _latestConsumption;

  @override
  void initState() {
    super.initState();
    _loadLatestConsumption();
  }

  @override
  void didUpdateWidget(covariant _SmartPlugExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plugWithRoom.plug.id != widget.plugWithRoom.plug.id) {
      _loadLatestConsumption();
    }
  }

  Future<void> _loadLatestConsumption() async {
    final provider = context.read<SmartPlugProvider>();
    final consumption = await provider
        .getLatestConsumptionForPlug(widget.plugWithRoom.plug.id);
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Card header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.plugWithRoom.roomName,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (_latestConsumption != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.lastEntry(
                              ValtraNumberFormat.consumption(
                                  _latestConsumption!.valueKwh, locale),
                              DateFormat.yMMM(locale)
                                  .format(_latestConsumption!.month),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.electricityColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
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
                              style:
                                  TextStyle(color: theme.colorScheme.error),
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
          // Expanded consumption section
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildConsumptionSection(context, l10n, locale),
          ],
        ],
      ),
    );
  }

  Widget _buildConsumptionSection(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final theme = Theme.of(context);
    final provider = context.watch<SmartPlugProvider>();

    return Column(
      children: [
        // Header row with label + Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                l10n.consumption,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addConsumption(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addConsumption),
              ),
            ],
          ),
        ),
        // Consumption list via StreamBuilder
        StreamBuilder<List<ConsumptionWithLabel>>(
          stream: provider.watchConsumptionsForPlug(
            widget.plugWithRoom.plug.id,
            locale,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final consumptions = snapshot.data!;
            if (consumptions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.noConsumption,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: consumptions.length,
              itemBuilder: (context, index) {
                final item = consumptions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.electric_bolt,
                    color: AppColors.electricityColor,
                  ),
                  title: Text(item.intervalLabel),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${ValtraNumberFormat.consumption(item.consumption.valueKwh, locale)} ${l10n.kWh}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editConsumption(context, item.consumption);
                          } else if (value == 'delete') {
                            _deleteConsumption(context, item.consumption);
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
                                  style: TextStyle(
                                      color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _addConsumption(BuildContext context) async {
    final provider = context.read<SmartPlugProvider>();
    final result = await SmartPlugConsumptionFormDialog.show(
      context,
      onCheckDuplicate: (month) async {
        final existing = await provider.getConsumptionForMonth(
            widget.plugWithRoom.plug.id, month);
        return existing != null;
      },
    );
    if (result == null) return;
    await provider.addConsumption(
        widget.plugWithRoom.plug.id, result.month, result.valueKwh);
    if (mounted) _loadLatestConsumption();
  }

  Future<void> _editConsumption(
      BuildContext context, SmartPlugConsumption consumption) async {
    final provider = context.read<SmartPlugProvider>();
    final result = await SmartPlugConsumptionFormDialog.show(
      context,
      consumption: consumption,
      onCheckDuplicate: (month) async {
        final existing = await provider.getConsumptionForMonth(
            widget.plugWithRoom.plug.id, month);
        return existing != null && existing.id != consumption.id;
      },
    );
    if (result == null || !context.mounted) return;
    await provider.updateConsumption(
        consumption.id, result.month, result.valueKwh);
    if (mounted) _loadLatestConsumption();
  }

  Future<void> _deleteConsumption(
      BuildContext context, SmartPlugConsumption consumption) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SmartPlugProvider>();
    final confirmed =
        await ConfirmDeleteDialog.show(context, itemLabel: l10n.consumption);
    if (confirmed && context.mounted) {
      await provider.deleteConsumption(consumption.id);
      if (mounted) _loadLatestConsumption();
    }
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
