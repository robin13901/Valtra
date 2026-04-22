import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valtra/database/app_database.dart';
import 'package:valtra/providers/backup_restore_provider.dart';
import 'package:valtra/providers/database_provider.dart';
import 'package:valtra/services/backup_restore_service.dart';

class MockBackupRestoreService extends Mock implements BackupRestoreService {}

class MockAppDatabase extends Mock implements AppDatabase {}

class FakeFile extends Fake implements File {}

class FakeAppDatabase extends Fake implements AppDatabase {}

void main() {
  late MockBackupRestoreService mockService;
  late BackupRestoreProvider provider;
  late File testFile;
  late MockAppDatabase mockDb;

  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(FakeAppDatabase());
    // Reset DatabaseProvider to avoid leaking state between tests
    DatabaseProvider.instance = DatabaseProvider.forTest();
    DatabaseProvider.instance.initialize(MockAppDatabase());
  });

  setUp(() {
    mockService = MockBackupRestoreService();
    provider = BackupRestoreProvider(service: mockService);
    testFile = File('test_backup.sqlite');
    mockDb = MockAppDatabase();
  });

  group('BackupRestoreProvider', () {
    test('initial state is idle', () {
      expect(provider.state, BackupRestoreState.idle);
      expect(provider.errorMessage, isNull);
      expect(provider.successMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    group('exportDatabase', () {
      test('sets state to exporting then success on success', () async {
        when(() => mockService.exportAndSaveDatabase())
            .thenAnswer((_) async {});

        final states = <BackupRestoreState>[];
        provider.addListener(() => states.add(provider.state));

        await provider.exportDatabase();

        expect(states, contains(BackupRestoreState.exporting));
        expect(states.last, BackupRestoreState.success);
        expect(provider.successMessage, isNotNull);
        expect(provider.errorMessage, isNull);
      });

      test('sets state to error on service failure', () async {
        when(() => mockService.exportAndSaveDatabase())
            .thenThrow(Exception('Export failed'));

        await provider.exportDatabase();

        expect(provider.state, BackupRestoreState.error);
        expect(provider.errorMessage, contains('Export failed'));
        expect(provider.successMessage, isNull);
      });

      test('isLoading is true during exporting', () async {
        when(() => mockService.exportAndSaveDatabase()).thenAnswer((_) async {
          expect(provider.isLoading, isTrue);
        });

        await provider.exportDatabase();

        expect(provider.isLoading, isFalse);
      });
    });

    group('importDatabase', () {
      test('validates file first', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => false);

        await provider.importDatabase(testFile, mockDb);

        verify(() => mockService.validateBackupFile(testFile)).called(1);
      });

      test('returns false and sets error for invalid files', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => false);

        final result = await provider.importDatabase(testFile, mockDb);

        expect(result, isFalse);
        expect(provider.state, BackupRestoreState.error);
        expect(provider.errorMessage, contains('Invalid'));
      });

      test('does not call replaceDatabase for invalid files', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => false);

        await provider.importDatabase(testFile, mockDb);

        verifyNever(() => mockService.replaceDatabase(any(), any()));
      });

      test('sets state to importing then success for valid files', () async {
        final newDb = MockAppDatabase();
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => true);
        when(() => mockService.createSafetyBackup())
            .thenAnswer((_) async => File('safety.sqlite'));
        when(() => mockService.replaceDatabase(mockDb, testFile))
            .thenAnswer((_) async => newDb);

        final states = <BackupRestoreState>[];
        provider.addListener(() => states.add(provider.state));

        final result = await provider.importDatabase(testFile, mockDb);

        expect(result, isTrue);
        expect(states, contains(BackupRestoreState.validating));
        expect(states, contains(BackupRestoreState.importing));
        expect(states.last, BackupRestoreState.success);
        expect(provider.successMessage, isNotNull);
      });

      test('returns false and sets error on service failure', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => true);
        when(() => mockService.createSafetyBackup())
            .thenAnswer((_) async => File('safety.sqlite'));
        when(() => mockService.replaceDatabase(mockDb, testFile))
            .thenThrow(Exception('Import error'));

        final result = await provider.importDatabase(testFile, mockDb);

        expect(result, isFalse);
        expect(provider.state, BackupRestoreState.error);
        expect(provider.errorMessage, contains('Import error'));
      });

      test('isLoading is true during importing', () async {
        final newDb = MockAppDatabase();
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => true);
        when(() => mockService.createSafetyBackup())
            .thenAnswer((_) async => File('safety.sqlite'));
        when(() => mockService.replaceDatabase(mockDb, testFile))
            .thenAnswer((_) async {
          expect(provider.isLoading, isTrue);
          return newDb;
        });

        await provider.importDatabase(testFile, mockDb);
      });

      test('isLoading is false during validating', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async {
          expect(provider.state, BackupRestoreState.validating);
          expect(provider.isLoading, isFalse);
          return true;
        });
        final newDb = MockAppDatabase();
        when(() => mockService.createSafetyBackup())
            .thenAnswer((_) async => File('safety.sqlite'));
        when(() => mockService.replaceDatabase(mockDb, testFile))
            .thenAnswer((_) async => newDb);

        await provider.importDatabase(testFile, mockDb);
      });
    });

    group('resetState', () {
      test('returns to idle and clears messages', () async {
        when(() => mockService.exportAndSaveDatabase())
            .thenThrow(Exception('fail'));
        await provider.exportDatabase();
        expect(provider.state, BackupRestoreState.error);
        expect(provider.errorMessage, isNotNull);

        provider.resetState();

        expect(provider.state, BackupRestoreState.idle);
        expect(provider.errorMessage, isNull);
        expect(provider.successMessage, isNull);
      });

      test('clears success message', () async {
        when(() => mockService.exportAndSaveDatabase())
            .thenAnswer((_) async {});

        await provider.exportDatabase();
        expect(provider.successMessage, isNotNull);

        provider.resetState();

        expect(provider.successMessage, isNull);
      });
    });
  });
}
