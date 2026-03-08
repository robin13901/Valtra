import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valtra/providers/backup_restore_provider.dart';
import 'package:valtra/services/backup_restore_service.dart';

class MockBackupRestoreService extends Mock implements BackupRestoreService {}

class FakeFile extends Fake implements File {}

void main() {
  late MockBackupRestoreService mockService;
  late BackupRestoreProvider provider;
  late File testFile;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockService = MockBackupRestoreService();
    provider = BackupRestoreProvider(service: mockService);
    testFile = File('test_backup.sqlite');
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
        final exportedFile = File('exported.sqlite');
        when(() => mockService.exportDatabase())
            .thenAnswer((_) async => exportedFile);
        when(() => mockService.shareBackup(exportedFile))
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
        when(() => mockService.exportDatabase())
            .thenThrow(Exception('Export failed'));

        await provider.exportDatabase();

        expect(provider.state, BackupRestoreState.error);
        expect(provider.errorMessage, contains('Export failed'));
        expect(provider.successMessage, isNull);
      });

      test('isLoading is true during exporting', () async {
        when(() => mockService.exportDatabase()).thenAnswer((_) async {
          // Check isLoading while in exporting state
          expect(provider.isLoading, isTrue);
          return File('exported.sqlite');
        });
        when(() => mockService.shareBackup(any())).thenAnswer((_) async {});

        await provider.exportDatabase();

        // After completion, isLoading should be false
        expect(provider.isLoading, isFalse);
      });

      test('calls shareBackup with exported file', () async {
        final exportedFile = File('exported.sqlite');
        when(() => mockService.exportDatabase())
            .thenAnswer((_) async => exportedFile);
        when(() => mockService.shareBackup(exportedFile))
            .thenAnswer((_) async {});

        await provider.exportDatabase();

        verify(() => mockService.shareBackup(exportedFile)).called(1);
      });
    });

    group('importDatabase', () {
      test('validates file first', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => false);

        await provider.importDatabase(testFile);

        verify(() => mockService.validateBackupFile(testFile)).called(1);
      });

      test('returns false and sets error for invalid files', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => false);

        final result = await provider.importDatabase(testFile);

        expect(result, isFalse);
        expect(provider.state, BackupRestoreState.error);
        expect(provider.errorMessage, contains('Invalid'));
      });

      test('does not call importDatabase for invalid files', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => false);

        await provider.importDatabase(testFile);

        verifyNever(() => mockService.importDatabase(any()));
      });

      test('sets state to importing then success for valid files', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => true);
        when(() => mockService.importDatabase(testFile))
            .thenAnswer((_) async {});

        final states = <BackupRestoreState>[];
        provider.addListener(() => states.add(provider.state));

        final result = await provider.importDatabase(testFile);

        expect(result, isTrue);
        expect(states, contains(BackupRestoreState.validating));
        expect(states, contains(BackupRestoreState.importing));
        expect(states.last, BackupRestoreState.success);
        expect(provider.successMessage, isNotNull);
      });

      test('returns false and sets error on service failure', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => true);
        when(() => mockService.importDatabase(testFile))
            .thenThrow(Exception('Import error'));

        final result = await provider.importDatabase(testFile);

        expect(result, isFalse);
        expect(provider.state, BackupRestoreState.error);
        expect(provider.errorMessage, contains('Import error'));
      });

      test('isLoading is true during importing', () async {
        when(() => mockService.validateBackupFile(testFile))
            .thenAnswer((_) async => true);
        when(() => mockService.importDatabase(testFile)).thenAnswer((_) async {
          expect(provider.isLoading, isTrue);
        });

        await provider.importDatabase(testFile);
      });

      test('isLoading is false during validating', () async {
        when(() => mockService.validateBackupFile(testFile)).thenAnswer((_) async {
          // validating is not in the isLoading states
          expect(provider.state, BackupRestoreState.validating);
          expect(provider.isLoading, isFalse);
          return true;
        });
        when(() => mockService.importDatabase(testFile))
            .thenAnswer((_) async {});

        await provider.importDatabase(testFile);
      });
    });

    group('resetState', () {
      test('returns to idle and clears messages', () async {
        // First put provider in error state
        when(() => mockService.exportDatabase())
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
        final exportedFile = File('exported.sqlite');
        when(() => mockService.exportDatabase())
            .thenAnswer((_) async => exportedFile);
        when(() => mockService.shareBackup(exportedFile))
            .thenAnswer((_) async {});

        await provider.exportDatabase();
        expect(provider.successMessage, isNotNull);

        provider.resetState();

        expect(provider.successMessage, isNull);
      });
    });

    group('onDatabaseReplaced callback', () {
      test('callback is stored when provided', () {
        var called = false;
        final providerWithCallback = BackupRestoreProvider(
          service: mockService,
          onDatabaseReplaced: () => called = true,
        );

        providerWithCallback.onDatabaseReplaced!();
        expect(called, isTrue);
      });

      test('callback is null when not provided', () {
        expect(provider.onDatabaseReplaced, isNull);
      });
    });
  });
}
