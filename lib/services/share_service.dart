import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Thin wrapper around share_plus for sharing CSV files.
class ShareService {
  /// Write CSV content to a temp file and share via system share sheet.
  Future<void> shareCsvFile({
    required String csvContent,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvContent);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
    );
  }
}
