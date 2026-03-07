import 'dart:math';

import 'package:flutter/material.dart';

import '../database/daos/electricity_dao.dart';
import '../database/daos/room_dao.dart';
import '../database/daos/smart_plug_dao.dart';
import '../providers/interpolation_settings_provider.dart';
import '../services/analytics/analytics_models.dart';
import '../services/interpolation/interpolation_service.dart';
import '../services/interpolation/reading_converters.dart';

/// Orchestrates data for smart plug analytics.
///
/// Combines SmartPlugDao, ElectricityDao, and InterpolationService to produce
/// chart-ready data (per-plug, per-room, Other consumption) for the
/// smart plug analytics screen.
class SmartPlugAnalyticsProvider extends ChangeNotifier {
  final SmartPlugDao _smartPlugDao;
  final ElectricityDao _electricityDao;
  final RoomDao _roomDao;
  final InterpolationService _interpolationService;
  final InterpolationSettingsProvider _settingsProvider;

  int? _householdId;
  SmartPlugAnalyticsData? _data;
  bool _isLoading = false;
  AnalyticsPeriod _period = AnalyticsPeriod.monthly;
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _selectedYear = DateTime.now().year;
  DateTimeRange? _customRange;

  SmartPlugAnalyticsProvider({
    required SmartPlugDao smartPlugDao,
    required ElectricityDao electricityDao,
    required RoomDao roomDao,
    required InterpolationService interpolationService,
    required InterpolationSettingsProvider settingsProvider,
  })  : _smartPlugDao = smartPlugDao,
        _electricityDao = electricityDao,
        _roomDao = roomDao,
        _interpolationService = interpolationService,
        _settingsProvider = settingsProvider;

  // Getters
  int? get householdId => _householdId;
  SmartPlugAnalyticsData? get data => _data;
  bool get isLoading => _isLoading;
  AnalyticsPeriod get period => _period;
  DateTime get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  DateTimeRange? get customRange => _customRange;

  void setHouseholdId(int? id) {
    _householdId = id;
    if (id == null) {
      _data = null;
      notifyListeners();
    } else {
      notifyListeners();
      loadData();
    }
  }

  void setPeriod(AnalyticsPeriod period) {
    _period = period;
    notifyListeners();
    loadData();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _customRange = null;
    notifyListeners();
    loadData();
  }

  void navigateMonth(int delta) {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    _customRange = null;
    notifyListeners();
    loadData();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
    loadData();
  }

  void navigateYear(int delta) {
    _selectedYear += delta;
    notifyListeners();
    loadData();
  }

  void setCustomRange(DateTimeRange? range) {
    _customRange = range;
    notifyListeners();
    loadData();
  }

  /// Loads all smart plug analytics data for the current household and period.
  Future<void> loadData() async {
    if (_householdId == null) return;
    final householdId = _householdId!;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Compute date range from period
      final DateTime from;
      final DateTime to;
      switch (_period) {
        case AnalyticsPeriod.monthly:
          from = _selectedMonth;
          to = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
        case AnalyticsPeriod.yearly:
          from = DateTime(_selectedYear, 1, 1);
          to = DateTime(_selectedYear + 1, 1, 1);
        case AnalyticsPeriod.custom:
          if (_customRange == null) {
            _isLoading = false;
            notifyListeners();
            return;
          }
          from = _customRange!.start;
          to = _customRange!.end;
      }

      // 2. Get all plugs and rooms for household
      final plugs =
          await _smartPlugDao.getSmartPlugsForHousehold(householdId);
      final rooms = await _roomDao.getRoomsForHousehold(householdId);

      // 3. Build room lookup map
      final roomMap = <int, dynamic>{};
      for (final room in rooms) {
        roomMap[room.id] = room;
      }

      // 4. Build per-plug breakdown
      final byPlug = <PlugConsumption>[];
      for (int i = 0; i < plugs.length; i++) {
        final plug = plugs[i];
        final consumption = await _smartPlugDao.getTotalConsumptionForPlug(
            plug.id, from, to);
        final room = roomMap[plug.roomId];
        byPlug.add(PlugConsumption(
          plugId: plug.id,
          plugName: plug.name,
          roomName: room?.name ?? 'Unknown',
          consumption: consumption,
          color: pieChartColors[i % pieChartColors.length],
        ));
      }

      // 5. Build per-room breakdown
      final byRoom = <RoomConsumption>[];
      for (int i = 0; i < rooms.length; i++) {
        final room = rooms[i];
        final consumption = await _smartPlugDao.getTotalConsumptionForRoom(
            room.id, from, to);
        byRoom.add(RoomConsumption(
          roomId: room.id,
          roomName: room.name,
          consumption: consumption,
          color: pieChartColors[i % pieChartColors.length],
        ));
      }

      // 6. Get total smart plug consumption
      final totalSmartPlug = await _smartPlugDao
          .getTotalSmartPlugConsumption(householdId, from, to);

      // 7. Calculate total electricity via interpolation
      double? totalElectricity;
      final electricityReadings = await _electricityDao.getReadingsForRange(
          householdId, from, to);
      if (electricityReadings.isNotEmpty) {
        final readingPoints = fromElectricityReadings(electricityReadings);
        final method =
            _settingsProvider.getMethodForMeterType('electricity');
        final monthly = _interpolationService.getMonthlyConsumption(
          readings: readingPoints,
          rangeStart: from,
          rangeEnd: to,
          method: method,
        );
        totalElectricity =
            monthly.fold<double>(0, (sum, p) => sum + p.consumption);
      }

      // 8. Calculate Other consumption
      final double? otherConsumption;
      if (totalElectricity != null) {
        otherConsumption =
            max(0.0, totalElectricity - totalSmartPlug);
      } else {
        otherConsumption = null;
      }

      // 9. Build data package
      _data = SmartPlugAnalyticsData(
        byPlug: byPlug,
        byRoom: byRoom,
        totalSmartPlug: totalSmartPlug,
        totalElectricity: totalElectricity,
        otherConsumption: otherConsumption,
      );
    } catch (e) {
      _data = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
