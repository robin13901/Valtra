import 'package:drift/drift.dart';

/// Water meter types for distinguishing cold/hot water
enum WaterMeterType { cold, hot, other }

/// Interval types for smart plug consumption aggregation
enum ConsumptionInterval { daily, weekly, monthly, yearly }

/// Households table - top-level entity for grouping meters
@DataClassName('Household')
class Households extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Electricity meter readings - one main meter per household
@DataClassName('ElectricityReading')
class ElectricityReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get valueKwh => real()();
}

/// Gas meter readings - one main meter per household
@DataClassName('GasReading')
class GasReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get valueCubicMeters => real()();
}

/// Water meters - multiple per household (cold, hot, etc.)
@DataClassName('WaterMeter')
class WaterMeters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get type => intEnum<WaterMeterType>()();
}

/// Water meter readings - linked to specific water meter
@DataClassName('WaterReading')
class WaterReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get waterMeterId => integer().references(WaterMeters, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get valueCubicMeters => real()();
}

/// Heating meters - multiple per household (room radiators, etc.)
@DataClassName('HeatingMeter')
class HeatingMeters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get location => text().nullable()();
}

/// Heating meter readings - linked to specific heating meter
@DataClassName('HeatingReading')
class HeatingReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get heatingMeterId => integer().references(HeatingMeters, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get value => real()();
}

/// Rooms - for organizing smart plugs within a household
@DataClassName('Room')
class Rooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
}

/// Smart plugs - electricity monitoring devices within rooms
@DataClassName('SmartPlug')
class SmartPlugs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roomId => integer().references(Rooms, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
}

/// Smart plug consumption - aggregated consumption data
@DataClassName('SmartPlugConsumption')
class SmartPlugConsumptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get smartPlugId => integer().references(SmartPlugs, #id)();
  IntColumn get intervalType => intEnum<ConsumptionInterval>()();
  DateTimeColumn get intervalStart => dateTime()();
  RealColumn get valueKwh => real()();
}
