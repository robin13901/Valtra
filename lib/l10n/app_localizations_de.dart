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

  @override
  String get electricityReading => 'Stromablesung';

  @override
  String get electricityReadings => 'Stromablesungen';

  @override
  String get addElectricityReading => 'Ablesung hinzufügen';

  @override
  String get editElectricityReading => 'Ablesung bearbeiten';

  @override
  String get deleteElectricityReading => 'Ablesung löschen';

  @override
  String get deleteReadingConfirm =>
      'Möchten Sie diese Ablesung wirklich löschen?';

  @override
  String get noElectricityReadings =>
      'Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!';

  @override
  String get meterValue => 'Zählerstand';

  @override
  String get meterValueHint => 'Aktuellen Zählerstand eingeben';

  @override
  String consumptionSince(String value) {
    return '+$value kWh seit letzter Ablesung';
  }

  @override
  String get firstReading => 'Erste Ablesung';

  @override
  String get readingMustBePositive => 'Der Wert muss positiv sein';

  @override
  String readingMustBeGreaterOrEqual(String previousValue) {
    return 'Der Wert muss >= $previousValue kWh sein';
  }

  @override
  String get dateAndTime => 'Datum & Uhrzeit';

  @override
  String get ok => 'OK';

  @override
  String get rooms => 'Räume';

  @override
  String get addRoom => 'Raum hinzufügen';

  @override
  String get editRoom => 'Raum bearbeiten';

  @override
  String get deleteRoom => 'Raum löschen';

  @override
  String get roomName => 'Raumname';

  @override
  String get roomNameHint => 'Raumnamen eingeben';

  @override
  String get noRooms =>
      'Noch keine Räume. Erstellen Sie einen, um Ihre Smart Plugs zu organisieren!';

  @override
  String get roomNameRequired => 'Raumname ist erforderlich';

  @override
  String get roomNameTooLong => 'Raumname darf maximal 100 Zeichen lang sein';

  @override
  String get deleteRoomConfirm => 'Möchten Sie diesen Raum wirklich löschen?';

  @override
  String roomHasSmartPlugs(int count) {
    return 'Dieser Raum hat $count Smart Plug(s). Diese werden ebenfalls gelöscht.';
  }

  @override
  String get smartPlugs => 'Smart Plugs';

  @override
  String get addSmartPlug => 'Smart Plug hinzufügen';

  @override
  String get editSmartPlug => 'Smart Plug bearbeiten';

  @override
  String get deleteSmartPlug => 'Smart Plug löschen';

  @override
  String get smartPlugName => 'Plug-Name';

  @override
  String get smartPlugNameHint => 'Smart Plug Namen eingeben';

  @override
  String get noSmartPlugs =>
      'Noch keine Smart Plugs. Fügen Sie einen hinzu, um den Geräteverbrauch zu verfolgen!';

  @override
  String get smartPlugNameRequired => 'Plug-Name ist erforderlich';

  @override
  String get deleteSmartPlugConfirm =>
      'Möchten Sie diesen Smart Plug wirklich löschen?';

  @override
  String get selectRoom => 'Raum auswählen';

  @override
  String get roomRequired => 'Bitte wählen Sie einen Raum';

  @override
  String get addConsumption => 'Verbrauch hinzufügen';

  @override
  String get editConsumption => 'Verbrauch bearbeiten';

  @override
  String get deleteConsumption => 'Verbrauch löschen';

  @override
  String get noConsumption => 'Noch keine Verbrauchseinträge.';

  @override
  String get deleteConsumptionConfirm =>
      'Möchten Sie diesen Eintrag wirklich löschen?';

  @override
  String get intervalType => 'Intervalltyp';

  @override
  String get intervalStart => 'Startdatum';

  @override
  String get daily => 'Täglich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get yearly => 'Jährlich';

  @override
  String smartPlugCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Smart Plugs',
      one: '1 Smart Plug',
      zero: 'Keine Smart Plugs',
    );
    return '$_temp0';
  }

  @override
  String lastEntry(String value, String interval) {
    return 'Zuletzt: $value kWh ($interval)';
  }

  @override
  String get manageRooms => 'Räume verwalten';

  @override
  String get waterMeters => 'Wasserzähler';

  @override
  String get addWaterMeter => 'Wasserzähler hinzufügen';

  @override
  String get editWaterMeter => 'Wasserzähler bearbeiten';

  @override
  String get deleteWaterMeter => 'Wasserzähler löschen';

  @override
  String get waterMeterName => 'Zählername';

  @override
  String get waterMeterNameHint => 'Zählernamen eingeben';

  @override
  String get waterMeterType => 'Zählertyp';

  @override
  String get coldWater => 'Kaltwasser';

  @override
  String get hotWater => 'Warmwasser';

  @override
  String get otherWater => 'Sonstiges';

  @override
  String get noWaterMeters =>
      'Noch keine Wasserzähler. Fügen Sie einen hinzu, um den Wasserverbrauch zu verfolgen!';

  @override
  String get waterMeterNameRequired => 'Zählername ist erforderlich';

  @override
  String get deleteWaterMeterConfirm =>
      'Möchten Sie diesen Wasserzähler wirklich löschen?';

  @override
  String waterMeterHasReadings(int count) {
    return 'Dieser Zähler hat $count Ablesung(en). Diese werden ebenfalls gelöscht.';
  }

  @override
  String get waterReading => 'Wasserablesung';

  @override
  String get waterReadings => 'Wasserablesungen';

  @override
  String get addWaterReading => 'Ablesung hinzufügen';

  @override
  String get editWaterReading => 'Ablesung bearbeiten';

  @override
  String get deleteWaterReading => 'Ablesung löschen';

  @override
  String get noWaterReadings =>
      'Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!';

  @override
  String waterConsumptionSince(String value) {
    return '+$value m³ seit letzter Ablesung';
  }

  @override
  String waterReadingMustBeGreaterOrEqual(String previousValue) {
    return 'Der Wert muss >= $previousValue m³ sein';
  }

  @override
  String get gasReading => 'Gasablesung';

  @override
  String get gasReadings => 'Gasablesungen';

  @override
  String get addGasReading => 'Ablesung hinzufügen';

  @override
  String get editGasReading => 'Ablesung bearbeiten';

  @override
  String get deleteGasReading => 'Ablesung löschen';

  @override
  String get deleteGasReadingConfirm =>
      'Möchten Sie diese Ablesung wirklich löschen?';

  @override
  String get noGasReadings =>
      'Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!';

  @override
  String gasConsumptionSince(String value) {
    return '+$value m³ seit letzter Ablesung';
  }

  @override
  String gasReadingMustBeGreaterOrEqual(String previousValue) {
    return 'Der Wert muss >= $previousValue m³ sein';
  }

  @override
  String get heatingMeters => 'Heizungszähler';

  @override
  String get addHeatingMeter => 'Heizungszähler hinzufügen';

  @override
  String get editHeatingMeter => 'Heizungszähler bearbeiten';

  @override
  String get deleteHeatingMeter => 'Heizungszähler löschen';

  @override
  String get heatingMeterName => 'Zählername';

  @override
  String get heatingMeterNameHint => 'Zählernamen eingeben';

  @override
  String get heatingMeterLocation => 'Standort';

  @override
  String get heatingMeterLocationHint => 'z.B. Wohnzimmer (optional)';

  @override
  String get noHeatingMeters =>
      'Noch keine Heizungszähler. Fügen Sie einen hinzu, um den Heizverbrauch zu verfolgen!';

  @override
  String get heatingMeterNameRequired => 'Zählername ist erforderlich';

  @override
  String get deleteHeatingMeterConfirm =>
      'Möchten Sie diesen Heizungszähler wirklich löschen?';

  @override
  String heatingMeterHasReadings(int count) {
    return 'Dieser Zähler hat $count Ablesung(en). Diese werden ebenfalls gelöscht.';
  }

  @override
  String get heatingReading => 'Heizungsablesung';

  @override
  String get heatingReadings => 'Heizungsablesungen';

  @override
  String get addHeatingReading => 'Ablesung hinzufügen';

  @override
  String get editHeatingReading => 'Ablesung bearbeiten';

  @override
  String get deleteHeatingReading => 'Ablesung löschen';

  @override
  String get deleteHeatingReadingConfirm =>
      'Möchten Sie diese Ablesung wirklich löschen?';

  @override
  String get noHeatingReadings =>
      'Noch keine Ablesungen. Fügen Sie Ihre erste Zählerablesung hinzu!';

  @override
  String heatingConsumptionSince(String value) {
    return '+$value Einheiten seit letzter Ablesung';
  }

  @override
  String heatingReadingMustBeGreaterOrEqual(String previousValue) {
    return 'Der Wert muss >= $previousValue sein';
  }
}
