import 'dart:io';

import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../database/app_database.dart';
import '../database/connection/shared.dart';

/// Service for database backup, restore, validation, and file-save export.
///
/// Handles all backup/restore business logic without UI dependencies.
/// Uses constructor injection for directory providers, making it testable
/// without platform channels.
class BackupRestoreService {
  /// Name of the Valtra database file.
  static const dbFileName = 'valtra.sqlite';

  /// Temp file name used during import.
  static const _dbFileNameTemp = 'valtra-db-temp.sqlite';

  /// Expected schema version for valid Valtra databases.
  static const expectedSchemaVersion = 5;

  final Future<Directory> Function() _getDbDirectory;
  final Future<Directory> Function() _getTempDirectory;

  /// Creates a [BackupRestoreService].
  ///
  /// Accepts optional directory provider overrides for testing.
  /// Defaults to [getApplicationDocumentsDirectory] and
  /// [getTemporaryDirectory] from path_provider.
  BackupRestoreService({
    Future<Directory> Function()? getDbDirectory,
    Future<Directory> Function()? getTempDirectory,
  })  : _getDbDirectory = getDbDirectory ?? getApplicationDocumentsDirectory,
        _getTempDirectory = getTempDirectory ?? getTemporaryDirectory;

  /// Returns the current database [File].
  Future<File> get _dbFile async {
    final dir = await _getDbDirectory();
    return File(p.join(dir.path, dbFileName));
  }

  /// Exports the current database by saving it directly to the device.
  ///
  /// Uses [FlutterFileSaver] to write the file (triggers system file-save
  /// dialog on most platforms). File name format:
  /// `{YYYYMMDD}-valtra-db-backup.sqlite`
  Future<void> exportAndSaveDatabase() async {
    final db = await _dbFile;
    if (!db.existsSync()) return;
    final bytes = await db.readAsBytes();
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    final name = '$stamp-valtra-db-backup.sqlite';
    await FlutterFileSaver().writeFileAsBytes(fileName: name, bytes: bytes);
  }

  /// Validates that a file is a genuine Valtra SQLite database.
  ///
  /// Checks:
  /// - File exists and is non-empty
  /// - File is a valid SQLite database
  /// - Contains a `households` table
  /// - Has schema version (PRAGMA user_version) equal to [expectedSchemaVersion]
  ///
  /// Returns `true` if all checks pass, `false` otherwise.
  Future<bool> validateBackupFile(File file) async {
    if (!file.existsSync()) return false;
    if (file.lengthSync() == 0) return false;

    sql.Database? db;
    try {
      db = sql.sqlite3.open(file.path);

      // Check for the households table
      final result = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='households'",
      );
      if (result.isEmpty) return false;

      // Check schema version
      final versionResult = db.select('PRAGMA user_version');
      final version = versionResult.first['user_version'] as int;
      if (version != expectedSchemaVersion) return false;

      return true;
    } catch (_) {
      return false;
    } finally {
      db?.dispose();
    }
  }

  /// Creates a safety backup of the current database in the temp directory.
  ///
  /// Returns the safety backup [File] with name format:
  /// `safety_backup_YYYYMMDD_HHmmss.sqlite`
  Future<File> createSafetyBackup() async {
    final db = await _dbFile;
    final tempDir = await _getTempDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safetyPath =
        p.join(tempDir.path, 'safety_backup_$timestamp.sqlite');
    return db.copy(safetyPath);
  }

  /// Replaces the current database with [source], matching XFin's workflow:
  ///
  /// 1. Closes [oldDb]
  /// 2. Copies source to a temp file
  /// 3. Deletes the current DB file and renames temp into place
  ///    (falls back to copy + delete if rename fails)
  /// 4. Opens a fresh [AppDatabase] and returns it
  ///
  /// The caller is responsible for validation and safety-backup before
  /// calling this method.
  Future<AppDatabase> replaceDatabase(
      AppDatabase oldDb, File source) async {
    final appDbFile = await _dbFile;
    await oldDb.close();

    final tmpDir = await _getTempDirectory();
    final tmp = File(p.join(tmpDir.path, _dbFileNameTemp));
    if (await tmp.exists()) await tmp.delete();
    await source.copy(tmp.path);

    try {
      if (await appDbFile.exists()) await appDbFile.delete();
      await tmp.rename(appDbFile.path);
    } catch (_) {
      await tmp.copy(appDbFile.path);
      if (await tmp.exists()) await tmp.delete();
    }

    return AppDatabase(openConnection());
  }
}
