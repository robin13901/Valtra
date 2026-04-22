import 'package:flutter/foundation.dart';

import '../database/app_database.dart';

/// Singleton provider that holds the active [AppDatabase] instance.
///
/// After a database import, call [replaceDatabase] with the new instance
/// so all listeners (and thus all DAOs / screens) pick up the change.
class DatabaseProvider extends ChangeNotifier {
  static DatabaseProvider _instance = DatabaseProvider._internal();
  DatabaseProvider._internal();

  /// Test-only constructor — creates a fresh instance for isolated tests.
  @visibleForTesting
  DatabaseProvider.forTest();

  late AppDatabase _db;

  /// The current database instance.
  AppDatabase get db => _db;

  @visibleForTesting
  static set instance(DatabaseProvider provider) => _instance = provider;

  static DatabaseProvider get instance => _instance;

  /// Called once at app start to set the initial database.
  void initialize(AppDatabase db) {
    _db = db;
    notifyListeners();
  }

  /// Replaces the active database with [newDb] and notifies listeners.
  ///
  /// The caller must close the old database before calling this.
  Future<void> replaceDatabase(AppDatabase newDb) async {
    _db = newDb;
    notifyListeners();
  }
}
