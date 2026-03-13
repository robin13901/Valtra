import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtra/main.dart';
import 'package:valtra/providers/household_provider.dart';
import 'package:valtra/database/daos/household_dao.dart';

import 'helpers/test_database.dart';

void main() {
  group('removeSplashWhenReady', () {
    late dynamic db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('removes splash after provider notifies listeners',
        (tester) async {
      final provider = HouseholdProvider(HouseholdDao(db));
      await provider.init();

      bool splashRemoved = false;

      // Register splash removal BEFORE pumpWidget to mirror the production flow:
      // In main(), removeSplashWhenReady is called before the widget tree builds,
      // so the listener is registered before pumpWidget drains the stream event.
      removeSplashWhenReady(
        provider,
        removeSplash: () => splashRemoved = true,
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // pumpWidget processes the stream event (triggering the listener)
      // and addPostFrameCallback is scheduled; pump() fires the callback.
      await tester.pump();

      expect(splashRemoved, isTrue);

      // Dispose provider and let Drift stream cleanup timers complete
      provider.dispose();
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('removes splash even when no households exist', (tester) async {
      final provider = HouseholdProvider(HouseholdDao(db));
      await provider.init();

      bool splashRemoved = false;

      // Register before pumpWidget to ensure listener is in place
      // before the widget binding drains the stream event.
      removeSplashWhenReady(
        provider,
        removeSplash: () => splashRemoved = true,
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(splashRemoved, isTrue);
      expect(provider.households, isEmpty);

      // Dispose provider and let Drift stream cleanup timers complete
      provider.dispose();
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
