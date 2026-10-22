import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../engagement/engagement_widgets.dart';
import '../home/home_shell.dart';
import '../reminders/rule_notifications.dart';
import '../spending/spending_models.dart' show SpendingAccess;
import '../vaccines/vaccine_notifications.dart';

/// Unified notification platform (P-174, docs/notifications/): the app's mirror of the semantic
/// destination registry in packages/contracts/src/notification-platform.ts. A contracts test
/// reads this file and expects every destination id there, quoted, so keep the ids literal.
///
/// One resolver ([openNotification]) serves an inbox tap (EN06) and a push open: it checks the
/// session, the baby's membership and the destination's permission, validates the params, opens
/// the screen, and walks the fallback chain (always ending at INBOX) when it cannot.

// ---------- Registry ----------

/// What the app checks before it navigates (the server checked again when it wrote the row).
enum DestinationPermission {
  signedIn,

  /// Current member of the baby the row names.
  member,

  /// Member who may read the baby's care (coParent, caregiver; relatives with daily care).
  careRead,

  /// Member who may see family Memories (coParent, relative).
  memoriesRead,

  /// coParent of the baby.
  coParent,

  /// The engagement link is re-authorised by `actOnEngagement` on the server.
  engagementServer,
}

@immutable
class DestinationParam {
  const DestinationParam(this.key, this.pattern, {this.required = true});
  final String key;
  final String pattern;
  final bool required;
}

@immutable
class NotificationDestination {
  const NotificationDestination({
    required this.id,
    required this.params,
    required this.permission,
    required this.fallback,
  });
  final String id;
  final List<DestinationParam> params;
  final DestinationPermission permission;

  /// Where the app goes when the target is gone, not allowed or the app is too old.
  final String? fallback;
}

const _babyId = DestinationParam('babyId', r'^[A-Za-z0-9_-]{1,128}$');
const _engagementId = DestinationParam('engagementId', r'^[a-f0-9]{64}$');
const _anyId = r'^[A-Za-z0-9_-]{1,128}$';

const _registry = <NotificationDestination>[
  NotificationDestination(
    id: 'CARE_RULE_REMINDER',
    params: [
      _babyId,
      DestinationParam('ruleId', _anyId),
      DestinationParam('dueAt', r'^\d{10,14}$', required: false),
    ],
    permission: DestinationPermission.careRead,
    fallback: 'CARE_REMINDERS',
  ),
  NotificationDestination(
    id: 'CARE_REMINDERS',
    params: [_babyId],
    permission: DestinationPermission.careRead,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'CARE_VACCINES',
    params: [
      _babyId,
      DestinationParam('date', r'^\d{4}-\d{2}-\d{2}$', required: false),
    ],
    permission: DestinationPermission.careRead,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'SPENDING',
    params: [_babyId],
    permission: DestinationPermission.coParent,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'SPENDING_IMPORT',
    params: [_babyId, DestinationParam('importId', r'^im_[a-f0-9]{32}$')],
    permission: DestinationPermission.coParent,
    fallback: 'SPENDING',
  ),
  NotificationDestination(
    id: 'MEMORIES',
    params: [_babyId],
    permission: DestinationPermission.member,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'MEMORIES_ALBUM',
    params: [_babyId, DestinationParam('albumId', _anyId)],
    permission: DestinationPermission.memoriesRead,
    fallback: 'MEMORIES',
  ),
  NotificationDestination(
    id: 'MEMORIES_STORY',
    params: [_babyId, DestinationParam('storyId', _anyId)],
    permission: DestinationPermission.memoriesRead,
    fallback: 'MEMORIES',
  ),
  NotificationDestination(
    id: 'MEMORIES_VIDEO_JOB',
    params: [_babyId, DestinationParam('jobId', r'^ksj_[a-f0-9]{32}$')],
    permission: DestinationPermission.member,
    fallback: 'MEMORIES',
  ),
  NotificationDestination(
    id: 'MEMORIES_PENDING_REVIEW',
    params: [_babyId, _engagementId],
    permission: DestinationPermission.engagementServer,
    fallback: 'MEMORIES',
  ),
  NotificationDestination(
    id: 'MEMORIES_KEEPSAKE_SUGGESTION',
    params: [_babyId, _engagementId],
    permission: DestinationPermission.engagementServer,
    fallback: 'MEMORIES',
  ),
  NotificationDestination(
    id: 'MEMORIES_WEEKLY_RECAP',
    params: [_babyId, _engagementId],
    permission: DestinationPermission.engagementServer,
    fallback: 'MEMORIES',
  ),
  NotificationDestination(
    id: 'FAMILY_MESSAGES',
    params: [_babyId],
    permission: DestinationPermission.coParent,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'FAMILY_SHARED_CONTENT',
    params: [_babyId, _engagementId],
    permission: DestinationPermission.engagementServer,
    fallback: 'MEMORIES',
  ),
  NotificationDestination(
    id: 'FAMILY_STORAGE',
    params: [],
    permission: DestinationPermission.signedIn,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'FAMILY_MEMBERS',
    params: [_babyId],
    permission: DestinationPermission.member,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'LUMI_INSIGHT',
    params: [_babyId, _engagementId],
    permission: DestinationPermission.engagementServer,
    fallback: 'INBOX',
  ),
  NotificationDestination(
    id: 'INBOX',
    params: [],
    permission: DestinationPermission.signedIn,
    fallback: null,
  ),
];

