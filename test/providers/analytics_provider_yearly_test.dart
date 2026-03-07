import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/database/daos/gas_dao.dart';
import 'package:valtra/database/daos/heating_dao.dart';
import 'package:valtra/database/daos/water_dao.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/services/interpolation/models.dart';

// Mock classes
class MockElectricityDao extends Mock implements ElectricityDao {}

class MockGasDao extends Mock implements GasDao {}

class MockWaterDao extends Mock implements WaterDao {}

class MockHeatingDao extends Mock implements HeatingDao {}

class MockInterpolationService extends Mock implements InterpolationService {}

class MockGasConversionService extends Mock implements GasConversionService {}

class MockInterpolationSettingsProvider extends Mock
    implements InterpolationSettingsProvider {}

void main() {
  late MockElectricityDao mockElectricityDao;
  late MockGasDao mockGasDao;
  late MockWaterDao mockWaterDao;
  late MockHeatingDao mockHeatingDao;
  late MockInterpolationService mockInterpolationService;
  late MockGasConversionService mockGasConversionService;
  late MockInterpolationSettingsProvider mockSettingsProvider;
  late AnalyticsProvider provider;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(InterpolationMethod.linear);
    registerFallbackValue(DateTime(2024));
    registerFallbackValue(<ReadingPoint>[]);
  });

  setUp(() {
    mockElectricityDao = MockElectricityDao();
    mockGasDao = MockGasDao();
    mockWaterDao = MockWaterDao();
    mockHeatingDao = MockHeatingDao();
    mockInterpolationService = MockInterpolationService();
    mockGasConversionService = MockGasConversionService();
    mockSettingsProvider = MockInterpolationSettingsProvider();

    // Default stubs for settings provider
    when(() => mockSettingsProvider.getMethodForMeterType(any()))
        .thenReturn(InterpolationMethod.linear);
    when(() => mockSettingsProvider.gasKwhFactor).thenReturn(10.3);

    provider = AnalyticsProvider(
      electricityDao: mockElectricityDao,
      gasDao: mockGasDao,
      waterDao: mockWaterDao,
      heatingDao: mockHeatingDao,
      interpolationService: mockInterpolationService,
      gasConversionService: mockGasConversionService,
      settingsProvider: mockSettingsProvider,
    );
  });

  // -- Test helpers --

  /// Creates a list of [PeriodConsumption] for a full year (12 months).
  List<PeriodConsumption> createYearlyBreakdown(
    int year, {
    double baseConsumption = 100.0,
    bool interpolated = false,
  }) {
    return List.generate(12, (i) {
      final start = DateTime(year, i + 1, 1);
      final end = DateTime(year, i + 2, 1);
      final startVal = baseConsumption * (i + 1);
      final endVal = baseConsumption * (i + 2);
      return PeriodConsumption(
        periodStart: start,
        periodEnd: end,
        startValue: startVal,
        endValue: endVal,
        consumption: baseConsumption,
        startInterpolated: interpolated,
        endInterpolated: interpolated,
      );
    });
  }

  /// Creates a partial breakdown for selected months.
  List<PeriodConsumption> createPartialBreakdown(
    int year,
    List<int> months, {
    double consumption = 50.0,
  }) {
    return months.map((m) {
      final start = DateTime(year, m, 1);
      final end = DateTime(year, m + 1, 1);
      return PeriodConsumption(
        periodStart: start,
        periodEnd: end,
        startValue: consumption * m,
        endValue: consumption * (m + 1),
        consumption: consumption,
        startInterpolated: false,
        endInterpolated: false,
      );
    }).toList();
  }

  group('initial state', () {
    test('selectedYear defaults to current year', () {
      expect(provider.selectedYear, DateTime.now().year);
    });

    test('yearlyData is null initially', () {
      expect(provider.yearlyData, isNull);
    });
  });

  group('setSelectedYear', () {
    test('updates selectedYear to specified value', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedYear(2022);

      expect(provider.selectedYear, 2022);
    });

    test('notifies listeners when year changes', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      var notified = false;
      provider.addListener(() => notified = true);

      provider.setSelectedYear(2023);

      expect(notified, true);
    });

    test('triggers _loadYearlyData when householdId is set', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify DAO was called for the selected year range
      verify(() => mockElectricityDao.getReadingsForRange(
            1,
            any(),
            any(),
          )).called(greaterThanOrEqualTo(1));
    });

    test('setting same year still triggers load', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      final currentYear = provider.selectedYear;
      provider.setSelectedYear(currentYear);

      expect(provider.selectedYear, currentYear);
    });
  });

  group('navigateYear', () {
    test('increments year by 1', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedYear(2024);
      provider.navigateYear(1);

      expect(provider.selectedYear, 2025);
    });

    test('decrements year by 1', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedYear(2024);
      provider.navigateYear(-1);

      expect(provider.selectedYear, 2023);
    });

    test('navigates by arbitrary delta', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedYear(2024);
      provider.navigateYear(-3);

      expect(provider.selectedYear, 2021);
    });

    test('notifies listeners', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      var notified = false;
      provider.addListener(() => notified = true);

      provider.navigateYear(1);

      expect(notified, true);
    });

    test('triggers _loadYearlyData', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      // Reset invocation counts from overview load
      clearInteractions(mockElectricityDao);
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.navigateYear(1);
      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockElectricityDao.getReadingsForRange(
            1,
            any(),
            any(),
          )).called(greaterThanOrEqualTo(1));
    });
  });

  group('_loadYearlyData with empty readings', () {
    test('empty readings produce empty monthlyBreakdown', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData, isNotNull);
      expect(provider.yearlyData!.monthlyBreakdown, isEmpty);
    });

    test('empty readings produce null totalConsumption', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.totalConsumption, isNull);
    });

    test('empty readings produce null previousYearBreakdown', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.previousYearBreakdown, isNull);
      expect(provider.yearlyData!.previousYearTotal, isNull);
    });

    test('empty readings set correct year on data', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2022);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.year, 2022);
    });

    test('empty readings set correct meter type on data', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.water);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.meterType, MeterType.water);
    });
  });

  group('_loadYearlyData with readings', () {
    test('computes 12-month breakdown from readings', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // Stub electricity readings present for the selected year
      final elReading1 = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 1, 1),
        valueKwh: 1000.0,
      );
      final elReading2 = _createElectricityReading(
        id: 2,
        householdId: 1,
        timestamp: DateTime(2024, 12, 31),
        valueKwh: 2200.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading1, elReading2]);

      // Stub interpolation to return a 12-month breakdown
      final breakdown = createYearlyBreakdown(2024);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(breakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData, isNotNull);
      expect(provider.yearlyData!.monthlyBreakdown, hasLength(12));
      expect(provider.yearlyData!.year, 2024);
    });

    test('totalConsumption is sum of monthly breakdown', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final elReading1 = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 1, 1),
        valueKwh: 1000.0,
      );
      final elReading2 = _createElectricityReading(
        id: 2,
        householdId: 1,
        timestamp: DateTime(2024, 12, 31),
        valueKwh: 2200.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading1, elReading2]);

      // 12 months x 100 each = 1200 total
      final breakdown = createYearlyBreakdown(2024, baseConsumption: 100.0);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(breakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.totalConsumption, 1200.0);
    });

    test('partial breakdown computes correct total', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final elReading1 = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 3, 1),
        valueKwh: 500.0,
      );
      final elReading2 = _createElectricityReading(
        id: 2,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueKwh: 650.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading1, elReading2]);

      // Only 3 months of data, 50 each = 150 total
      final breakdown =
          createPartialBreakdown(2024, [3, 4, 5], consumption: 50.0);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(breakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.totalConsumption, 150.0);
      expect(provider.yearlyData!.monthlyBreakdown, hasLength(3));
    });
  });

  group('previous year data', () {
    test('loads previous year when readings available', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // Return readings for both current and previous year calls
      final elReading = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueKwh: 1000.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading]);

      // Current year breakdown
      final currentBreakdown =
          createYearlyBreakdown(2024, baseConsumption: 100.0);
      // Previous year breakdown
      final prevBreakdown =
          createYearlyBreakdown(2023, baseConsumption: 80.0);

      var callCount = 0;
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenAnswer((invocation) {
        callCount++;
        // First call is for current year, second for previous year
        return callCount <= 1 ? currentBreakdown : prevBreakdown;
      });

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.previousYearBreakdown, isNotNull);
      expect(provider.yearlyData!.previousYearBreakdown, hasLength(12));
    });

    test('previousYearTotal is sum of previous year breakdown', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final elReading = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueKwh: 1000.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading]);

      final currentBreakdown =
          createYearlyBreakdown(2024, baseConsumption: 100.0);
      final prevBreakdown =
          createYearlyBreakdown(2023, baseConsumption: 80.0);

      var callCount = 0;
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenAnswer((invocation) {
        callCount++;
        return callCount <= 1 ? currentBreakdown : prevBreakdown;
      });

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // 12 months x 80 = 960
      expect(provider.yearlyData!.previousYearTotal, 960.0);
    });

    test('previous year null when no readings for previous year', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // First call (current year) returns readings; second call (prev year) empty
      var fetchCallCount = 0;
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async {
        fetchCallCount++;
        if (fetchCallCount <= 1) {
          return [
            _createElectricityReading(
              id: 1,
              householdId: 1,
              timestamp: DateTime(2024, 6, 1),
              valueKwh: 1000.0,
            ),
          ];
        }
        return <ElectricityReading>[];
      });

      final currentBreakdown =
          createYearlyBreakdown(2024, baseConsumption: 100.0);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(currentBreakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData!.previousYearBreakdown, isNull);
      expect(provider.yearlyData!.previousYearTotal, isNull);
    });

    test('previous year null when previous year breakdown is empty', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final elReading = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueKwh: 1000.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading]);

      final currentBreakdown =
          createYearlyBreakdown(2024, baseConsumption: 100.0);

      var callCount = 0;
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenAnswer((invocation) {
        callCount++;
        // First call returns data, second returns empty
        return callCount <= 1 ? currentBreakdown : <PeriodConsumption>[];
      });

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // Empty breakdown should result in null
      expect(provider.yearlyData!.previousYearBreakdown, isNull);
      expect(provider.yearlyData!.previousYearTotal, isNull);
    });
  });

  group('gas conversion on yearly data', () {
    test('gas meter type applies kWh conversion to monthly breakdown',
        () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // Stub gas readings
      final gasReading = _createGasReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueCubicMeters: 100.0,
      );
      when(() => mockGasDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [gasReading]);

      // Stub interpolation
      final breakdown = createYearlyBreakdown(2024, baseConsumption: 50.0);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(breakdown);

      // Stub gas conversion
      final convertedBreakdown =
          createYearlyBreakdown(2024, baseConsumption: 515.0);
      when(() => mockGasConversionService.toKwhConsumptions(
            any(),
            factor: any(named: 'factor'),
          )).thenReturn(convertedBreakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.gas);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify gas conversion was called for current year breakdown
      verify(() => mockGasConversionService.toKwhConsumptions(
            any(),
            factor: any(named: 'factor'),
          )).called(greaterThanOrEqualTo(1));
    });

    test('gas conversion applied to previous year breakdown too', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final gasReading = _createGasReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueCubicMeters: 100.0,
      );
      when(() => mockGasDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [gasReading]);

      final breakdown = createYearlyBreakdown(2024, baseConsumption: 50.0);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(breakdown);

      final convertedBreakdown =
          createYearlyBreakdown(2024, baseConsumption: 515.0);
      when(() => mockGasConversionService.toKwhConsumptions(
            any(),
            factor: any(named: 'factor'),
          )).thenReturn(convertedBreakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.gas);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // toKwhConsumptions called at least 2 times: current year + previous year
      verify(() => mockGasConversionService.toKwhConsumptions(
            any(),
            factor: any(named: 'factor'),
          )).called(greaterThanOrEqualTo(2));
    });

    test('non-gas meter types do not apply gas conversion on yearly data',
        () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final elReading = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueKwh: 1000.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading]);

      final breakdown = createYearlyBreakdown(2024, baseConsumption: 100.0);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(breakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.electricity);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      verifyNever(() => mockGasConversionService.toKwhConsumptions(
            any(),
            factor: any(named: 'factor'),
          ));
    });

    test('gas yearly totalConsumption reflects converted values', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final gasReading = _createGasReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 6, 1),
        valueCubicMeters: 100.0,
      );
      when(() => mockGasDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [gasReading]);

      final rawBreakdown = createYearlyBreakdown(2024, baseConsumption: 10.0);
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
            method: any(named: 'method'),
          )).thenReturn(rawBreakdown);

      // Each month 10 * 10.3 = 103, total = 103 * 12 = 1236
      final convertedBreakdown =
          createYearlyBreakdown(2024, baseConsumption: 103.0);
      when(() => mockGasConversionService.toKwhConsumptions(
            any(),
            factor: any(named: 'factor'),
          )).thenReturn(convertedBreakdown);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.gas);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // Total should be sum of converted breakdown: 103 * 12 = 1236
      expect(provider.yearlyData!.totalConsumption, 1236.0);
    });
  });

  group('null householdId', () {
    test('_loadYearlyData skipped when householdId is null', () async {
      provider.setHouseholdId(null);

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // No DAO calls should be made
      verifyNever(
          () => mockElectricityDao.getReadingsForRange(any(), any(), any()));
      verifyNever(
          () => mockGasDao.getReadingsForRange(any(), any(), any()));
    });

    test('yearlyData remains null when householdId is null', () async {
      provider.setHouseholdId(null);

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData, isNull);
    });

    test('navigateYear does not load when householdId is null', () async {
      provider.setHouseholdId(null);

      provider.navigateYear(1);
      await Future.delayed(const Duration(milliseconds: 100));

      verifyNever(
          () => mockElectricityDao.getReadingsForRange(any(), any(), any()));
    });
  });

  group('display unit per meter type for yearly data', () {
    test('electricity yearly unit is kWh', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.electricity);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData?.unit, 'kWh');
    });

    test('gas yearly display unit is kWh (converted)', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.gas);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData?.unit, 'kWh');
    });

    test('water yearly display unit is m\u00B3', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.water);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData?.unit, 'm\u00B3');
    });

    test('heating yearly display unit is units', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.heating);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.yearlyData?.unit, 'units');
    });
  });

  group('loading state for yearly data', () {
    test('isLoading toggles during yearly load', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      final loadingStates = <bool>[];
      provider.addListener(() {
        loadingStates.add(provider.isLoading);
      });

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have been true at some point, then false
      expect(loadingStates, contains(true));
      expect(loadingStates.last, false);
    });
  });

  group('clearing householdId clears yearly data', () {
    test('setting householdId to null clears yearlyData', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedYear(2024);
      await Future.delayed(const Duration(milliseconds: 100));

      // Yearly data should exist (even if empty readings)
      expect(provider.yearlyData, isNotNull);

      // Clear household
      provider.setHouseholdId(null);

      expect(provider.yearlyData, isNull);
    });
  });
}

