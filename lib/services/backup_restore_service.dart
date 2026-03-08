import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

/// Service for database backup, restore, validation, and sharing.
///
/// Handles all backup/restore business logic without UI dependencies.
/// Uses constructor injection for directory providers, making it testable
/// without platform channels.
///
/// This service does NOT manage database connection lifecycle (close/reconnect).
/// That responsibility belongs to the provider layer.
class BackupRestoreService {
  /// Name of the Valtra database file.
  static const dbFileName = 'valtra.sqlite';

  /// Expected schema version for valid Valtra databases.
  static const expectedSchemaVersion = 3;

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

  /// Exports the current database to a timestamped file in the temp directory.
  ///
  /// Returns the exported [File] with name format:
  /// `valtra_backup_YYYYMMDD_HHmmss.sqlite`
  Future<File> exportDatabase() async {
    final db = await _dbFile;
    final tempDir = await _getTempDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportPath = p.join(tempDir.path, 'valtra_backup_$timestamp.sqlite');
    return db.copy(exportPath);
  }

  /// Shares a backup file via the system share sheet.
  ///
  /// Uses [Share.shareXFiles] with SQLite MIME type.
  Future<void> shareBackup(File file) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/x-sqlite3')],
    );
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

  /// Imports a database file, replacing the current database.
  ///
  /// Sequence:
  /// 1. Validates the source file
  /// 2. Creates a safety backup of the current database
  /// 3. Copies the source file over the current database
  ///
  /// Throws [ArgumentError] if the source file is not a valid Valtra database.
  ///
  /// Does NOT handle database connection close/reconnect -- that is the
  /// responsibility of the provider layer.
  Future<void> importDatabase(File sourceFile) async {
    final isValid = await validateBackupFile(sourceFile);
    if (!isValid) {
      throw ArgumentError('Invalid backup file: ${sourceFile.path}');
    }

    await createSafetyBackup();

    final db = await _dbFile;
    await sourceFile.copy(db.path);
  }
}
