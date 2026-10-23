import 'package:child_life/app/route_guard.dart';
import 'package:child_life/features/ai/ai_consent_screen.dart';
import 'package:child_life/features/ai/ai_models.dart';
import 'package:child_life/features/ai/ai_repository.dart';
import 'package:child_life/features/ai/handover_screen.dart';
import 'package:child_life/features/rhythm/activity_screens.dart';
import 'package:child_life/features/rhythm/milestone_screen.dart';
import 'package:child_life/features/rhythm/preferences_screens.dart';
import 'package:child_life/features/rhythm/result_screen.dart';
import 'package:child_life/features/rhythm/rhythm_labels.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/today/today_for_baby.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ai_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

/// Premium Slice 3 on the phone (plan §5.5, A1–A3): the models, SU01 in every ST01 / NL10b
/// state, the AI consent screen, "Giải thích thêm" (PS01 / AC01) and the MS01 nudge. Everything
/// through fakes; the server is never called.
final l10n = lookupAppLocalizations(const Locale('vi'));

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

/// Lets a toast's timer run out.
Future<void> _toastGone(WidgetTester t) async {
  await t.pump(const Duration(seconds: 5));
  await t.pumpAndSettle();
}

Future<(List<Visit>, FakeAiRepository)> _handover(
  WidgetTester tester,
  FakeAiRepository ai, {
  bool online = true,
  FakeRhythmRepository? repo,
  Map<String, Object?>? caps,
  List<Shared>? shared,
  Locale locale = const Locale('vi'),
  member,
}) async {
  final (visits, _) = await pumpRouted(
    tester,
    const HandoverScreen(),
    locale: locale,
    overrides: aiOverrides(
      ai: ai,
      online: online,
      repo: repo,
      caps: caps,
      shared: shared,
      member: member,
    ),
  );
  return (visits, ai);
}

