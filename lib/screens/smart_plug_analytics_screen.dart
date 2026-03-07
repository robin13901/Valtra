import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/smart_plug_analytics_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/number_format_service.dart';
import '../widgets/charts/consumption_pie_chart.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying smart plug analytics with pie charts and breakdown lists.
class SmartPlugAnalyticsScreen extends StatelessWidget {
  const SmartPlugAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<SmartPlugAnalyticsProvider>();

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.smartPlugAnalytics,
        actions: [
          if (provider.period == AnalyticsPeriod.custom)
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: () => _pickDateRange(context),
              tooltip: l10n.customDateRange,
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, provider, l10n),
    );
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
        // Period selector
        _PeriodSelector(
          period: provider.period,
          onChanged: provider.setPeriod,
          l10n: l10n,
        ),
        const SizedBox(height: 16),

        // Period navigation
        _PeriodNavigationHeader(provider: provider, l10n: l10n),
        const SizedBox(height: 16),

        // Content: empty state or data
        if (data == null || data.byPlug.isEmpty)
          _buildEmptyState(context, l10n)
        else
          ..._buildDataSections(context, data, l10n),
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
  ) {
    final locale = context.watch<LocaleProvider>().localeString;

    return [
      // Consumption by Plug section
      Text(l10n.consumptionByPlug,
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
      const SizedBox(height: 24),

      // Consumption by Room section
      Text(l10n.consumptionByRoom,
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
      const SizedBox(height: 24),

      // Summary card
      _SummaryCard(data: data, l10n: l10n, locale: locale),
      const SizedBox(height: 24),

      // Plug Breakdown list
      Text(l10n.plugBreakdown,
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...data.byPlug.map((plug) => _PlugBreakdownItem(plug: plug, locale: locale)),
      const SizedBox(height: 24),

      // Room Breakdown list
      Text(l10n.roomBreakdown,
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...data.byRoom.map((room) => _RoomBreakdownItem(room: room, locale: locale)),
    ];
  }

  List<PieSliceData> _buildPlugSlices(SmartPlugAnalyticsData data) {
    final total = data.totalSmartPlug + (data.otherConsumption ?? 0);
    if (total == 0) return [];
    final slices = data.byPlug
        .map((p) => PieSliceData(
              label: p.plugName,
              value: p.consumption,
              percentage: (p.consumption / total) * 100,
              color: p.color,
            ))
        .toList();
    if (data.otherConsumption != null && data.otherConsumption! > 0) {
      slices.add(PieSliceData(
        label: 'Other',
        value: data.otherConsumption!,
        percentage: (data.otherConsumption! / total) * 100,
        color: AppColors.otherColor,
      ));
    }
    return slices;
  }

  List<PieSliceData> _buildRoomSlices(SmartPlugAnalyticsData data) {
    final total = data.totalSmartPlug + (data.otherConsumption ?? 0);
    if (total == 0) return [];
    final slices = data.byRoom
        .map((r) => PieSliceData(
              label: r.roomName,
              value: r.consumption,
              percentage: (r.consumption / total) * 100,
              color: r.color,
            ))
        .toList();
    if (data.otherConsumption != null && data.otherConsumption! > 0) {
      slices.add(PieSliceData(
        label: 'Other',
        value: data.otherConsumption!,
        percentage: (data.otherConsumption! / total) * 100,
        color: AppColors.otherColor,
      ));
    }
    return slices;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<SmartPlugAnalyticsProvider>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: provider.customRange ??
          DateTimeRange(
            start: provider.selectedMonth,
            end: DateTime(
                provider.selectedMonth.year, provider.selectedMonth.month + 1, 0),
          ),
    );
    if (range != null) {
      provider.setCustomRange(range);
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  final AnalyticsPeriod period;
  final ValueChanged<AnalyticsPeriod> onChanged;
  final AppLocalizations l10n;

  const _PeriodSelector({
    required this.period,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AnalyticsPeriod>(
      segments: [
        ButtonSegment(
          value: AnalyticsPeriod.monthly,
          label: Text(l10n.periodMonthly),
        ),
        ButtonSegment(
          value: AnalyticsPeriod.yearly,
          label: Text(l10n.periodYearly),
        ),
        ButtonSegment(
          value: AnalyticsPeriod.custom,
          label: Text(l10n.periodCustom),
        ),
      ],
      selected: {period},
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }
}

class _PeriodNavigationHeader extends StatelessWidget {
  final SmartPlugAnalyticsProvider provider;
  final AppLocalizations l10n;

  const _PeriodNavigationHeader({
    required this.provider,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    switch (provider.period) {
      case AnalyticsPeriod.monthly:
        return _MonthNavigation(provider: provider);
      case AnalyticsPeriod.yearly:
        return _YearNavigation(provider: provider);
      case AnalyticsPeriod.custom:
        return _CustomRangeDisplay(provider: provider, l10n: l10n);
    }
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

class _YearNavigation extends StatelessWidget {
  final SmartPlugAnalyticsProvider provider;

  const _YearNavigation({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => provider.navigateYear(-1),
        ),
        Expanded(
          child: Text(
            '${provider.selectedYear}',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => provider.navigateYear(1),
        ),
      ],
    );
  }
}

class _CustomRangeDisplay extends StatelessWidget {
  final SmartPlugAnalyticsProvider provider;
  final AppLocalizations l10n;

  const _CustomRangeDisplay({
    required this.provider,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final range = provider.customRange;
    if (range == null) {
      return Center(
        child: Text(
          l10n.customDateRange,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    return Center(
      child: Text(
        '${DateFormat.MMMd().format(range.start)} \u2013 ${DateFormat.MMMd().format(range.end)}',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SmartPlugAnalyticsData data;
  final AppLocalizations l10n;
  final String locale;

  const _SummaryCard({required this.data, required this.l10n, required this.locale});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: l10n.totalTracked,
            value: '${ValtraNumberFormat.consumption(data.totalSmartPlug, locale)} ${data.unit}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: l10n.totalElectricity,
            value: data.totalElectricity != null
                ? '${ValtraNumberFormat.consumption(data.totalElectricity!, locale)} ${data.unit}'
                : '\u2014',
          ),
          const SizedBox(height: 8),
          if (data.otherConsumption != null) ...[
            _SummaryRow(
              label: l10n.otherConsumption,
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

  const _RoomBreakdownItem({required this.room, required this.locale});

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
        '${ValtraNumberFormat.consumption(room.consumption, locale)} kWh',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
