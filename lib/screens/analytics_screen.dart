import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../services/analytics/analytics_models.dart';
import 'monthly_analytics_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsHub)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.consumptionOverview,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                ...MeterType.values.map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MeterOverviewCard(
                        meterType: type,
                        summary: provider.overviewSummaries[type],
                        onTap: () => _navigateToMonthly(context, type),
                      ),
                    )),
              ],
            ),
    );
  }

  void _navigateToMonthly(BuildContext context, MeterType meterType) {
    final provider = context.read<AnalyticsProvider>();
    provider.setSelectedMeterType(meterType);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MonthlyAnalyticsScreen()),
    );
  }
}

class _MeterOverviewCard extends StatelessWidget {
  final MeterType meterType;
  final MeterTypeSummary? summary;
  final VoidCallback onTap;

  const _MeterOverviewCard({
    required this.meterType,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = colorForMeterType(meterType);
    final icon = iconForMeterType(meterType);
    final label = _meterTypeLabel(l10n, meterType);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    _buildConsumptionText(context),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsumptionText(BuildContext context) {
    if (summary == null || summary!.latestMonthConsumption == null) {
      return Text(
        AppLocalizations.of(context)!.noData,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final value = summary!.latestMonthConsumption!.toStringAsFixed(1);
    final unit = summary!.unit;
    return Text(
      '$value $unit',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorForMeterType(meterType),
            fontWeight: FontWeight.w600,
          ),
    );
  }

  String _meterTypeLabel(AppLocalizations l10n, MeterType type) {
    switch (type) {
      case MeterType.electricity:
        return l10n.electricity;
      case MeterType.gas:
        return l10n.gas;
      case MeterType.water:
        return l10n.water;
      case MeterType.heating:
        return l10n.heating;
    }
  }
}
