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
  String get selectMonth => 'Select month';

  @override
  String get entryExistsForMonth =>
      'Entry already exists for this month. It will be updated.';

  @override
  String consumptionForMonth(String month) {
    return 'Consumption for $month';
  }

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

  @override
  String get gasReading => 'Gas Reading';

  @override
  String get gasReadings => 'Gas Readings';

  @override
  String get addGasReading => 'Add Reading';

  @override
  String get editGasReading => 'Edit Reading';

  @override
  String get deleteGasReading => 'Delete Reading';

  @override
  String get deleteGasReadingConfirm =>
      'Are you sure you want to delete this reading?';

  @override
  String get noGasReadings => 'No readings yet. Add your first meter reading!';

  @override
  String gasConsumptionSince(String value) {
    return '+$value m³ since previous';
  }

  @override
  String gasReadingMustBeGreaterOrEqual(String previousValue) {
    return 'Value must be >= $previousValue m³';
  }

  @override
  String get heatingMeters => 'Heating Meters';

  @override
  String get addHeatingMeter => 'Add Heating Meter';

  @override
  String get editHeatingMeter => 'Edit Heating Meter';

  @override
  String get deleteHeatingMeter => 'Delete Heating Meter';

  @override
  String get heatingMeterName => 'Meter Name';

  @override
  String get heatingMeterNameHint => 'Enter meter name';

  @override
  String get noHeatingMeters =>
      'No heating meters yet. Add one to start tracking heating consumption!';

  @override
  String get heatingMeterNameRequired => 'Meter name is required';

  @override
  String get deleteHeatingMeterConfirm =>
      'Are you sure you want to delete this heating meter?';

  @override
  String heatingMeterHasReadings(int count) {
    return 'This meter has $count reading(s). They will also be deleted.';
  }

  @override
  String get heatingReading => 'Heating Reading';

  @override
  String get heatingReadings => 'Heating Readings';

  @override
  String get addHeatingReading => 'Add Reading';

  @override
  String get editHeatingReading => 'Edit Reading';

  @override
  String get deleteHeatingReading => 'Delete Reading';

  @override
  String get deleteHeatingReadingConfirm =>
      'Are you sure you want to delete this reading?';

  @override
  String get noHeatingReadings =>
      'No readings yet. Add your first meter reading!';

  @override
  String heatingConsumptionSince(String value) {
    return '+$value units since previous';
  }

  @override
  String heatingReadingMustBeGreaterOrEqual(String previousValue) {
    return 'Value must be >= $previousValue';
  }

  @override
  String get interpolation => 'Interpolation';

  @override
  String get interpolationMethod => 'Interpolation Method';

  @override
  String get linear => 'Linear';

  @override
  String get step => 'Step';

  @override
  String get interpolated => 'Interpolated';

  @override
  String get actual => 'Actual';

  @override
  String get gasKwhConversion => 'Gas kWh Conversion';

  @override
  String get gasConversionFactor => 'Conversion Factor';

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
    return '+$value kWh since previous';
  }

  @override
  String get defaultGasConversionFactor =>
      'Default: 10.3 kWh/m³ (German natural gas)';

  @override
  String get analyticsHub => 'Analytics';

  @override
  String get consumptionOverview => 'Consumption Overview';

  @override
  String get monthlyAnalytics => 'Monthly Analytics';

  @override
  String get totalConsumption => 'Total Consumption';

  @override
  String get noAnalyticsData =>
      'Not enough data for analytics. Add more readings!';

  @override
  String consumptionValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String monthlyConsumptionValue(String value, String unit, String month) {
    return '$value $unit in $month';
  }

  @override
  String analyticsFor(String meterType) {
    return 'Analytics for $meterType';
  }

  @override
  String get previousMonth => 'Previous Month';

  @override
  String get nextMonth => 'Next Month';

  @override
  String get recentMonths => 'Recent Months';

  @override
  String averageConsumption(String value, String unit) {
    return 'Average: $value $unit';
  }

  @override
  String get yearlyAnalytics => 'Yearly Analytics';

  @override
  String get monthlyBreakdown => 'Monthly Breakdown';

  @override
  String get yearOverYear => 'Year-over-Year';

  @override
  String get previousYear => 'Previous Year';

  @override
  String get nextYear => 'Next Year';

  @override
  String get currentYear => 'Current Year';

  @override
  String totalForYear(String year) {
    return 'Total for $year';
  }

  @override
  String changeFromLastYear(String change) {
    return '$change% vs last year';
  }

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportAll => 'Export All Meters';

  @override
  String get exportSuccess => 'Export ready to share';

  @override
  String noYearlyData(String year) {
    return 'No data for $year';
  }

  @override
  String get smartPlugAnalytics => 'Smart Plug Analytics';

  @override
  String get consumptionByPlug => 'Consumption by Plug';

  @override
  String get consumptionByRoom => 'Consumption by Room';

  @override
  String get otherConsumption => 'Other (Untracked)';

  @override
  String get otherConsumptionExplanation =>
      'Difference between total electricity and tracked smart plug consumption';

  @override
  String get plugBreakdown => 'Plug Breakdown';

  @override
  String get roomBreakdown => 'Room Breakdown';

  @override
  String get noSmartPlugData =>
      'No smart plug consumption data for this period.';

  @override
  String get noElectricityData =>
      'No electricity readings to calculate \'Other\'.';

  @override
  String get totalTracked => 'Total Tracked';

  @override
  String get totalElectricity => 'Total Electricity';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodYearly => 'Yearly';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get meterSettings => 'Meter Settings';

  @override
  String get gasKwhConversionFactor => 'Gas kWh Conversion Factor';

  @override
  String get gasKwhConversionHint => 'Default: 10.3 kWh/m³';

  @override
  String get interpolationMethodLabel => 'Interpolation Method';

  @override
  String get aboutSection => 'About';

  @override
  String get appVersion => 'Version';

  @override
  String get settingsUpdated => 'Settings updated';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String get costConfiguration => 'Cost Configuration';

  @override
  String get costTracking => 'Cost Tracking';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get standingCharge => 'Standing Charge';

  @override
  String get standingChargePerMonth => 'Standing Charge (per month)';

  @override
  String get priceTiers => 'Price Tiers';

  @override
  String get tier => 'Tier';

  @override
  String tierLimit(String limit, String unit) {
    return 'Up to $limit $unit';
  }

  @override
  String get tierUnlimited => 'Remaining';

  @override
  String get tierRate => 'Rate';

  @override
  String get addTier => 'Add Tier';

  @override
  String get removeTier => 'Remove Tier';

  @override
  String get maxTiersReached => 'Maximum 3 tiers';

  @override
  String get validFrom => 'Valid From';

  @override
  String get currency => 'Currency';

  @override
  String get estimatedCost => 'Estimated Cost';

  @override
  String get monthlyCost => 'Monthly Cost';

  @override
  String get yearlyCost => 'Yearly Cost';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get noCostConfig => 'No pricing configured';

  @override
  String get addCostConfig => 'Configure Pricing';

  @override
  String get editCostConfig => 'Edit Pricing';

  @override
  String get deleteCostConfig => 'Delete Pricing';

  @override
  String deleteCostConfigConfirm(String meterType) {
    return 'Delete cost configuration for $meterType?';
  }

  @override
  String get costSummary => 'Cost Summary';

  @override
  String costComparison(String change) {
    return '$change% vs last year';
  }

  @override
  String get pricePerKwh => '€/kWh';

  @override
  String get pricePerCubicMeter => '€/m³';

  @override
  String get costNotConfigured => 'Configure pricing in Settings to see costs';

  @override
  String get saveCostConfig => 'Save';

  @override
  String get costConfigSaved => 'Cost configuration saved';

  @override
  String get costConfigDeleted => 'Cost configuration deleted';

  @override
  String get perMonth => 'per month';

  @override
  String get monthlyProgress => 'Monthly Progress';

  @override
  String get language => 'Language';

  @override
  String get languageDE => 'German';

  @override
  String get languageEN => 'English';

  @override
  String get home => 'Home';

  @override
  String get interpolatedValue => 'Interpolated value';

  @override
  String get showInterpolatedValues => 'Show interpolated values';

  @override
  String get hideInterpolatedValues => 'Hide interpolated values';

  @override
  String get heatingType => 'Heating type';

  @override
  String get ownMeter => 'Own meter';

  @override
  String get centralHeating => 'Central heating';

  @override
  String get heatingRatio => 'Heating ratio (%)';

  @override
  String get heatingRatioHint => 'Share of total heating energy';

  @override
  String get heatingRatioRequired => 'Heating ratio is required';

  @override
  String get heatingRatioInvalid => 'Must be between 1 and 100';

  @override
  String get saveAndNext => 'Save & next';

  @override
  String previousReading(String value) {
    return 'Previous: $value';
  }

  @override
  String readingTooLow(String value) {
    return 'Must be >= $value';
  }

  @override
  String addReadingCount(String count) {
    return 'Add reading ($count)';
  }

  @override
  String deleteConfirmTitle(String item) {
    return 'Delete $item?';
  }

  @override
  String get deleteCannotUndo => 'This action cannot be undone.';

  @override
  String get saved => 'Saved';

  @override
  String get projected => 'Projected';

  @override
  String projectedTotal(String value) {
    return 'Projected total: $value';
  }

  @override
  String basedOnMonths(int count) {
    return 'Based on $count months';
  }

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get exportDatabase => 'Export Database';

  @override
  String get importDatabase => 'Import Database';

  @override
  String get exportInProgress => 'Exporting database...';

  @override
  String get importInProgress => 'Importing database...';

  @override
  String get backupExportSuccess => 'Database exported successfully';

  @override
  String get importSuccess => 'Database imported successfully. Restarting...';

  @override
  String get importFailed => 'Import failed';

  @override
  String get importConfirmTitle => 'Replace Database?';

  @override
  String get importConfirmMessage =>
      'This will replace all current data with the imported backup. A safety backup will be created automatically. Continue?';

  @override
  String get invalidBackupFile =>
      'Invalid backup file. Please select a valid Valtra database.';

  @override
  String get backupCreated => 'Safety backup created';

  @override
  String get validatingFile => 'Validating file...';
}
