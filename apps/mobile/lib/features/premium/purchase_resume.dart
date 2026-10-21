import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appearance/appearance_providers.dart';
import '../../app/local_owner.dart';

/// MO03 / M17: the draft a purchase started from, kept under an opaque `draftRef` so the parent
/// lands back on the exact template with the same photos after a verified purchase.
///
/// The live object stays in memory for this run (photos, crops and texts exactly as they were);
/// a JSON copy goes to SharedPreferences so the draft can be rebuilt after the app was closed
/// mid-purchase. Only this phone ever has it: the server gets the ref, never the photos.
class ResumeDrafts {
  ResumeDrafts(this._prefs, {required String? owner})
    : _owner = owner,
      _prefix = 'premium.draft.${Uri.encodeComponent(owner ?? "signed-out")}.';
  final SharedPreferences _prefs;
  final String? _owner;
  final _memory = <String, Object>{};

  final String _prefix;

  Future<void> clearAll() async {
    _memory.clear();
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await _prefs.remove(key);
    }
  }

  /// Drafts older than this are dropped the next time one is kept.
  static const keepFor = Duration(days: 7);

  /// Keeps [draft] (and its [json] copy) and returns its ref (≤ 80 characters, contracts
  /// `purchaseResumeSchema`).
  String keep(Object draft, Map<String, Object?> json, {DateTime? now}) {
    if (_owner == null) throw StateError('signed-out');
    final at = now ?? DateTime.now();
    _prune(at);
    final ref = 'd${at.microsecondsSinceEpoch.toRadixString(36)}';
    _memory[ref] = draft;
    _prefs.setString(
      '$_prefix$ref',
      jsonEncode({'savedAt': at.toUtc().toIso8601String(), 'draft': json}),
    );
    return ref;
  }

  /// The draft as it was, while this run lasts.
  Object? live(String ref) => _owner == null ? null : _memory[ref];

  /// The saved copy, to rebuild the draft after a restart.
  Map<String, Object?>? saved(String ref) {
    if (_owner == null) return null;
    final raw = _prefs.getString('$_prefix$ref');
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw);
      return j is Map && j['draft'] is Map
          ? (j['draft'] as Map).cast<String, Object?>()
          : null;
    } on FormatException {
      return null;
    }
  }

  /// Done with it (resumed, or the parent went another way).
  void drop(String ref) {
    _memory.remove(ref);
    _prefs.remove('$_prefix$ref');
  }

  void _prune(DateTime now) {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      final raw = _prefs.getString(key);
      DateTime? at;
      try {
        final j = raw == null ? null : jsonDecode(raw);
        at = j is Map ? DateTime.tryParse('${j['savedAt']}') : null;
      } on FormatException {
        at = null;
      }
      if (at == null || now.difference(at) > keepFor) {
        _prefs.remove(key);
        _memory.remove(key.substring(_prefix.length));
      }
    }
  }
}

final resumeDraftsProvider = Provider<ResumeDrafts>(
  (ref) => ResumeDrafts(
    ref.watch(sharedPreferencesProvider),
    owner: ref.watch(localOwnerProvider),
  ),
);

/// The template the parent was just brought back to after a purchase: the editor shows MO03's
/// "Đã mở Premium · tiếp tục chỗ bạn đang làm" once, then clears it.
final justResumedProvider = NotifierProvider<JustResumed, String?>(
  JustResumed.new,
);

class JustResumed extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? templateId) => state = templateId;
}

/// Whether the screen for [templateId] is the one just resumed; clears the mark after this frame
/// (providers cannot change while widgets build). Call from `initState`.
bool takeJustResumed(WidgetRef ref, String templateId) {
  if (ref.read(justResumedProvider) != templateId) return false;
  Future.microtask(() => ref.read(justResumedProvider.notifier).set(null));
  return true;
}
