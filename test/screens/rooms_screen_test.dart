import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/app_theme.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/database/daos/room_dao.dart';
import 'package:valtra/database/daos/smart_plug_dao.dart';
import 'package:valtra/l10n/app_localizations.dart';
import 'package:valtra/providers/room_provider.dart';
import 'package:valtra/providers/theme_provider.dart';
import 'package:valtra/screens/rooms_screen.dart';
import 'package:valtra/widgets/liquid_glass_widgets.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late RoomDao roomDao;
  late RoomProvider provider;
  late ThemeProvider themeProvider;
  late int householdId;

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<RoomProvider>.value(value: provider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = createTestDatabase();
    roomDao = RoomDao(database);
    provider = RoomProvider(roomDao);
    themeProvider = ThemeProvider();
    await themeProvider.init();

    householdId = await database
        .into(database.households)
        .insert(HouseholdsCompanion.insert(name: 'Test Household'));

    provider.setHouseholdId(householdId);
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    provider.dispose();
    await database.close();
  });

  group('RoomsScreen', () {
    testWidgets('displays empty state when no rooms',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const RoomsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.meeting_room_outlined), findsOneWidget);
              expect(
                  find.text('No rooms yet. Create one to organize your smart plugs!'),
                  findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays list of rooms',
        (tester) => tester.runAsync(() async {
              await provider.addRoom('Living Room');
              await provider.addRoom('Kitchen');
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const RoomsScreen()));
              await tester.pumpAndSettle();

              expect(find.text('Living Room'), findsOneWidget);
              expect(find.text('Kitchen'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('FAB opens add room dialog',
        (tester) => tester.runAsync(() async {
              await tester
                  .pumpWidget(wrapWithProviders(const RoomsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(FloatingActionButton));
              await tester.pumpAndSettle();

              expect(find.text('Room Name'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('room card shows room icon',
        (tester) => tester.runAsync(() async {
              await provider.addRoom('Test Room');
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const RoomsScreen()));
              await tester.pumpAndSettle();

              expect(find.byIcon(Icons.meeting_room), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('popup menu shows edit and delete options',
        (tester) => tester.runAsync(() async {
              await provider.addRoom('Room A');
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const RoomsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(PopupMenuButton<String>));
              await tester.pumpAndSettle();

              expect(find.text('Edit'), findsOneWidget);
              expect(find.text('Delete'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping room card opens edit dialog',
        (tester) => tester.runAsync(() async {
              await provider.addRoom('Editable Room');
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const RoomsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(GlassCard));
              await tester.pumpAndSettle();

              // Edit dialog should appear with name pre-filled
              expect(find.text('Editable Room'), findsAtLeastNWidgets(1));

              await tester.pumpWidget(Container());
            }));

    testWidgets('delete confirmation dialog appears',
        (tester) => tester.runAsync(() async {
              await provider.addRoom('Deletable Room');
              await Future.delayed(const Duration(milliseconds: 100));

              await tester
                  .pumpWidget(wrapWithProviders(const RoomsScreen()));
              await tester.pumpAndSettle();

              await tester.tap(find.byType(PopupMenuButton<String>));
              await tester.pumpAndSettle();

              await tester.tap(find.text('Delete'));
              await tester.pumpAndSettle();

              expect(find.text('Delete Room'), findsOneWidget);

              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();

              await tester.pumpWidget(Container());
            }));
  });
}
