import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Valtra'**
  String get appTitle;

  /// No description provided for @electricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get electricity;

  /// No description provided for @gas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get gas;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @heating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get heating;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @households.
  ///
  /// In en, this message translates to:
  /// **'Households'**
  String get households;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @addReading.
  ///
  /// In en, this message translates to:
  /// **'Add Reading'**
  String get addReading;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @consumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get consumption;

  /// No description provided for @meter.
  ///
  /// In en, this message translates to:
  /// **'Meter'**
  String get meter;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @smartPlug.
  ///
  /// In en, this message translates to:
  /// **'Smart Plug'**
  String get smartPlug;

  /// No description provided for @kWh.
  ///
  /// In en, this message translates to:
  /// **'kWh'**
  String get kWh;

  /// No description provided for @cubicMeters.
  ///
  /// In en, this message translates to:
  /// **'m³'**
  String get cubicMeters;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @selectHousehold.
  ///
  /// In en, this message translates to:
  /// **'Select Household'**
  String get selectHousehold;

  /// No description provided for @createHousehold.
  ///
  /// In en, this message translates to:
  /// **'Create Household'**
  String get createHousehold;

  /// No description provided for @householdName.
  ///
  /// In en, this message translates to:
  /// **'Household Name'**
  String get householdName;

  /// No description provided for @editHousehold.
  ///
  /// In en, this message translates to:
  /// **'Edit Household'**
  String get editHousehold;

  /// No description provided for @deleteHousehold.
  ///
  /// In en, this message translates to:
  /// **'Delete Household'**
  String get deleteHousehold;

  /// No description provided for @householdDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get householdDescription;

  /// No description provided for @deleteHouseholdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this household?'**
  String get deleteHouseholdConfirm;

  /// No description provided for @noHouseholds.
  ///
  /// In en, this message translates to:
  /// **'No households yet. Create one to get started!'**
  String get noHouseholds;

  /// No description provided for @householdRequired.
  ///
  /// In en, this message translates to:
  /// **'Household name is required'**
  String get householdRequired;

  /// No description provided for @householdNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Household name must be 100 characters or less'**
  String get householdNameTooLong;

  /// No description provided for @cannotDeleteHousehold.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete Household'**
  String get cannotDeleteHousehold;

  /// No description provided for @householdHasRelatedData.
  ///
  /// In en, this message translates to:
  /// **'This household has related meters or readings. Delete them first before removing the household.'**
  String get householdHasRelatedData;

  /// No description provided for @addHousehold.
  ///
  /// In en, this message translates to:
  /// **'Add Household'**
  String get addHousehold;

  /// No description provided for @electricityReading.
  ///
  /// In en, this message translates to:
  /// **'Electricity Reading'**
  String get electricityReading;

  /// No description provided for @electricityReadings.
  ///
  /// In en, this message translates to:
  /// **'Electricity Readings'**
  String get electricityReadings;

  /// No description provided for @addElectricityReading.
  ///
  /// In en, this message translates to:
  /// **'Add Reading'**
  String get addElectricityReading;

  /// No description provided for @editElectricityReading.
  ///
  /// In en, this message translates to:
  /// **'Edit Reading'**
  String get editElectricityReading;

  /// No description provided for @deleteElectricityReading.
  ///
  /// In en, this message translates to:
  /// **'Delete Reading'**
  String get deleteElectricityReading;

  /// No description provided for @deleteReadingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reading?'**
  String get deleteReadingConfirm;

  /// No description provided for @noElectricityReadings.
  ///
  /// In en, this message translates to:
  /// **'No readings yet. Add your first meter reading!'**
  String get noElectricityReadings;

  /// No description provided for @meterValue.
  ///
  /// In en, this message translates to:
  /// **'Meter Value'**
  String get meterValue;

  /// No description provided for @meterValueHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current meter value'**
  String get meterValueHint;

  /// No description provided for @consumptionSince.
  ///
  /// In en, this message translates to:
  /// **'+{value} kWh since previous'**
  String consumptionSince(String value);

  /// No description provided for @firstReading.
  ///
  /// In en, this message translates to:
  /// **'First reading'**
  String get firstReading;

  /// No description provided for @readingMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Value must be positive'**
  String get readingMustBePositive;

  /// No description provided for @readingMustBeGreaterOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Value must be >= {previousValue} kWh'**
  String readingMustBeGreaterOrEqual(String previousValue);

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// No description provided for @editRoom.
  ///
  /// In en, this message translates to:
  /// **'Edit Room'**
  String get editRoom;

  /// No description provided for @deleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete Room'**
  String get deleteRoom;

  /// No description provided for @roomName.
  ///
  /// In en, this message translates to:
  /// **'Room Name'**
  String get roomName;

  /// No description provided for @roomNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter room name'**
  String get roomNameHint;

  /// No description provided for @noRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet. Create one to organize your smart plugs!'**
  String get noRooms;

  /// No description provided for @roomNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Room name is required'**
  String get roomNameRequired;

  /// No description provided for @roomNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Room name must be 100 characters or less'**
  String get roomNameTooLong;

  /// No description provided for @deleteRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this room?'**
  String get deleteRoomConfirm;

  /// No description provided for @roomHasSmartPlugs.
  ///
  /// In en, this message translates to:
  /// **'This room has {count} smart plug(s). They will also be deleted.'**
  String roomHasSmartPlugs(int count);

  /// No description provided for @smartPlugs.
  ///
  /// In en, this message translates to:
  /// **'Smart Plugs'**
  String get smartPlugs;

  /// No description provided for @addSmartPlug.
  ///
  /// In en, this message translates to:
  /// **'Add Smart Plug'**
  String get addSmartPlug;

  /// No description provided for @editSmartPlug.
  ///
  /// In en, this message translates to:
  /// **'Edit Smart Plug'**
  String get editSmartPlug;

  /// No description provided for @deleteSmartPlug.
  ///
  /// In en, this message translates to:
  /// **'Delete Smart Plug'**
  String get deleteSmartPlug;

  /// No description provided for @smartPlugName.
  ///
  /// In en, this message translates to:
  /// **'Plug Name'**
  String get smartPlugName;

  /// No description provided for @smartPlugNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter smart plug name'**
  String get smartPlugNameHint;

  /// No description provided for @noSmartPlugs.
  ///
  /// In en, this message translates to:
  /// **'No smart plugs yet. Add one to start tracking device consumption!'**
  String get noSmartPlugs;

  /// No description provided for @smartPlugNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Plug name is required'**
  String get smartPlugNameRequired;

  /// No description provided for @deleteSmartPlugConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this smart plug?'**
  String get deleteSmartPlugConfirm;

  /// No description provided for @selectRoom.
  ///
  /// In en, this message translates to:
  /// **'Select Room'**
  String get selectRoom;

  /// No description provided for @roomRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a room'**
  String get roomRequired;

  /// No description provided for @addConsumption.
  ///
  /// In en, this message translates to:
  /// **'Add Consumption'**
  String get addConsumption;

  /// No description provided for @editConsumption.
  ///
  /// In en, this message translates to:
  /// **'Edit Consumption'**
  String get editConsumption;

  /// No description provided for @deleteConsumption.
  ///
  /// In en, this message translates to:
  /// **'Delete Consumption'**
  String get deleteConsumption;

  /// No description provided for @noConsumption.
  ///
  /// In en, this message translates to:
  /// **'No consumption entries yet.'**
  String get noConsumption;

  /// No description provided for @deleteConsumptionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get deleteConsumptionConfirm;

  /// No description provided for @intervalType.
  ///
  /// In en, this message translates to:
  /// **'Interval Type'**
  String get intervalType;

  /// No description provided for @intervalStart.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get intervalStart;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @smartPlugCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No smart plugs} =1{1 smart plug} other{{count} smart plugs}}'**
  String smartPlugCount(int count);

  /// No description provided for @lastEntry.
  ///
  /// In en, this message translates to:
  /// **'Last: {value} kWh ({interval})'**
  String lastEntry(String value, String interval);

  /// No description provided for @manageRooms.
  ///
  /// In en, this message translates to:
  /// **'Manage Rooms'**
  String get manageRooms;

  /// No description provided for @waterMeters.
  ///
  /// In en, this message translates to:
  /// **'Water Meters'**
  String get waterMeters;

  /// No description provided for @addWaterMeter.
  ///
  /// In en, this message translates to:
  /// **'Add Water Meter'**
  String get addWaterMeter;

  /// No description provided for @editWaterMeter.
  ///
  /// In en, this message translates to:
  /// **'Edit Water Meter'**
  String get editWaterMeter;

  /// No description provided for @deleteWaterMeter.
  ///
  /// In en, this message translates to:
  /// **'Delete Water Meter'**
  String get deleteWaterMeter;

  /// No description provided for @waterMeterName.
  ///
  /// In en, this message translates to:
  /// **'Meter Name'**
  String get waterMeterName;

  /// No description provided for @waterMeterNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter meter name'**
  String get waterMeterNameHint;

  /// No description provided for @waterMeterType.
  ///
  /// In en, this message translates to:
  /// **'Meter Type'**
  String get waterMeterType;

  /// No description provided for @coldWater.
  ///
  /// In en, this message translates to:
  /// **'Cold Water'**
  String get coldWater;

  /// No description provided for @hotWater.
  ///
  /// In en, this message translates to:
  /// **'Hot Water'**
  String get hotWater;

  /// No description provided for @otherWater.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherWater;

  /// No description provided for @noWaterMeters.
  ///
  /// In en, this message translates to:
  /// **'No water meters yet. Add one to start tracking water consumption!'**
  String get noWaterMeters;

  /// No description provided for @waterMeterNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Meter name is required'**
  String get waterMeterNameRequired;

  /// No description provided for @deleteWaterMeterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this water meter?'**
  String get deleteWaterMeterConfirm;

  /// No description provided for @waterMeterHasReadings.
  ///
  /// In en, this message translates to:
  /// **'This meter has {count} reading(s). They will also be deleted.'**
  String waterMeterHasReadings(int count);

  /// No description provided for @waterReading.
  ///
  /// In en, this message translates to:
  /// **'Water Reading'**
  String get waterReading;

  /// No description provided for @waterReadings.
  ///
  /// In en, this message translates to:
  /// **'Water Readings'**
  String get waterReadings;

  /// No description provided for @addWaterReading.
  ///
  /// In en, this message translates to:
  /// **'Add Reading'**
  String get addWaterReading;

  /// No description provided for @editWaterReading.
  ///
  /// In en, this message translates to:
  /// **'Edit Reading'**
  String get editWaterReading;

  /// No description provided for @deleteWaterReading.
  ///
  /// In en, this message translates to:
  /// **'Delete Reading'**
  String get deleteWaterReading;

  /// No description provided for @noWaterReadings.
  ///
  /// In en, this message translates to:
  /// **'No readings yet. Add your first meter reading!'**
  String get noWaterReadings;

  /// No description provided for @waterConsumptionSince.
  ///
  /// In en, this message translates to:
  /// **'+{value} m³ since previous'**
  String waterConsumptionSince(String value);

  /// No description provided for @waterReadingMustBeGreaterOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Value must be >= {previousValue} m³'**
  String waterReadingMustBeGreaterOrEqual(String previousValue);

  /// No description provided for @gasReading.
  ///
  /// In en, this message translates to:
  /// **'Gas Reading'**
  String get gasReading;

  /// No description provided for @gasReadings.
  ///
  /// In en, this message translates to:
  /// **'Gas Readings'**
  String get gasReadings;

  /// No description provided for @addGasReading.
  ///
  /// In en, this message translates to:
  /// **'Add Reading'**
  String get addGasReading;

  /// No description provided for @editGasReading.
  ///
  /// In en, this message translates to:
  /// **'Edit Reading'**
  String get editGasReading;

  /// No description provided for @deleteGasReading.
  ///
  /// In en, this message translates to:
  /// **'Delete Reading'**
  String get deleteGasReading;

  /// No description provided for @deleteGasReadingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reading?'**
  String get deleteGasReadingConfirm;

  /// No description provided for @noGasReadings.
  ///
  /// In en, this message translates to:
  /// **'No readings yet. Add your first meter reading!'**
  String get noGasReadings;

  /// No description provided for @gasConsumptionSince.
  ///
  /// In en, this message translates to:
  /// **'+{value} m³ since previous'**
  String gasConsumptionSince(String value);

  /// No description provided for @gasReadingMustBeGreaterOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Value must be >= {previousValue} m³'**
  String gasReadingMustBeGreaterOrEqual(String previousValue);

  /// No description provided for @heatingMeters.
  ///
  /// In en, this message translates to:
  /// **'Heating Meters'**
  String get heatingMeters;

  /// No description provided for @addHeatingMeter.
  ///
  /// In en, this message translates to:
  /// **'Add Heating Meter'**
  String get addHeatingMeter;

  /// No description provided for @editHeatingMeter.
  ///
  /// In en, this message translates to:
  /// **'Edit Heating Meter'**
  String get editHeatingMeter;

  /// No description provided for @deleteHeatingMeter.
  ///
  /// In en, this message translates to:
  /// **'Delete Heating Meter'**
  String get deleteHeatingMeter;

  /// No description provided for @heatingMeterName.
  ///
  /// In en, this message translates to:
  /// **'Meter Name'**
  String get heatingMeterName;

  /// No description provided for @heatingMeterNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter meter name'**
  String get heatingMeterNameHint;

  /// No description provided for @heatingMeterLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get heatingMeterLocation;

  /// No description provided for @heatingMeterLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living Room (optional)'**
  String get heatingMeterLocationHint;

  /// No description provided for @noHeatingMeters.
  ///
  /// In en, this message translates to:
  /// **'No heating meters yet. Add one to start tracking heating consumption!'**
  String get noHeatingMeters;

  /// No description provided for @heatingMeterNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Meter name is required'**
  String get heatingMeterNameRequired;

  /// No description provided for @deleteHeatingMeterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this heating meter?'**
  String get deleteHeatingMeterConfirm;

  /// No description provided for @heatingMeterHasReadings.
  ///
  /// In en, this message translates to:
  /// **'This meter has {count} reading(s). They will also be deleted.'**
  String heatingMeterHasReadings(int count);

  /// No description provided for @heatingReading.
  ///
  /// In en, this message translates to:
  /// **'Heating Reading'**
  String get heatingReading;

  /// No description provided for @heatingReadings.
  ///
  /// In en, this message translates to:
  /// **'Heating Readings'**
  String get heatingReadings;

  /// No description provided for @addHeatingReading.
  ///
  /// In en, this message translates to:
  /// **'Add Reading'**
  String get addHeatingReading;

  /// No description provided for @editHeatingReading.
  ///
  /// In en, this message translates to:
  /// **'Edit Reading'**
  String get editHeatingReading;

  /// No description provided for @deleteHeatingReading.
  ///
  /// In en, this message translates to:
  /// **'Delete Reading'**
  String get deleteHeatingReading;

  /// No description provided for @deleteHeatingReadingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reading?'**
  String get deleteHeatingReadingConfirm;

  /// No description provided for @noHeatingReadings.
  ///
  /// In en, this message translates to:
  /// **'No readings yet. Add your first meter reading!'**
  String get noHeatingReadings;

  /// No description provided for @heatingConsumptionSince.
  ///
  /// In en, this message translates to:
  /// **'+{value} units since previous'**
  String heatingConsumptionSince(String value);

  /// No description provided for @heatingReadingMustBeGreaterOrEqual.
  ///
  /// In en, this message translates to:
  /// **'Value must be >= {previousValue}'**
  String heatingReadingMustBeGreaterOrEqual(String previousValue);

  /// No description provided for @interpolation.
  ///
  /// In en, this message translates to:
  /// **'Interpolation'**
  String get interpolation;

  /// No description provided for @interpolationMethod.
  ///
  /// In en, this message translates to:
  /// **'Interpolation Method'**
  String get interpolationMethod;

  /// No description provided for @linear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get linear;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @interpolated.
  ///
  /// In en, this message translates to:
  /// **'Interpolated'**
  String get interpolated;

  /// No description provided for @actual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actual;

  /// No description provided for @gasKwhConversion.
  ///
  /// In en, this message translates to:
  /// **'Gas kWh Conversion'**
  String get gasKwhConversion;

  /// No description provided for @gasConversionFactor.
  ///
  /// In en, this message translates to:
  /// **'Conversion Factor'**
  String get gasConversionFactor;

  /// No description provided for @gasKwhPerCubicMeter.
  ///
  /// In en, this message translates to:
  /// **'{value} kWh/m³'**
  String gasKwhPerCubicMeter(String value);

  /// No description provided for @gasValueKwh.
  ///
  /// In en, this message translates to:
  /// **'{value} kWh'**
  String gasValueKwh(String value);

  /// No description provided for @gasConsumptionKwh.
  ///
  /// In en, this message translates to:
  /// **'+{value} kWh since previous'**
  String gasConsumptionKwh(String value);

  /// No description provided for @defaultGasConversionFactor.
  ///
  /// In en, this message translates to:
  /// **'Default: 10.3 kWh/m³ (German natural gas)'**
  String get defaultGasConversionFactor;

  /// No description provided for @analyticsHub.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsHub;

  /// No description provided for @consumptionOverview.
  ///
  /// In en, this message translates to:
  /// **'Consumption Overview'**
  String get consumptionOverview;

  /// No description provided for @monthlyAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Monthly Analytics'**
  String get monthlyAnalytics;

  /// No description provided for @dailyTrends.
  ///
  /// In en, this message translates to:
  /// **'Daily Trends'**
  String get dailyTrends;

  /// No description provided for @monthlyComparison.
  ///
  /// In en, this message translates to:
  /// **'Monthly Comparison'**
  String get monthlyComparison;

  /// No description provided for @customDateRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get customDateRange;

  /// No description provided for @totalConsumption.
  ///
  /// In en, this message translates to:
  /// **'Total Consumption'**
  String get totalConsumption;

  /// No description provided for @noAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for analytics. Add more readings!'**
  String get noAnalyticsData;

  /// No description provided for @consumptionValue.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String consumptionValue(String value, String unit);

  /// No description provided for @monthlyConsumptionValue.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit} in {month}'**
  String monthlyConsumptionValue(String value, String unit, String month);

  /// No description provided for @analyticsFor.
  ///
  /// In en, this message translates to:
  /// **'Analytics for {meterType}'**
  String analyticsFor(String meterType);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get nextMonth;

  /// No description provided for @recentMonths.
  ///
  /// In en, this message translates to:
  /// **'Recent Months'**
  String get recentMonths;

  /// No description provided for @averageConsumption.
  ///
  /// In en, this message translates to:
  /// **'Average: {value} {unit}'**
  String averageConsumption(String value, String unit);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
