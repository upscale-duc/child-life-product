import '../engagement/engagement_local.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/navigation.dart' show SafePush;
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/platform/android_channels.dart';
import '../../core/platform/external_apps.dart' show openNotificationSettings;
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../keepsakes/keepsake_nudges.dart';
import '../rhythm/try_reminders.dart';
import '../care/timer_models.dart' show TimerType;
import '../rhythm/wake_check.dart';
import '../rhythm/rhythm_access.dart';
import '../rhythm/personalization_digest.dart';
import '../rhythm/personalization_events.dart';
import '../rhythm/rhythm_local.dart'
    show
        rhythmCheckInOfPayload,
        rhythmEveningNotification,
        rhythmEveningPlanProvider,
        rhythmOfPayload,
        rhythmPlansReadyProvider,
        rhythmStageNotification,
        rhythmStageReminderPlanProvider,
        rhythmWeekOfPayload,
        rhythmWeeklyNotification,
        rhythmWeeklyPlanProvider;
import 'device_identity.dart';
import 'reminder_models.dart';
import 'reminder_repository.dart';
import '../me/me_repository.dart';
import '../notifications/notification_destinations.dart' show untilInApp;

/// One local notification this device should have pending (D-032: once, at due − lead).
@immutable
class LocalReminder {
  const LocalReminder({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime fireAt;
  final String title;
  final String body;

  /// Identifies the reminder for a tap and carries the content, so any edit reschedules.
  final String payload;
}

/// Stable notification id from the reminder id (28 bits of its UUID).
int notificationIdOf(String reminderId) =>
    int.parse(reminderId.substring(3, 10), radix: 16);

String reminderPayload(
  Reminder r,
  DateTime fireAt,
  String title,
  String body,
) => jsonEncode({
  'k': 'reminder',
  'b': r.babyId,
  'r': r.id,
  'at': fireAt.millisecondsSinceEpoch,
  't': title,
  'x': body,
});

/// (babyId, reminderId) from a notification payload, or null for anything else.
(String, String)? reminderOfPayload(String? payload) {
  if (payload == null) return null;
  try {
    final json = jsonDecode(payload);
    if (json is Map && json['k'] == 'reminder') {
      final b = json['b'], r = json['r'];
      if (b is String && r is String) return (b, r);
    }
  } on FormatException {
    return null;
  }
  return null;
}

/// The OS side of reminders: permission and the pending local notifications (R-091, R-092).
abstract class ReminderNotifications {
  Future<void> init(void Function(String? payload) onTap);

  /// The payload of the notification that launched the app, if any.
  Future<String?> launchPayload();

  Future<bool> enabled();

  /// Shows the OS prompt (8c "Bật thông báo"); false when refused or no longer askable.
  Future<bool> request();

  /// Makes the pending reminder notifications exactly [desired].
  Future<void> sync(List<LocalReminder> desired, AppLocalizations l10n);
}

class PluginReminderNotifications implements ReminderNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  /// ENG-00 adapter handoff: cancel only this baby's optional legacy producers.
  /// User-configured Care notifications retain their ids and schedules.
  Future<bool> cancelEngagementLegacy(String babyId, String lane) async {
    if (!_ready) return false;
    final pending = await _plugin.pendingNotificationRequests();
    for (final row in pending) {
      try {
        final data = jsonDecode(row.payload ?? 'null');
        if (data is Map &&
            data['b'] == babyId &&
            ((lane == 'milestone' && data['k'] == 'keepsake') ||
                (lane == 'lumi' && data['k'] == 'personal_day'))) {
          await _plugin.cancel(id: row.id);
        }
      } catch (_) {
        /* Unrelated or legacy malformed payload: do not touch Care. */
      }
    }
    return true;
  }

  @override
  Future<void> init(void Function(String? payload) onTap) async {
    if (_ready) return;
    _ready = true;
    // No permission prompt here: it comes after the first save (R-092).
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(AndroidChannels.icon),
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: (r) => onTap(r.payload),
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? details!.notificationResponse?.payload
        : null;
  }

  @override
  Future<bool> enabled() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> request() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> sync(List<LocalReminder> desired, AppLocalizations l10n) async {
    final pending = await _plugin.pendingNotificationRequests();
    final want = {for (final d in desired) d.id: d};
    final kept = <int>{};
    for (final p in pending) {
      if (want[p.id]?.payload == p.payload) {
        kept.add(p.id);
      } else {
        await _plugin.cancel(id: p.id);
      }
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        AndroidChannels.reminders,
        l10n.notifChannel,
        channelDescription: l10n.notifChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final now = DateTime.now();
    for (final d in desired) {
      if (kept.contains(d.id) || !d.fireAt.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: d.id,
        scheduledDate: tz.TZDateTime.from(d.fireAt, tz.UTC),
        notificationDetails: details,
        // No exact-alarm permission: a few minutes' slack is fine for "Báo trước".
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: d.title,
        body: d.body,
        payload: d.payload,
      );
    }
  }
}

final reminderNotificationsProvider = Provider<ReminderNotifications>(
  (ref) => PluginReminderNotifications(),
);

/// Whether this device may show notifications; null until checked. Re-checked on resume.
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabled, bool?>(NotificationsEnabled.new);

class NotificationsEnabled extends Notifier<bool?> {
  @override
  bool? build() {
    unawaited(refresh());
    return null;
  }

  Future<void> refresh() async {
    try {
      final on = await ref.read(reminderNotificationsProvider).enabled();
      if (ref.mounted) state = on;
    } on Object {
      if (ref.mounted) state = false;
    }
  }

  /// "Bật" wherever notifications are off (EN07, 8d, the rules tab): the system prompt while it
  /// can still show, else system settings, so the tap is never a no-op (NT-3).
  Future<void> turnOn() async {
    if (await request()) return;
    await openNotificationSettings();
  }

  /// The system prompt. Whoever asks (the launch prompt, EN03, 8c), it counts as asked for all
  /// of them: the OS shows its prompt once, so the next "Bật" can only open Settings (NT-3).
  Future<bool> request() async {
    var on = false;
    try {
      on = await ref.read(reminderNotificationsProvider).request();
    } on Object {
      on = false;
    }
    if (ref.mounted) {
      state = on;
      await ref.read(notificationsAskedProvider.notifier).mark();
    }
    return on;
  }
}

const _kAsked = 'reminders.notificationsAsked';
const _kAskedOnLaunch = 'notifications.askedOnLaunch';

/// Whether this install has shown the system notification prompt: one flag for the launch
/// prompt (D-098), EN03 and 8c (NT-3). 8d's card and EN07 then link to Settings (R-092).
/// Installs from before NT-3 kept two flags; either one counts.
final notificationsAskedProvider = NotifierProvider<NotificationsAsked, bool>(
  NotificationsAsked.new,
);

class NotificationsAsked extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return (prefs.getBool(_kAsked) ?? false) ||
        (prefs.getBool(_kAskedOnLaunch) ?? false);
  }

