import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';

/// FB5 "Khoảnh khắc vui · hỏi đánh giá" (477:6608, D-065): only the system prompt
/// (SKStoreReviewController / Play In-App Review), asked right after a happy moment. Never a
/// custom "Bạn có thích app không?" first: sending happy people to the store and unhappy ones to
/// Góp ý is review gating, against App Store and Google Play policy. The OS decides whether the
/// prompt shows (iOS at most 3 times in 365 days), so a request is all the app can know.
enum ReviewTrigger {
  /// A milestone saved ("Đã lưu mốc đáng nhớ").
  milestone,

  /// A memory posted.
  memory,

  /// Seven days in a row with a log each day, completed by this log.
  fullWeek,

  /// The first reaction to a memory someone in the family shared.
  firstReaction,
}

/// What stops a prompt, in the order checked (the first one found is kept for tests).
enum ReviewBlock {
  tooNew,
  fewLogs,
  fewActiveDays,
  night,
  timerRunning,
  firstAid,
  afterError,
  justUpdated,
  afterBugReport,
  sameVersion,
  tooSoon,
}

abstract final class ReviewRules {
  static const minDaysInstalled = 7;
  static const minLogs = 10;
  static const minActiveDays = 3;
  static const activeWindowDays = 7;
  static const quietAfterBugReportDays = 30;
  static const minDaysBetween = 120;
  static const fullWeekDays = 7;
}

/// The moment of a trigger, read from the app at that time.
class ReviewContext {
  const ReviewContext({
    required this.now,
    required this.version,
    this.night = false,
    this.timerRunning = false,
    this.onFirstAid = false,
    this.afterError = false,
  });

  final DateTime now;

  /// The installed version ("1.0.3"): one request per version.
  final String version;

  /// Night care on screen.
  final bool night;
  final bool timerRunning;
  final bool onFirstAid;

  /// An error or a crash this session or on the last launch.
  final bool afterError;
}

/// Kept on this install (SharedPreferences): no server copy, nothing about the child.
class ReviewState {
  const ReviewState({
    required this.installedAt,
    this.logs = 0,
    this.activeDays = const [],
    this.logDays = const [],
    this.lastPromptAt,
    this.lastPromptVersion,
    this.bugReportAt,
    this.reacted = false,
    this.fullWeekUntil,
    this.lastVersion,
    this.updatedAt,
  });

  /// First launch with this rule set (an install that predates it starts counting then).
  final DateTime installedAt;

  /// Care logs written on this install.
  final int logs;

  /// Local days ("2026-10-13") the app was opened, newest last, at most 14.
  final List<String> activeDays;

  /// Local days with a log written here, newest last, at most 14.
  final List<String> logDays;
  final DateTime? lastPromptAt;
  final String? lastPromptVersion;

  /// The last "Báo lỗi" sent from FB2.
  final DateTime? bugReportAt;

  /// The first reaction already counted.
  final bool reacted;

  /// The last day of the full week already counted, so one streak triggers once.
  final String? fullWeekUntil;

  /// The version seen at the last launch; a different one means the app was just updated.
  final String? lastVersion;

  /// When [lastVersion] changed: the session that follows an update is left alone.
  final DateTime? updatedAt;

  ReviewState copyWith({
    int? logs,
    List<String>? activeDays,
    List<String>? logDays,
    DateTime? lastPromptAt,
    String? lastPromptVersion,
    DateTime? bugReportAt,
    bool? reacted,
    String? fullWeekUntil,
    String? lastVersion,
    DateTime? updatedAt,
  }) => ReviewState(
    installedAt: installedAt,
    logs: logs ?? this.logs,
    activeDays: activeDays ?? this.activeDays,
    logDays: logDays ?? this.logDays,
    lastPromptAt: lastPromptAt ?? this.lastPromptAt,
    lastPromptVersion: lastPromptVersion ?? this.lastPromptVersion,
    bugReportAt: bugReportAt ?? this.bugReportAt,
    reacted: reacted ?? this.reacted,
    fullWeekUntil: fullWeekUntil ?? this.fullWeekUntil,
    lastVersion: lastVersion ?? this.lastVersion,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'installedAt': installedAt.millisecondsSinceEpoch,
    'logs': logs,
    'activeDays': activeDays,
    'logDays': logDays,
    'lastPromptAt': lastPromptAt?.millisecondsSinceEpoch,
    'lastPromptVersion': lastPromptVersion,
    'bugReportAt': bugReportAt?.millisecondsSinceEpoch,
    'reacted': reacted,
    'fullWeekUntil': fullWeekUntil,
    'lastVersion': lastVersion,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };

