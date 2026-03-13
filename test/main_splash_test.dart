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

    testWidgets(
        'removes splash immediately when provider is already initialized',
        (tester) async {
      final provider = HouseholdProvider(HouseholdDao(db));
      await provider.init();

      // Provider is initialized — this mirrors the production flow where
      // removeSplashWhenReady is called after await householdProvider.init().
      expect(provider.isInitialized, isTrue);

      bool splashRemoved = false;

      removeSplashWhenReady(
        provider,
        removeSplash: () => splashRemoved = true,
      );

      // Build a widget tree so the post-frame callback can fire.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(splashRemoved, isTrue);

      provider.dispose();
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('removes splash even when no households exist', (tester) async {
      final provider = HouseholdProvider(HouseholdDao(db));
      await provider.init();

      bool splashRemoved = false;

      removeSplashWhenReady(
        provider,
        removeSplash: () => splashRemoved = true,
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(splashRemoved, isTrue);
      expect(provider.households, isEmpty);

      provider.dispose();
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