final Map<String, NotificationDestination> notificationDestinations = {
  for (final d in _registry) d.id: d,
};

const inboxDestination = 'INBOX';

/// Params of [destination] taken from [data]; null when a required one is missing or malformed
/// (or the destination is unknown to this version).
Map<String, String>? destinationParams(
  String destination,
  Map<String, String> data,
) {
  final def = notificationDestinations[destination];
  if (def == null) return null;
  final out = <String, String>{};
  for (final p in def.params) {
    final v = data[p.key];
    if (v == null || v.isEmpty) {
      if (p.required) return null;
      continue;
    }
    if (!RegExp(p.pattern).hasMatch(v)) return null;
    out[p.key] = v;
  }
  return out;
}

/// The chain the app walks when a destination cannot open: itself, its fallback, … INBOX.
List<String> destinationChain(String id) {
  final chain = <String>[];
  String? next = notificationDestinations.containsKey(id)
      ? id
      : inboxDestination;
  while (next != null && !chain.contains(next)) {
    chain.add(next);
    next = notificationDestinations[next]?.fallback;
  }
  if (chain.last != inboxDestination) chain.add(inboxDestination);
  return chain;
}

// ---------- Catalog mirror (kind → chip, kind → default destination) ----------

/// Chips of EN06: Tất cả · Kỷ niệm · Gia đình · Chăm sóc · Khác.
enum InboxGroup { memories, family, care, other }

/// `notificationTypes[kind].group` in the contract.
const notificationKindGroups = <String, InboxGroup>{
  'reminderRule': InboxGroup.care,
  'vaccine': InboxGroup.care,
  'spending': InboxGroup.care,
  'memories': InboxGroup.memories,
  'shared': InboxGroup.memories,
  'album': InboxGroup.memories,
  'story': InboxGroup.memories,
  'message': InboxGroup.family,
  'storage': InboxGroup.family,
  'storageGranted': InboxGroup.family,
  'keepsakeVideo': InboxGroup.memories,
  'keepsakeVideoFailed': InboxGroup.memories,
  'rhythm': InboxGroup.other,
  'stage': InboxGroup.other,
  'milestone': InboxGroup.other,
  'article': InboxGroup.other,
  'weeklySummary': InboxGroup.memories,
  'photoSuggestion': InboxGroup.memories,
  'keepsakePrompt': InboxGroup.memories,
  'familyActivity': InboxGroup.family,
  // D-092: membership events.
  'memberJoined': InboxGroup.family,
  'inviteDeclined': InboxGroup.family,
  'roleChanged': InboxGroup.family,
  'memberRemoved': InboxGroup.family,
  'test': InboxGroup.other,
};