  static ReviewState? fromJson(Object? json) {
    if (json is! Map) return null;
    DateTime? at(Object? v) =>
        v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    List<String> days(Object? v) =>
        v is List ? v.whereType<String>().toList() : [];
    final installed = at(json['installedAt']);
    if (installed == null) return null;
    return ReviewState(
      installedAt: installed,
      logs: json['logs'] is int ? json['logs'] as int : 0,
      activeDays: days(json['activeDays']),
      logDays: days(json['logDays']),
      lastPromptAt: at(json['lastPromptAt']),
      lastPromptVersion: json['lastPromptVersion'] as String?,
      bugReportAt: at(json['bugReportAt']),
      reacted: json['reacted'] == true,
      fullWeekUntil: json['fullWeekUntil'] as String?,
      lastVersion: json['lastVersion'] as String?,
      updatedAt: at(json['updatedAt']),
    );
  }
}

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

List<String> _withDay(List<String> days, String day) {
  if (days.isNotEmpty && days.last == day) return days;
  final next = [...days.where((d) => d != day), day]..sort();
  return next.length > 14 ? next.sublist(next.length - 14) : next;
}

/// The last [n] local days up to [now], oldest first.
List<String> _lastDays(DateTime now, int n) => [
  for (var i = n - 1; i >= 0; i--)
    dayKey(DateTime(now.year, now.month, now.day - i)),
];

/// The eligibility part of the rules, from this install's own record only.
ReviewBlock? eligibilityBlock(ReviewState s, DateTime now) {
  if (now.difference(s.installedAt).inDays < ReviewRules.minDaysInstalled) {
    return ReviewBlock.tooNew;
  }
  if (s.logs < ReviewRules.minLogs) return ReviewBlock.fewLogs;
  final window = _lastDays(now, ReviewRules.activeWindowDays).toSet();
  if (s.activeDays.where(window.contains).length < ReviewRules.minActiveDays) {
    return ReviewBlock.fewActiveDays;
  }
  return null;
}

/// The decision for a trigger: [eligible] (eligibility and the "never" rules pass) and
/// [request] (the frequency allows it too). Pure, so every rule is unit-tested.
({bool eligible, bool request, ReviewBlock? block}) decideReview(
  ReviewState s,
  ReviewContext c,
) {
  ({bool eligible, bool request, ReviewBlock? block}) no(ReviewBlock b) =>
      (eligible: false, request: false, block: b);
  final now = c.now;
  final eligibility = eligibilityBlock(s, now);
  if (eligibility != null) return no(eligibility);
  if (c.night) return no(ReviewBlock.night);
  if (c.timerRunning) return no(ReviewBlock.timerRunning);
  if (c.onFirstAid) return no(ReviewBlock.firstAid);
  if (c.afterError) return no(ReviewBlock.afterError);
  final updated = s.updatedAt;
  if (updated != null && now.difference(updated) < const Duration(hours: 24)) {
    return no(ReviewBlock.justUpdated);
  }
  final bug = s.bugReportAt;
  if (bug != null &&
      now.difference(bug).inDays < ReviewRules.quietAfterBugReportDays) {
    return no(ReviewBlock.afterBugReport);
  }
  ({bool eligible, bool request, ReviewBlock? block}) held(ReviewBlock b) =>
      (eligible: true, request: false, block: b);
  if (s.lastPromptVersion == c.version) return held(ReviewBlock.sameVersion);
  final last = s.lastPromptAt;
  if (last != null &&
      now.difference(last).inDays < ReviewRules.minDaysBetween) {
    return held(ReviewBlock.tooSoon);
  }
  return (eligible: true, request: true, block: null);
}

/// The system prompt and the first-party counters (P-137: aggregate only, no SDK).
class ReviewPlatform {
  const ReviewPlatform({required this.request, required this.track});

  /// Asks the OS; it may show nothing.
  final Future<void> Function() request;

  /// `reviewPromptEligible` / `reviewPromptRequested`.
  final Future<void> Function(String event) track;
}