void main() {
  group('models', () {
    test(
      'a handover parses; citations go, unknown parts drop, never a crash',
      () {
        final json = handoverJson();
        (json['sections']! as List).add({'kind': 'poem', 'text': 'x'});
        (json['facts']! as List).add({'id': 'x', 'kind': 'photo', 'date': 'x'});
        final a = SummaryAnswer.fromJson(json)!;
        expect(a.kind, AiSummaryKind.handover);
        expect(a.method, SummaryMethod.ai);
        expect(a.aiWorded, isTrue);
        expect(a.sections, hasLength(3));
        expect(a.sections.first.text, isNot(contains('[F1]')));
        expect(a.facts, hasLength(4));
        expect(a.records, hasLength(4));
        expect(a.rangeFrom, '2026-10-06');
        expect(a.generatedAt, DateTime.utc(2026, 10, 8, 13, 12));
        expect(a.requestedBy, 'u_mai');
        expect(SummaryAnswer.fromJson(a.toJson())!.sections.length, 3);
        expect(SummaryAnswer.fromJson('nope'), isNull);
        expect(SummaryAnswer.fromJson({'id': 'x', 'kind': 'nope'}), isNull);
        // "AI" without a readable sentence is not shown as AI.
        expect(
          SummaryAnswer.fromJson({
            'id': 'x',
            'kind': 'handover',
            'method': 'ai',
            'sections': <Object>[],
          }),
          isNull,
        );
      },
    );

    test(
      'fallback reasons: technical, gates, health; cache counts as AI wording',
      () {
        final timeout = handover(method: 'fallback', reason: 'timeout');
        expect(timeout.technicalFailure, isTrue);
        expect(timeout.aiWorded, isFalse);
        final quota = handover(
          method: 'fallback',
          reason: 'QUOTA_EXCEEDED',
          quota: quotaDayUsed(),
        );
        expect(quota.quotaDay!.exhausted, isTrue);
        expect(quota.quotaMonth!.exhausted, isFalse);
        expect(
          handover(method: 'fallback', reason: 'HEALTH_FLOW').health,
          isTrue,
        );
        expect(handover(method: 'cache').aiWorded, isTrue);
        expect(handover(stale: true).stale, isTrue);
        expect(
          cleanSummaryText('Bé ngủ ít hơn [ci_ab12] [F2].'),
          'Bé ngủ ít hơn.',
        );
      },
    );

    test('consent: current, withdrawn, outdated', () {
      expect(AiSettings.fromJson(null).granted, isFalse);
      expect(AiSettings.fromJson(null).withdrawn, isFalse);
      final given = AiSettings.fromJson({
        'consent': {
          'version': aiConsentVersion,
          'grantedAt': '2026-10-08T03:00:00.000Z',
          'shareMyNotes': true,
        },
        'updatedAt': '2026-10-08T03:00:00.000Z',
      });
      expect(given.granted, isTrue);
      expect(given.consent!.shareMyNotes, isTrue);
      final withdrawn = AiSettings.fromJson({
        'consent': null,
        'updatedAt': '2026-10-09T03:00:00.000Z',
      });
      expect(withdrawn.withdrawn, isTrue);
      final old = AiSettings.fromJson({
        'consent': {'version': 'ai-consent-v0', 'shareMyNotes': false},
      });
      expect(old.granted, isFalse);
      expect(old.outdated, isTrue);
    });

    test('the latest handover prefers the reading language', () {
      final vi = handover();
      final en = SummaryAnswer.fromJson(
        handoverJson(language: 'en')..['generatedAt'] = '2026-10-08T14:00:00Z',
      )!;
      final list = newestSummariesFirst([vi, en]);
      expect(list.first, en);
      expect(latestHandover(list, 'vi'), vi);
      expect(latestHandover(list, 'en'), en);
      expect(latestHandover(const [], 'vi'), isNull);
    });
  });

  group('SU01 · handover', () {
    testWidgets('AI: three parts, readable links, AI label, share, report', (
      tester,
    ) async {
      final shared = <Shared>[];
      final (visits, ai) = await _handover(
        tester,
        FakeAiRepository(answer: handover()),
        shared: shared,
      );
      // Nothing stored: a Cùng nuôi's open asks once.
      expect(ai.calls, hasLength(1));
      expect(ai.calls.single.kind, AiSummaryKind.handover);
      expect(ai.calls.single.locale, 'vi');
      expect(find.text(l10n.aiHandoverTitle), findsOneWidget);
      expect(
        find.text('06/10 – 08/10 · từ 4 ghi nhận của bạn, Ba và Cô Lan'),
        findsOneWidget,
      );
      expect(find.text(l10n.aiGeneratedAt('08/10 · 20:12')), findsOneWidget);
      expect(find.text(l10n.aiSectionNoticed), findsOneWidget);
      expect(find.text(l10n.aiSectionHelped), findsOneWidget);
      expect(find.text(l10n.aiSectionNext), findsOneWidget);
      expect(find.textContaining('[F1]'), findsNothing);
      // Each source says what it is (owner 2026-10-22), with who and when under it.
      expect(find.text('Ba · 07/10'), findsOneWidget);
      expect(find.text('Bạn · 06/10'), findsOneWidget);
      expect(find.text('Bạn · 07/10'), findsOneWidget);
      expect(
        find.text(checkInParts(l10n, sleepCheckIn(uid: 'u_minh')).join(' · ')),
        findsWidgets,
      );
      expect(find.text(l10n.aiWordedByAi), findsOneWidget);
      expect(find.text(l10n.aiTemplateLine), findsNothing);

      // A link opens the note it came from.
      await _tap(tester, find.text('Ba · 07/10'));
      expect(find.text(l10n.aiRecordCheckIn), findsOneWidget);
      expect(find.text(l10n.aiRecordWho('Ba', '07/10')), findsWidgets);
      await _tap(tester, find.text(l10n.rhDone));
      // Feedback opens its activity.
      await _tap(tester, find.text('Bạn · 07/10'));
      await _tap(tester, find.text(l10n.aiRecordOpenActivity));
      expect(visits.last.location, '${Routes.rhythmActivity}/act_wind_down');
      Navigator.of(tester.element(find.text('stub'))).pop();
      await tester.pumpAndSettle();

      // "Chia sẻ qua ứng dụng khác…": plain text, the three parts, the AI line, no citations.
      await _tap(tester, find.text(l10n.aiShareOther));
      expect(shared, hasLength(1));
      expect(shared.single.text, contains(l10n.aiSectionHelped));
      expect(shared.single.text, contains('tắm ấm'));
      expect(shared.single.text, contains(l10n.aiShareAiLine));
      expect(shared.single.text, isNot(contains('[F1]')));

      // "Chưa đúng? Báo lại": a chosen reason only.
      await _tap(tester, find.text(l10n.aiReport));
      expect(find.text(l10n.aiReportTitle), findsOneWidget);
      await _tap(tester, find.text(l10n.aiProblemWrongPerson));
      await _tap(tester, find.text(l10n.aiReportSend));
      expect(ai.reports.single, ('sum_handover_1', ReportProblem.wrongPerson));
      expect(find.text(l10n.aiReportThanks), findsOneWidget);
      await _toastGone(tester);
    });

    testWidgets('consent missing: the template, then the consent screen', (
      tester,
    ) async {
      final (visits, _) = await _handover(
        tester,
        FakeAiRepository(
          answer: handover(method: 'fallback', reason: 'CONSENT_REQUIRED'),
          settings: AiSettings.none,
        ),
      );
      expect(find.text(l10n.aiStateConsentEyebrow), findsOneWidget);
      expect(find.text(l10n.aiStateConsentBody), findsOneWidget);
      expect(find.text(l10n.aiWordedByAi), findsNothing);
      expect(find.text(l10n.aiTemplateLine), findsOneWidget);
      // Still three parts.
      expect(find.text(l10n.aiSectionNext), findsOneWidget);
      await _tap(tester, find.text(l10n.aiStateConsentAction));
      expect(visits.last.location, Routes.rhythmAiConsent);
    });

    testWidgets('AI turned off by the person: "Bật AI trong Cài đặt"', (
      tester,
    ) async {
      await _handover(
        tester,
        FakeAiRepository(
          answer: handover(method: 'fallback', reason: 'CONSENT_REQUIRED'),
          settings: AiSettings(updatedAt: DateTime.utc(2026, 10, 7)),
        ),
      );
      expect(find.text(l10n.aiStateOffEyebrow), findsOneWidget);
      expect(find.text(l10n.aiStateWithdrawnBody), findsOneWidget);
      expect(find.text(l10n.aiStateWithdrawnAction), findsOneWidget);
    });

    testWidgets('feature paused: explained, no link, no plan', (tester) async {
      await _handover(
        tester,
        FakeAiRepository(
          answer: handover(method: 'fallback', reason: 'FEATURE_DISABLED'),
        ),
      );
      expect(find.text(l10n.aiStateDisabledBody), findsOneWidget);
      expect(find.text(l10n.rhLearnMoreOptional), findsNothing);
      expect(find.text(l10n.aiWordedByAi), findsNothing);
    });

    testWidgets(
      'AI error: template, no credit line (D-081), retry is a new attempt',
      (tester) async {
        final (_, ai) = await _handover(
          tester,
          FakeAiRepository(
            answer: handover(method: 'fallback', reason: 'timeout'),
          ),
        );
        expect(find.text(l10n.aiStateErrorEyebrow), findsOneWidget);
        expect(find.text(l10n.aiStateTemplateTitle), findsOneWidget);
        expect(find.text(l10n.aiStateErrorBody), findsOneWidget);
        // D-081: the error body no longer mentions credits.
        expect(find.textContaining('lượt'), findsNothing);
        ai.answer = handover();
        await _tap(tester, find.text(l10n.rhRetry));
        expect(ai.calls, hasLength(2));
        expect(ai.calls[1].requestId, isNot(ai.calls[0].requestId));
        expect(find.text(l10n.aiStateErrorEyebrow), findsNothing);
        expect(find.text(l10n.aiWordedByAi), findsOneWidget);
      },
    );

    testWidgets('quota: template with the quota line, no plan', (tester) async {
      await _handover(
        tester,
        FakeAiRepository(
          answer: handover(
            method: 'fallback',
            reason: 'QUOTA_EXCEEDED',
            quota: quotaDayUsed(),
          ),
        ),
      );
      expect(find.text(l10n.aiStateQuotaEyebrow), findsOneWidget);
      expect(find.text(l10n.aiStateQuotaDay(1, 1, '09/10')), findsOneWidget);
      expect(find.text(l10n.rhLearnMoreOptional), findsNothing);
    });

    testWidgets('PREMIUM_REQUIRED alone links to the plan', (tester) async {
      final (visits, _) = await _handover(
        tester,
        FakeAiRepository(
          answer: handover(method: 'fallback', reason: 'PREMIUM_REQUIRED'),
        ),
      );
      expect(find.text(l10n.aiStatePremiumBody), findsOneWidget);
      await _tap(tester, find.text(l10n.rhLearnMoreOptional));
      // PR01 from Nhịp lớn lên (entry A).
      expect(visits.last.location, '${Routes.premium}?entry=rhythm');
    });

    testWidgets('another gate reason is explained, never sold', (tester) async {
      await _handover(
        tester,
        FakeAiRepository(
          answer: handover(method: 'fallback', reason: 'REGION_UNAVAILABLE'),
        ),
      );
      expect(find.text(l10n.aiStateOtherBody), findsOneWidget);
      expect(find.text(l10n.rhLearnMoreOptional), findsNothing);
      await _tap(tester, find.text(l10n.rhWhy));
      expect(find.text(l10n.pmGateRegionTitle), findsOneWidget);
    });

    testWidgets('stale: "Có ghi nhận mới · Tạo lại", never by itself', (
      tester,
    ) async {
      final ai = FakeAiRepository(
        answer: handover(dataVersion: 9),
        stored: [handover(dataVersion: 7)],
        dataVersion: 9,
      );
      await _handover(tester, ai);
      // Something stored in this language: no call on open.
      expect(ai.calls, isEmpty);
      expect(find.text(l10n.aiStateStaleTitle), findsOneWidget);
      await _tap(tester, find.text(l10n.aiStateStaleAction));
      expect(ai.calls, hasLength(1));
      expect(find.text(l10n.aiStateStaleTitle), findsNothing);
    });

    testWidgets('offline: the last stored version, no call', (tester) async {
      final ai = FakeAiRepository(answer: handover(), stored: [handover()]);
      await _handover(tester, ai, online: false);
      expect(ai.calls, isEmpty);
      expect(find.text(l10n.aiStateOfflineTitle), findsOneWidget);
      expect(find.text(l10n.aiSectionNoticed), findsOneWidget);
    });

    testWidgets('offline with nothing stored: says so', (tester) async {
      final ai = FakeAiRepository(answer: handover());
      await _handover(tester, ai, online: false);
      expect(ai.calls, isEmpty);
      expect(find.text(l10n.aiStateOfflineEmptyTitle), findsOneWidget);
    });

    testWidgets('the call fails with nothing stored: retry', (tester) async {
      final ai = FakeAiRepository(error: const AiException('unavailable'));
      await _handover(tester, ai);
      expect(find.text(l10n.aiStateFailedTitle), findsOneWidget);
      ai
        ..error = null
        ..answer = handover();
      await _tap(tester, find.text(l10n.rhRetry));
      expect(find.text(l10n.aiSectionNoticed), findsOneWidget);
    });

    testWidgets('caregiver: reads the latest stored one, never generates', (
      tester,
    ) async {
      final ai = FakeAiRepository(answer: handover(), stored: [handover()]);
      await _handover(tester, ai, member: lan);
      expect(ai.calls, isEmpty);
      expect(find.text(l10n.aiSectionNoticed), findsOneWidget);
      expect(find.text(l10n.aiReport), findsOneWidget);
      expect(find.text(l10n.aiSendTo('Cô Lan')), findsNothing);
      expect(find.text(l10n.aiShare), findsNothing);
    });

    testWidgets('caregiver with nothing stored: an honest empty state', (
      tester,
    ) async {
      final ai = FakeAiRepository(answer: handover());
      await _handover(tester, ai, member: lan);
      expect(ai.calls, isEmpty);
      expect(find.text(l10n.aiReadEmptyTitle), findsOneWidget);
    });

    testWidgets('a health sign today: the health route, never AI text', (
      tester,
    ) async {
      final ai = FakeAiRepository(answer: handover(), stored: [handover()]);
      final (visits, _) = await _handover(
        tester,
        ai,
        repo: FakeRhythmRepository(
          checkIns: [...recentCheckIns(), healthCheckIn()],
        ),
      );
      expect(find.text(l10n.rhHealthCardTitle), findsOneWidget);
      expect(find.text(l10n.aiHealthBody), findsOneWidget);
      expect(find.text(l10n.aiWordedByAi), findsNothing);
      expect(find.text(l10n.aiSectionNoticed), findsNothing);
      await _tap(tester, find.text(l10n.rhHealthCardTitle));
      expect(visits.last.location, startsWith(Routes.rhythmHealth));
    });

    testWidgets('HEALTH_FLOW from the server: the template, no AI label', (
      tester,
    ) async {
      await _handover(
        tester,
        FakeAiRepository(
          answer: handover(method: 'fallback', reason: 'HEALTH_FLOW'),
        ),
      );
      expect(find.text(l10n.rhHealthCardTitle), findsOneWidget);
      expect(find.text(l10n.aiWordedByAi), findsNothing);
      expect(find.text(l10n.aiStateConsentEyebrow), findsNothing);
    });

    testWidgets('English: the EN frame copy', (tester) async {
      await _handover(
        tester,
        FakeAiRepository(answer: handover(language: 'en')),
        locale: const Locale('en'),
      );
      expect(find.text('Handover for the next carer'), findsOneWidget);
      expect(find.text('Dad · 7 Oct'), findsOneWidget);
      expect(find.text('Send the handover'), findsOneWidget);
    });
  });

  group('D-093 · "Gửi cho Jun" in the app', () {
    testWidgets(
      'the sender picks who, then sees sent → opened → acknowledged',
      (tester) async {
        final ai = FakeAiRepository(answer: handover());
        await _handover(tester, ai);
        // Ba and Cô Lan both read care: "Gửi bàn giao" asks who.
        await _tap(tester, find.byKey(const Key('handoverSend')));
        await _tap(tester, find.text('Cô Lan'));
        expect(ai.sends.single.recipientUid, 'u_lan');
        expect(find.text(l10n.aiSentToast('Cô Lan')), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('handoverSendStatus')), findsOneWidget);
        expect(find.text(l10n.aiSendNotSeen), findsOneWidget);
        // One left: the button names them.
        expect(find.text(l10n.aiSendTo('Ba')), findsOneWidget);
        // Cô Lan opens it, then acknowledges it.
        await ai.markHandover(
          babyId: teddyId,
          sendId: ai.sends.single.id,
          received: true,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Cô Lan đã nhận bàn giao'), findsOneWidget);
      },
    );

    testWidgets('no push reaches them: it says so and offers the share sheet', (
      tester,
    ) async {
      final ai = FakeAiRepository(answer: handover())..pushable = false;
      await _handover(tester, ai);
      await _tap(tester, find.byKey(const Key('handoverSend')));
      await _tap(tester, find.text('Ba'));
      expect(find.text(l10n.aiSentNoPush('Ba')), findsOneWidget);
      expect(find.text(l10n.aiShareShort), findsOneWidget);
    });

    testWidgets(
      'the recipient opens it from the push: seen at once, then "Tôi đã nhận bàn giao"',
      (tester) async {
        final ai = FakeAiRepository(stored: [handover()])
          ..sends.add(
            HandoverSend(
              id: 'hs_1',
              summaryId: 'sum_handover_1',
              senderUid: 'u_mai',
              recipientUid: 'u_lan',
              sentAt: DateTime.utc(2026, 10, 8, 13, 30),
            ),
          );
        await pumpRouted(
          tester,
          const HandoverScreen(summaryId: 'sum_handover_1'),
          overrides: aiOverrides(ai: ai, member: lan),
        );
        expect(find.byKey(const Key('handoverReceived')), findsOneWidget);
        expect(ai.marks.first, ('hs_1', false));
        await _tap(tester, find.byKey(const Key('handoverAcknowledge')));
        expect(ai.marks.last, ('hs_1', true));
        expect(find.byKey(const Key('handoverAcknowledge')), findsNothing);
        expect(find.textContaining(l10n.aiYouReceived('').trim()), findsOneWidget);
      },
    );
  });

  group('entries', () {
    testWidgets('Home: a Cùng nuôi gets the handover with ai_assist only', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const SingleChildScrollView(child: TodayHandoverRow()),
        overrides: aiOverrides(ai: FakeAiRepository(answer: handover())),
      );
      await _tap(tester, find.text(l10n.aiHandoverTitle));
      expect(visits.last.location, Routes.rhythmHandover);
    });

    testWidgets('Home: hidden without the ai_assist rollout', (tester) async {
      await pumpRouted(
        tester,
        const SingleChildScrollView(child: TodayHandoverRow()),
        overrides: aiOverrides(
          ai: FakeAiRepository(answer: handover()),
          caps: aiCaps(aiAssist: false),
        ),
      );
      expect(find.text(l10n.aiHandoverTitle), findsNothing);
    });

    testWidgets('Home: a caregiver sees it once one is stored', (tester) async {
      await pumpRouted(
        tester,
        const SingleChildScrollView(child: TodayHandoverRow()),
        overrides: aiOverrides(
          ai: FakeAiRepository(stored: [handover()]),
          member: lan,
        ),
      );
      expect(find.text(l10n.aiHandoverTitle), findsOneWidget);
      expect(find.text(l10n.aiHandoverEntryLatest('08/10')), findsOneWidget);
    });

    testWidgets('Home: a caregiver with nothing stored sees nothing', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const SingleChildScrollView(child: TodayHandoverRow()),
        overrides: aiOverrides(ai: FakeAiRepository(), member: lan),
      );
      expect(find.text(l10n.aiHandoverTitle), findsNothing);
    });

    testWidgets('Cá nhân hoá: the AI consent row', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const PersonalizeScreen(),
        overrides: aiOverrides(ai: FakeAiRepository()),
      );
      expect(find.text(l10n.aiConsentTitle), findsOneWidget);
      expect(find.text(l10n.aiConsentOn), findsOneWidget);
      await _tap(tester, find.text(l10n.aiConsentTitle));
      expect(visits.last.location, Routes.rhythmAiConsent);
    });
  });

  group('A1 · consent', () {
    testWidgets(
      'not given: what is sent and never sent, share my notes, agree',
      (tester) async {
        final ai = FakeAiRepository(settings: AiSettings.none);
        await pumpRouted(
          tester,
          const AiConsentScreen(),
          overrides: aiOverrides(ai: ai),
        );
        expect(find.text(l10n.aiConsentSent2), findsOneWidget);
        expect(find.text(l10n.aiConsentNever1), findsOneWidget);
        expect(find.text(l10n.aiConsentNever3), findsOneWidget);
        expect(find.text(l10n.aiConsentWhere2), findsOneWidget);
        expect(
          find.text(l10n.aiConsentVersion(aiConsentVersion)),
          findsOneWidget,
        );
        expect(find.text(l10n.aiConsentWithdraw), findsNothing);
        // Off unless chosen.
        await _tap(tester, find.byType(CupertinoSwitch).first);
        await _tap(tester, find.text(l10n.aiConsentAgree));
        expect(ai.consents, [true]);
        await _toastGone(tester);
      },
    );

    testWidgets('given: the toggle saves at once; withdraw asks first', (
      tester,
    ) async {
      final ai = FakeAiRepository(
        settings: AiSettings(
          consent: AiConsent(
            version: aiConsentVersion,
            shareMyNotes: true,
            grantedAt: DateTime.utc(2026, 10, 1, 3),
          ),
          updatedAt: DateTime.utc(2026, 10, 1, 3),
        ),
      );
      await pumpRouted(
        tester,
        const AiConsentScreen(),
        overrides: aiOverrides(ai: ai),
      );
      expect(
        find.textContaining(l10n.aiConsentGranted('01/10/2026')),
        findsOneWidget,
      );
      await _tap(tester, find.byType(CupertinoSwitch).first);
      expect(ai.consents, [false]);
      await _toastGone(tester);
      await _tap(tester, find.text(l10n.aiConsentWithdraw));
      expect(find.text(l10n.aiWithdrawTitle), findsOneWidget);
      await _tap(tester, find.text(l10n.aiWithdrawConfirm));
      expect(ai.consents, [false, null]);
      expect(ai.forgot, 1);
      expect(find.text(l10n.aiConsentAgree), findsOneWidget);
      await _toastGone(tester);
    });

    testWidgets('a failure keeps the screen and says so', (tester) async {
      final ai = FakeAiRepository(
        settings: AiSettings.none,
        consentError: const AiException('unavailable'),
      );
      await pumpRouted(
        tester,
        const AiConsentScreen(),
        overrides: aiOverrides(ai: ai),
      );
      await _tap(tester, find.text(l10n.aiConsentAgree));
      expect(find.text(l10n.aiConsentFailed), findsOneWidget);
      expect(find.text(l10n.aiConsentAgree), findsOneWidget);
      await _toastGone(tester);
    });
  });

  group('explain and moment', () {
    final rec = Recommendation.fromJson(recommendationJson())!;

    testWidgets('PS01: "Giải thích thêm" adds AI wording under the reason', (
      tester,
    ) async {
      final ai = FakeAiRepository(
        answers: {
          AiSummaryKind.explain: shortAnswer(
            AiSummaryKind.explain,
            'Ba ghi tối qua con khó vào giấc; nếp thư giãn từng có ích với nhà mình.',
          ),
        },
      );
      await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: sleepCheckIn()),
        overrides: aiOverrides(
          ai: ai,
          repo: FakeRhythmRepository(
            checkIns: [sleepCheckIn()],
            answer: NextActionAnswer.fromJson(nextActionJson()),
          ),
        ),
      );
      expect(find.text(l10n.rhWhyThis), findsOneWidget);
      await _tap(tester, find.text(l10n.aiExplainMore));
      expect(ai.calls.single.kind, AiSummaryKind.explain);
      expect(ai.calls.single.recommendationId, rec.id);
      expect(find.textContaining('nếp thư giãn từng có ích'), findsOneWidget);
      expect(find.text(l10n.aiWordedShort), findsOneWidget);
      // The free reason stays.
      expect(find.text(l10n.rhWhyThis), findsOneWidget);
    });

    testWidgets('PS01: consent missing says so; the reason stays', (
      tester,
    ) async {
      final ai = FakeAiRepository(
        answers: {
          AiSummaryKind.explain: shortAnswer(
            AiSummaryKind.explain,
            '',
            method: 'fallback',
            reason: 'CONSENT_REQUIRED',
          ),
        },
      );
      final (visits, _) = await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: sleepCheckIn()),
        overrides: aiOverrides(
          ai: ai,
          repo: FakeRhythmRepository(
            checkIns: [sleepCheckIn()],
            answer: NextActionAnswer.fromJson(nextActionJson()),
          ),
        ),
      );
      await _tap(tester, find.text(l10n.aiExplainMore));
      expect(find.text(l10n.aiExplainConsent), findsOneWidget);
      await _tap(tester, find.text(l10n.aiStateConsentAction));
      expect(visits.last.location, Routes.rhythmAiConsent);
    });

    testWidgets('PS01: no link without ai.assistance', (tester) async {
      await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: sleepCheckIn()),
        overrides: aiOverrides(
          ai: FakeAiRepository(),
          caps: aiCaps(ai: false),
          repo: FakeRhythmRepository(
            checkIns: [sleepCheckIn()],
            answer: NextActionAnswer.fromJson(nextActionJson()),
          ),
        ),
      );
      expect(find.text(l10n.rhWhyThis), findsOneWidget);
      expect(find.text(l10n.aiExplainMore), findsNothing);
    });

    testWidgets('PS01: an error keeps the reason and offers a retry', (
      tester,
    ) async {
      final ai = FakeAiRepository(error: const AiException('timeout'));
      await pumpRouted(
        tester,
        RhythmResultScreen(checkIn: sleepCheckIn()),
        overrides: aiOverrides(
          ai: ai,
          repo: FakeRhythmRepository(
            checkIns: [sleepCheckIn()],
            answer: NextActionAnswer.fromJson(nextActionJson()),
          ),
        ),
      );
      await _tap(tester, find.text(l10n.aiExplainMore));
      expect(find.text(l10n.aiExplainFailed), findsOneWidget);
      expect(find.text(l10n.rhWhyThis), findsOneWidget);
    });

    testWidgets('AC01: explains the household suggestion of this activity', (
      tester,
    ) async {
      final ai = FakeAiRepository(
        answers: {
          AiSummaryKind.explain: shortAnswer(
            AiSummaryKind.explain,
            'Vì tối qua Ba ghi con khó vào giấc.',
          ),
        },
      );
      await pumpRouted(
        tester,
        const ActivityScreen(contentId: 'act_wind_down'),
        overrides: aiOverrides(
          ai: ai,
          repo: FakeRhythmRepository(recommendations: [rec]),
        ),
      );
      await _tap(tester, find.text(l10n.aiExplainMore));
      expect(ai.calls.single.recommendationId, rec.id);
      expect(find.text('Vì tối qua Ba ghi con khó vào giấc.'), findsOneWidget);
    });

    testWidgets('AC01: no suggestion of it, no link', (tester) async {
      await pumpRouted(
        tester,
        const ActivityScreen(contentId: 'act_skin_to_skin'),
        overrides: aiOverrides(
          ai: FakeAiRepository(),
          repo: FakeRhythmRepository(recommendations: [rec]),
        ),
      );
      expect(find.text(l10n.aiExplainMore), findsNothing);
    });

    testWidgets('MS01: the moment nudge once the milestone is saved', (
      tester,
    ) async {
      final ai = FakeAiRepository(
        answers: {
          AiSummaryKind.moment: shortAnswer(
            AiSummaryKind.moment,
            'Lần đầu lẫy của Teddy: giữ lại cùng một tấm ảnh để cả nhà cùng nhớ.',
          ),
        },
      );
      await pumpRouted(
        tester,
        const RhythmMilestoneScreen(note: 'Lần đầu lẫy'),
        overrides: aiOverrides(ai: ai),
      );
      await _tap(tester, find.text(l10n.rhSaveToMilestones));
      expect(ai.calls.single.kind, AiSummaryKind.moment);
      expect(ai.calls.single.milestoneId, isNotNull);
      expect(find.textContaining('giữ lại cùng một tấm ảnh'), findsOneWidget);
      expect(find.text(l10n.aiWordedShort), findsOneWidget);
      // The screen's own copy stays.
      expect(find.text(l10n.rhMsKeepTitle), findsOneWidget);
    });

    testWidgets('MS01: AI failing leaves the screen as it was', (tester) async {
      final ai = FakeAiRepository(error: const AiException('unavailable'));
      await pumpRouted(
        tester,
        const RhythmMilestoneScreen(note: 'Lần đầu lẫy'),
        overrides: aiOverrides(ai: ai),
      );
      await _tap(tester, find.text(l10n.rhSaveToMilestones));
      expect(find.text(l10n.rhMsKeepTitle), findsOneWidget);
      expect(find.text(l10n.aiWordedShort), findsNothing);
    });
  });
}
