import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/providers/theme_provider.dart';

import 'test_database.dart';

/// Wraps a widget with all required providers for testing.
Widget wrapWithProviders(
  Widget child, {
  AppDatabase? database,
  ThemeProvider? themeProvider,
}) {
  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: database ?? createTestDatabase()),
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider ?? ThemeProvider(),
      ),
    ],
    child: MaterialApp(
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
}) async {
  await tester.pumpWidget(wrapWithProviders(
    child,
    database: database,
    themeProvider: themeProvider,
  ));
}