  Future<void> mark() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_kAsked, true);
  }
}

/// D-098: the system notification prompt on the first entry into the app, once per install
/// (a refusal is final for the OS; the Thông báo screen then says they are off). Not when
/// EN03 or 8c already asked.
Future<void> askNotificationsOnLaunch(Ref ref) async {
  if (ref.read(notificationsAskedProvider)) return;
  await ref.read(notificationsAskedProvider.notifier).mark();
  try {
    if (await ref.read(reminderNotificationsProvider).enabled()) return;
  } on Object {
    return;
  }
  await ref.read(notificationsEnabledProvider.notifier).request();
}

/// Runs [askNotificationsOnLaunch] once per app run; watched by the home shell.
final notificationsLaunchAskProvider = FutureProvider<void>(
  askNotificationsOnLaunch,
);

// ---- D-075 #5: "Giờ nhắc việc cả ngày" ----

const _kAllDayMinutes = 'reminders.allDayMinutes';

/// When this person's all-day reminders ring, as minutes after midnight in the baby's zone
/// (default 08:00). Kept on this install like the 8c flag; always shown where it applies
/// (form, 8e), never a silent hard-coded time.
final reminderAllDayTimeProvider = NotifierProvider<ReminderAllDayTime, int>(
  ReminderAllDayTime.new,
);

class ReminderAllDayTime extends Notifier<int> {
  @override
  int build() {
    final v = ref.read(sharedPreferencesProvider).getInt(_kAllDayMinutes);
    return v != null && v >= 0 && v < 24 * 60
        ? v
        : defaultReminderAllDayMinutes;
  }

  Future<void> set(int minutes) async {
    state = minutes;
    await ref.read(sharedPreferencesProvider).setInt(_kAllDayMinutes, minutes);
  }
}
// ---- end D-075 #5 ----

