import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../spending/spending_calc.dart' show foldVietnamese;
import 'keepsake_catalog.dart';
import 'keepsake_occasions.dart';

/// Thiệp / Video templates a person saved (owner, 2026-10-30: "có search và bookmark"): per
/// account, on every device, newest first, at most 100 (`users/{uid}/settings/keepsakes`, the
/// same shape as Sơ cứu's saved situations). Template ids only, never child data.
const keepsakeSavedMax = 100;

DocumentReference<Map<String, dynamic>> _doc(
  FirebaseFirestore db,
  String uid,
) => db.doc('users/$uid/settings/keepsakes');

final keepsakeSavedProvider = StreamProvider<List<String>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn) return Stream.value(const []);
  return _doc(ref.watch(firestoreProvider), session.user.uid).snapshots().map(
    (s) => [for (final id in (s.data()?['saved'] as List?) ?? const []) '$id'],
  );
});

/// "Lưu mẫu" / "Bỏ lưu"; true when [id] is saved afterwards.
Future<bool> toggleKeepsakeSaved(WidgetRef ref, String id) async {
  final session = ref.read(sessionProvider);
  if (session is! SessionSignedIn) return false;
  final now = [...?ref.read(keepsakeSavedProvider).value];
  final saved = !now.contains(id);
  saved ? now.insert(0, id) : now.remove(id);
  await _doc(ref.read(firestoreProvider), session.user.uid).set({
    'saved': now.take(keepsakeSavedMax).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  return saved;
}

/// The search on Thiệp · Video: the template's name in both languages and its dịp, without
/// Vietnamese marks ("thang" finds "1 tháng"). [query] is already folded; empty matches all.
bool keepsakeMatches(KeepsakeTemplate t, String query, AppLocalizations l10n) {
  if (query.isEmpty) return true;
  final words = [
    t.name.vi,
    t.name.en,
    for (final w in t.occasions) ?Occasion.fromWire(w)?.label(l10n),
  ];
  return words.any((w) => foldVietnamese(w).contains(query));
}
