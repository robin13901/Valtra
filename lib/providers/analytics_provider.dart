import 'package:flutter/material.dart';

import '../database/daos/electricity_dao.dart';
import '../database/daos/gas_dao.dart';
import '../database/daos/heating_dao.dart';
import '../database/daos/water_dao.dart';
import '../providers/interpolation_settings_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/gas_conversion_service.dart';
import '../services/interpolation/interpolation_service.dart';
import '../services/interpolation/models.dart';
import '../services/interpolation/reading_converters.dart';

/// Orchestrates analytics data across all meter types.
///
/// Combines DAOs, interpolation, and gas conversion to produce
/// chart-ready data for the analytics hub and detail screens.
class AnalyticsProvider extends ChangeNotifier {
  final ElectricityDao _electricityDao;
  final GasDao _gasDao;
  final WaterDao _waterDao;
  final HeatingDao _heatingDao;
  final InterpolationService _interpolationService;
  final GasConversionService _gasConversionService;
  final InterpolationSettingsProvider _settingsProvider;

  int? _householdId;
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  MeterType _selectedMeterType = MeterType.electricity;
  DateTimeRange? _customRange; // null = use selectedMonth
  int _selectedYear = DateTime.now().year;

  // Computed state
  MonthlyAnalyticsData? _monthlyData;
  YearlyAnalyticsData? _yearlyData;
  Map<MeterType, MeterTypeSummary> _overviewSummaries = {};
  bool _isLoading = false;

  AnalyticsProvider({
    required ElectricityDao electricityDao,
    required GasDao gasDao,
    required WaterDao waterDao,
    required HeatingDao heatingDao,
    required InterpolationService interpolationService,
    required GasConversionService gasConversionService,
    required InterpolationSettingsProvider settingsProvider,
  })  : _electricityDao = electricityDao,
        _gasDao = gasDao,
        _waterDao = waterDao,
        _heatingDao = heatingDao,
        _interpolationService = interpolationService,
        _gasConversionService = gasConversionService,
        _settingsProvider = settingsProvider;

  // Getters
  int? get householdId => _householdId;
  DateTime get selectedMonth => _selectedMonth;
  MeterType get selectedMeterType => _selectedMeterType;
  DateTimeRange? get customRange => _customRange;
  MonthlyAnalyticsData? get monthlyData => _monthlyData;
  YearlyAnalyticsData? get yearlyData => _yearlyData;
  int get selectedYear => _selectedYear;
  Map<MeterType, MeterTypeSummary> get overviewSummaries => _overviewSummaries;
  bool get isLoading => _isLoading;

  void setHouseholdId(int? id) {
    _householdId = id;
    notifyListeners();
    if (id != null) {
      _loadOverview();
    } else {
      _overviewSummaries = {};
      _monthlyData = null;
      _yearlyData = null;
      notifyListeners();
    }
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _customRange = null;
    notifyListeners();
    _loadMonthlyData();
  }

  void setSelectedMeterType(MeterType type) {
    _selectedMeterType = type;
    notifyListeners();
    _loadMonthlyData();
  }

  void setCustomRange(DateTimeRange? range) {
    _customRange = range;
    notifyListeners();
    _loadMonthlyData();
  }

  void navigateMonth(int delta) {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    _customRange = null;
    notifyListeners();
    _loadMonthlyData();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
    _loadYearlyData();
  }

  void navigateYear(int delta) {
    _selectedYear += delta;
    notifyListeners();
    _loadYearlyData();
  }

