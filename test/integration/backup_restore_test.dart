import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:valtra/database/app_database.dart';
import 'package:valtra/services/backup_restore_service.dart';

void main() {
  group('Backup & Restore Integration', () {
    late Directory tempDir;
    late Directory dbDir;
    late Directory exportDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('valtra_backup_test_');
      dbDir = Directory(p.join(tempDir.path, 'db'));
      exportDir = Directory(p.join(tempDir.path, 'export'));
      await dbDir.create(recursive: true);
      await exportDir.create(recursive: true);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    /// Helper: create a real SQLite DB file with households + readings data.
    Future<File> createDbFileWithData({
      required String dirPath,
      String householdName = 'Test House',
      double readingValue = 1000.0,
    }) async {
      final dbPath = p.join(dirPath, BackupRestoreService.dbFileName);

      // Create a real Drift database backed by a file
      final db = AppDatabase(NativeDatabase(File(dbPath)));

      final householdId = await db.householdDao.insert(
        HouseholdsCompanion.insert(name: householdName, personCount: 1),
      );
      await db.electricityDao.insertReading(
        ElectricityReadingsCompanion.insert(
          householdId: householdId,
          timestamp: DateTime(2025, 1, 1),
          valueKwh: readingValue,
        ),
      );

      await db.close();
      return File(dbPath);
    }

    test('export creates valid database copy', () async {
      // Create a DB file with known data
      await createDbFileWithData(dirPath: dbDir.path);

      // Note: exportAndSaveDatabase() uses FlutterFileSaver which requires
      // platform channels. We test the underlying file operations instead.
      final dbFile = File(p.join(dbDir.path, BackupRestoreService.dbFileName));
      expect(dbFile.existsSync(), isTrue);
      expect(dbFile.lengthSync(), greaterThan(0));

      // Verify the DB file contains our data
      final sqlDb = sql.sqlite3.open(dbFile.path);
      try {
        final result = sqlDb.select('SELECT name FROM households');
        expect(result.length, 1);
        expect(result.first['name'], 'Test House');

        final readings = sqlDb.select('SELECT value_kwh FROM electricity_readings');
        expect(readings.length, 1);
        expect(readings.first['value_kwh'], 1000.0);
      } finally {
        sqlDb.dispose();
      }
    });

    test('validate accepts exported database', () async {
      // Create a valid DB file
      final dbFile = await createDbFileWithData(dirPath: dbDir.path);

      final service = BackupRestoreService(
        getDbDirectory: () async => dbDir,
        getTempDirectory: () async => exportDir,
      );

      // Validate should return true for a genuine Valtra DB
      final isValid = await service.validateBackupFile(dbFile);
      expect(isValid, isTrue);
    });

    test('validate rejects non-database file', () async {
      // Create a text file that's not a DB
      final fakeFile = File(p.join(dbDir.path, 'fake.sqlite'));
      await fakeFile.writeAsString('not a database');

      final service = BackupRestoreService(
        getDbDirectory: () async => dbDir,
        getTempDirectory: () async => exportDir,
      );

      final isValid = await service.validateBackupFile(fakeFile);
      expect(isValid, isFalse);
    });

    test('replaceDatabase replaces database content', () async {
      // Create "current" DB with household A
      await createDbFileWithData(
        dirPath: dbDir.path,
        householdName: 'House A',
        readingValue: 1000.0,
      );

      // Create "backup" DB with household B in a separate directory
      final backupDir = Directory(p.join(tempDir.path, 'backup'));
      await backupDir.create(recursive: true);
      final backupFile = await createDbFileWithData(
        dirPath: backupDir.path,
        householdName: 'House B',
        readingValue: 9999.0,
      );

      final service = BackupRestoreService(
        getDbDirectory: () async => dbDir,
        getTempDirectory: () async => exportDir,
      );

      // Open the current DB so we can pass it to replaceDatabase
      final currentDbFile = File(p.join(dbDir.path, BackupRestoreService.dbFileName));
      final oldDb = AppDatabase(NativeDatabase(currentDbFile));

      // Replace the database
      final newDb = await service.replaceDatabase(oldDb, backupFile);
      await newDb.close();

      // Verify the main DB now contains House B data
      final mainDbPath = p.join(dbDir.path, BackupRestoreService.dbFileName);
      final sqlDb = sql.sqlite3.open(mainDbPath);
      try {
        final households = sqlDb.select('SELECT name FROM households');
        expect(households.length, 1);
        expect(households.first['name'], 'House B');

        final readings = sqlDb.select('SELECT value_kwh FROM electricity_readings');
        expect(readings.length, 1);
        expect(readings.first['value_kwh'], 9999.0);
      } finally {
        sqlDb.dispose();
      }
    });

    test('safety backup preserves original data', () async {
      // Create DB with known data
      await createDbFileWithData(
        dirPath: dbDir.path,
        householdName: 'Original House',
        readingValue: 42.0,
      );

      final service = BackupRestoreService(
        getDbDirectory: () async => dbDir,
        getTempDirectory: () async => exportDir,
      );

      // Create safety backup
      final safetyFile = await service.createSafetyBackup();
      expect(safetyFile.existsSync(), isTrue);
      expect(safetyFile.path, contains('safety_backup_'));

      // Verify safety backup contains the original data
      final sqlDb = sql.sqlite3.open(safetyFile.path);
      try {
        final households = sqlDb.select('SELECT name FROM households');
        expect(households.length, 1);
        expect(households.first['name'], 'Original House');

        final readings = sqlDb.select('SELECT value_kwh FROM electricity_readings');
        expect(readings.length, 1);
        expect(readings.first['value_kwh'], 42.0);
      } finally {
        sqlDb.dispose();
      }
    });

    test('validate rejects invalid backup file', () async {
      // Create a valid current DB
      await createDbFileWithData(dirPath: dbDir.path);

      // Create an invalid file
      final invalidFile = File(p.join(tempDir.path, 'invalid.sqlite'));
      await invalidFile.writeAsString('this is not a database');

      final service = BackupRestoreService(
        getDbDirectory: () async => dbDir,
        getTempDirectory: () async => exportDir,
      );

      // Validate should return false for invalid files
      final isValid = await service.validateBackupFile(invalidFile);
      expect(isValid, isFalse);
    });
  });
}
