import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('coverage/lcov.info not found');
    exit(1);
  }

  final content = file.readAsStringSync();
  final records = content.split('end_of_record');

  final excludePatterns = ['.g.dart', 'app_theme.dart', 'tables.dart', 'l10n/'];

  var totalLh = 0;
  var totalLf = 0;
  final results = <Map<String, dynamic>>[];

  for (final record in records) {
    if (record.trim().isEmpty) continue;

    final sfMatch = RegExp(r'SF:(.*)').firstMatch(record);
    final lhMatch = RegExp(r'LH:(\d+)').firstMatch(record);
    final lfMatch = RegExp(r'LF:(\d+)').firstMatch(record);

    if (sfMatch == null || lhMatch == null || lfMatch == null) continue;

    final sf = sfMatch.group(1)!.trim();
    final lh = int.parse(lhMatch.group(1)!);
    final lf = int.parse(lfMatch.group(1)!);

    // Check exclusion
    var skip = false;
    for (final pat in excludePatterns) {
      if (sf.contains(pat)) {
        skip = true;
        break;
      }
    }
    if (skip) continue;

    final pct = lf > 0 ? (lh / lf * 100) : 100.0;
    totalLh += lh;
    totalLf += lf;
    results.add({'sf': sf, 'lh': lh, 'lf': lf, 'pct': pct});
  }

  results.sort((a, b) => (a['pct'] as double).compareTo(b['pct'] as double));

  final overall = totalLf > 0 ? (totalLh / totalLf * 100) : 0.0;

  print('OVERALL COVERAGE: $totalLh/$totalLf = ${overall.toStringAsFixed(1)}%');
  print('');
  print('=== FILES BELOW 80% COVERAGE ===');
  for (final r in results) {
    if ((r['pct'] as double) < 80) {
      print('${(r['pct'] as double).toStringAsFixed(1).padLeft(5)}% (${r['lh']}/${r['lf']}) ${r['sf']}');
    }
  }
  print('');
  print('=== ALL FILES (sorted by coverage) ===');
  for (final r in results) {
    final marker = (r['pct'] as double) < 80 ? ' ***' : '';
    print('${(r['pct'] as double).toStringAsFixed(1).padLeft(5)}% (${r['lh']}/${r['lf']}) ${r['sf']}$marker');
  }
}