/// `notificationTypes[kind].destination` in the contract.
const notificationKindDestinations = <String, String>{
  'reminderRule': 'CARE_RULE_REMINDER',
  'vaccine': 'CARE_VACCINES',
  'spending': 'SPENDING',
  'memories': 'MEMORIES',
  'shared': 'MEMORIES',
  'album': 'MEMORIES_ALBUM',
  'story': 'MEMORIES_STORY',
  'message': 'FAMILY_MESSAGES',
  'storage': 'FAMILY_STORAGE',
  'storageGranted': 'FAMILY_STORAGE',
  'keepsakeVideo': 'MEMORIES_VIDEO_JOB',
  'keepsakeVideoFailed': 'MEMORIES_VIDEO_JOB',
  'rhythm': 'LUMI_INSIGHT',
  'stage': 'INBOX',
  'milestone': 'INBOX',
  'article': 'INBOX',
  'weeklySummary': 'MEMORIES_WEEKLY_RECAP',
  'photoSuggestion': 'MEMORIES_PENDING_REVIEW',
  'keepsakePrompt': 'MEMORIES_KEEPSAKE_SUGGESTION',
  'familyActivity': 'FAMILY_SHARED_CONTENT',
  'memberJoined': 'FAMILY_MEMBERS',
  'inviteDeclined': 'FAMILY_MEMBERS',
  'roleChanged': 'FAMILY_MEMBERS',
  // The removed person no longer follows the baby: the row (and its push) opens the inbox.
  'memberRemoved': 'INBOX',
  'test': 'INBOX',
};

/// The app's chip for [kind]; unknown kinds (a newer server) show under "Khác".
InboxGroup inboxGroupOf(String kind) =>
    notificationKindGroups[kind] ?? InboxGroup.other;

/// The chip of a row: the server's `group` when this version knows it, else the kind's.
InboxGroup inboxGroupFor(String kind, String? group) =>
    InboxGroup.values.asNameMap()[group] ?? inboxGroupOf(kind);

/// The destination a row opens, from what the producer put in `data` (legacy rows included).
String destinationFor(String kind, Map<String, String> data) {
  final explicit = data['destination'];
  if (explicit != null && notificationDestinations.containsKey(explicit)) {
    return explicit;
  }
  if (kind == 'spending' && (data['importId'] ?? '').isNotEmpty) {
    return 'SPENDING_IMPORT';
  }
  if (kind == 'album' &&
      data['sourceCollection'] == 'albums' &&
      (data['sourceId'] ?? '').isNotEmpty) {
    return 'MEMORIES_ALBUM';
  }
  if (kind == 'story' &&
      data['sourceCollection'] == 'stories' &&
      (data['sourceId'] ?? '').isNotEmpty) {
    return 'MEMORIES_STORY';
  }
  if ((kind == 'keepsakeVideo' || kind == 'keepsakeVideoFailed') &&
      (data['jobId'] ?? '').isEmpty &&
      _legacyJobId(data) == null) {
    return 'MEMORIES';
  }
  return notificationKindDestinations[kind] ?? inboxDestination;
}

/// Before `jobId`, the keepsake notice id was `keepsake_<jobId>(_failed_n)`.
String? _legacyJobId(Map<String, String> data) {
  final notice = data['noticeId'];
  if (notice == null || !notice.startsWith('keepsake_')) return null;
  return notice.substring('keepsake_'.length).split('_failed').first;
}

// ---------- One notification to open ----------

enum NotificationSurface { push, inbox }

enum NotificationOpenOutcome { navigated, fallback, unavailable }

const _inboxIdPattern = r'^n_[A-Za-z0-9_-]{6,120}$';

/// What a push or an inbox row carries: the kind, the baby, ids only (R-120), and since P-174
/// the destination. Legacy ids are mapped onto the registry's param names.
@immutable
class NotificationTarget {
  NotificationTarget._(this.kind, this.babyId, Map<String, String> data)
    : data = Map.unmodifiable(data);

  factory NotificationTarget({
    required String kind,
    String? babyId,
    Map<String, String> data = const {},
    String? destination,
    String? inboxId,
  }) {
    final out = <String, String>{...data, 'kind': kind};
    if (babyId != null) out['babyId'] = babyId;
    if (destination != null) out['destination'] = destination;
    if (inboxId != null) out['inboxId'] = inboxId;
    // Rows written before P-174 name the album / story by its source, the job by the notice.
    final source = out['sourceId'];
    if (source != null) {
      if (out['sourceCollection'] == 'albums') out['albumId'] ??= source;
      if (out['sourceCollection'] == 'stories') out['storyId'] ??= source;
    }
    if (kind == 'keepsakeVideo' || kind == 'keepsakeVideoFailed') {
      final legacy = _legacyJobId(out);
      if (legacy != null) out['jobId'] ??= legacy;
    }
    return NotificationTarget._(kind, out['babyId'], out);
  }

