import 'package:drift/drift.dart';

/// Water meter types for distinguishing cold/hot water
enum WaterMeterType { cold, hot, other }

/// Heating meter types: own meter (direct reading) or central meter (shared with ratio)
enum HeatingType { ownMeter, centralMeter }

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

/// Heating meters - multiple per household, assigned to rooms
@DataClassName('HeatingMeter')
class HeatingMeters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  IntColumn get roomId => integer().references(Rooms, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get heatingType =>
      intEnum<HeatingType>().withDefault(const Constant(0))();
  RealColumn get heatingRatio => real().nullable()();
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

/// Smart plug consumption - monthly consumption data per plug
@DataClassName('SmartPlugConsumption')
class SmartPlugConsumptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get smartPlugId => integer().references(SmartPlugs, #id)();
  DateTimeColumn get month => dateTime()();
  RealColumn get valueKwh => real()();
}

/// Meter types that support cost tracking (heating excluded — unit-less)
enum CostMeterType { electricity, gas, water }

/// Cost configuration per meter type per household
@DataClassName('CostConfig')
class CostConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get householdId => integer().references(Households, #id)();
  IntColumn get meterType => intEnum<CostMeterType>()();
  RealColumn get unitPrice => real()();
  RealColumn get standingCharge =>
      real().withDefault(const Constant(0.0))();
  TextColumn get priceTiers => text().nullable()();
  TextColumn get currencySymbol =>
      text().withDefault(const Constant('\u20AC'))();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
