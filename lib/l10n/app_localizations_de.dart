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
  String get selectMonth => 'Monat wählen';

  @override
  String get entryExistsForMonth =>
      'Eintrag für diesen Monat existiert bereits. Er wird aktualisiert.';

  @override
  String consumptionForMonth(String month) {
    return 'Verbrauch für $month';
  }

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

  @override
  String get interpolation => 'Interpolation';

  @override
  String get interpolationMethod => 'Interpolationsmethode';

  @override
  String get linear => 'Linear';

  @override
  String get step => 'Stufenfunktion';

  @override
  String get interpolated => 'Interpoliert';

  @override
  String get actual => 'Tatsächlich';

  @override
  String get gasKwhConversion => 'Gas kWh-Umrechnung';

  @override
  String get gasConversionFactor => 'Umrechnungsfaktor';

  @override
  String gasKwhPerCubicMeter(String value) {
    return '$value kWh/m³';
  }

  @override
  String gasValueKwh(String value) {
    return '$value kWh';
  }

  @override
  String gasConsumptionKwh(String value) {
    return '+$value kWh seit vorheriger Ablesung';
  }

  @override
  String get defaultGasConversionFactor =>
      'Standard: 10,3 kWh/m³ (deutsches Erdgas)';

  @override
  String get analyticsHub => 'Analyse';

  @override
  String get monthlyAnalytics => 'Monatsanalyse';

  @override
  String get totalConsumption => 'Gesamtverbrauch';

  @override
  String get noAnalyticsData =>
      'Nicht genügend Daten für Analysen. Fügen Sie weitere Ablesungen hinzu!';

  @override
  String consumptionValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String monthlyConsumptionValue(String value, String unit, String month) {
    return '$value $unit im $month';
  }

  @override
  String analyticsFor(String meterType) {
    return 'Analyse für $meterType';
  }

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get recentMonths => 'Letzte Monate';

  @override
  String averageConsumption(String value, String unit) {
    return 'Durchschnitt: $value $unit';
  }

  @override
  String get yearlyAnalytics => 'Jahresanalyse';

  @override
  String get monthlyBreakdown => 'Monatsaufschlüsselung';

  @override
  String get yearOverYear => 'Jahresvergleich';

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get currentYear => 'Aktuelles Jahr';

  @override
  String totalForYear(String year) {
    return 'Gesamt für $year';
  }

  @override
  String changeFromLastYear(String change) {
    return '$change% ggü. Vorjahr';
  }

  @override
  String noYearlyData(String year) {
    return 'Keine Daten für $year';
  }

  @override
  String get smartPlugAnalytics => 'Smart-Plug-Analyse';

  @override
  String get consumptionByPlug => 'Verbrauch nach Steckdose';

  @override
  String get consumptionByRoom => 'Verbrauch nach Raum';

  @override
  String get otherConsumption => 'Sonstiger (nicht erfasst)';

  @override
  String get otherConsumptionExplanation =>
      'Differenz zwischen Gesamtstrom und erfasstem Smart-Plug-Verbrauch';

  @override
  String get plugBreakdown => 'Aufschlüsselung nach Steckdose';

  @override
  String get roomBreakdown => 'Aufschlüsselung nach Raum';

  @override
  String get noSmartPlugData =>
      'Keine Smart-Plug-Verbrauchsdaten für diesen Zeitraum.';

  @override
  String get noElectricityData =>
      'Keine Stromablesungen zur Berechnung von \'Sonstiges\'.';

  @override
  String get totalTracked => 'Gesamt erfasst';

  @override
  String get totalElectricity => 'Gesamtstrom';

  @override
  String get periodMonthly => 'Monatlich';

  @override
  String get periodYearly => 'Jährlich';

  @override
  String get appearance => 'Darstellung';

  @override
  String get themeMode => 'Design';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get meterSettings => 'Zählereinstellungen';

  @override
  String get gasKwhConversionFactor => 'Gas kWh-Umrechnungsfaktor';

  @override
  String get gasKwhConversionHint => 'Standard: 10,3 kWh/m³';

  @override
  String get interpolationMethodLabel => 'Interpolationsmethode';

  @override
  String get aboutSection => 'Über';

  @override
  String get appVersion => 'Version';

  @override
  String get settingsUpdated => 'Einstellungen aktualisiert';

  @override
  String get invalidNumber => 'Bitte gültige Zahl eingeben';

  @override
  String get costConfiguration => 'Kosteneinstellungen';

  @override
  String get costTracking => 'Kostenverfolgung';

  @override
  String get unitPrice => 'Arbeitspreis';

  @override
  String get priceTiers => 'Preisstufen';

  @override
  String get tier => 'Stufe';

  @override
  String tierLimit(String limit, String unit) {
    return 'Bis $limit $unit';
  }

  @override
  String get tierUnlimited => 'Rest';

  @override
  String get tierRate => 'Tarif';

  @override
  String get addTier => 'Stufe hinzufügen';

  @override
  String get removeTier => 'Stufe entfernen';

  @override
  String get maxTiersReached => 'Maximal 3 Stufen';

  @override
  String get validFrom => 'Gültig ab';

  @override
  String get currency => 'Währung';

  @override
  String get estimatedCost => 'Geschätzte Kosten';

  @override
  String get monthlyCost => 'Monatliche Kosten';

  @override
  String get yearlyCost => 'Jährliche Kosten';

  @override
  String get totalCost => 'Gesamtkosten';

  @override
  String get noCostConfig => 'Keine Preise konfiguriert';

  @override
  String get addCostConfig => 'Preise konfigurieren';

  @override
  String get editCostConfig => 'Preise bearbeiten';

  @override
  String get deleteCostConfig => 'Preise löschen';

  @override
  String deleteCostConfigConfirm(String meterType) {
    return 'Kosteneinstellung für $meterType löschen?';
  }

  @override
  String get costSummary => 'Kostenübersicht';

  @override
  String costComparison(String change) {
    return '$change% gg. Vorjahr';
  }

  @override
  String get pricePerKwh => '€/kWh';

  @override
  String get pricePerCubicMeter => '€/m³';

  @override
  String get costNotConfigured =>
      'Preise in Haushalt-Einstellungen konfigurieren, um Kosten zu sehen';

  @override
  String get saveCostConfig => 'Speichern';

  @override
  String get costConfigSaved => 'Kosteneinstellung gespeichert';

  @override
  String get costConfigDeleted => 'Kosteneinstellung gelöscht';

  @override
  String get annualBasePrice => 'Grundpreis pro Jahr';

  @override
  String get perYear => 'pro Jahr';

  @override
  String get costProfile => 'Kostenprofil';

  @override
  String get costProfiles => 'Kostenprofile';

  @override
  String get addCostProfile => 'Kostenprofil hinzufügen';

  @override
  String get editCostProfile => 'Kostenprofil bearbeiten';

  @override
  String get noCostProfiles => 'Keine Kostenprofile konfiguriert';

  @override
  String get householdSettings => 'Haushalt-Einstellungen';

  @override
  String get activeProfile => 'Aktiv';

  @override
  String profileValidFrom(String date) {
    return 'Gültig ab $date';
  }

  @override
  String get monthlyProgress => 'Monatsverlauf';

  @override
  String get language => 'Sprache';

  @override
  String get languageDE => 'Deutsch';

  @override
  String get languageEN => 'Englisch';

  @override
  String get home => 'Start';

  @override
  String get interpolatedValue => 'Interpolierter Wert';

  @override
  String get showInterpolatedValues => 'Interpolierte Werte anzeigen';

  @override
  String get hideInterpolatedValues => 'Interpolierte Werte ausblenden';

  @override
  String get heatingType => 'Heizungstyp';

  @override
  String get ownMeter => 'Eigener Zähler';

  @override
  String get centralHeating => 'Zentralheizung';

  @override
  String get heatingRatio => 'Heizanteil (%)';

  @override
  String get heatingRatioHint => 'Anteil an der Gesamtheizenergie';

  @override
  String get heatingRatioRequired => 'Heizanteil ist erforderlich';

  @override
  String get heatingRatioInvalid => 'Muss zwischen 1 und 100 liegen';

  @override
  String previousReading(String value) {
    return 'Vorheriger Wert: $value';
  }

  @override
  String readingTooLow(String value) {
    return 'Muss >= $value sein';
  }

  @override
  String deleteConfirmTitle(String item) {
    return '$item löschen?';
  }

  @override
  String get deleteCannotUndo =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get projected => 'Hochgerechnet';

  @override
  String projectedTotal(String value) {
    return 'Hochgerechnet: $value';
  }

  @override
  String basedOnMonths(int count) {
    return 'Basierend auf $count Monaten';
  }

  @override
  String get backupRestore => 'Sicherung & Wiederherstellung';

  @override
  String get exportDatabase => 'Datenbank exportieren';

  @override
  String get importDatabase => 'Datenbank importieren';

  @override
  String get exportInProgress => 'Datenbank wird exportiert...';

  @override
  String get importInProgress => 'Datenbank wird importiert...';

  @override
  String get backupExportSuccess => 'Datenbank erfolgreich exportiert';

  @override
  String get importSuccess => 'Datenbank erfolgreich importiert. Neustart...';

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get importConfirmTitle => 'Datenbank ersetzen?';

  @override
  String get importConfirmMessage =>
      'Alle aktuellen Daten werden durch die importierte Sicherung ersetzt. Eine Sicherheitskopie wird automatisch erstellt. Fortfahren?';

  @override
  String get invalidBackupFile =>
      'Ungültige Sicherungsdatei. Bitte eine gültige Valtra-Datenbank auswählen.';

  @override
  String get backupCreated => 'Sicherheitskopie erstellt';

  @override
  String get validatingFile => 'Datei wird überprüft...';

  @override
  String get list => 'Liste';

  @override
  String get showCosts => 'Kosten anzeigen';

  @override
  String get showConsumption => 'Verbrauch anzeigen';

  @override
  String get costPerMonth => 'Kosten pro Monat';

  @override
  String get totalConsumptionLabel => 'Gesamtverbrauch';

  @override
  String get trackedByPlugs => 'Davon erfasst';

  @override
  String get notTracked => 'Nicht erfasst';

  @override
  String get consumptionByRoomTitle => 'Verbrauch nach Raum';

  @override
  String get consumptionByPlugTitle => 'Verbrauch nach Steckdose';

  @override
  String consumptionWithPercent(String value, String percent) {
    return '$value kWh ($percent%)';
  }
}
