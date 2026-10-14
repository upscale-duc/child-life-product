import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/environment.dart';
import '../../app/providers.dart';
import '../../core/appearance/appearance_providers.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart';

/// Kỷ niệm 2.0 is a free beta like Tự lưu (D-068 #3): each part follows its rollout flag per
/// family (`milestone_cards`, `memory_story`), asked from the server (`getFeatureAccess`, which
/// also checks the caller is a Cùng nuôi) and remembered on the phone for when it is offline.
/// Debug runs against dev always have it.
typedef KeepsakeAccess = ({bool cards, bool videos});

const _none = (cards: false, videos: false);

final keepsakeAccessProvider = FutureProvider.autoDispose
    .family<KeepsakeAccess, String>((ref, babyId) async {
      if (kDebugMode && ref.watch(environmentProvider) == AppEnvironment.dev) {
        return (cards: true, videos: true);
      }
      final prefs = ref.watch(sharedPreferencesProvider);
      final key = 'keepsakes.access.$babyId';
      try {
        final r = await ref
            .watch(functionsProvider)
            .httpsCallable('getFeatureAccess')
            .call<Object?>({'babyId': babyId});
        final m = r.data is Map ? r.data! as Map : const {};
        final access = (
          cards: m['milestoneCards'] == true,
          videos: m['memoryStory'] == true,
        );
        unawaited(
          prefs.setString(
            key,
            '${access.cards ? 'c' : ''}${access.videos ? 'v' : ''}',
          ),
        );
        return access;
      } on Object {
        // Offline or failing: the last answer this phone got (so scheduled nudges stay).
        final last = prefs.getString(key) ?? '';
        return (cards: last.contains('c'), videos: last.contains('v'));
      }
    });

/// What the selected baby offers to this person: only Cùng nuôi create (R-119).
final selectedKeepsakeAccessProvider = Provider<KeepsakeAccess>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null || me.role != MemberRole.coParent) return _none;
  return ref.watch(keepsakeAccessProvider(me.babyId)).value ?? _none;
});
