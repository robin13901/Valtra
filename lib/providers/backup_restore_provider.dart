import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/backup_restore_service.dart';

/// State of the backup/restore operation.
enum BackupRestoreState { idle, exporting, importing, validating, success, error }

/// Manages backup and restore operations, bridging [BackupRestoreService]
/// to the UI layer via [ChangeNotifier].
///
/// Provides loading indicators, success/error messages, and an optional
/// [onDatabaseReplaced] callback that the app can use to reinitialize
/// the database connection after a successful import.
class BackupRestoreProvider extends ChangeNotifier {
  final BackupRestoreService _service;

  /// Called after a successful database import so the app can reinitialize.
  final VoidCallback? onDatabaseReplaced;

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

  BackupRestoreProvider({
    required BackupRestoreService service,
    this.onDatabaseReplaced,
  }) : _service = service;

  /// Exports the database and opens the system share sheet.
  ///
  /// Sets state to [BackupRestoreState.exporting] during the operation,
  /// then to [BackupRestoreState.success] or [BackupRestoreState.error].
  Future<void> exportDatabase() async {
    _state = BackupRestoreState.exporting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final file = await _service.exportDatabase();
      await _service.shareBackup(file);
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
  /// Sets state through [BackupRestoreState.validating] ->
  /// [BackupRestoreState.importing] -> [BackupRestoreState.success]
  /// (or [BackupRestoreState.error] on failure).
  Future<bool> importDatabase(File sourceFile) async {
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

      await _service.importDatabase(sourceFile);
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
