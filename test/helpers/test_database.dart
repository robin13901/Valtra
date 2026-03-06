import 'package:drift/native.dart';
import 'package:valtra/database/app_database.dart';

/// Creates an in-memory test database.
///
/// Use this for unit tests to avoid file system operations
/// and ensure test isolation.
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
