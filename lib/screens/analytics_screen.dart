import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/csv_export_service.dart';
import '../services/interpolation/models.dart';
import '../services/share_service.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'monthly_analytics_screen.dart';
import 'smart_plug_analytics_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.analyticsHub,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportAll(context, provider),
            tooltip: l10n.exportAll,
          ),
        ],
      ),
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
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(l10n.smartPlugAnalytics,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _navigateToSmartPlugAnalytics(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.electricityColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.pie_chart,
                                color: AppColors.electricityColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.smartPlugAnalytics,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 4),
                                Text(l10n.consumptionByPlug,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        )),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
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

  void _navigateToSmartPlugAnalytics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => const SmartPlugAnalyticsScreen()),
    );
  }

  Future<void> _exportAll(
      BuildContext context, AnalyticsProvider provider) async {
    final l10n = AppLocalizations.of(context)!;

    // Collect data from all overview summaries — use recent months data
    // For a hub-level export, we export the overview summaries as a simple CSV
    final dataByType = <MeterType, List<PeriodConsumption>>{};

    // Load yearly data for each meter type
    for (final type in MeterType.values) {
      final summary = provider.overviewSummaries[type];
      if (summary != null && summary.latestMonthConsumption != null) {
        // We need the provider to load yearly data for each type
        // For simplicity, export overview data available
        dataByType[type] = [];
      }
    }

    // If no data available, show message
    if (dataByType.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noData)),
        );
      }
      return;
    }

    const csvService = CsvExportService();
    final shareService = ShareService();

    final year = DateTime.now().year;
    final csv = csvService.exportAllMeters(
      year: year,
      dataByType: dataByType,
    );
    final filename = 'valtra_all_meters_$year.csv';

    await shareService.shareCsvFile(csvContent: csv, filename: filename);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
    }
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

    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
    final costText = summary!.latestMonthCost != null
        ? '  ~${summary!.currencySymbol ?? '\u20AC'}${summary!.latestMonthCost!.toStringAsFixed(2)}'
        : '';
    return Text(
      '$value $unit$costText',
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
