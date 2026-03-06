import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/household_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/household_provider.dart';
import 'package:valtra/providers/theme_provider.dart';

import 'test_database.dart';

/// Wraps a widget with all required providers for testing.
Widget wrapWithProviders(
  Widget child, {
  AppDatabase? database,
  ThemeProvider? themeProvider,
  HouseholdProvider? householdProvider,
}) {
  final db = database ?? createTestDatabase();
  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: db),
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider ?? ThemeProvider(),
      ),
      if (householdProvider != null)
        ChangeNotifierProvider<HouseholdProvider>.value(
          value: householdProvider,
        ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Pumps a widget with all required providers.
Future<void> pumpWidgetWithProviders(
  WidgetTester tester,
  Widget child, {
  AppDatabase? database,
  ThemeProvider? themeProvider,
  HouseholdProvider? householdProvider,
}) async {
  await tester.pumpWidget(wrapWithProviders(
    child,
    database: database,
    themeProvider: themeProvider,
    householdProvider: householdProvider,
  ));
}

/// Creates an initialized HouseholdProvider for testing.
///
/// Remember to dispose() after use.
Future<HouseholdProvider> createTestHouseholdProvider(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final provider = HouseholdProvider(HouseholdDao(db));
  await provider.init();
  return provider;
}
