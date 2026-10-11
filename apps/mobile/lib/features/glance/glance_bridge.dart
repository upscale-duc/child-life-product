import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/glance_copy.dart';
import '../auth/auth_repository.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../care/timer_models.dart';
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart' show relationLabel;

/// S8 glanceables (Figma W1–W5): keeps the iOS widgets and Live Activities in step with the app.
/// It hands the native side the signed-in session (so widget and Live Activity buttons can write
/// as this person) and a "glance snapshot" of Today for the selected baby: last bottle / breast /
/// diaper, sleep, running timers, today's totals, the 3 most recent entries, and every string
/// the widgets show (ARB, D-012). No photos, ever.
abstract class GlanceChannel {
  Future<void> setSession(String uid, String refreshToken);
  Future<void> clearSession();
  Future<void> setSnapshot(String json);

  /// Sends what widgets logged offline and re-syncs the Live Activities.
  Future<void> refresh();
}

class MethodGlanceChannel implements GlanceChannel {
  static const _channel = MethodChannel('childlife/glance');

  @override
  Future<void> setSession(String uid, String refreshToken) =>
      _channel.invokeMethod<void>('setSession', {
        'uid': uid,
        'refreshToken': refreshToken,
      });

  @override
  Future<void> clearSession() => _channel.invokeMethod<void>('clearSession');

  @override
  Future<void> setSnapshot(String json) =>
      _channel.invokeMethod<void>('setSnapshot', json);

  @override
  Future<void> refresh() => _channel.invokeMethod<void>('refresh');
}

final glanceChannelProvider = Provider<GlanceChannel?>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS
      ? MethodGlanceChannel()
      : null,
);

const _useEmulators = bool.fromEnvironment('CL_EMULATORS');

int _ms(DateTime d) => d.millisecondsSinceEpoch;

Map<String, Object?> _author(CareAuthor a) => {
  'name': a.name,
  'relation': a.relation.name,
  'relationCustom': a.relationCustom,
};

/// The snapshot JSON (dates as epoch milliseconds, as GlanceCoding decodes them).
Map<String, Object?> buildGlanceSnapshot({
  required AppLocalizations l10n,
  required String locale,
  required DateTime now,
  required String projectId,
  required String apiKey,
  required String? emulatorHost,
  required Membership? me,
  required String? nickname,
  required String zone,
  required List<CareRecord> records,
  required CareTimer? sleep,
  required CareTimer? breast,
}) {
  final base = <String, Object?>{
    'signedIn': me != null,
    'canLog': me != null && me.role != MemberRole.relative,
    'locale': locale,
    'projectId': projectId,
    'apiKey': apiKey,
    'emulatorHost': emulatorHost,
    'sleptTodayMin': 0,
    'feedsToday': 0,
    'bottleMlToday': 0,
    'bottlesToday': 0,
    'breastsToday': 0,
    'diapersToday': 0,
    'recent': <Object?>[],
    'pending': 0,
    'copy': glanceCopy(l10n),
    'generatedAt': _ms(now),
  };
  if (me == null) return base;

  // Widgets show the name on its own ("Bạn ghi", "Từ 11:46 · Bạn"), so "me" is the widget's
  // own "Bạn" / "You" rather than the in-sentence form.
  String by(CareAuthor a, String uid) => uid == me.uid
      ? l10n.glanceYou
      : authorLabel(
          l10n,
          a,
          isMe: false,
          relationLabel: (r, c) => relationLabel(l10n, r, c),
        );
  CareRecord? last(CareType t) =>
      records.where((r) => r.type == t).firstOrNull; // newest first
  Map<String, Object?> lastJson(CareRecord r) => {
    'at': _ms(
      r.type == CareType.breast ? (r.endedAt ?? r.occurredAt) : r.occurredAt,
    ),
    'by': by(r.author, r.createdBy),
    'amountMl': r.amountMl,
    'milk': r.milk?.name,
    'kind': r.diaper?.name,
    'side': r.side?.name,
    'durationMin': r.durationMin,
  };
  Map<String, Object?> timerJson(CareTimer t) => {
    'type': t.type.name,
    'sessionId': t.sessionId,
    'startedAt': _ms(t.startedAt),
    'startedBy': t.startedBy,
    'byName': by(t.author, t.startedBy),
    'left': t.type == TimerType.sleep ? null : _side(t.sideOf(Side.left)),
    'right': t.type == TimerType.sleep ? null : _side(t.sideOf(Side.right)),
    'paused': t.paused,
  };

  final day = babyDayBounds(zone, now);
  final today = [
    for (final r in records)
      if (!r.occurredAt.isBefore(day.start) && r.occurredAt.isBefore(day.end))
        r,
  ];
  final bottles = today.where((r) => r.type == CareType.bottle).toList();
  final breasts = today.where((r) => r.type == CareType.breast).length;
  final sleptToday = today
      .where((r) => r.type == CareType.sleep && r.endedAt != null)
      .fold<int>(
        0,
        (s, r) => s + r.endedAt!.difference(r.occurredAt).inMinutes,
      );
  final lastSleep = last(CareType.sleep);

  return {
    ...base,
    'uid': me.uid,
    'babyId': me.babyId,
    'nickname': nickname,
    'author': _author(CareAuthor.of(me)),
    'lastBottle': last(CareType.bottle).let(lastJson),
    'lastBreast': last(CareType.breast).let(lastJson),
    'lastDiaper': last(CareType.diaper).let(lastJson),
    'lastWokeAt': lastSleep?.endedAt.let(_ms),
    'lastSleepMin': lastSleep?.endedAt
        ?.difference(lastSleep.occurredAt)
        .inMinutes,
    'sleptTodayMin': sleptToday,
    'feedsToday': bottles.length + breasts,
    'bottleMlToday': bottles.fold<int>(0, (s, r) => s + (r.amountMl ?? 0)),
    'bottlesToday': bottles.length,
    'breastsToday': breasts,
    'diapersToday': today.where((r) => r.type == CareType.diaper).length,
    'sleep': sleep.let(timerJson),
    'breast': breast.let(timerJson),
    'recent': [
      for (final r in records.where((r) => r.type != CareType.growth).take(3))
        {
          'id': r.id,
          'at': _ms(r.occurredAt),
          'type': r.type.name,
          'text': recordSummary(l10n, locale, r),
          'by': by(r.author, r.createdBy),
        },
    ],
  };
}