  /// A push's `data` (strings only are kept).
  factory NotificationTarget.fromPush(Map<String, dynamic> data) =>
      NotificationTarget(
        kind: data['kind'] is String ? data['kind'] as String : '',
        data: {
          for (final e in data.entries)
            if (e.value is String) e.key: e.value as String,
        },
      );

  final String kind;
  final String? babyId;
  final Map<String, String> data;

  String get destination => destinationFor(kind, data);

  String? get inboxId {
    final id = data['inboxId'];
    return id != null && RegExp(_inboxIdPattern).hasMatch(id) ? id : null;
  }

  String? get engagementId {
    final id = data['engagementId'];
    return id != null && RegExp(_engagementId.pattern).hasMatch(id) ? id : null;
  }
}

// ---------- Open reporting ----------

/// `recordNotificationOpen` (P-174): where an open got. Fire-and-forget; ids never logged.
abstract class NotificationOpenReporter {
  Future<void> record({
    required String inboxId,
    required NotificationSurface surface,
    required NotificationOpenOutcome outcome,
    String? destination,
  });
}

class CallableNotificationOpenReporter implements NotificationOpenReporter {
  CallableNotificationOpenReporter(this._ref);
  final Ref _ref;

  @override
  Future<void> record({
    required String inboxId,
    required NotificationSurface surface,
    required NotificationOpenOutcome outcome,
    String? destination,
  }) async {
    try {
      await _ref
          .read(functionsProvider)
          .httpsCallable('recordNotificationOpen')
          .call<Object?>({
            'inboxId': inboxId,
            'surface': surface.name,
            'outcome': outcome.name,
            'destination': ?destination,
          })
          .timeout(const Duration(seconds: 15));
    } on Object {
      // Offline, an older server or another account's row: the open is simply not counted.
    }
  }
}

final notificationOpenReporterProvider = Provider<NotificationOpenReporter>(
  CallableNotificationOpenReporter.new,
);

/// Opens an engagement link (ENG); the server re-authorises it. Swappable in tests.
typedef EngagementOpener = Future<bool> Function(WidgetRef ref, String id);

final notificationEngagementOpenerProvider = Provider<EngagementOpener>(
  (ref) =>
      (widgetRef, id) => openEngagement(widgetRef, id, surface: 'notification'),
);

// ---------- Resolver ----------

/// Opens [target] from [surface]: the destination when this person may see it, else the first
/// link of its fallback chain they may (with a toast), else nothing. INBOX from the inbox is
/// where they already are. Records the open when the row's id is known. [launchAction] gives
/// the lock-screen action a care push was opened with (1f / VX 8). [toaster] and [l10n] (taken
/// before any await by a screen) default to the root navigator's.
Future<NotificationOpenOutcome> openNotification(
  WidgetRef ref,
  NotificationTarget target, {
  required NotificationSurface surface,
  Future<String?> Function()? launchAction,
  ClToaster? toaster,
  AppLocalizations? l10n,
}) async {
  // INBOX needs no baby (a removed member's row names one they no longer follow, D-092).
  if (surface == NotificationSurface.push) {
    await _settle(
      ref,
      target.destination == inboxDestination ? null : target.babyId,
    );
  }
  final session = ref.read(sessionProvider);
  if (session is! SessionSignedIn) {
    return NotificationOpenOutcome.unavailable;
  }
  // Read before any navigation: an inbox row's screen may be gone once a destination opens.
  final router = ref.read(routerProvider);
  final reporter = ref.read(notificationOpenReporterProvider);
  final opener = ref.read(notificationEngagementOpenerProvider);
  final requested = target.destination;
  final chain = destinationChain(requested);
  var engagementFailed = false;
  String? landed;
  var index = -1;

  // An engagement link whose kind maps elsewhere (a row written before P-174): the server
  // decides where it goes.
  final engagementId = target.engagementId;
  final requestedDef = notificationDestinations[requested]!;
  if (engagementId != null &&
      requestedDef.permission != DestinationPermission.engagementServer &&
      !target.data.containsKey('destination') &&
      _babyAllowed(session, target.babyId)) {
    if (await opener(ref, engagementId)) {
      _report(
        reporter,
        target,
        surface,
        NotificationOpenOutcome.navigated,
        null,
      );
      return NotificationOpenOutcome.navigated;
    }
    engagementFailed = true;
  }

  for (var i = 0; i < chain.length; i++) {
    final id = chain[i];
    final opened = await _tryOpen(
      ref,
      router,
      opener,
      id,
      target,
      session,
      surface: surface,
      first: i == 0,
      launchAction: launchAction,
    );
    if (opened == _Opened.engagementFailed) engagementFailed = true;
    if (opened == _Opened.yes) {
      landed = id;
      index = i;
      break;
    }
  }

  final NotificationOpenOutcome outcome;
  if (landed == null) {
    outcome = NotificationOpenOutcome.unavailable;
  } else if (index == 0 && !engagementFailed) {
    outcome = NotificationOpenOutcome.navigated;
  } else if (landed == inboxDestination) {
    outcome = NotificationOpenOutcome.unavailable;
  } else {
    outcome = NotificationOpenOutcome.fallback;
  }
  _report(reporter, target, surface, outcome, landed);
  if (outcome != NotificationOpenOutcome.navigated) {
    _toast(
      router,
      toaster,
      l10n,
      (s) => engagementFailed && surface == NotificationSurface.push
          ? s.engExpired
          : outcome == NotificationOpenOutcome.fallback
          ? s.ntOpenedNearest
          : s.ntGone,
    );
  }
  return outcome;
}

