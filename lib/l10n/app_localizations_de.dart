// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Valtra';

  @override
  String get electricity => 'Strom';

  @override
  String get gas => 'Gas';

  @override
  String get water => 'Wasser';

  @override
  String get heating => 'Heizung';

  @override
  String get analysis => 'Analyse';

  @override
  String get settings => 'Einstellungen';

  @override
  String get households => 'Haushalte';

  @override
  String get household => 'Haushalt';

  @override
  String get addReading => 'Ablesung hinzufügen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get date => 'Datum';

  @override
  String get time => 'Uhrzeit';

  @override
  String get value => 'Wert';

  @override
  String get consumption => 'Verbrauch';

  @override
  String get meter => 'Zähler';

  @override
  String get room => 'Raum';

  @override
  String get smartPlug => 'Smarte Steckdose';

  @override
  String get kWh => 'kWh';

  @override
  String get cubicMeters => 'm³';

  @override
  String get noData => 'Keine Daten vorhanden';

  @override
  String get selectHousehold => 'Haushalt auswählen';

  @override
  String get createHousehold => 'Haushalt erstellen';

  @override
  String get householdName => 'Haushaltsname';

  @override
  String get editHousehold => 'Haushalt bearbeiten';

  @override
  String get deleteHousehold => 'Haushalt löschen';

  @override
  String get householdDescription => 'Beschreibung (optional)';

  @override
  String get deleteHouseholdConfirm =>
      'Möchten Sie diesen Haushalt wirklich löschen?';

  @override
  String get noHouseholds =>
      'Noch keine Haushalte. Erstellen Sie einen, um zu beginnen!';

  @override
  String get householdRequired => 'Haushaltsname ist erforderlich';

  @override
  String get householdNameTooLong =>
      'Haushaltsname darf maximal 100 Zeichen lang sein';

  @override
  String get cannotDeleteHousehold => 'Haushalt kann nicht gelöscht werden';

  @override
  String get householdHasRelatedData =>
      'Dieser Haushalt hat zugehörige Zähler oder Ablesungen. Löschen Sie diese zuerst, bevor Sie den Haushalt entfernen.';

  @override
  String get addHousehold => 'Haushalt hinzufügen';
}
