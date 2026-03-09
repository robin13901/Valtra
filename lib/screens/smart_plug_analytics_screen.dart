import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/smart_plug_analytics_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/number_format_service.dart';
import '../widgets/charts/consumption_pie_chart.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Inline Analyse tab content for smart plug analytics.
/// Used as a child of IndexedStack in SmartPlugsScreen.
class SmartPlugAnalyseTab extends StatelessWidget {
  const SmartPlugAnalyseTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<SmartPlugAnalyticsProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildBody(context, provider, l10n);
  }

  Widget _buildBody(
    BuildContext context,
    SmartPlugAnalyticsProvider provider,
    AppLocalizations l10n,
  ) {
    final data = provider.data;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month navigation
        _MonthNavigation(provider: provider),
        const SizedBox(height: 16),

        // Content: empty state or data
        if (data == null || data.byPlug.isEmpty)
          _buildEmptyState(context, l10n)
        else
          ..._buildDataSections(context, data, l10n, provider),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.power_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSmartPlugData,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDataSections(
    BuildContext context,
    SmartPlugAnalyticsData data,
    AppLocalizations l10n,
    SmartPlugAnalyticsProvider provider,
  ) {
    final locale = context.watch<LocaleProvider>().localeString;

    return [
      // Stats summary card
      _SummaryCard(data: data, l10n: l10n, locale: locale),
      const SizedBox(height: 24),

      // Consumption by Room section
      Text(l10n.consumptionByRoomTitle,
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SizedBox(
        height: 250,
        child: ConsumptionPieChart(
          slices: _buildRoomSlices(data),
          unit: data.unit,
          locale: locale,
        ),
      ),
      const SizedBox(height: 8),
      ...data.byRoom.map((room) => _RoomBreakdownItem(
            room: room,
            locale: locale,
            totalSmartPlug: data.totalSmartPlug,
            l10n: l10n,
          )),
      const SizedBox(height: 24),

      // Consumption by Plug section
      Text(l10n.consumptionByPlugTitle,
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SizedBox(
        height: 250,
        child: ConsumptionPieChart(
          slices: _buildPlugSlices(data),
          unit: data.unit,
          locale: locale,
        ),
      ),
      const SizedBox(height: 8),
      ...data.byPlug
          .map((plug) => _PlugBreakdownItem(plug: plug, locale: locale)),
    ];
  }

  List<PieSliceData> _buildPlugSlices(SmartPlugAnalyticsData data) {
    final total = data.totalSmartPlug + (data.otherConsumption ?? 0);
    if (total == 0) return [];
    return data.byPlug
        .map((p) => PieSliceData(
              label: p.plugName,
              value: p.consumption,
              percentage: (p.consumption / total) * 100,
              color: p.color,
            ))
        .toList();
  }

  List<PieSliceData> _buildRoomSlices(SmartPlugAnalyticsData data) {
    final total = data.totalSmartPlug + (data.otherConsumption ?? 0);
    if (total == 0) return [];
    return data.byRoom
        .map((r) => PieSliceData(
              label: r.roomName,
              value: r.consumption,
              percentage: (r.consumption / total) * 100,
              color: r.color,
            ))
        .toList();
  }
}

class _MonthNavigation extends StatelessWidget {
  final SmartPlugAnalyticsProvider provider;

  const _MonthNavigation({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => provider.navigateMonth(-1),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(provider.selectedMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => provider.navigateMonth(1),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SmartPlugAnalyticsData data;
  final AppLocalizations l10n;
  final String locale;

  const _SummaryCard(
      {required this.data, required this.l10n, required this.locale});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Consumption = totalElectricity (from electricity meter)
          _SummaryRow(
            label: l10n.totalConsumptionLabel,
            value: data.totalElectricity != null
                ? '${ValtraNumberFormat.consumption(data.totalElectricity!, locale)} ${data.unit}'
                : '\u2014',
          ),
          const SizedBox(height: 8),
          // Tracked by Plugs = totalSmartPlug
          _SummaryRow(
            label: l10n.trackedByPlugs,
            value:
                '${ValtraNumberFormat.consumption(data.totalSmartPlug, locale)} ${data.unit}',
          ),
          const SizedBox(height: 8),
          // Not Tracked = otherConsumption
          if (data.otherConsumption != null) ...[
            _SummaryRow(
              label: l10n.notTracked,
              value:
                  '${ValtraNumberFormat.consumption(data.otherConsumption!, locale)} ${data.unit}',
            ),
          ] else ...[
            Text(
              l10n.noElectricityData,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PlugBreakdownItem extends StatelessWidget {
  final PlugConsumption plug;
  final String locale;

  const _PlugBreakdownItem({required this.plug, required this.locale});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: plug.color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(plug.plugName),
      subtitle: Text(plug.roomName),
      trailing: Text(
        '${ValtraNumberFormat.consumption(plug.consumption, locale)} kWh',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RoomBreakdownItem extends StatelessWidget {
  final RoomConsumption room;
  final String locale;
  final double totalSmartPlug;
  final AppLocalizations l10n;

  const _RoomBreakdownItem({
    required this.room,
    required this.locale,
    required this.totalSmartPlug,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalSmartPlug > 0 ? (room.consumption / totalSmartPlug) * 100 : 0.0;
    final formattedKwh =
        ValtraNumberFormat.consumption(room.consumption, locale);
    final formattedPercent = percentage.toStringAsFixed(0);

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: room.color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(room.roomName),
      trailing: Text(
        l10n.consumptionWithPercent(formattedKwh, formattedPercent),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
