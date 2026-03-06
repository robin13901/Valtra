// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Valtra';

  @override
  String get electricity => 'Electricity';

  @override
  String get gas => 'Gas';

  @override
  String get water => 'Water';

  @override
  String get heating => 'Heating';

  @override
  String get analysis => 'Analysis';

  @override
  String get settings => 'Settings';

  @override
  String get households => 'Households';

  @override
  String get household => 'Household';

  @override
  String get addReading => 'Add Reading';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get value => 'Value';

  @override
  String get consumption => 'Consumption';

  @override
  String get meter => 'Meter';

  @override
  String get room => 'Room';

  @override
  String get smartPlug => 'Smart Plug';

  @override
  String get kWh => 'kWh';

  @override
  String get cubicMeters => 'm³';

  @override
  String get noData => 'No data available';

  @override
  String get selectHousehold => 'Select Household';

  @override
  String get createHousehold => 'Create Household';

  @override
  String get householdName => 'Household Name';

  @override
  String get editHousehold => 'Edit Household';

  @override
  String get deleteHousehold => 'Delete Household';

  @override
  String get householdDescription => 'Description (optional)';

  @override
  String get deleteHouseholdConfirm =>
      'Are you sure you want to delete this household?';

  @override
  String get noHouseholds => 'No households yet. Create one to get started!';

  @override
  String get householdRequired => 'Household name is required';

  @override
  String get householdNameTooLong =>
      'Household name must be 100 characters or less';

  @override
  String get cannotDeleteHousehold => 'Cannot Delete Household';

  @override
  String get householdHasRelatedData =>
      'This household has related meters or readings. Delete them first before removing the household.';

  @override
  String get addHousehold => 'Add Household';

  @override
  String get electricityReading => 'Electricity Reading';

  @override
  String get electricityReadings => 'Electricity Readings';

  @override
  String get addElectricityReading => 'Add Reading';

  @override
  String get editElectricityReading => 'Edit Reading';

  @override
  String get deleteElectricityReading => 'Delete Reading';

  @override
  String get deleteReadingConfirm =>
      'Are you sure you want to delete this reading?';

  @override
  String get noElectricityReadings =>
      'No readings yet. Add your first meter reading!';

  @override
  String get meterValue => 'Meter Value';

  @override
  String get meterValueHint => 'Enter current meter value';

  @override
  String consumptionSince(String value) {
    return '+$value kWh since previous';
  }

  @override
  String get firstReading => 'First reading';

  @override
  String get readingMustBePositive => 'Value must be positive';

  @override
  String readingMustBeGreaterOrEqual(String previousValue) {
    return 'Value must be >= $previousValue kWh';
  }

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get ok => 'OK';

  @override
  String get rooms => 'Rooms';

  @override
  String get addRoom => 'Add Room';

  @override
  String get editRoom => 'Edit Room';

  @override
  String get deleteRoom => 'Delete Room';

  @override
  String get roomName => 'Room Name';

  @override
  String get roomNameHint => 'Enter room name';

  @override
  String get noRooms =>
      'No rooms yet. Create one to organize your smart plugs!';

  @override
  String get roomNameRequired => 'Room name is required';

  @override
  String get roomNameTooLong => 'Room name must be 100 characters or less';

  @override
  String get deleteRoomConfirm => 'Are you sure you want to delete this room?';

  @override
  String roomHasSmartPlugs(int count) {
    return 'This room has $count smart plug(s). They will also be deleted.';
  }

  @override
  String get smartPlugs => 'Smart Plugs';

  @override
  String get addSmartPlug => 'Add Smart Plug';

  @override
  String get editSmartPlug => 'Edit Smart Plug';

  @override
  String get deleteSmartPlug => 'Delete Smart Plug';

  @override
  String get smartPlugName => 'Plug Name';

  @override
  String get smartPlugNameHint => 'Enter smart plug name';

  @override
  String get noSmartPlugs =>
      'No smart plugs yet. Add one to start tracking device consumption!';

  @override
  String get smartPlugNameRequired => 'Plug name is required';

  @override
  String get deleteSmartPlugConfirm =>
      'Are you sure you want to delete this smart plug?';

  @override
  String get selectRoom => 'Select Room';

  @override
  String get roomRequired => 'Please select a room';

  @override
  String get addConsumption => 'Add Consumption';

  @override
  String get editConsumption => 'Edit Consumption';

  @override
  String get deleteConsumption => 'Delete Consumption';

  @override
  String get noConsumption => 'No consumption entries yet.';

  @override
  String get deleteConsumptionConfirm =>
      'Are you sure you want to delete this entry?';

  @override
  String get intervalType => 'Interval Type';

  @override
  String get intervalStart => 'Start Date';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String smartPlugCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count smart plugs',
      one: '1 smart plug',
      zero: 'No smart plugs',
    );
    return '$_temp0';
  }

  @override
  String lastEntry(String value, String interval) {
    return 'Last: $value kWh ($interval)';
  }

  @override
  String get manageRooms => 'Manage Rooms';

  @override
  String get waterMeters => 'Water Meters';

  @override
  String get addWaterMeter => 'Add Water Meter';

  @override
  String get editWaterMeter => 'Edit Water Meter';

  @override
  String get deleteWaterMeter => 'Delete Water Meter';

  @override
  String get waterMeterName => 'Meter Name';

  @override
  String get waterMeterNameHint => 'Enter meter name';

  @override
  String get waterMeterType => 'Meter Type';

  @override
  String get coldWater => 'Cold Water';

  @override
  String get hotWater => 'Hot Water';

  @override
  String get otherWater => 'Other';

  @override
  String get noWaterMeters =>
      'No water meters yet. Add one to start tracking water consumption!';

  @override
  String get waterMeterNameRequired => 'Meter name is required';

  @override
  String get deleteWaterMeterConfirm =>
      'Are you sure you want to delete this water meter?';

  @override
  String waterMeterHasReadings(int count) {
    return 'This meter has $count reading(s). They will also be deleted.';
  }

  @override
  String get waterReading => 'Water Reading';

  @override
  String get waterReadings => 'Water Readings';

  @override
  String get addWaterReading => 'Add Reading';

  @override
  String get editWaterReading => 'Edit Reading';

  @override
  String get deleteWaterReading => 'Delete Reading';

  @override
  String get noWaterReadings =>
      'No readings yet. Add your first meter reading!';

  @override
  String waterConsumptionSince(String value) {
    return '+$value m³ since previous';
  }

  @override
  String waterReadingMustBeGreaterOrEqual(String previousValue) {
    return 'Value must be >= $previousValue m³';
  }
}
