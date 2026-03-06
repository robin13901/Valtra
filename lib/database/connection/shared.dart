import 'package:drift/drift.dart';

import 'native.dart' as native;

/// Shared database connection interface.
///
/// This abstraction allows the app to use the appropriate connection
/// implementation based on the platform (native vs web).
QueryExecutor openConnection() {
  return native.openConnection();
}
