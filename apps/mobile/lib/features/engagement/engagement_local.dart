import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ENG-01: only an opaque review episode and approved cloud batch ids leave this UID scope.
/// PhotoKit ids, face samples and discovery ledgers remain in Auto Save's local store.
class EngagementLocal {
  EngagementLocal(this.prefs, this.uid);
  final SharedPreferences prefs;
  final String uid;
  bool get _owns => prefs.getString('privacy.owner') == uid;
  Future<void> _write(String key, Object value) async {
    if (!_owns) return;
    if (value is bool) {
      await prefs.setBool(key, value);
    } else {
      await prefs.setString(key, value as String);
    }
    if (!_owns) await prefs.remove(key);
  }

  String key(String baby) => 'engagement.pending.$uid.$baby';
  Map<String, dynamic> _read(String baby) {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(prefs.getString(key(baby)) ?? '{}') as Map,
      );
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, Object?>?> pending(
    String baby, {
    required bool pending,
    required bool available,
  }) async {
    if (!_owns) return null;
    var old = _read(baby);
    if (old.isEmpty || pending && old['pending'] == false) {
      old = {'episode': const Uuid().v4(), 'approvedBatches': <String>[]};
    }
    old['pending'] = pending;
    await _write(key(baby), jsonEncode(old));
    if (!_owns) return null;
    return {
      'episode': old['episode'],
      'state': !available
          ? 'unavailable'
          : pending
          ? 'pending'
          : 'resolved',
      'approvedBatches': List<String>.from(
        old['approvedBatches'] as List? ?? const [],
      ),
    };
  }

  Future<void> approved(String baby, String batch) async {
    final old = _read(baby);
    if (old.isEmpty) return;
    final batches = {
      ...List<String>.from(old['approvedBatches'] as List? ?? const []),
      batch,
    }.toList();
    old['approvedBatches'] = batches.length > 20
        ? batches.sublist(batches.length - 20)
        : batches;
    await _write(key(baby), jsonEncode(old));
  }

  /// Per baby: rollout is per family, so one baby's handoff never silences another's reminders.
  bool ownsLegacy(String lane, String baby) =>
      prefs.getBool('engagement.owns.$uid.$baby.$lane') == true;
  Future<void> handoff(String lane, String baby) =>
      _write('engagement.owns.$uid.$baby.$lane', true);

  /// The server no longer owns this lane (flag off, rollback): the legacy producer comes back.
  Future<bool> release(String lane, String baby) async {
    if (!_owns || !ownsLegacy(lane, baby)) return false;
    await prefs.remove('engagement.owns.$uid.$baby.$lane');
    await prefs.remove('engagement.handoff.$uid.$baby.$lane');
    return true;
  }

  Future<void> acknowledge(String lane, String baby) =>
      _write('engagement.handoff.$uid.$baby.$lane', true);
}

final engagementRevisionProvider = NotifierProvider<EngagementRevision, int>(
  EngagementRevision.new,
);

class EngagementRevision extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}