/// Open reminders whose notification lives on this install, across every baby the account can
/// see: the ones put on this device (R-091, D-029) and, since D-075 #5, the ones assigned to
/// the signed-in person (each of their installs schedules its own local notification once it
/// has synced). What [ReminderNotificationSync] keeps scheduled.
final deviceRemindersProvider = Provider<List<Reminder>>((ref) {
  final session = ref.watch(sessionProvider);
  final device = ref.watch(deviceIdentityProvider).value;
  if (session is! SessionSignedIn || device == null) return const [];
  // "Thông báo · Nhắc việc" off (G-056): nothing is scheduled on this account's devices.
  final prefs = ref.watch(notificationPrefsProvider(session.user.uid));
  if (prefs.value?.reminders == false) return const [];
  return [
    for (final m in session.active)
      if (m.role != MemberRole.relative)
        for (final r
            in ref.watch(remindersProvider(m.babyId)).value ??
                const <Reminder>[])
          if (!r.done && r.ringsOn(deviceId: device.id, uid: session.user.uid))
            r,
  ];
});

/// Whether a stream or future the sync reads has answered (a value, even from the cache, or an
/// error). Still loading means "not known yet", never "nothing".
bool loadSettled(AsyncValue<Object?> v) => v.hasValue || v.hasError;

/// Whether everything [deviceRemindersProvider] reads has answered. The sync cancels whatever
/// it is not given, so it waits for this: a cold start that is suspended before Firestore
/// answers (an iOS background launch draws one frame) must not cancel tomorrow's reminders.
final deviceRemindersReadyProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is SessionLoading) return false;
  if (session is! SessionSignedIn) return true;
  if (!loadSettled(ref.watch(deviceIdentityProvider))) return false;
  final prefs = ref.watch(notificationPrefsProvider(session.user.uid));
  if (!loadSettled(prefs)) return false;
  if (prefs.value?.reminders == false) return true;
  for (final m in session.active) {
    if (m.role == MemberRole.relative) continue;
    if (!loadSettled(ref.watch(remindersProvider(m.babyId)))) return false;
    if (!loadSettled(ref.watch(babyProvider(m.babyId)))) return false;
  }
  return true;
});

/// Whether every source of this device's notifications has answered (reminders, milestone
/// nudges, Nhịp lớn lên), so a sync may cancel what is no longer wanted.
final notificationSourcesReadyProvider = Provider.autoDispose<bool>(
  (ref) =>
      ref.watch(deviceRemindersReadyProvider) &&
      ref.watch(nudgePlanReadyProvider) &&
      ref.watch(rhythmPlansReadyProvider) &&
      loadSettled(ref.watch(personalDigestPlanProvider)),
);

/// Keeps this device's reminder notifications in step with Firestore — on start, on every
/// change (create, edit, done, move, delete), when permission is granted and on sign-out (all
/// cancelled) — and opens a reminder when its notification is tapped. Wraps the whole app.
class ReminderNotificationSync extends ConsumerStatefulWidget {
  const ReminderNotificationSync({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ReminderNotificationSync> createState() =>
      _ReminderNotificationSyncState();
}

class _ReminderNotificationSyncState
    extends ConsumerState<ReminderNotificationSync>
    with WidgetsBindingObserver {
  String? _lastSignature;
  var _syncing = false;
  var _again = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final notifications = ref.read(reminderNotificationsProvider);
    unawaited(
      notifications
          .init((payload) => unawaited(_open(payload)))
          .then((_) async {
            await _open(await notifications.launchPayload());
          })
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Settings (8d "Cài đặt").
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(notificationsEnabledProvider.notifier).refresh());
    }
  }

