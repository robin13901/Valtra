import 'dart:io';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../services/backup_restore_service.dart';
import 'database_provider.dart';

/// State of the backup/restore operation.
enum BackupRestoreState { idle, exporting, importing, validating, success, error }

/// Manages backup and restore operations, bridging [BackupRestoreService]
/// to the UI layer via [ChangeNotifier].
///
/// Provides loading indicators, success/error messages, and integrates
/// with [DatabaseProvider] to reinitialize the database after import.
class BackupRestoreProvider extends ChangeNotifier {
  final BackupRestoreService _service;

  BackupRestoreState _state = BackupRestoreState.idle;
  String? _errorMessage;
  String? _successMessage;

  /// Current operation state.
  BackupRestoreState get state => _state;

  /// Error message from the last failed operation, if any.
  String? get errorMessage => _errorMessage;

  /// Success message from the last completed operation, if any.
  String? get successMessage => _successMessage;

  /// Whether an export or import is currently in progress.
  bool get isLoading =>
      _state == BackupRestoreState.exporting ||
      _state == BackupRestoreState.importing;

  BackupRestoreProvider({required BackupRestoreService service})
      : _service = service;

  /// Exports the database and saves it directly to the device.
  Future<void> exportDatabase() async {
    _state = BackupRestoreState.exporting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _service.exportAndSaveDatabase();
      _state = BackupRestoreState.success;
      _successMessage = 'Database exported successfully';
      notifyListeners();
    } catch (e) {
      _state = BackupRestoreState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Imports a database file after validation.
  ///
  /// Returns `true` if the import succeeded, `false` otherwise.
  /// Closes the old database, replaces the file, and reinitializes
  /// via [DatabaseProvider].
  Future<bool> importDatabase(File sourceFile, AppDatabase currentDb) async {
    _state = BackupRestoreState.validating;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final isValid = await _service.validateBackupFile(sourceFile);
      if (!isValid) {
        _state = BackupRestoreState.error;
        _errorMessage = 'Invalid backup file';
        notifyListeners();
        return false;
      }

      _state = BackupRestoreState.importing;
      notifyListeners();

      await _service.createSafetyBackup();
      final newDb = await _service.replaceDatabase(currentDb, sourceFile);
      await DatabaseProvider.instance.replaceDatabase(newDb);

      _state = BackupRestoreState.success;
      _successMessage = 'Database imported successfully';
      notifyListeners();
      return true;
    } catch (e) {
      _state = BackupRestoreState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Resets the provider to [BackupRestoreState.idle] and clears messages.
  void resetState() {
    _state = BackupRestoreState.idle;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