Map<String, Object?> _side(TimerSide s) => {
  'accumulatedMs': s.accumulatedMs,
  'runningSince': s.runningSince.let(_ms),
};

extension _Let<T> on T? {
  R? let<R>(R Function(T) f) => this == null ? null : f(this as T);
}

/// Mounted under the app: pushes the session and snapshot whenever they change, and on resume
/// sends offline widget logs and re-syncs the Live Activities.
class GlanceSync extends ConsumerStatefulWidget {
  const GlanceSync({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<GlanceSync> createState() => _GlanceSyncState();
}

class _GlanceSyncState extends ConsumerState<GlanceSync>
    with WidgetsBindingObserver {
  String? _sentSnapshot;
  String? _sentSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(glanceChannelProvider)?.refresh().catchError((Object _) {}),
      );
    }
  }

  void _session(GlanceChannel channel, User? user) {
    final token = user?.refreshToken;
    final key = user == null || token == null ? '' : '${user.uid}:$token';
    if (key == _sentSession) return;
    _sentSession = key;
    unawaited(
      (key.isEmpty
              ? channel.clearSession()
              : channel.setSession(user!.uid, token!))
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(glanceChannelProvider);
    if (channel == null) return widget.child;
    final user = ref.watch(authUserProvider).value;
    final session = ref.watch(sessionProvider);
    if (session is SessionLoading) return widget.child;
    _session(channel, session is SessionSignedIn ? user : null);

    final me = session is SessionSignedIn
        ? ref.watch(selectedMembershipProvider)
        : null;
    final usable = me != null && me.canViewToday;
    final baby = usable ? ref.watch(babyProvider(me.babyId)).value : null;
    final records = usable
        ? ref.watch(recentRecordsProvider(me.babyId)).value
        : null;
    final sleep = usable
        ? ref.watch(careTimerProvider((me.babyId, TimerType.sleep))).value
        : null;
    final breast = usable
        ? ref.watch(careTimerProvider((me.babyId, TimerType.breast))).value
        : null;
    ref.watch(careClockProvider);
    // Wait for the first answer rather than showing an empty Today on the widgets.
    if (usable && records == null) return widget.child;

    final options = Firebase.app().options;
    final json = buildGlanceSnapshot(
      l10n: AppLocalizations.of(context),
      locale: Localizations.localeOf(context).languageCode == 'en'
          ? 'en'
          : 'vi',
      now: DateTime.now(),
      projectId: options.projectId,
      apiKey: options.apiKey,
      emulatorHost: _useEmulators ? 'localhost' : null,
      me: usable ? me : null,
      nickname: baby?.nickname,
      zone: baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh',
      records: records ?? const [],
      sleep: sleep,
      breast: breast,
    );
    final stable = jsonEncode({...json, 'generatedAt': 0});
    if (stable != _sentSnapshot) {
      _sentSnapshot = stable;
      unawaited(
        channel.setSnapshot(jsonEncode(json)).catchError((Object _) {}),
      );
    }
    return widget.child;
  }
}