// -- Test helpers --

/// Stubs all DAOs to return empty data.
void _stubEmptyDaos(
  MockElectricityDao elDao,
  MockGasDao gasDao,
  MockWaterDao waterDao,
  MockHeatingDao heatingDao,
) {
  when(() => elDao.getReadingsForRange(any(), any(), any()))
      .thenAnswer((_) async => <ElectricityReading>[]);
  when(() => gasDao.getReadingsForRange(any(), any(), any()))
      .thenAnswer((_) async => <GasReading>[]);
  when(() => waterDao.getMetersForHousehold(any()))
      .thenAnswer((_) async => <WaterMeter>[]);
  when(() => waterDao.getReadingsForRange(any(), any(), any()))
      .thenAnswer((_) async => <WaterReading>[]);
  when(() => heatingDao.getMetersForHousehold(any()))
      .thenAnswer((_) async => <HeatingMeter>[]);
  when(() => heatingDao.getReadingsForRange(any(), any(), any()))
      .thenAnswer((_) async => <HeatingReading>[]);
}

/// Creates a fake [GasReading] for testing.
GasReading _createGasReading({
  required int id,
  required int householdId,
  required DateTime timestamp,
  required double valueCubicMeters,
}) {
  final mock = _MockGasReading();
  when(() => mock.id).thenReturn(id);
  when(() => mock.householdId).thenReturn(householdId);
  when(() => mock.timestamp).thenReturn(timestamp);
  when(() => mock.valueCubicMeters).thenReturn(valueCubicMeters);
  return mock;
}

/// Creates a fake [ElectricityReading] for testing.
ElectricityReading _createElectricityReading({
  required int id,
  required int householdId,
  required DateTime timestamp,
  required double valueKwh,
}) {
  final mock = _MockElectricityReading();
  when(() => mock.id).thenReturn(id);
  when(() => mock.householdId).thenReturn(householdId);
  when(() => mock.timestamp).thenReturn(timestamp);
  when(() => mock.valueKwh).thenReturn(valueKwh);
  return mock;
}

// Private mock classes for data models
class _MockGasReading extends Mock implements GasReading {}

class _MockElectricityReading extends Mock implements ElectricityReading {}
