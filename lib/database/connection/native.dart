import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

/// Opens a native SQLite connection for mobile platforms.
///
/// This function handles platform-specific setup including:
/// - iOS/Android native library loading via sqlite3_flutter_libs
/// - Android-specific workarounds for system library issues
/// - Database file storage in application documents directory
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    // Get the application documents directory for storing the database
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'valtra.sqlite'));

    // On Android, apply workaround for sqlite3 issues on older devices
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // Configure temp directory for sqlite3 operations
    final cacheBase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cacheBase;

    return NativeDatabase.createInBackground(file);
  });
}