  /// Load overview summaries for all 4 meter types (analytics hub).
  Future<void> _loadOverview() async {
    if (_householdId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      // Range: go back 6 months for overview data
      final rangeStart = DateTime(now.year, now.month - 6, 1);
      final rangeEnd = DateTime(now.year, now.month + 1, 1);

      final summaries = <MeterType, MeterTypeSummary>{};

      for (final type in MeterType.values) {
        final method = _settingsProvider.getMethodForMeterType(type.name);
        final readingsPerMeter =
            await _getReadingsPerMeter(type, rangeStart, rangeEnd);

        if (readingsPerMeter.isEmpty) {
          summaries[type] = MeterTypeSummary(
            meterType: type,
            latestMonthConsumption: null,
            hasInterpolation: false,
            unit: unitForMeterType(type),
          );
          continue;
        }

        final consumption = _aggregateMonthlyConsumption(
          readingsPerMeter,
          rangeStart,
          rangeEnd,
          method,
        );

        // Find current month consumption
        double? currentConsumption;
        bool hasInterpolation = false;
        for (final period in consumption) {
          if (period.periodStart.year == currentMonthStart.year &&
              period.periodStart.month == currentMonthStart.month) {
            currentConsumption = period.consumption;
            hasInterpolation =
                period.startInterpolated || period.endInterpolated;
            break;
          }
        }

        // Apply gas kWh conversion if gas type
        if (type == MeterType.gas && currentConsumption != null) {
          currentConsumption = _gasConversionService.toKwh(
            currentConsumption,
            factor: _settingsProvider.gasKwhFactor,
          );
        }

        summaries[type] = MeterTypeSummary(
          meterType: type,
          latestMonthConsumption: currentConsumption,
          hasInterpolation: hasInterpolation,
          unit: type == MeterType.gas ? 'kWh' : unitForMeterType(type),
        );
      }

      _overviewSummaries = summaries;
    } catch (e) {
      // Silently handle errors - show empty data
      _overviewSummaries = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load detailed monthly data for selected meter type + month/range.
  Future<void> _loadMonthlyData() async {
    if (_householdId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final method =
          _settingsProvider.getMethodForMeterType(_selectedMeterType.name);

      // Determine date range for line chart
      final DateTime lineStart;
      final DateTime lineEnd;
      if (_customRange != null) {
        lineStart = _customRange!.start;
        lineEnd = _customRange!.end;
      } else {
        lineStart = _selectedMonth;
        lineEnd =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      }

      // Bar chart range: 6 months back from selected month
      final barStart =
          DateTime(_selectedMonth.year, _selectedMonth.month - 5, 1);
      final barEnd =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

      // Combine range for data fetch (earliest to latest)
      final fetchStart = barStart.isBefore(lineStart) ? barStart : lineStart;
      final fetchEnd = barEnd.isAfter(lineEnd) ? barEnd : lineEnd;

      final readingsPerMeter = await _getReadingsPerMeter(
        _selectedMeterType,
        fetchStart,
        fetchEnd,
      );

      if (readingsPerMeter.isEmpty) {
        _monthlyData = MonthlyAnalyticsData(
          meterType: _selectedMeterType,
          month: _selectedMonth,
          dailyValues: [],
          recentMonths: [],
          totalConsumption: null,
          unit: _getDisplayUnit(_selectedMeterType),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Daily boundaries for line chart
      final dailyBoundaries = _aggregateDailyBoundaries(
        readingsPerMeter,
        lineStart,
        lineEnd,
        method,
      );

      // Monthly consumption for bar chart
      var monthlyConsumption = _aggregateMonthlyConsumption(
        readingsPerMeter,
        barStart,
        barEnd,
        method,
      );

      // Apply gas conversion if needed
      if (_selectedMeterType == MeterType.gas) {
        monthlyConsumption = _gasConversionService.toKwhConsumptions(
          monthlyConsumption,
          factor: _settingsProvider.gasKwhFactor,
        );
      }

      // Calculate total consumption for the selected month/range
      double? totalConsumption;
      if (_customRange != null) {
        // For custom range, sum all monthly consumption in range
        totalConsumption = monthlyConsumption
            .where((p) =>
                !p.periodStart.isBefore(lineStart) &&
                    p.periodEnd.isBefore(lineEnd) ||
                p.periodEnd.isAtSameMomentAs(lineEnd))
            .fold<double>(0, (sum, p) => sum + p.consumption);
      } else {
        // For single month, find the period matching selected month
        for (final period in monthlyConsumption) {
          if (period.periodStart.year == _selectedMonth.year &&
              period.periodStart.month == _selectedMonth.month) {
            totalConsumption = period.consumption;
            break;
          }
        }
      }

      // Convert daily boundaries to ChartDataPoints
      final dailyValues = dailyBoundaries
          .map((b) => ChartDataPoint(
                timestamp: b.timestamp,
                value: _selectedMeterType == MeterType.gas
                    ? _gasConversionService.toKwh(b.value,
                        factor: _settingsProvider.gasKwhFactor)
                    : b.value,
                isInterpolated: b.isInterpolated,
              ))
          .toList();

      _monthlyData = MonthlyAnalyticsData(
        meterType: _selectedMeterType,
        month: _selectedMonth,
        dailyValues: dailyValues,
        recentMonths: monthlyConsumption,
        totalConsumption: totalConsumption,
        unit: _getDisplayUnit(_selectedMeterType),
      );
    } catch (e) {
      _monthlyData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getDisplayUnit(MeterType type) {
    return type == MeterType.gas ? 'kWh' : unitForMeterType(type);
  }

  /// Load yearly analytics data for selected meter type + year.
  Future<void> _loadYearlyData() async {
    if (_householdId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final method =
          _settingsProvider.getMethodForMeterType(_selectedMeterType.name);

      // Current year: Jan 1 to Jan 1 of next year
      final yearStart = DateTime(_selectedYear, 1, 1);
      final yearEnd = DateTime(_selectedYear + 1, 1, 1);

      final readingsPerMeter = await _getReadingsPerMeter(
        _selectedMeterType,
        yearStart,
        yearEnd,
      );

      if (readingsPerMeter.isEmpty) {
        _yearlyData = YearlyAnalyticsData(
          meterType: _selectedMeterType,
          year: _selectedYear,
          monthlyBreakdown: [],
          totalConsumption: null,
          unit: _getDisplayUnit(_selectedMeterType),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Monthly consumption for current year (12 bars)
      var monthlyBreakdown = _aggregateMonthlyConsumption(
        readingsPerMeter,
        yearStart,
        yearEnd,
        method,
      );

      // Apply gas conversion if needed
      if (_selectedMeterType == MeterType.gas) {
        monthlyBreakdown = _gasConversionService.toKwhConsumptions(
          monthlyBreakdown,
          factor: _settingsProvider.gasKwhFactor,
        );
      }

      final totalConsumption = monthlyBreakdown.isEmpty
          ? null
          : monthlyBreakdown.fold<double>(
              0, (sum, p) => sum + p.consumption);

      // Previous year data for comparison
      final prevYearStart = DateTime(_selectedYear - 1, 1, 1);
      final prevYearEnd = DateTime(_selectedYear, 1, 1);

      final prevReadingsPerMeter = await _getReadingsPerMeter(
        _selectedMeterType,
        prevYearStart,
        prevYearEnd,
      );

      List<PeriodConsumption>? prevBreakdown;
      double? prevTotal;

      if (prevReadingsPerMeter.isNotEmpty) {
        prevBreakdown = _aggregateMonthlyConsumption(
          prevReadingsPerMeter,
          prevYearStart,
          prevYearEnd,
          method,
        );
        if (_selectedMeterType == MeterType.gas) {
          prevBreakdown = _gasConversionService.toKwhConsumptions(
            prevBreakdown,
            factor: _settingsProvider.gasKwhFactor,
          );
        }
        if (prevBreakdown.isNotEmpty) {
          prevTotal = prevBreakdown.fold<double>(
              0, (sum, p) => sum + p.consumption);
        } else {
          prevBreakdown = null;
        }
      }

      _yearlyData = YearlyAnalyticsData(
        meterType: _selectedMeterType,
        year: _selectedYear,
        monthlyBreakdown: monthlyBreakdown,
        previousYearBreakdown: prevBreakdown,
        totalConsumption: totalConsumption,
        previousYearTotal: prevTotal,
        unit: _getDisplayUnit(_selectedMeterType),
      );
    } catch (e) {
      _yearlyData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get readings for a meter type, returning one list per physical meter.
  Future<List<List<ReadingPoint>>> _getReadingsPerMeter(
    MeterType type,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    if (_householdId == null) return [];

    final List<List<ReadingPoint>> raw;
    switch (type) {
      case MeterType.electricity:
        final readings = await _electricityDao.getReadingsForRange(
            _householdId!, rangeStart, rangeEnd);
        raw = [fromElectricityReadings(readings)];
      case MeterType.gas:
        final readings = await _gasDao.getReadingsForRange(
            _householdId!, rangeStart, rangeEnd);
        raw = [fromGasReadings(readings)];
      case MeterType.water:
        final meters =
            await _waterDao.getMetersForHousehold(_householdId!);
        if (meters.isEmpty) return [];
        final result = <List<ReadingPoint>>[];
        for (final meter in meters) {
          final readings = await _waterDao.getReadingsForRange(
              meter.id, rangeStart, rangeEnd);
          result.add(fromWaterReadings(readings));
        }
        raw = result;
      case MeterType.heating:
        final meters =
            await _heatingDao.getMetersForHousehold(_householdId!);
        if (meters.isEmpty) return [];
        final result = <List<ReadingPoint>>[];
        for (final meter in meters) {
          final readings = await _heatingDao.getReadingsForRange(
              meter.id, rangeStart, rangeEnd);
          result.add(fromHeatingReadings(readings));
        }
        raw = result;
    }
    // Filter out empty reading lists — they produce no interpolation data
    return raw.where((readings) => readings.isNotEmpty).toList();
  }

  /// Aggregate monthly consumption across multiple meters.
  List<PeriodConsumption> _aggregateMonthlyConsumption(
    List<List<ReadingPoint>> readingsPerMeter,
    DateTime rangeStart,
    DateTime rangeEnd,
    InterpolationMethod method,
  ) {
    if (readingsPerMeter.isEmpty) return [];

    final perMeterConsumptions = readingsPerMeter
        .map((readings) => _interpolationService.getMonthlyConsumption(
              readings: readings,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              method: method,
            ))
        .toList();

    if (perMeterConsumptions.length == 1) return perMeterConsumptions.first;

    // Sum consumption across meters for each period
    final base = perMeterConsumptions.first;
    return base.asMap().entries.map((entry) {
      final i = entry.key;
      final basePeriod = entry.value;
      var totalConsumption = basePeriod.consumption;
      var anyInterpolated =
          basePeriod.startInterpolated || basePeriod.endInterpolated;
      for (int m = 1; m < perMeterConsumptions.length; m++) {
        if (i < perMeterConsumptions[m].length) {
          totalConsumption += perMeterConsumptions[m][i].consumption;
          anyInterpolated = anyInterpolated ||
              perMeterConsumptions[m][i].startInterpolated ||
              perMeterConsumptions[m][i].endInterpolated;
        }
      }
      return PeriodConsumption(
        periodStart: basePeriod.periodStart,
        periodEnd: basePeriod.periodEnd,
        startValue: basePeriod.startValue,
        endValue: basePeriod.endValue,
        consumption: totalConsumption,
        startInterpolated: anyInterpolated,
        endInterpolated: anyInterpolated,
      );
    }).toList();
  }

  /// Aggregate daily boundaries across multiple meters.
  List<TimestampedValue> _aggregateDailyBoundaries(
    List<List<ReadingPoint>> readingsPerMeter,
    DateTime rangeStart,
    DateTime rangeEnd,
    InterpolationMethod method,
  ) {
    if (readingsPerMeter.isEmpty) return [];

    final perMeterBoundaries = readingsPerMeter
        .map((readings) => _interpolationService.getMonthlyBoundaries(
              readings: readings,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              method: method,
            ))
        .toList();

    if (perMeterBoundaries.length == 1) return perMeterBoundaries.first;

    final base = perMeterBoundaries.first;
    return base.asMap().entries.map((entry) {
      final i = entry.key;
      final baseVal = entry.value;
      var totalValue = baseVal.value;
      var anyInterpolated = baseVal.isInterpolated;
      for (int m = 1; m < perMeterBoundaries.length; m++) {
        if (i < perMeterBoundaries[m].length) {
          totalValue += perMeterBoundaries[m][i].value;
          anyInterpolated =
              anyInterpolated || perMeterBoundaries[m][i].isInterpolated;
        }
      }
      return TimestampedValue(
        timestamp: baseVal.timestamp,
        value: totalValue,
        isInterpolated: anyInterpolated,
      );
    }).toList();
  }
}
