import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D-076 #9: no "Miễn phí" / "Luôn miễn phí" / "Bản theo mẫu luôn miễn phí" / "free" label on the
/// Premium-feature and AI screens (Nhịp lớn lên `rh`, Premium `pm`, AI summaries `ai`, the
/// assistant `as`, Kỷ niệm 2.0 `ks`). Honest cost lines stay ("không trừ lượt" = 0 credits).
void main() {
  const prefixes = ['rh', 'pm', 'ai', 'as', 'ks'];

  /// Facts, not labels: the beta's end date with no automatic charge; "Free some up" (storage).
  const allowed = {'pmPlanBetaBody', 'ksVideoErrQuota'};

  Map<String, Object?> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, Object?>;

  bool ours(String key) =>
      !key.startsWith('@') &&
      !allowed.contains(key) &&
      prefixes.any(
        (p) =>
            key.startsWith(p) &&
            key.length > p.length &&
            key[p.length].toUpperCase() == key[p.length],
      );

  test('Vietnamese: no "miễn phí"', () {
    final hits = [
      for (final e in arb('vi').entries)
        if (ours(e.key) && '${e.value}'.toLowerCase().contains('miễn phí'))
          e.key,
    ];
    expect(hits, isEmpty);
  });

  test('English: no "free"', () {
    final word = RegExp(r'\bfree\b', caseSensitive: false);
    final hits = [
      for (final e in arb('en').entries)
        if (ours(e.key) && word.hasMatch('${e.value}')) e.key,
    ];
    expect(hits, isEmpty);
  });
}