/// The session's own signals: an error or a crash on the last launch (rules "never after an
/// error / crash"). Set from bootstrap's error handlers and from failed writes.
abstract final class ReviewSession {
  static bool afterError = false;
}

const _kState = 'review.state';

/// FB5's rules on this install. Callers report what happened ([opened], [logged],
/// [bugReported]) and the happy moments ([trigger]); [contextOf] reads the app at that moment.
class ReviewPrompter {
  ReviewPrompter(this._prefs, this._platform, this._contextOf);

  final SharedPreferences _prefs;
  final ReviewPlatform _platform;
  final ReviewContext Function() _contextOf;

  ReviewState _read(DateTime now) {
    final raw = _prefs.getString(_kState);
    ReviewState? state;
    if (raw != null) {
      try {
        state = ReviewState.fromJson(jsonDecode(raw));
      } on FormatException {
        state = null;
      }
    }
    return state ?? ReviewState(installedAt: now);
  }

  Future<void> _write(ReviewState s) =>
      _prefs.setString(_kState, jsonEncode(s.toJson()));

  ReviewState get state => _read(DateTime.now());

  /// The app came to the foreground: an active day, and the version (an update starts a quiet
  /// day).
  Future<void> opened(DateTime now, String version) async {
    final s = _read(now);
    final changed = s.lastVersion != null && s.lastVersion != version;
    await _write(
      s.copyWith(
        activeDays: _withDay(s.activeDays, dayKey(now)),
        lastVersion: version,
        updatedAt: changed ? now : null,
      ),
    );
  }

  /// A care log written here; a seventh day in a row is a happy moment.
  Future<void> logged(DateTime now) async {
    final s = _read(now);
    final today = dayKey(now);
    final next = s.copyWith(
      logs: s.logs + 1,
      logDays: _withDay(s.logDays, today),
      activeDays: _withDay(s.activeDays, today),
    );
    final week = _lastDays(now, ReviewRules.fullWeekDays);
    final full =
        week.every(next.logDays.contains) &&
        (s.fullWeekUntil == null || s.fullWeekUntil!.compareTo(week.first) < 0);
    await _write(full ? next.copyWith(fullWeekUntil: today) : next);
    if (full) await trigger(ReviewTrigger.fullWeek);
  }

  /// "Báo lỗi" sent: no prompt for 30 days.
  Future<void> bugReported(DateTime now) async =>
      _write(_read(now).copyWith(bugReportAt: now));

  /// A happy moment; returns whether the OS was asked.
  Future<bool> trigger(ReviewTrigger trigger) async {
    var s = _read(DateTime.now());
    if (trigger == ReviewTrigger.firstReaction) {
      if (s.reacted) return false;
      s = s.copyWith(reacted: true);
      await _write(s);
    }
    // Most moments end here; the app is read only for an install that qualifies.
    if (eligibilityBlock(s, DateTime.now()) != null) return false;
    final c = _contextOf();
    final d = decideReview(s, c);
    if (!d.eligible) return false;
    unawaited(_platform.track('reviewPromptEligible'));
    if (!d.request) return false;
    await _write(s.copyWith(lastPromptAt: c.now, lastPromptVersion: c.version));
    unawaited(_platform.track('reviewPromptRequested'));
    try {
      await _platform.request();
    } on Object catch (e) {
      debugPrint('review prompt: $e');
    }
    return true;
  }
}

final reviewPlatformProvider = Provider<ReviewPlatform>(
  (ref) => ReviewPlatform(
    request: () async {
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    },
    track: (event) async {
      try {
        await ref
            .read(functionsProvider)
            .httpsCallable('recordAppEvent')
            .call<Object?>({'event': event});
      } on Object {
        // Counters only; never in the way.
      }
    },
  ),
);

final reviewPrompterProvider = Provider<ReviewPrompter>(
  (ref) => ReviewPrompter(
    ref.watch(sharedPreferencesProvider),
    ref.watch(reviewPlatformProvider),
    () => ReviewContext(
      now: DateTime.now(),
      version: ref.read(appVersionProvider).value ?? '',
      night: ref.read(paletteProvider) == ClPalette.nightCare,
      timerRunning: ref.read(nightCareTimerRunningProvider),
      onFirstAid: ref
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path
          .startsWith(Routes.firstAid),
      afterError: ReviewSession.afterError,
    ),
  ),
);
