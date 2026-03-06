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
}
