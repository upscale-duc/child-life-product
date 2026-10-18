import 'dart:convert';

import 'package:child_life/features/feedback/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// FB5 "hỏi đánh giá" rules (D-065): eligibility, the "never" list and the frequency.
final now = DateTime(2026, 10, 13, 10);
DateTime ago(int days) => now.subtract(Duration(days: days));
List<String> days(int n) => [for (var i = n - 1; i >= 0; i--) dayKey(ago(i))];

ReviewState ready({
  DateTime? lastPromptAt,
  String? lastPromptVersion,
  DateTime? bugReportAt,
  DateTime? updatedAt,
}) => ReviewState(
  installedAt: ago(30),
  logs: 25,
  activeDays: days(5),
  logDays: days(5),
  lastPromptAt: lastPromptAt,
  lastPromptVersion: lastPromptVersion,
  bugReportAt: bugReportAt,
  updatedAt: updatedAt,
);

ReviewContext at({
  bool night = false,
  bool timer = false,
  bool firstAid = false,
  bool error = false,
  String version = '1.0.3',
}) => ReviewContext(
  now: now,
  version: version,
  night: night,
  timerRunning: timer,
  onFirstAid: firstAid,
  afterError: error,
);

void main() {
  group('decideReview', () {
    test('asks after a happy moment when everything allows it', () {
      final d = decideReview(ready(), at());
      expect((d.eligible, d.request, d.block), (true, true, null));
    });

    test(
      'eligibility: 7 days installed, 10 logs, 3 active days in the last 7',
      () {
        ReviewBlock? block(ReviewState s) => decideReview(s, at()).block;
        expect(
          block(
            ReviewState(installedAt: ago(6), logs: 25, activeDays: days(5)),
          ),
          ReviewBlock.tooNew,
        );
        expect(
          block(
            ReviewState(installedAt: ago(30), logs: 9, activeDays: days(5)),
          ),
          ReviewBlock.fewLogs,
        );
        expect(
          block(
            ReviewState(
              installedAt: ago(30),
              logs: 25,
              // Busy two weeks ago, only two days this week.
              activeDays: [dayKey(ago(12)), dayKey(ago(10)), ...days(2)],
            ),
          ),
          ReviewBlock.fewActiveDays,
        );
      },
    );

    test(
      'never at night, with a timer, on first aid, after an error, after an update',
      () {
        ReviewBlock? block(ReviewContext c, [ReviewState? s]) =>
            decideReview(s ?? ready(), c).block;
        expect(block(at(night: true)), ReviewBlock.night);
        expect(block(at(timer: true)), ReviewBlock.timerRunning);
        expect(block(at(firstAid: true)), ReviewBlock.firstAid);
        expect(block(at(error: true)), ReviewBlock.afterError);
        expect(
          block(at(), ready(updatedAt: now.subtract(const Duration(hours: 3)))),
          ReviewBlock.justUpdated,
        );
        expect(block(at(), ready(updatedAt: ago(2))), isNull);
      },
    );

    test('never within 30 days of a bug report', () {
      expect(
        decideReview(ready(bugReportAt: ago(29)), at()).block,
        ReviewBlock.afterBugReport,
      );
      expect(decideReview(ready(bugReportAt: ago(31)), at()).request, isTrue);
    });

    test('once per version and 120 days apart: eligible, but not asked', () {
      final same = decideReview(
        ready(lastPromptAt: ago(200), lastPromptVersion: '1.0.3'),
        at(),
      );
      expect(
        (same.eligible, same.request, same.block),
        (true, false, ReviewBlock.sameVersion),
      );
      final soon = decideReview(
        ready(lastPromptAt: ago(119), lastPromptVersion: '1.0.2'),
        at(),
      );
      expect(soon.block, ReviewBlock.tooSoon);
      expect(
        decideReview(
          ready(lastPromptAt: ago(121), lastPromptVersion: '1.0.2'),
          at(),
        ).request,
        isTrue,
      );
    });
  });

  group('ReviewPrompter', () {
    late SharedPreferences prefs;
    late List<String> events;
    late int asked;
    var context = at();

    ReviewPrompter prompter() => ReviewPrompter(
      prefs,
      ReviewPlatform(
        request: () async => asked++,
        track: (e) async => events.add(e),
      ),
      () => context,
      clock: () => context.now,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      events = [];
      asked = 0;
      context = at();
    });

    Future<void> seed(ReviewState s) =>
        prefs.setString('review.state', _encode(s));

    test('asks the OS once, then not again for the same version', () async {
      await seed(ready());
      final p = prompter();
      expect(await p.trigger(ReviewTrigger.milestone), isTrue);
      expect(asked, 1);
      expect(events, ['reviewPromptEligible', 'reviewPromptRequested']);
      expect(await p.trigger(ReviewTrigger.memory), isFalse);
      expect(asked, 1);
      expect(events.last, 'reviewPromptEligible');
      expect(p.state.lastPromptVersion, '1.0.3');
    });

    test('a new install counts days, logs and the version', () async {
      final p = prompter();
      await p.opened(now, '1.0.3');
      for (var i = 0; i < 3; i++) {
        await p.logged(now);
      }
      expect(p.state.logs, 3);
      expect(p.state.activeDays, [dayKey(now)]);
      expect(await p.trigger(ReviewTrigger.memory), isFalse);
      expect(events, isEmpty);
      // An update: the next day stays quiet.
      await p.opened(now, '1.0.4');
      expect(p.state.updatedAt, now);
    });

    test('the seventh day in a row with logs triggers once', () async {
      await seed(
        ReviewState(
          installedAt: ago(30),
          logs: 20,
          activeDays: days(6).sublist(0, 6),
          logDays: [for (var i = 6; i >= 1; i--) dayKey(ago(i))],
        ),
      );
      context = ReviewContext(now: now, version: '1.0.3');
      final p = prompter();
      await p.logged(now);
      expect(asked, 1);
      await p.logged(now);
      expect(events.where((e) => e == 'reviewPromptEligible'), hasLength(1));
    });

    test('only the first reaction counts', () async {
      await seed(ready(lastPromptVersion: '1.0.2', lastPromptAt: ago(200)));
      context = at(night: true);
      final p = prompter();
      expect(await p.trigger(ReviewTrigger.firstReaction), isFalse);
      context = at();
      expect(await p.trigger(ReviewTrigger.firstReaction), isFalse);
      expect(asked, 0);
    });

    test('a bug report holds prompts for 30 days', () async {
      await seed(ready());
      final p = prompter();
      await p.bugReported(now);
      expect(await p.trigger(ReviewTrigger.milestone), isFalse);
      expect(events, isEmpty);
    });
  });
}

String _encode(ReviewState s) => jsonEncode(s.toJson());
