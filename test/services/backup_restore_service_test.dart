import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:valtra/database/app_database.dart';
import 'package:valtra/services/backup_restore_service.dart';

void main() {
  late Directory tempDbDir;
  late Directory tempExportDir;
  late BackupRestoreService service;

  setUp(() {
    tempDbDir = Directory.systemTemp.createTempSync('valtra_test_db_');
    tempExportDir = Directory.systemTemp.createTempSync('valtra_test_export_');

    // Create a fake valtra.sqlite in the DB directory
    _createValidValtraDb(
      File('${tempDbDir.path}/valtra.sqlite').path,
      schemaVersion: 5,
    );

    service = BackupRestoreService(
      getDbDirectory: () async => tempDbDir,
      getTempDirectory: () async => tempExportDir,
    );
  });

  tearDown(() {
    tempDbDir.deleteSync(recursive: true);
    tempExportDir.deleteSync(recursive: true);
  });

  group('validateBackupFile', () {
    test('returns true for valid Valtra SQLite DB with households table and '
        'schema version 5', () async {
      final validDb = File('${tempExportDir.path}/valid.sqlite');
      _createValidValtraDb(validDb.path, schemaVersion: 5);

      final result = await service.validateBackupFile(validDb);

      expect(result, isTrue);
    });

    test('returns false for non-existent file', () async {
      final nonExistent = File('${tempExportDir.path}/does_not_exist.sqlite');

      final result = await service.validateBackupFile(nonExistent);

      expect(result, isFalse);
    });

    test('returns false for empty file', () async {
      final emptyFile = File('${tempExportDir.path}/empty.sqlite');
      emptyFile.writeAsBytesSync([]);

      final result = await service.validateBackupFile(emptyFile);

      expect(result, isFalse);
    });

    test('returns false for random bytes file (not SQLite)', () async {
      final randomFile = File('${tempExportDir.path}/random.sqlite');
      randomFile.writeAsBytesSync(
        Uint8List.fromList(List.generate(256, (i) => i % 256)),
      );

      final result = await service.validateBackupFile(randomFile);

      expect(result, isFalse);
    });

    test('returns false for valid SQLite without households table', () async {
      final noHouseholds = File('${tempExportDir.path}/no_households.sqlite');
      final db = sql.sqlite3.open(noHouseholds.path);
      db.execute('CREATE TABLE other_table (id INTEGER PRIMARY KEY)');
      db.execute('PRAGMA user_version = 5');
      db.dispose();

      final result = await service.validateBackupFile(noHouseholds);

      expect(result, isFalse);
    });

    test('returns false for Valtra SQLite with schema version != 5', () async {
      final wrongVersion =
          File('${tempExportDir.path}/wrong_version.sqlite');
      _createValidValtraDb(wrongVersion.path, schemaVersion: 1);

      final result = await service.validateBackupFile(wrongVersion);

      expect(result, isFalse);
    });

    test('returns false for Valtra SQLite with schema version 0', () async {
      final versionZero =
          File('${tempExportDir.path}/version_zero.sqlite');
      _createValidValtraDb(versionZero.path, schemaVersion: 0);

      final result = await service.validateBackupFile(versionZero);

      expect(result, isFalse);
    });
  });

  group('createSafetyBackup', () {
    test('creates file with safety_backup prefix', () async {
      final safetyFile = await service.createSafetyBackup();

      expect(
        safetyFile.path.split(Platform.pathSeparator).last,
        matches(RegExp(r'^safety_backup_\d{8}_\d{6}\.sqlite$')),
      );
    });

    test('safety backup file exists', () async {
      final safetyFile = await service.createSafetyBackup();

      expect(safetyFile.existsSync(), isTrue);
    });

    test('safety backup has same content as current DB', () async {
      final dbFile = File('${tempDbDir.path}/valtra.sqlite');
      final dbBytes = dbFile.readAsBytesSync();

      final safetyFile = await service.createSafetyBackup();
      final safetyBytes = safetyFile.readAsBytesSync();

      expect(safetyBytes, equals(dbBytes));
    });

    test('safety backup is placed in temp directory', () async {
      final safetyFile = await service.createSafetyBackup();

      expect(safetyFile.parent.path, equals(tempExportDir.path));
    });
  });

  group('replaceDatabase', () {
    test('replaces DB file with source file content', () async {
      // Create a valid source with distinct content
      final validSource = File('${tempExportDir.path}/source.sqlite');
      _createValidValtraDb(validSource.path, schemaVersion: 5);
      final sourceDb = sql.sqlite3.open(validSource.path);
      sourceDb.execute(
          'INSERT INTO households (name) VALUES (?)', ['Test Household']);
      sourceDb.dispose();

      final sourceBytes = validSource.readAsBytesSync();

      // Create an AppDatabase that replaceDatabase can close
      final dbFile = File('${tempDbDir.path}/valtra.sqlite');
      final oldDb = AppDatabase(NativeDatabase(dbFile));

      final newDb = await service.replaceDatabase(oldDb, validSource);
      await newDb.close();

      final dbBytes = dbFile.readAsBytesSync();
      expect(dbBytes, equals(sourceBytes));
    });

    test('returns a usable AppDatabase', () async {
      final validSource = File('${tempExportDir.path}/source.sqlite');
      _createValidValtraDb(validSource.path, schemaVersion: 5);

      final dbFile = File('${tempDbDir.path}/valtra.sqlite');
      final oldDb = AppDatabase(NativeDatabase(dbFile));

      final newDb = await service.replaceDatabase(oldDb, validSource);

      // The returned DB should be usable (not closed)
      expect(newDb, isA<AppDatabase>());
      await newDb.close();
    });
  });
}

/// Creates a valid Valtra-like SQLite database at the given path with the
/// specified schema version.
void _createValidValtraDb(String path, {required int schemaVersion}) {
  final db = sql.sqlite3.open(path);
  db.execute('''
    CREATE TABLE households (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  ''');
  db.execute('PRAGMA user_version = $schemaVersion');
  db.dispose();
}
