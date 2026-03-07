import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/database/daos/room_dao.dart';
import 'package:valtra/database/daos/smart_plug_dao.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/providers/smart_plug_analytics_provider.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/services/interpolation/models.dart';

// Mock classes
class MockSmartPlugDao extends Mock implements SmartPlugDao {}

class MockElectricityDao extends Mock implements ElectricityDao {}

class MockRoomDao extends Mock implements RoomDao {}

class MockInterpolationService extends Mock implements InterpolationService {}

class MockInterpolationSettingsProvider extends Mock
    implements InterpolationSettingsProvider {}

// Mock data classes for Drift-generated types
class _MockSmartPlug extends Mock implements SmartPlug {}

class _MockRoom extends Mock implements Room {}

class _MockElectricityReading extends Mock implements ElectricityReading {}

void main() {
  late MockSmartPlugDao mockSmartPlugDao;
  late MockElectricityDao mockElectricityDao;
  late MockRoomDao mockRoomDao;
  late MockInterpolationService mockInterpolationService;
  late MockInterpolationSettingsProvider mockSettingsProvider;
  late SmartPlugAnalyticsProvider provider;

  setUpAll(() {
    registerFallbackValue(InterpolationMethod.linear);
    registerFallbackValue(DateTime(2024));
    registerFallbackValue(<ReadingPoint>[]);
  });

  setUp(() {
    mockSmartPlugDao = MockSmartPlugDao();
    mockElectricityDao = MockElectricityDao();
    mockRoomDao = MockRoomDao();
    mockInterpolationService = MockInterpolationService();
    mockSettingsProvider = MockInterpolationSettingsProvider();

    // Default stubs
    when(() => mockSettingsProvider.getMethodForMeterType(any()))
        .thenReturn(InterpolationMethod.linear);

    provider = SmartPlugAnalyticsProvider(
      smartPlugDao: mockSmartPlugDao,
      electricityDao: mockElectricityDao,
      roomDao: mockRoomDao,
      interpolationService: mockInterpolationService,
      settingsProvider: mockSettingsProvider,
    );
  });

  // -- Helper functions --

  _MockSmartPlug createSmartPlug({
    required int id,
    required int roomId,
    required String name,
  }) {
    final plug = _MockSmartPlug();
    when(() => plug.id).thenReturn(id);
    when(() => plug.roomId).thenReturn(roomId);
    when(() => plug.name).thenReturn(name);
    return plug;
  }

  _MockRoom createRoom({
    required int id,
    required int householdId,
    required String name,
  }) {
    final room = _MockRoom();
    when(() => room.id).thenReturn(id);
    when(() => room.householdId).thenReturn(householdId);
    when(() => room.name).thenReturn(name);
    return room;
  }

  void stubEmptyData() {
    when(() => mockSmartPlugDao.getSmartPlugsForHousehold(any()))
        .thenAnswer((_) async => <SmartPlug>[]);
    when(() => mockRoomDao.getRoomsForHousehold(any()))
        .thenAnswer((_) async => <Room>[]);
    when(() => mockSmartPlugDao.getTotalSmartPlugConsumption(
            any(), any(), any()))
        .thenAnswer((_) async => 0.0);
    when(() => mockElectricityDao.getReadingsForRange(any(), any(), any()))
        .thenAnswer((_) async => <ElectricityReading>[]);
  }

  void stub3PlugsAcross2Rooms() {
    final room1 = createRoom(id: 1, householdId: 1, name: 'Living Room');
    final room2 = createRoom(id: 2, householdId: 1, name: 'Kitchen');

    final plug1 =
        createSmartPlug(id: 10, roomId: 1, name: 'TV');
    final plug2 =
        createSmartPlug(id: 20, roomId: 1, name: 'Lamp');
    final plug3 =
        createSmartPlug(id: 30, roomId: 2, name: 'Fridge');

    when(() => mockSmartPlugDao.getSmartPlugsForHousehold(1))
        .thenAnswer((_) async => [plug1, plug2, plug3]);
    when(() => mockRoomDao.getRoomsForHousehold(1))
        .thenAnswer((_) async => [room1, room2]);

    when(() => mockSmartPlugDao.getTotalConsumptionForPlug(10, any(), any()))
        .thenAnswer((_) async => 10.0);
    when(() => mockSmartPlugDao.getTotalConsumptionForPlug(20, any(), any()))
        .thenAnswer((_) async => 20.0);
    when(() => mockSmartPlugDao.getTotalConsumptionForPlug(30, any(), any()))
        .thenAnswer((_) async => 30.0);

    when(() => mockSmartPlugDao.getTotalConsumptionForRoom(1, any(), any()))
        .thenAnswer((_) async => 30.0);
    when(() => mockSmartPlugDao.getTotalConsumptionForRoom(2, any(), any()))
        .thenAnswer((_) async => 30.0);

    when(() => mockSmartPlugDao.getTotalSmartPlugConsumption(1, any(), any()))
        .thenAnswer((_) async => 60.0);
  }

  void stubElectricityReturning(double totalKwh) {
    final reading1 = _MockElectricityReading();
    when(() => reading1.id).thenReturn(1);
    when(() => reading1.householdId).thenReturn(1);
    when(() => reading1.timestamp).thenReturn(DateTime(2026, 1, 1));
    when(() => reading1.valueKwh).thenReturn(0.0);

    final reading2 = _MockElectricityReading();
    when(() => reading2.id).thenReturn(2);
    when(() => reading2.householdId).thenReturn(1);
    when(() => reading2.timestamp).thenReturn(DateTime(2026, 3, 1));
    when(() => reading2.valueKwh).thenReturn(totalKwh);

    when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
        .thenAnswer((_) async => [reading1, reading2]);

    when(() => mockInterpolationService.getMonthlyConsumption(
          readings: any(named: 'readings'),
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
          method: any(named: 'method'),
        )).thenReturn([
      PeriodConsumption(
        periodStart: DateTime(2026, 2, 1),
        periodEnd: DateTime(2026, 3, 1),
        startValue: 0.0,
        endValue: totalKwh,
        consumption: totalKwh,
        startInterpolated: false,
        endInterpolated: false,
      ),
    ]);
  }

  // -- Tests --

  group('initial state', () {
    test('householdId is null', () {
      expect(provider.householdId, isNull);
    });

    test('data is null', () {
      expect(provider.data, isNull);
    });

    test('isLoading is false', () {
      expect(provider.isLoading, false);
    });

    test('period is monthly', () {
      expect(provider.period, AnalyticsPeriod.monthly);
    });

    test('selectedMonth is first of current month', () {
      final now = DateTime.now();
      expect(provider.selectedMonth, DateTime(now.year, now.month, 1));
    });

    test('selectedYear is current year', () {
      expect(provider.selectedYear, DateTime.now().year);
    });

  });

  group('setHouseholdId', () {
    test('setting null clears data and notifies listeners', () {
      stubEmptyData();
      provider.setHouseholdId(1);

      var notified = false;
      provider.addListener(() => notified = true);

      provider.setHouseholdId(null);

      expect(provider.householdId, isNull);
      expect(provider.data, isNull);
      expect(notified, true);
    });

    test('setting non-null triggers loadData', () async {
      stubEmptyData();

      provider.setHouseholdId(1);

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockSmartPlugDao.getSmartPlugsForHousehold(1)).called(1);
    });
  });

  group('loadData with 3 plugs across 2 rooms', () {
    test('returns correct byPlug list', () async {
      stub3PlugsAcross2Rooms();
      stubElectricityReturning(100.0);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final data = provider.data;
      expect(data, isNotNull);
      expect(data!.byPlug, hasLength(3));
      expect(data.byPlug[0].plugName, 'TV');
      expect(data.byPlug[0].roomName, 'Living Room');
      expect(data.byPlug[0].consumption, 10.0);
      expect(data.byPlug[1].plugName, 'Lamp');
      expect(data.byPlug[1].consumption, 20.0);
      expect(data.byPlug[2].plugName, 'Fridge');
      expect(data.byPlug[2].roomName, 'Kitchen');
      expect(data.byPlug[2].consumption, 30.0);
    });

    test('returns correct byRoom list', () async {
      stub3PlugsAcross2Rooms();
      stubElectricityReturning(100.0);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final data = provider.data;
      expect(data, isNotNull);
      expect(data!.byRoom, hasLength(2));
      expect(data.byRoom[0].roomName, 'Living Room');
      expect(data.byRoom[0].consumption, 30.0);
      expect(data.byRoom[1].roomName, 'Kitchen');
      expect(data.byRoom[1].consumption, 30.0);
    });
  });

  group('Other consumption calculation', () {
    test('totalElectricity=100, totalSmartPlug=75 => otherConsumption=25',
        () async {
      // Set up plugs returning 75 total
      final room1 = createRoom(id: 1, householdId: 1, name: 'Room');
      final plug1 = createSmartPlug(id: 10, roomId: 1, name: 'Plug');
      when(() => mockSmartPlugDao.getSmartPlugsForHousehold(1))
          .thenAnswer((_) async => [plug1]);
      when(() => mockRoomDao.getRoomsForHousehold(1))
          .thenAnswer((_) async => [room1]);
      when(() => mockSmartPlugDao.getTotalConsumptionForPlug(10, any(), any()))
          .thenAnswer((_) async => 75.0);
      when(() => mockSmartPlugDao.getTotalConsumptionForRoom(1, any(), any()))
          .thenAnswer((_) async => 75.0);
      when(() => mockSmartPlugDao.getTotalSmartPlugConsumption(1, any(), any()))
          .thenAnswer((_) async => 75.0);

      stubElectricityReturning(100.0);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final data = provider.data;
      expect(data, isNotNull);
      expect(data!.totalSmartPlug, 75.0);
      expect(data.totalElectricity, 100.0);
      expect(data.otherConsumption, 25.0);
    });

    test('Other clamped to 0 when totalSmartPlug > totalElectricity', () async {
      final room1 = createRoom(id: 1, householdId: 1, name: 'Room');
      final plug1 = createSmartPlug(id: 10, roomId: 1, name: 'Plug');
      when(() => mockSmartPlugDao.getSmartPlugsForHousehold(1))
          .thenAnswer((_) async => [plug1]);
      when(() => mockRoomDao.getRoomsForHousehold(1))
          .thenAnswer((_) async => [room1]);
      when(() => mockSmartPlugDao.getTotalConsumptionForPlug(10, any(), any()))
          .thenAnswer((_) async => 150.0);
      when(() => mockSmartPlugDao.getTotalConsumptionForRoom(1, any(), any()))
          .thenAnswer((_) async => 150.0);
      when(() => mockSmartPlugDao.getTotalSmartPlugConsumption(1, any(), any()))
          .thenAnswer((_) async => 150.0);

      // Total electricity only 100
      stubElectricityReturning(100.0);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final data = provider.data;
      expect(data, isNotNull);
      expect(data!.otherConsumption, 0.0);
    });

    test('Other is null when no electricity readings exist', () async {
      final room1 = createRoom(id: 1, householdId: 1, name: 'Room');
      final plug1 = createSmartPlug(id: 10, roomId: 1, name: 'Plug');
      when(() => mockSmartPlugDao.getSmartPlugsForHousehold(1))
          .thenAnswer((_) async => [plug1]);
      when(() => mockRoomDao.getRoomsForHousehold(1))
          .thenAnswer((_) async => [room1]);
      when(() => mockSmartPlugDao.getTotalConsumptionForPlug(10, any(), any()))
          .thenAnswer((_) async => 50.0);
      when(() => mockSmartPlugDao.getTotalConsumptionForRoom(1, any(), any()))
          .thenAnswer((_) async => 50.0);
      when(() => mockSmartPlugDao.getTotalSmartPlugConsumption(1, any(), any()))
          .thenAnswer((_) async => 50.0);

      // No electricity readings
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => <ElectricityReading>[]);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final data = provider.data;
      expect(data, isNotNull);
      expect(data!.totalElectricity, isNull);
      expect(data.otherConsumption, isNull);
    });
  });

  group('period switching', () {
    test('setPeriod(monthly) + setSelectedMonth changes date range and reloads',
        () async {
      stubEmptyData();

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setPeriod(AnalyticsPeriod.monthly);
      provider.setSelectedMonth(DateTime(2026, 3, 1));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.period, AnalyticsPeriod.monthly);
      expect(provider.selectedMonth, DateTime(2026, 3, 1));
      // Verify loadData was called (by checking DAO calls)
      verify(() => mockSmartPlugDao.getSmartPlugsForHousehold(1))
          .called(greaterThanOrEqualTo(2));
    });

    test('setPeriod(yearly) + setSelectedYear changes date range and reloads',
        () async {
      stubEmptyData();

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setPeriod(AnalyticsPeriod.yearly);
      provider.setSelectedYear(2025);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.period, AnalyticsPeriod.yearly);
      expect(provider.selectedYear, 2025);
      verify(() => mockSmartPlugDao.getSmartPlugsForHousehold(1))
          .called(greaterThanOrEqualTo(2));
    });

  });

  group('month navigation', () {
    test('navigateMonth(1) increments month', () async {
      stubEmptyData();

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMonth(DateTime(2026, 3, 1));
      await Future.delayed(const Duration(milliseconds: 50));

      provider.navigateMonth(1);

      expect(provider.selectedMonth, DateTime(2026, 4, 1));
    });

    test('navigateMonth(-1) decrements month', () async {
      stubEmptyData();

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMonth(DateTime(2026, 3, 1));
      await Future.delayed(const Duration(milliseconds: 50));

      provider.navigateMonth(-1);

      expect(provider.selectedMonth, DateTime(2026, 2, 1));
    });
  });

  group('year navigation', () {
    test('navigateYear(1) increments year', () async {
      stubEmptyData();

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2025);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.navigateYear(1);

      expect(provider.selectedYear, 2026);
    });

    test('navigateYear(-1) decrements year', () async {
      stubEmptyData();

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2026);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.navigateYear(-1);

      expect(provider.selectedYear, 2025);
    });
  });

  group('empty state', () {
    test('no plugs returns empty byPlug and byRoom with totalSmartPlug=0',
        () async {
      stubEmptyData();

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final data = provider.data;
      expect(data, isNotNull);
      expect(data!.byPlug, isEmpty);
      expect(data.byRoom, isEmpty);
      expect(data.totalSmartPlug, 0.0);
    });
  });

  group('loading state', () {
    test('isLoading is true during loadData, false after completion', () async {
      stubEmptyData();

      final loadingStates = <bool>[];
      provider.addListener(() {
        loadingStates.add(provider.isLoading);
      });

      provider.setHouseholdId(1);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(loadingStates, contains(true));
      expect(loadingStates.last, false);
    });
  });

  group('pie chart colors', () {
    test('pie slice colors are assigned from predefined palette in order',
        () async {
      stub3PlugsAcross2Rooms();
      stubElectricityReturning(100.0);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final data = provider.data;
      expect(data, isNotNull);

      // byPlug colors should be first 3 colors from pieChartColors
      expect(data!.byPlug[0].color, pieChartColors[0]);
      expect(data.byPlug[1].color, pieChartColors[1]);
      expect(data.byPlug[2].color, pieChartColors[2]);

      // byRoom colors should be first 2 colors from pieChartColors
      expect(data.byRoom[0].color, pieChartColors[0]);
      expect(data.byRoom[1].color, pieChartColors[1]);
    });
  });
}
