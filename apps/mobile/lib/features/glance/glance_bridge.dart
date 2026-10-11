import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/glance_copy.dart';
import '../auth/auth_repository.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_format.dart';
import '../care/care_models.dart';
import '../care/care_repository.dart';
import '../care/care_sheets.dart';
import '../care/timer_models.dart';
import '../care/timer_screens.dart' show showSleepChooser;
import '../home/home_shell.dart';
import '../onboarding/setup_screens.dart' show relationLabel;
import '../memories/quick_add.dart';

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
    // Camera / photo widgets add to Kỷ niệm: Cùng nuôi only.
    'canAddMemories': me?.role == MemberRole.coParent,
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

/// The care type a widget tile asked to log (`/today?log=bottle`), or null.
String? widgetLogRequest(Uri uri) {
  final type = uri.queryParameters['log'];
  if (uri.path != Routes.today || type == null) return null;
  return const {'bottle', 'breast', 'sleep', 'diaper'}.contains(type)
      ? type
      : null;
}

/// Mounted under the app: pushes the session and snapshot whenever they change, and on resume
/// sends offline widget logs and re-syncs the Live Activities. A widget tile opens Hôm nay with
/// `?log=<type>`: the same log the Hôm nay tile opens is shown over it (ml, kind, side, time).
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
  GoRouter? _router;

  /// Kept until Hôm nay is showing for a signed-in member (a cold start passes the splash first).
  String? _pendingLog;

  /// The camera / photo widgets (`/memories?add=`), kept until Kỷ niệm shows the same way.
  QuickAdd? _pendingAdd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final launch = Uri.parse(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );
    _pendingLog = widgetLogRequest(launch);
    _pendingAdd = quickAddRequest(launch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(glanceChannelProvider) == null) return;
      final router = ref.read(routerProvider);
      _router = router;
      router.routerDelegate.addListener(_onRoute);
      _onRoute();
    });
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRoute);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onRoute() {
    final router = _router;
    if (router == null || !mounted) return;
    final uri = router.routerDelegate.currentConfiguration.uri;
    final add = quickAddRequest(uri);
    if (add != null) {
      _pendingAdd = add;
      router.go(Routes.memories);
      return;
    }
    final asked = widgetLogRequest(uri);
    if (asked != null) {
      _pendingLog = asked;
      // Drop the query so going back to Hôm nay later does not open it again.
      router.go(Routes.today);
      return;
    }
    _tryPendingLog();
    _tryPendingAdd();
  }

  /// Opens the camera or library once Kỷ niệm shows for a signed-in member; anyone but Cùng
  /// nuôi just stays there (the widget links them to Hôm nay anyway).
  void _tryPendingAdd() {
    final router = _router;
    final add = _pendingAdd;
    if (router == null || add == null || !mounted) return;
    if (router.routerDelegate.currentConfiguration.uri.path !=
        Routes.memories) {
      return;
    }
    final me = ref.read(selectedMembershipProvider);
    if (ref.read(sessionProvider) is! SessionSignedIn || me == null) return;
    _pendingAdd = null;
    if (me.role != MemberRole.coParent) return;
    unawaited(_openAdd(router, add));
  }

  Future<void> _openAdd(GoRouter router, QuickAdd add) async {
    // Like the log sheet: let the palette settle (Night care follows a running sleep).
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(
      ClMotion.gentle + const Duration(milliseconds: 100),
    );
    if (!mounted) return;
    await openQuickAdd(router, ref, add);
  }

  /// Opens the asked log once Hôm nay shows for a signed-in member. Called on route changes and
  /// on every rebuild (session and membership arrive after the link on a cold start).
  void _tryPendingLog() {
    final router = _router;
    final type = _pendingLog;
    if (router == null || type == null || !mounted) return;
    if (router.routerDelegate.currentConfiguration.uri.path != Routes.today) {
      return;
    }
    final me = ref.read(selectedMembershipProvider);
    if (ref.read(sessionProvider) is! SessionSignedIn || me == null) return;
    _pendingLog = null;
    // Người thân only views (the widget hides "+" for them too).
    if (me.role == MemberRole.relative) return;
    unawaited(_openLog(router, me.babyId, type));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(glanceChannelProvider)?.refresh().catchError((Object _) {}),
      );
    }
  }

  /// After a cold start the palette is not settled yet (Night care follows a running sleep
  /// timer, which is still loading); a sheet keeps the theme it opened with, so wait for it.
  Future<void> _openLog(GoRouter router, String babyId, String type) async {
    try {
      await ref
          .read(careTimerProvider((babyId, TimerType.sleep)).future)
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Open anyway.
    }
    // The palette follows the timer a frame later, then the theme cross-fades (ClMotion.gentle).
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(
      ClMotion.gentle + const Duration(milliseconds: 100),
    );
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (!mounted || context == null || !context.mounted) return;
    if (type == 'sleep') {
      unawaited(showSleepChooser(context, ref));
    } else {
      unawaited(openCareLog(context, CareType.values.byName(type)));
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
    if (_pendingLog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryPendingLog());
    }
    if (_pendingAdd != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryPendingAdd());
    }
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
