import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/heating_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/rooms_screen.dart';
import '../services/analytics/analytics_models.dart';
import '../services/interpolation/models.dart';
import '../services/number_format_service.dart';
import '../widgets/charts/chart_legend.dart';
import '../widgets/charts/consumption_pie_chart.dart';
import '../widgets/charts/household_comparison_chart.dart';
import '../widgets/charts/month_selector.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/charts/monthly_summary_card.dart';
import '../widgets/charts/year_comparison_chart.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/dialogs/heating_meter_form_dialog.dart';
import '../widgets/dialogs/heating_reading_form_dialog.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Screen displaying heating meters grouped by room with bottom navigation
/// for switching between Analyse and Liste tabs.
class HeatingScreen extends StatefulWidget {
  const HeatingScreen({super.key});

  @override
  State<HeatingScreen> createState() => _HeatingScreenState();
}

class _HeatingScreenState extends State<HeatingScreen> {
  int _currentTab = 1; // 0=Analyse, 1=Liste (default Liste)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.setSelectedMeterType(MeterType.heating);
      provider.setSelectedMonth(DateTime.now());
      provider.setSelectedYear(DateTime.now().year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.heatingMeters,
        actions: [
          // Visibility toggle: only on Liste tab
          if (_currentTab == 1)
            Builder(builder: (context) {
              final provider = context.watch<HeatingProvider>();
              return IconButton(
                icon: Icon(
                  provider.showInterpolatedValues
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () => provider.toggleInterpolatedValues(),
                tooltip: provider.showInterpolatedValues
                    ? l10n.hideInterpolatedValues
                    : l10n.showInterpolatedValues,
              );
            }),
          // Room management: only on Liste tab
          if (_currentTab == 1)
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
            bottom: 0,
            left: 0,
            right: 0,
            child: LiquidGlassBottomNav(
              icons: const [Icons.analytics, Icons.list],
              labels: [l10n.analysis, l10n.list],
              keys: const [
                Key('heating_nav_analyse'),
                Key('heating_nav_liste'),
              ],
              currentIndex: _currentTab,
              onTap: (index) => setState(() => _currentTab = index),
              rightIcon: Icons.add,
              onRightTap: () => _addMeter(context),
              rightVisibleForIndices: const {1},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<HeatingProvider>();
    final metersByRoom = provider.metersByRoom;

    if (metersByRoom.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return _HeatingMetersByRoom(metersByRoom: metersByRoom);
  }

  Widget _buildAnalyseTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final heatingProvider = context.watch<HeatingProvider>();
    final locale = context.watch<LocaleProvider>().localeString;
    final color = colorForMeterType(MeterType.heating);
    final monthlyData = analyticsProvider.monthlyData;
    final yearlyData = analyticsProvider.yearlyData;

    if (analyticsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (monthlyData == null) {
      return Center(child: Text(l10n.noData));
    }

    // Compute previous month total from recentMonths
    double? previousMonthTotal;
    final selectedMonth = analyticsProvider.selectedMonth;
    for (final period in monthlyData.recentMonths) {
      final pm = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
      if (period.periodStart.year == pm.year &&
          period.periodStart.month == pm.month) {
        previousMonthTotal = period.consumption;
        break;
      }
    }

    // Build per-heater pie slices for selected month
    final heaterSlices = _buildHeaterSlices(heatingProvider, selectedMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Month selector
        MonthSelector(
          selectedMonth: analyticsProvider.selectedMonth,
          onMonthChanged: (month) {
            analyticsProvider.setSelectedMonth(month);
            if (month.year != analyticsProvider.selectedYear) {
              analyticsProvider.setSelectedYear(month.year);
            }
          },
          locale: locale,
        ),
        const SizedBox(height: 16),

        // Monthly summary card
        MonthlySummaryCard(
          totalConsumption: monthlyData.totalConsumption,
          previousMonthTotal: previousMonthTotal,
          unit: monthlyData.unit,
          month: analyticsProvider.selectedMonth,
          color: color,
          locale: locale,
        ),
        const SizedBox(height: 24),

        // Bar chart section: monthly breakdown
        Text(l10n.monthlyBreakdown,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: MonthlyBarChart(
            periods: monthlyData.recentMonths,
            primaryColor: color,
            unit: monthlyData.unit,
            highlightMonth: analyticsProvider.selectedMonth,
            locale: locale,
            showCosts: false,
            periodCosts: null,
            costUnit: null,
          ),
        ),
        const SizedBox(height: 24),

        // Year-over-year comparison (only if previous year data exists)
        if (yearlyData != null &&
            yearlyData.previousYearBreakdown != null &&
            yearlyData.previousYearBreakdown!.isNotEmpty) ...[
          Text(l10n.yearOverYear,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: YearComparisonChart(
              currentYear: yearlyData.monthlyBreakdown,
              previousYear: yearlyData.previousYearBreakdown,
              primaryColor: color,
              unit: yearlyData.unit,
              locale: locale,
              showCosts: false,
              currentYearCosts: null,
              previousYearCosts: null,
              costUnit: null,
            ),
          ),
          const SizedBox(height: 8),
          ChartLegend(items: [
            ChartLegendItem(
              color: color,
              label: l10n.currentYear,
            ),
            ChartLegendItem(
              color: color.withValues(alpha: 0.5),
              label: l10n.previousYear,
              isDashed: true,
            ),
          ]),
          const SizedBox(height: 24),
        ],

        // Household comparison (only if >1 household data available)
        if (analyticsProvider.householdComparisonData.length > 1) ...[
          SizedBox(
            height: 250,
            child: HouseholdComparisonChart(
              households: analyticsProvider.householdComparisonData,
              unit: monthlyData.unit,
              locale: locale,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Per-heater distribution section
        if (heaterSlices.isNotEmpty) ...[
          Text(l10n.consumptionByRoomTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: ConsumptionPieChart(
              slices: heaterSlices,
              unit: 'units',
              locale: locale,
            ),
          ),
          const SizedBox(height: 8),
          ...heatingProvider.metersWithRooms.map((mwr) {
            // Find the slice for this meter
            final slice = heaterSlices.firstWhere(
              (s) => s.label == mwr.meter.name,
              orElse: () => const PieSliceData(
                label: '',
                value: 0,
                percentage: 0,
                color: Colors.transparent,
              ),
            );
            if (slice.value == 0) return const SizedBox.shrink();
            return _HeaterBreakdownItem(
              meterName: mwr.meter.name,
              roomName: mwr.roomName,
              percentage: slice.percentage,
              color: slice.color,
            );
          }),
        ],
      ],
    );
  }

  /// Computes per-heater pie slices from raw reading deltas for the selected month.
  List<PieSliceData> _buildHeaterSlices(
    HeatingProvider heatingProvider,
    DateTime selectedMonth,
  ) {
    final meters = heatingProvider.metersWithRooms;
    if (meters.isEmpty) return [];

    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    double totalDelta = 0;
    final meterDeltas = <String, double>{};

    for (final mwr in meters) {
      final readings = heatingProvider.getReadingsWithDeltas(mwr.meter.id);
      double sum = 0;
      for (final r in readings) {
        if (r.delta != null &&
            !r.reading.timestamp.isBefore(monthStart) &&
            r.reading.timestamp.isBefore(monthEnd)) {
          sum += r.delta!;
        }
      }
      if (sum > 0) {
        meterDeltas[mwr.meter.name] = sum;
        totalDelta += sum;
      }
    }

    if (totalDelta == 0) return [];

    int i = 0;
    return meterDeltas.entries
        .map((e) => PieSliceData(
              label: e.key,
              value: e.value,
              percentage: (e.value / totalDelta) * 100,
              color: pieChartColors[i++ % pieChartColors.length],
            ))
        .toList();
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.thermostat_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noHeatingMeters,
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

  Future<void> _addMeter(BuildContext context) async {
    final provider = context.read<HeatingProvider>();
    final roomDao = context.read<AppDatabase>().roomDao;
    final householdId = provider.householdId;
    if (householdId == null) return;

    final rooms = await roomDao.getRoomsForHousehold(householdId);
    if (!context.mounted) return;

    if (rooms.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
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

    final result = await HeatingMeterFormDialog.show(
      context,
      rooms: rooms,
    );
    if (result == null || !context.mounted) return;

    await provider.addMeter(
      result.name,
      result.roomId,
      heatingType: result.heatingType,
      heatingRatio: result.heatingRatio,
    );
  }
}

/// Per-heater breakdown list item for the Analyse tab pie chart section.
class _HeaterBreakdownItem extends StatelessWidget {
  final String meterName;
  final String roomName;
  final double percentage;
  final Color color;

  const _HeaterBreakdownItem({
    required this.meterName,
    required this.roomName,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(meterName),
      subtitle: Text(roomName),
      trailing: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HeatingMetersByRoom extends StatelessWidget {
  final Map<String, List<HeatingMeterWithRoom>> metersByRoom;

  const _HeatingMetersByRoom({required this.metersByRoom});

  @override
  Widget build(BuildContext context) {
    final roomNames = metersByRoom.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: roomNames.length,
      itemBuilder: (context, index) {
        final roomName = roomNames[index];
        final meters = metersByRoom[roomName]!;
        return _RoomSection(roomName: roomName, meters: meters);
      },
    );
  }
}

class _RoomSection extends StatelessWidget {
  final String roomName;
  final List<HeatingMeterWithRoom> meters;

  const _RoomSection({required this.roomName, required this.meters});

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
        ...meters.map((mwr) => _HeatingMeterCard(meterWithRoom: mwr)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HeatingMeterCard extends StatefulWidget {
  final HeatingMeterWithRoom meterWithRoom;

  const _HeatingMeterCard({required this.meterWithRoom});

  @override
  State<_HeatingMeterCard> createState() => _HeatingMeterCardState();
}

class _HeatingMeterCardState extends State<_HeatingMeterCard> {
  bool _isExpanded = false;

  HeatingMeter get meter => widget.meterWithRoom.meter;
  String get roomName => widget.meterWithRoom.roomName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = context.watch<HeatingProvider>();
    final readings = provider.getReadingsWithDeltas(meter.id);
    final displayItems = provider.getDisplayItems(meter.id);
    final locale = context.watch<LocaleProvider>().localeString;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Meter header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.thermostat,
                    color: AppColors.heatingColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                meter.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (meter.heatingType == HeatingType.centralMeter &&
                                meter.heatingRatio != null)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.heatingColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(meter.heatingRatio! * 100).toStringAsFixed(0)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.heatingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meter.heatingType == HeatingType.centralMeter
                              ? l10n.centralHeating
                              : l10n.ownMeter,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (readings.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ValtraNumberFormat.consumption(
                                readings.first.reading.value, locale),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editMeter(context);
                      } else if (value == 'delete') {
                        _deleteMeter(context);
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
            ),
          ),
          // Expanded readings section
          if (_isExpanded) ...[
            const Divider(height: 1),
            provider.showInterpolatedValues
                ? _buildDisplayItemsSection(context, l10n, displayItems)
                : _buildReadingsSection(context, l10n, readings),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<HeatingReadingWithDelta> readings,
  ) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    return Column(
      children: [
        // Add reading button
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                l10n.heatingReadings,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addReading(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addHeatingReading),
              ),
            ],
          ),
        ),
        if (readings.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.noHeatingReadings,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final readingWithDelta = readings[index];
              final reading = readingWithDelta.reading;
              final delta = readingWithDelta.delta;

              return ListTile(
                leading: const Icon(
                  Icons.thermostat,
                  color: AppColors.heatingColor,
                ),
                title: Text(
                  ValtraNumberFormat.consumption(reading.value, locale),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ValtraNumberFormat.dateTime(reading.timestamp, locale),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (delta != null)
                      Text(
                        l10n.heatingConsumptionSince(
                            ValtraNumberFormat.consumption(delta, locale)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.heatingColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        l10n.firstReading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editReading(context, reading);
                    } else if (value == 'delete') {
                      _deleteReading(context, reading);
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
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDisplayItemsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<ReadingDisplayItem> items,
  ) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().localeString;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                l10n.heatingReadings,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addReading(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addHeatingReading),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.noHeatingReadings,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              if (item.isInterpolated) {
                return ListTile(
                  tileColor: AppColors.ultraViolet.withValues(alpha: 0.08),
                  leading: Icon(
                    Icons.thermostat,
                    color: AppColors.ultraViolet.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    ValtraNumberFormat.consumption(item.value, locale),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ValtraNumberFormat.dateTime(item.timestamp, locale),
                        style: theme.textTheme.bodySmall,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.ultraViolet.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.interpolated,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ultraViolet,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListTile(
                leading: const Icon(
                  Icons.thermostat,
                  color: AppColors.heatingColor,
                ),
                title: Text(
                  ValtraNumberFormat.consumption(item.value, locale),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ValtraNumberFormat.dateTime(item.timestamp, locale),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.delta != null)
                      Text(
                        l10n.heatingConsumptionSince(
                            ValtraNumberFormat.consumption(item.delta!, locale)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.heatingColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        l10n.firstReading,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editReadingById(context, item.readingId!);
                    } else if (value == 'delete') {
                      _deleteReadingById(context, item.readingId!);
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
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _editMeter(BuildContext context) async {
    final provider = context.read<HeatingProvider>();
    final roomDao = context.read<AppDatabase>().roomDao;
    final householdId = provider.householdId;
    if (householdId == null) return;

    final rooms = await roomDao.getRoomsForHousehold(householdId);
    if (!context.mounted) return;

    final result = await HeatingMeterFormDialog.show(
      context,
      meter: meter,
      rooms: rooms,
    );
    if (result == null || !context.mounted) return;

    await provider.updateMeter(
      meter.id,
      result.name,
      result.roomId,
      heatingType: result.heatingType,
      heatingRatio: result.heatingRatio,
    );
  }

  Future<void> _deleteMeter(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<HeatingProvider>();

    final readingCount =
        await provider.getReadingCountForMeter(meter.id);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteHeatingMeter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteHeatingMeterConfirm),
            if (readingCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.heatingMeterHasReadings(readingCount),
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
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
      await provider.deleteMeter(meter.id);
    }
  }

  Future<void> _addReading(BuildContext context) async {
    final provider = context.read<HeatingProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await HeatingReadingFormDialog.show(context);
    if (result == null || !context.mounted) return;

    final error = await provider.validateReading(
      meter.id,
      result.value,
      result.timestamp,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(l10n.heatingReadingMustBeGreaterOrEqual(
                  ValtraNumberFormat.consumption(error, locale))),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.addReading(
      meter.id,
      result.timestamp,
      result.value,
    );
  }

  Future<void> _editReading(
      BuildContext context, HeatingReading reading) async {
    final provider = context.read<HeatingProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final result = await HeatingReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null || !context.mounted) return;

    final error = await provider.validateReading(
      meter.id,
      result.value,
      result.timestamp,
      excludeId: reading.id,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(l10n.heatingReadingMustBeGreaterOrEqual(
                  ValtraNumberFormat.consumption(error, locale))),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.updateReading(
      reading.id,
      result.timestamp,
      result.value,
    );
  }

  Future<void> _deleteReading(
      BuildContext context, HeatingReading reading) async {
    await _deleteReadingById(context, reading.id);
  }

  Future<void> _editReadingById(BuildContext context, int readingId) async {
    final provider = context.read<HeatingProvider>();
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().localeString;

    final readings = provider.getReadingsWithDeltas(meter.id);
    final readingWithDelta = readings.firstWhere((r) => r.reading.id == readingId);
    final reading = readingWithDelta.reading;

    final result = await HeatingReadingFormDialog.show(
      context,
      reading: reading,
    );
    if (result == null || !context.mounted) return;

    final error = await provider.validateReading(
      meter.id,
      result.value,
      result.timestamp,
      excludeId: reading.id,
    );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.heatingReadingMustBeGreaterOrEqual(
              ValtraNumberFormat.consumption(error, locale))),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await provider.updateReading(
      reading.id,
      result.timestamp,
      result.value,
    );
  }

  Future<void> _deleteReadingById(BuildContext context, int readingId) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<HeatingProvider>();

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      itemLabel: l10n.heatingReading,
    );

    if (confirmed && context.mounted) {
      await provider.deleteReading(readingId);
    }
  }
}
