import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/electricity_dao.dart';
import 'package:valtra/database/daos/gas_dao.dart';
import 'package:valtra/database/daos/heating_dao.dart';
import 'package:valtra/database/daos/water_dao.dart';
import 'package:valtra/database/tables.dart';
import 'package:valtra/providers/analytics_provider.dart';
import 'package:valtra/providers/cost_config_provider.dart';
import 'package:valtra/providers/interpolation_settings_provider.dart';
import 'package:valtra/services/analytics/analytics_models.dart';
import 'package:valtra/services/gas_conversion_service.dart';
import 'package:valtra/services/interpolation/interpolation_service.dart';
import 'package:valtra/services/interpolation/models.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}

class MockElectricityDao extends Mock implements ElectricityDao {}

class MockGasDao extends Mock implements GasDao {}

class MockWaterDao extends Mock implements WaterDao {}

class MockHeatingDao extends Mock implements HeatingDao {}

class MockInterpolationService extends Mock implements InterpolationService {}

class MockGasConversionService extends Mock implements GasConversionService {}

class MockInterpolationSettingsProvider extends Mock
    implements InterpolationSettingsProvider {}

class MockCostConfigProvider extends Mock implements CostConfigProvider {}

void main() {
  late MockElectricityDao mockElectricityDao;
  late MockGasDao mockGasDao;
  late MockWaterDao mockWaterDao;
  late MockHeatingDao mockHeatingDao;
  late MockInterpolationService mockInterpolationService;
  late MockGasConversionService mockGasConversionService;
  late MockInterpolationSettingsProvider mockSettingsProvider;
  late MockCostConfigProvider mockCostConfigProvider;
  late AnalyticsProvider provider;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(InterpolationMethod.linear);
    registerFallbackValue(DateTime(2024));
    registerFallbackValue(<ReadingPoint>[]);
    registerFallbackValue(CostMeterType.electricity);
  });

  setUp(() {
    mockElectricityDao = MockElectricityDao();
    mockGasDao = MockGasDao();
    mockWaterDao = MockWaterDao();
    mockHeatingDao = MockHeatingDao();
    mockInterpolationService = MockInterpolationService();
    mockGasConversionService = MockGasConversionService();
    mockSettingsProvider = MockInterpolationSettingsProvider();
    mockCostConfigProvider = MockCostConfigProvider();

    // Default stubs for settings provider
    when(() => mockSettingsProvider.gasKwhFactor).thenReturn(10.3);

    // Default stubs for cost config provider
    when(() => mockCostConfigProvider.calculateCost(
          meterType: any(named: 'meterType'),
          consumption: any(named: 'consumption'),
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'),
        )).thenReturn(null);
    when(() => mockCostConfigProvider.getActiveConfig(any(), any()))
        .thenReturn(null);

    provider = AnalyticsProvider(
      electricityDao: mockElectricityDao,
      gasDao: mockGasDao,
      waterDao: mockWaterDao,
      heatingDao: mockHeatingDao,
      interpolationService: mockInterpolationService,
      gasConversionService: mockGasConversionService,
      settingsProvider: mockSettingsProvider,
      costConfigProvider: mockCostConfigProvider,
    );
  });

  group('initial state', () {
    test('householdId is null', () {
      expect(provider.householdId, isNull);
    });

    test('selectedMonth is first of current month', () {
      final now = DateTime.now();
      expect(provider.selectedMonth, DateTime(now.year, now.month, 1));
    });

    test('selectedMeterType is electricity', () {
      expect(provider.selectedMeterType, MeterType.electricity);
    });

    test('monthlyData is null', () {
      expect(provider.monthlyData, isNull);
    });

    test('overviewSummaries is empty', () {
      expect(provider.overviewSummaries, isEmpty);
    });

    test('isLoading is false', () {
      expect(provider.isLoading, false);
    });
  });

  group('setHouseholdId', () {
    test('notifies listeners when id changes', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.setHouseholdId(1);

      // At least one notification for the setter
      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('setting null clears overview and monthly data', () {
      provider.setHouseholdId(null);

      expect(provider.householdId, isNull);
      expect(provider.overviewSummaries, isEmpty);
      expect(provider.monthlyData, isNull);
    });

    test('setting non-null triggers overview load', () async {
      // Stub all DAOs to return empty data
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(1);

      // Allow async loading to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify electricity DAO was called (part of overview load)
      verify(() => mockElectricityDao.getReadingsForRange(
            1,
            any(),
            any(),
          )).called(1);
    });

    test('updates householdId getter', () {
      // Stub empty DAOs since setHouseholdId triggers load
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setHouseholdId(42);
      expect(provider.householdId, 42);
    });
  });

  group('setSelectedMonth', () {
    test('updates selectedMonth to first of month', () {
      // Stub empty DAOs
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedMonth(DateTime(2024, 6, 15));

      expect(provider.selectedMonth, DateTime(2024, 6, 1));
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

      provider.setSelectedMonth(DateTime(2024, 6, 1));

      expect(notified, true);
    });
  });

  group('setSelectedMeterType', () {
    test('updates selectedMeterType', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedMeterType(MeterType.gas);

      expect(provider.selectedMeterType, MeterType.gas);
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

      provider.setSelectedMeterType(MeterType.water);

      expect(notified, true);
    });
  });

  group('navigateMonth', () {
    test('increments month by 1', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // Set a known month first
      provider.setSelectedMonth(DateTime(2024, 3, 1));

      provider.navigateMonth(1);

      expect(provider.selectedMonth, DateTime(2024, 4, 1));
    });

    test('decrements month by 1', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedMonth(DateTime(2024, 3, 1));

      provider.navigateMonth(-1);

      expect(provider.selectedMonth, DateTime(2024, 2, 1));
    });

    test('handles year boundary forward', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedMonth(DateTime(2024, 12, 1));

      provider.navigateMonth(1);

      expect(provider.selectedMonth, DateTime(2025, 1, 1));
    });

    test('handles year boundary backward', () {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      provider.setSelectedMonth(DateTime(2024, 1, 1));

      provider.navigateMonth(-1);

      expect(provider.selectedMonth, DateTime(2023, 12, 1));
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

      provider.navigateMonth(1);

      expect(notified, true);
    });
  });

  group('loading state', () {
    test('isLoading toggles during overview load', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      final loadingStates = <bool>[];
      provider.addListener(() {
        loadingStates.add(provider.isLoading);
      });

      provider.setHouseholdId(1);

      // Allow async work to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have been true at some point, then false
      expect(loadingStates, contains(true));
      expect(loadingStates.last, false);
    });
  });

  group('null householdId produces empty data', () {
    test('overview load skipped when household is null', () async {
      provider.setHouseholdId(null);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.overviewSummaries, isEmpty);
      expect(provider.monthlyData, isNull);
      verifyNever(() => mockElectricityDao.getReadingsForRange(
            any(),
            any(),
            any(),
          ));
    });

    test('monthly load skipped when household is null', () async {
      // Ensure householdId is null
      provider.setHouseholdId(null);

      provider.setSelectedMonth(DateTime(2024, 6, 1));

      await Future.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockElectricityDao.getReadingsForRange(
            any(),
            any(),
            any(),
          ));
    });
  });

  group('DAO routing per meter type', () {
    setUp(() {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );
    });

    test('electricity type calls ElectricityDao', () async {
      provider.setHouseholdId(1);
      provider.setSelectedMeterType(MeterType.electricity);

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockElectricityDao.getReadingsForRange(
            1,
            any(),
            any(),
          )).called(greaterThanOrEqualTo(1));
    });

    test('gas type calls GasDao', () async {
      provider.setHouseholdId(1);
      provider.setSelectedMeterType(MeterType.gas);

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockGasDao.getReadingsForRange(
            1,
            any(),
            any(),
          )).called(greaterThanOrEqualTo(1));
    });

    test('water type calls WaterDao for meters then readings', () async {
      final mockMeter = _createWaterMeter(id: 10, householdId: 1);
      when(() => mockWaterDao.getMetersForHousehold(1))
          .thenAnswer((_) async => [mockMeter]);
      when(() => mockWaterDao.getReadingsForRange(10, any(), any()))
          .thenAnswer((_) async => <WaterReading>[]);

      provider.setHouseholdId(1);
      provider.setSelectedMeterType(MeterType.water);

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockWaterDao.getMetersForHousehold(1))
          .called(greaterThanOrEqualTo(1));
      verify(() => mockWaterDao.getReadingsForRange(10, any(), any()))
          .called(greaterThanOrEqualTo(1));
    });

    test('heating type calls HeatingDao for meters then readings', () async {
      final mockMeter = _createHeatingMeter(id: 20, householdId: 1);
      when(() => mockHeatingDao.getMetersForHousehold(1))
          .thenAnswer((_) async => [mockMeter]);
      when(() => mockHeatingDao.getReadingsForRange(20, any(), any()))
          .thenAnswer((_) async => <HeatingReading>[]);

      provider.setHouseholdId(1);
      provider.setSelectedMeterType(MeterType.heating);

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockHeatingDao.getMetersForHousehold(1))
          .called(greaterThanOrEqualTo(1));
      verify(() => mockHeatingDao.getReadingsForRange(20, any(), any()))
          .called(greaterThanOrEqualTo(1));
    });
  });

  group('gas conversion', () {
    test('gas overview summary uses kWh unit', () async {
      // Stub electricity, water, heating empty
      when(() => mockElectricityDao.getReadingsForRange(any(), any(), any()))
          .thenAnswer((_) async => <ElectricityReading>[]);
      when(() => mockWaterDao.getMetersForHousehold(any()))
          .thenAnswer((_) async => <WaterMeter>[]);
      when(() => mockHeatingDao.getMetersForHousehold(any()))
          .thenAnswer((_) async => <HeatingMeter>[]);

      // Stub gas DAO with readings
      final gasReading1 = _createGasReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 1, 1),
        valueCubicMeters: 100.0,
      );
      final gasReading2 = _createGasReading(
        id: 2,
        householdId: 1,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        valueCubicMeters: 200.0,
      );
      when(() => mockGasDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [gasReading1, gasReading2]);

      // Stub interpolation service
      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
          )).thenReturn(<PeriodConsumption>[]);

      // Stub gas conversion
      when(() => mockGasConversionService.toKwh(any(), factor: any(named: 'factor')))
          .thenAnswer((inv) =>
              (inv.positionalArguments[0] as double) *
              (inv.namedArguments[#factor] as double));

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final gasSummary = provider.overviewSummaries[MeterType.gas];
      expect(gasSummary, isNotNull);
      expect(gasSummary!.unit, 'kWh');
    });

    test('gas monthly data applies kWh conversion to daily values', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // Stub gas readings for monthly data load
      final gasReading1 = _createGasReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 5, 1),
        valueCubicMeters: 100.0,
      );
      final gasReading2 = _createGasReading(
        id: 2,
        householdId: 1,
        timestamp: DateTime(2024, 7, 1),
        valueCubicMeters: 200.0,
      );
      when(() => mockGasDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [gasReading1, gasReading2]);

      // Stub interpolation
      when(() => mockInterpolationService.getMonthlyBoundaries(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
          )).thenReturn([
        TimestampedValue(
            timestamp: DateTime(2024, 6, 1),
            value: 10.0,
            isInterpolated: false),
      ]);

      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
          )).thenReturn(<PeriodConsumption>[]);

      when(() => mockGasConversionService.toKwh(any(),
              factor: any(named: 'factor')))
          .thenAnswer((inv) =>
              (inv.positionalArguments[0] as double) *
              (inv.namedArguments[#factor] as double));

      when(() => mockGasConversionService.toKwhConsumptions(any(),
              factor: any(named: 'factor')))
          .thenReturn(<PeriodConsumption>[]);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      // Now set gas meter type to trigger monthly data load
      provider.setSelectedMeterType(MeterType.gas);
      provider.setSelectedMonth(DateTime(2024, 6, 1));
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify gas conversion was called
      verify(() => mockGasConversionService.toKwh(
            any(),
            factor: any(named: 'factor'),
          )).called(greaterThanOrEqualTo(1));
    });

    test('non-gas meter types do not apply gas conversion on daily values',
        () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // Stub electricity readings
      final elReading1 = _createElectricityReading(
        id: 1,
        householdId: 1,
        timestamp: DateTime(2024, 5, 1),
        valueKwh: 100.0,
      );
      final elReading2 = _createElectricityReading(
        id: 2,
        householdId: 1,
        timestamp: DateTime(2024, 7, 1),
        valueKwh: 200.0,
      );
      when(() => mockElectricityDao.getReadingsForRange(1, any(), any()))
          .thenAnswer((_) async => [elReading1, elReading2]);

      when(() => mockInterpolationService.getMonthlyBoundaries(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
          )).thenReturn([
        TimestampedValue(
            timestamp: DateTime(2024, 6, 1),
            value: 150.0,
            isInterpolated: true),
      ]);

      when(() => mockInterpolationService.getMonthlyConsumption(
            readings: any(named: 'readings'),
            rangeStart: any(named: 'rangeStart'),
            rangeEnd: any(named: 'rangeEnd'),
          )).thenReturn(<PeriodConsumption>[]);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.electricity);
      provider.setSelectedMonth(DateTime(2024, 6, 1));
      await Future.delayed(const Duration(milliseconds: 100));

      // Gas conversion should NOT be called for toKwh on daily values
      verifyNever(() => mockGasConversionService.toKwh(
            any(),
            factor: any(named: 'factor'),
          ));

      // The daily value should be the raw value, not converted
      if (provider.monthlyData != null &&
          provider.monthlyData!.dailyValues.isNotEmpty) {
        expect(provider.monthlyData!.dailyValues.first.value, 150.0);
      }
    });
  });

  group('display unit', () {
    test('electricity unit is kWh', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      // Need to set householdId to trigger monthly data load,
      // and have it return empty to get unit from empty data
      when(() => mockElectricityDao.getReadingsForRange(any(), any(), any()))
          .thenAnswer((_) async => <ElectricityReading>[]);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.electricity);
      provider.setSelectedMonth(DateTime(2024, 6, 1));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.monthlyData?.unit, 'kWh');
    });

    test('gas display unit is kWh (converted)', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      when(() => mockGasDao.getReadingsForRange(any(), any(), any()))
          .thenAnswer((_) async => <GasReading>[]);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.gas);
      provider.setSelectedMonth(DateTime(2024, 6, 1));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.monthlyData?.unit, 'kWh');
    });

    test('water display unit is m\u00B3', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      when(() => mockWaterDao.getMetersForHousehold(any()))
          .thenAnswer((_) async => <WaterMeter>[]);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.water);
      provider.setSelectedMonth(DateTime(2024, 6, 1));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.monthlyData?.unit, 'm\u00B3');
    });

    test('heating display unit is units', () async {
      _stubEmptyDaos(
        mockElectricityDao,
        mockGasDao,
        mockWaterDao,
        mockHeatingDao,
      );

      when(() => mockHeatingDao.getMetersForHousehold(any()))
          .thenAnswer((_) async => <HeatingMeter>[]);

      provider.setHouseholdId(1);
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setSelectedMeterType(MeterType.heating);
      provider.setSelectedMonth(DateTime(2024, 6, 1));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.monthlyData?.unit, 'units');
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

/// Creates a fake [WaterMeter] for testing.
WaterMeter _createWaterMeter({
  required int id,
  required int householdId,
}) {
  final mock = _MockWaterMeter();
  when(() => mock.id).thenReturn(id);
  when(() => mock.householdId).thenReturn(householdId);
  when(() => mock.name).thenReturn('Test Water Meter');
  return mock;
}

/// Creates a fake [HeatingMeter] for testing.
HeatingMeter _createHeatingMeter({
  required int id,
  required int householdId,
}) {
  final mock = _MockHeatingMeter();
  when(() => mock.id).thenReturn(id);
  when(() => mock.householdId).thenReturn(householdId);
  when(() => mock.name).thenReturn('Test Heating Meter');
  return mock;
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
class _MockWaterMeter extends Mock implements WaterMeter {}

class _MockHeatingMeter extends Mock implements HeatingMeter {}

class _MockGasReading extends Mock implements GasReading {}

class _MockElectricityReading extends Mock implements ElectricityReading {}