  Future<void> _open(String? payload) async {
    if (payload == null) return;
    // A cold start: the session and the tabs first, else the checks below find no membership
    // yet and the tap was dropped.
    await untilInApp(ref);
    if (!mounted) return;
    // L6 "Bé dậy chưa?": the running sleep timer of that baby, to end it at the right time.
    final wakeBaby = wakeCheckOfPayload(payload);
    if (wakeBaby != null && mounted) {
      final session = ref.read(sessionProvider);
      if (session is! SessionSignedIn ||
          session.membershipFor(wakeBaby) == null) {
        return;
      }
      ref.read(selectedBabyIdProvider.notifier).select(wakeBaby);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(routerProvider)
              .pushSafe('${Routes.timer}/${TimerType.sleep.name}');
        }
      });
      return;
    }
    // Nhịp lớn lên weekly summary (EN07 → EN09): open the week of that baby.
    final weekBaby = rhythmWeekOfPayload(payload);
    if (weekBaby != null && mounted) {
      final session = ref.read(sessionProvider);
      final m = session is SessionSignedIn
          ? session.membershipFor(weekBaby)
          : null;
      if (m == null || !familyCan(m, FamilyAction.historyRead)) return;
      ref.read(selectedBabyIdProvider.notifier).select(weekBaby);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(routerProvider).push(Routes.rhythmWeek);
      });
      return;
    }
    final tried = tryReminderFromPayload(payload);
    if (tried != null && mounted) {
      final session = ref.read(sessionProvider);
      final member = session is SessionSignedIn
          ? session.membershipFor(tried.babyId)
          : null;
      if (member == null) return;
      ref.read(selectedBabyIdProvider.notifier).select(tried.babyId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(routerProvider)
              .push('${Routes.rhythmActivity}/${tried.contentId}');
        }
      });
      return;
    }
    final personalBaby = personalDayFromPayload(payload);
    if (personalBaby != null && mounted) {
      final session = ref.read(sessionProvider);
      final member = session is SessionSignedIn
          ? session.membershipFor(personalBaby)
          : null;
      if (member == null || !familyCan(member, FamilyAction.historyRead)) {
        return;
      }
      ref.read(selectedBabyIdProvider.notifier).select(personalBaby);
      personalEvent(ref, 'digestOpened');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(routerProvider).push(Routes.personalDay);
      });
      return;
    }
    // Nhịp lớn lên evening prompt (NL02c): open the check-in C01 for that baby.
    final checkInBaby = rhythmCheckInOfPayload(payload);
    if (checkInBaby != null && mounted) {
      final session = ref.read(sessionProvider);
      final m = session is SessionSignedIn
          ? session.membershipFor(checkInBaby)
          : null;
      if (m == null || !familyCan(m, FamilyAction.rhythmCheckin)) return;
      ref.read(selectedBabyIdProvider.notifier).select(checkInBaby);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(routerProvider).push(Routes.rhythmCheckIn);
      });
      return;
    }
    // Nhịp lớn lên stage reminder (NL02c): open the overview of that baby.
    final rhythmBaby = rhythmOfPayload(payload);
    if (rhythmBaby != null && mounted) {
      final session = ref.read(sessionProvider);
      if (session is! SessionSignedIn ||
          session.membershipFor(rhythmBaby) == null) {
        return;
      }
      ref.read(selectedBabyIdProvider.notifier).select(rhythmBaby);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(routerProvider).push(Routes.rhythm);
      });
      return;
    }
    // Kỷ niệm 2.0 milestone nudges (D-068 #9): open Thiệp cột mốc on that occasion.
    final nudge = nudgeOfPayload(payload);
    if (nudge != null && mounted) {
      final (babyId, occasion) = nudge;
      final session = ref.read(sessionProvider);
      if (session is! SessionSignedIn ||
          session.membershipFor(babyId) == null) {
        return;
      }
      ref.read(selectedBabyIdProvider.notifier).select(babyId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // D-076 nav: a tap lands wherever the app was, maybe above the tabs.
        if (mounted) {
          ref
              .read(routerProvider)
              .pushSafe('${Routes.milestoneCard}?occasion=${occasion.wire}');
        }
      });
      return;
    }
    final target = reminderOfPayload(payload);
    if (target == null || !mounted) return;
    final (babyId, reminderId) = target;
    final session = ref.read(sessionProvider);
    if (session is! SessionSignedIn || session.membershipFor(babyId) == null) {
      return;
    }
    ref.read(selectedBabyIdProvider.notifier).select(babyId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // D-076 nav: a tap lands wherever the app was, maybe above the tabs.
      if (mounted) {
        ref.read(routerProvider).pushSafe('${Routes.reminders}/$reminderId');
      }
    });
  }

  List<LocalReminder> _desired(AppLocalizations l10n, String locale) {
    final out = <LocalReminder>[];
    final allDayMinutes = ref.read(reminderAllDayTimeProvider);
    for (final r in ref.read(deviceRemindersProvider)) {
      final baby = ref.read(babyProvider(r.babyId)).value;
      final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
      final day = r.dueDay;
      // "Teddy · Thứ Bảy 08:30", or "Teddy · Thứ Bảy · Cả ngày" (D-075 #5).
      final body = l10n.notifBody(
        baby?.nickname ?? '',
        day != null
            ? '${DateFormat('EEEE', locale).format(day)} · ${l10n.reminderAllDay}'
            : DateFormat(
                'EEEE HH:mm',
                locale,
              ).format(inBabyZone(zone, r.dueAt)),
      );
      final fireAt = r.fireAt(zone, allDayMinutes: allDayMinutes);
      out.add(
        LocalReminder(
          id: notificationIdOf(r.id),
          fireAt: fireAt,
          title: r.title,
          body: body,
          payload: reminderPayload(r, fireAt, r.title, body),
        ),
      );
    }
    // Kỷ niệm 2.0 milestone nudges (D-068 #9) share this device's notifications: the sync
    // cancels anything it was not given. Look-back slots handed out now are kept for good.
    try {
      final plan = ref.read(nudgePlanProvider);
      if (plan.newSlots.isNotEmpty) {
        unawaited(ref.read(nudgeStoreProvider).addSlots(plan.newSlots));
      }
      final currentSession = ref.read(sessionProvider);
      for (final n in plan.nudges) {
        if (currentSession is SessionSignedIn &&
            EngagementLocal(
              ref.read(sharedPreferencesProvider),
              currentSession.user.uid,
            ).ownsLegacy('milestone', n.babyId)) {
          continue;
        }
        out.add(nudgeNotification(l10n, n));
      }
    } on Object {
      // Nudges are best effort; reminders are scheduled regardless.
    }
    // Nhịp lớn lên stage reminders (NL02c), best effort too.
    final where = Localizations.localeOf(context);
    for (final p in ref.read(rhythmStageReminderPlanProvider)) {
      out.add(rhythmStageNotification(where, p));
    }
    // The evening check-in prompt (NL02c), skipped once I noted something today.
    for (final p in ref.read(rhythmEveningPlanProvider)) {
      out.add(rhythmEveningNotification(l10n, p));
    }
    // The weekly summary, Sunday 20:30 (EN07), before the person's quiet hours.
    for (final p in ref.read(rhythmWeeklyPlanProvider)) {
      out.add(rhythmWeeklyNotification(l10n, p));
    }
    // P-179: "Mình sẽ thử" at a chosen time, and the next morning's question.
    final tries = ref.read(tryReminderStoreProvider)?.read().values ?? const [];
    out.addAll(tryReminderNotifications(l10n, tries, DateTime.now()));
    final digest = ref.read(personalDigestPlanProvider).value;
    if (digest != null) {
      out.add(
        LocalReminder(
          id: personalDigestNotificationId,
          fireAt: digest.fireAt,
          title: l10n.pv2DigestTitle,
          body: l10n.pv2DigestBody,
          payload: jsonEncode({
            'k': 'personal_day',
            'b': digest.babyId,
            'at': digest.fireAt.toIso8601String(),
          }),
        ),
      );
    }
    // L6 "Bé dậy chưa?" (lumi-plan §7.1): the sleep timers this person started.
    for (final p in ref.read(wakeCheckPlanProvider)) {
      out.add(wakeCheckNotification(l10n, p));
    }
    return out;
  }

  Future<void> _sync() async {
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _again = false;
        if (!mounted) return;
        // Partial inputs would cancel what is still wanted (a 05:57 launch once cancelled a
        // 09:00 "tròn 1 tháng", D-077 #2); the build runs this again once they answer.
        if (!ref.read(notificationSourcesReadyProvider)) return;
        final l10n = AppLocalizations.of(context);
        final locale = Localizations.localeOf(context).toLanguageTag();
        final desired = _desired(l10n, locale);
        final signature = [for (final d in desired) d.payload].join('\n');
        if (signature == _lastSignature) continue;
        await ref.read(reminderNotificationsProvider).sync(desired, l10n);
        if (desired.any((d) => d.id == personalDigestNotificationId)) {
          personalEvent(ref, 'digestScheduled');
        }
        _lastSignature = signature;
      } while (_again);
    } on Object {
      // Scheduling is best effort; the next change or start retries.
      _lastSignature = null;
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(engagementRevisionProvider);
    ref.watch(tryReminderStoreProvider);
    final enabled = ref.watch(notificationsEnabledProvider);
    ref.watch(deviceRemindersProvider);
    for (final r in ref.watch(deviceRemindersProvider)) {
      ref.watch(babyProvider(r.babyId));
    }
    ref.watch(reminderAllDayTimeProvider);
    ref.watch(nudgePlanProvider);
    ref.watch(rhythmStageReminderPlanProvider);
    ref.watch(rhythmEveningPlanProvider);
    ref.watch(rhythmWeeklyPlanProvider);
    ref.watch(personalDigestPlanProvider);
    ref.watch(wakeCheckPlanProvider);
    final ready = ref.watch(notificationSourcesReadyProvider);
    if (enabled == true && ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_sync()));
    } else {
      _lastSignature = null;
    }
    return widget.child;
  }
}