/// A push can open the app before the session (or a just-joined baby) has loaded: wait for it
/// a little, as the rule reminder sheet always did.
Future<void> _settle(WidgetRef ref, String? babyId) async {
  for (var i = 0; i < 40; i++) {
    final session = ref.read(sessionProvider);
    final ready = switch (session) {
      SessionLoading() => false,
      SessionSignedIn() =>
        babyId == null || session.membershipFor(babyId) != null,
      _ => true,
    };
    if (ready) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

bool _babyAllowed(SessionSignedIn session, String? babyId) =>
    babyId == null || session.membershipFor(babyId) != null;

void _report(
  NotificationOpenReporter reporter,
  NotificationTarget target,
  NotificationSurface surface,
  NotificationOpenOutcome outcome,
  String? landed,
) {
  final inboxId = target.inboxId;
  if (inboxId == null) return;
  try {
    unawaited(
      reporter
          .record(
            inboxId: inboxId,
            surface: surface,
            outcome: outcome,
            destination: landed,
          )
          .catchError((Object _) {}),
    );
  } on Object {
    // Never blocks or breaks navigation.
  }
}

void _toast(
  GoRouter router,
  ClToaster? toaster,
  AppLocalizations? l10n,
  String Function(AppLocalizations l10n) message,
) {
  try {
    final context = router.routerDelegate.navigatorKey.currentContext;
    final strings =
        l10n ?? (context != null ? AppLocalizations.of(context) : null);
    final to = toaster ?? (context != null ? ClToaster.of(context) : null);
    if (strings == null || to == null) return;
    to.show(message: message(strings));
  } on Object {
    // No navigator yet (cold start): nothing to show on.
  }
}

enum _Opened { yes, no, engagementFailed }

Membership? _member(SessionSignedIn session, Map<String, String> params) {
  final babyId = params['babyId'];
  return babyId == null ? null : session.membershipFor(babyId);
}

bool _permitted(
  String id,
  DestinationPermission permission,
  SessionSignedIn session,
  Map<String, String> params,
) {
  if (permission == DestinationPermission.signedIn) return true;
  final m = _member(session, params);
  if (m == null) return false;
  return switch (permission) {
    DestinationPermission.signedIn => true,
    DestinationPermission.member => true,
    // The server re-authorises the link; here only the baby must be this person's.
    DestinationPermission.engagementServer => true,
    DestinationPermission.careRead => m.canViewToday,
    DestinationPermission.memoriesRead =>
      m.role == MemberRole.coParent || m.role == MemberRole.relative,
    // Chi tiêu also opens for members a Cùng nuôi gave a spending right (8l, D-055): an
    // import's result goes to whoever imported.
    DestinationPermission.coParent =>
      m.role == MemberRole.coParent ||
          ((id == 'SPENDING' || id == 'SPENDING_IMPORT') &&
              SpendingAccess.of(m).any),
  };
}

Future<_Opened> _tryOpen(
  WidgetRef ref,
  GoRouter router,
  EngagementOpener opener,
  String id,
  NotificationTarget target,
  SessionSignedIn session, {
  required NotificationSurface surface,
  required bool first,
  Future<String?> Function()? launchAction,
}) async {
  final def = notificationDestinations[id];
  if (def == null) return _Opened.no;
  // The row names a baby this person no longer follows (or another account's): only INBOX.
  if (id != inboxDestination && !_babyAllowed(session, target.babyId)) {
    return _Opened.no;
  }
  final params = destinationParams(id, target.data);
  if (params == null) return _Opened.no;
  if (!_permitted(id, def.permission, session, params)) return _Opened.no;
  final babyId = params['babyId'];
  void select() {
    if (babyId != null && ref.read(selectedBabyIdProvider) != babyId) {
      ref.read(selectedBabyIdProvider.notifier).select(babyId);
    }
  }

  switch (id) {
    case 'CARE_RULE_REMINDER':
      final action = await launchAction?.call();
      await openRulePush(ref, (
        babyId: babyId!,
        ruleId: params['ruleId']!,
        type: target.data['type'] ?? 'feed',
      ), action: action);
    case 'CARE_REMINDERS':
      select();
      router.go(Routes.reminders);
    case 'CARE_VACCINES':
      final push = vaccinePushOf({...target.data, 'kind': 'vaccine'});
      if (push != null) {
        final action = await launchAction?.call();
        openVaccinePush(ref, push, action: action);
      } else {
        select();
        router.go(Routes.vaccines);
      }
    case 'SPENDING':
      select();
      // Chi tiêu lives in Tiện ích (450:6597).
      router
        ..go(Routes.utilities)
        ..push(Routes.spending);
    case 'SPENDING_IMPORT':
      select();
      // Nhập chi tiêu (D-060): the import's result.
      router
        ..go(Routes.utilities)
        ..push(Routes.spending)
        ..push('${Routes.spendingImport}/${params['importId']}');
    case 'MEMORIES':
      select();
      router.go(Routes.memories);
    case 'MEMORIES_ALBUM':
      select();
      router
        ..go(Routes.memories)
        ..push('${Routes.memories}/album/${params['albumId']}');
    case 'MEMORIES_STORY':
      select();
      router
        ..go(Routes.memories)
        ..push('${Routes.story}/${params['storyId']}');
    case 'MEMORIES_VIDEO_JOB':
      // Video kỷ niệm ready or not made (D-068 #4): MM09 / MM14 for that job.
      select();
      router
        ..go(Routes.memories)
        ..push('${Routes.memoryStoryJob}/${params['jobId']}?baby=$babyId');
    case 'MEMORIES_PENDING_REVIEW' ||
        'MEMORIES_KEEPSAKE_SUGGESTION' ||
        'MEMORIES_WEEKLY_RECAP' ||
        'FAMILY_SHARED_CONTENT' ||
        'LUMI_INSIGHT':
      final opened = await opener(ref, params['engagementId']!);
      if (!opened) return _Opened.engagementFailed;
    case 'FAMILY_MESSAGES':
      select();
      if (surface == NotificationSurface.inbox) {
        router.push(Routes.messages);
      } else {
        router
          ..go(Routes.today)
          ..push(Routes.messages);
      }
    case 'FAMILY_MEMBERS':
      // Gia đình lives in Tiện ích.
      select();
      router.go(Routes.family);
    case 'FAMILY_STORAGE':
      if (surface == NotificationSurface.inbox) {
        router.push(Routes.meStorage);
      } else {
        router
          ..go(Routes.today)
          ..push(Routes.meStorage);
      }
    case 'INBOX':
      // From the inbox: already there.
      if (surface == NotificationSurface.push) {
        if (first) {
          router.push(Routes.notifications);
        } else {
          router.go(Routes.notifications);
        }
      }
    default:
      return _Opened.no;
  }
  return _Opened.yes;
}
