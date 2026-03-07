import '../../database/app_database.dart';
import 'models.dart';

/// Converts meter-specific reading types to generic [ReadingPoint].
List<ReadingPoint> fromElectricityReadings(
        List<ElectricityReading> readings) =>
    readings
        .map((r) => (timestamp: r.timestamp, value: r.valueKwh))
        .toList();

/// Converts gas readings to generic [ReadingPoint].
List<ReadingPoint> fromGasReadings(List<GasReading> readings) =>
    readings
        .map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters))
        .toList();

/// Converts water readings to generic [ReadingPoint].
List<ReadingPoint> fromWaterReadings(List<WaterReading> readings) =>
    readings
        .map((r) => (timestamp: r.timestamp, value: r.valueCubicMeters))
        .toList();

/// Converts heating readings to generic [ReadingPoint].
List<ReadingPoint> fromHeatingReadings(List<HeatingReading> readings) =>
    readings
        .map((r) => (timestamp: r.timestamp, value: r.value))
        .toList();
