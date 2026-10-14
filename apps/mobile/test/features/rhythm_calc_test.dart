import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/rhythm/rhythm_access.dart';
import 'package:child_life/features/rhythm/rhythm_calc.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';

/// Nhịp lớn lên ports (plan §7.1 R1): the same fixture pack as the contracts
/// (`premium-v2.json`, qa-policy-v2, synthetic) through the Dart calendar and observation code,
/// plus the tolerant parsing of published content and callable answers.
final _pack =
    jsonDecode(
          File(
            '../../packages/contracts/test/vectors/premium-v2.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

List<Map<String, dynamic>> _cases(String kind) => [
  for (final c in _pack['cases'] as List)
    if ((c as Map)['kind'] == kind) c.cast<String, dynamic>(),
];

void main() {
  group('fixture pack · calendar C01–C06', () {
    final cases = _cases('calendar');
    test('has the six cases', () {
      expect(
        [for (final c in cases) c['id']],
        ['C01', 'C02', 'C03', 'C04', 'C05', 'C06'],
      );
    });
    for (final c in cases) {
      test('${c['id']} → ${c['expected']}', () {
        final input = (c['input'] as Map).cast<String, dynamic>();
        final state = calendarState(
          input['due_date'] as String?,
          input['today'] as String,
          startOffsetDays: input['start_offset_days'] as int,
          endOffsetDays: input['end_offset_days'] as int,
        );
        expect(state.wire, c['expected']);
      });
    }
  });

  group('fixture pack · observations X01–X03', () {
    final cases = _cases('observations');
    test('has the three cases', () {
      expect([for (final c in cases) c['id']], ['X01', 'X02', 'X03']);
    });
    for (final c in cases) {
      test('${c['id']} → ${c['expected']}', () {
        final rows = [
          for (final r in (c['input'] as Map)['rows'] as List)
            (r as Map)['state'] == 'changed',
        ];
        expect(observationState(rows).wire, c['expected']);
      });
    }
    test(
      'check-ins: "Như mọi ngày" is normal, any other observation a change',
      () {
        CheckIn of(Observation o, String uid) => CheckIn(
          id: checkInIdFor(
            babyId: teddyId,
            uid: uid,
            date: '2026-10-14',
            observation: o,
          ),
          babyId: teddyId,
          date: '2026-10-14',
          authorUid: uid,
          observation: o,
        );
        expect(
          observationStateOf([
            of(Observation.usual, 'u_mai'),
            of(Observation.sleep, 'u_minh'),
          ]),
          ObservationState.mixed,
        );
        expect(
          observationStateOf([of(Observation.health, 'u_mai')]),
          ObservationState.reportedChange,
        );
        expect(observationStateOf(const []), ObservationState.normal);
      },
    );
  });

  group('dates and the reference calendar', () {
    test('addDaysIso / daysBetweenIso cross months and leap years', () {
      expect(addDaysIso('2026-09-21', 21), '2026-10-12');
      expect(addDaysIso('2028-02-28', 1), '2028-02-29');
      expect(addDaysIso('2026-01-01', -1), '2025-12-31');
      expect(daysBetweenIso('2026-09-21', '2026-10-22'), 31);
      expect(daysBetweenIso('2026-10-22', '2026-09-21'), -31);
    });

    test('estimateDueDate: birth + (280 − gestational age)', () {
      // 38w0d → 14 days before term.
      expect(estimateDueDate('2026-09-18', 38, 0), '2026-10-02');
      expect(estimateDueDate('2026-09-18', 40, 0), '2026-09-18');
      expect(estimateDueDate('2026-09-18', 41, 3), '2026-09-08');
    });

    test('stageWindow is inclusive, date-only', () {
      expect(
        stageWindow('2026-09-21', startOffsetDays: 21, endOffsetDays: 30),
        (start: '2026-10-12', end: '2026-10-21'),
      );
    });

    test('currentStages: overlapping windows show both, else the next', () {
      final model = referenceModel();
      final s = model.stages;
      // Due 21/09: stage 1 = 12/10–21/10, stage 2 = 20/10–30/10.
      var r = currentStages('2026-09-21', '2026-10-11', s);
      expect(r.current, isEmpty);
      expect(r.next?.number, 1);
      r = currentStages('2026-09-21', '2026-10-20', s);
      expect([for (final x in r.current) x.number], [1, 2]);
      r = currentStages('2026-09-21', '2027-12-01', s);
      expect(r.current, isEmpty);
      expect(r.next, isNull);
      expect(currentStages(null, '2026-10-20', s).current, isEmpty);
    });
  });

  group('age content', () {
    test('ageInDays counts calendar days from the date of birth', () {
      expect(
        ageInDays(DateTime(2026, 9, 17), DateTime(2026, 10, 8, 23, 59)),
        21,
      );
      expect(ageInDays(DateTime(2026, 10, 8), DateTime(2026, 10, 8)), 0);
    });

    test('ageCardFor: the narrowest published range', () {
      final cards = rhythmContent().ageCards;
      expect(ageCardFor(cards, 21)?.id, 'age_week_3');
      // Week 3 and the 0–3 month card both hold day 21; drafts never show.
      expect(ageCardFor(cards, 40)?.id, 'age_month_0');
      expect(ageCardFor(cards, 400), isNull);
    });

    test('signsFor: fever only under 3 months; unknown age asks everything', () {
      final pack = rhythmContent().health;
      expect(
        signsFor(pack, 21).map((s) => s.sign),
        contains(HealthSign.feverYoung),
      );
      expect(
        signsFor(pack, 120).map((s) => s.sign),
        isNot(contains(HealthSign.feverYoung)),
      );
      // No published pack (offline first run): every sign, from the app's own labels.
      expect(signsFor(null, null).map((s) => s.sign), HealthSign.values);
      expect(
        signsFor(null, 200).map((s) => s.sign),
        isNot(contains(HealthSign.feverYoung)),
      );
    });
  });

  group('models', () {
    test('health sign ids are exactly the contract’s', () {
      expect(
        [for (final s in HealthSign.values) s.wire],
        [
          'fever_young',
          'breathing',
          'lethargic',
          'poor_feeding',
          'inconsolable',
          'lost_skill',
          'dehydration',
          'seizure',
        ],
      );
      expect(
        [for (final o in Observation.values) o.wire],
        ['sleep', 'feeding', 'soothing', 'new_skill', 'usual', 'health'],
      );
    });

    test('a check-in writes exactly the schema fields and reads back', () {
      final c = sleepCheckIn();
      expect(c.toJson().keys.toSet(), {
        'id',
        'babyId',
        'date',
        'authorUid',
        'observation',
        'when',
        'since',
        'tried',
        'healthSigns',
        'note',
        'revision',
      });
      expect(c.toJson()['since'], 'days_2_3');
      final back = CheckIn.fromJson(c.toJson())!;
      expect(back.when, CheckInWhen.night);
      expect(back.tried, [Tried.rocking]);
      expect(back.changed, isTrue);
      expect(CheckIn.fromJson({...c.toJson(), 'id': 'ci_short'}), isNull);
      // Unknown values are dropped, not fatal.
      expect(
        CheckIn.fromJson({
          ...c.toJson(),
          'tried': ['rocking', 'dancing'],
        })!.tried,
        [Tried.rocking],
      );
    });

    test('check-in ids: one per author, observation and day', () {
      String id(String uid, String date, Observation o) =>
          checkInIdFor(babyId: teddyId, uid: uid, date: date, observation: o);
      final a = id('u_mai', '2026-10-08', Observation.sleep);
      expect(isCheckInId(a), isTrue);
      expect(id('u_mai', '2026-10-08', Observation.sleep), a);
      expect(id('u_minh', '2026-10-08', Observation.sleep), isNot(a));
      expect(id('u_mai', '2026-10-09', Observation.sleep), isNot(a));
      expect(id('u_mai', '2026-10-08', Observation.feeding), isNot(a));
      expect(isFeedbackId(newFeedbackId()), isTrue);
      expect(newFeedbackId(), isNot(newFeedbackId()));
    });

    test('feedback rows: schema fields, newest first', () {
      final f = RecFeedback(
        id: newFeedbackId(),
        babyId: teddyId,
        authorUid: 'u_mai',
        contentId: 'act_wind_down',
        contentVersion: 1,
        kind: FeedbackKind.notSuitable,
        date: '2026-10-08',
      );
      expect(f.toJson()['kind'], 'not_suitable');
      expect(f.toJson().keys.toSet(), {
        'id',
        'babyId',
        'authorUid',
        'contentId',
        'contentVersion',
        'kind',
        'date',
        'note',
      });
      final older = RecFeedback.fromJson(
        f.toJson(),
        createdAt: DateTime.utc(2026, 10, 8, 1),
      )!;
      final pending = RecFeedback.fromJson({
        ...f.toJson(),
        'id': newFeedbackId(),
      })!;
      final yesterday = RecFeedback.fromJson({
        ...f.toJson(),
        'id': newFeedbackId(),
        'date': '2026-10-07',
      })!;
      expect(newestFirst([yesterday, older, pending]), [
        pending,
        older,
        yesterday,
      ]);
    });

    test('published content: one bad item never hides the rest', () {
      final json = rhythmContentJson();
      (json['activities'] as List).add({'id': 'not-an-activity'});
      (json['ageCards'] as List).add({'id': 'age_x', 'version': 'one'});
      final content = RhythmContent.fromJson(json)!;
      expect(content.activities.length, rhythmContent().activities.length);
      expect(
        content.activity('act_wind_down')?.timeOfDay,
        ActivityTime.evening,
      );
      expect(content.activity('act_wind_down')?.review, isNull);
      expect(content.health?.emergencyNumberFor('VN'), '115');
      expect(content.health?.emergencyNumberFor('FR'), isNull);
      expect(content.health?.emergencyNumberFor(null), isNull);
      expect(RhythmContent.fromJson({'activities': []}), isNull);
      expect(ReferenceModel.fromJson(referenceModelJson())?.stages.length, 3);
      expect(
        ReferenceModel.fromJson({'version': 'ref_x', 'stages': []}),
        isNull,
      );
    });

    test('callable answers: tolerant, never an unlock', () {
      final a = NextActionAnswer.fromJson(nextActionJson());
      expect(a.state, AnswerState.suggestion);
      expect(a.recommendation?.contentId, 'act_wind_down');
      expect(a.recommendation?.checkInId, sleepCheckIn().id);
      expect(a.sleep?.status, SleepStatus.changeDetected);
      // A suggestion without a recommendation is no suggestion.
      expect(
        NextActionAnswer.fromJson({'state': 'suggestion'}).state,
        AnswerState.noSuggestion,
      );
      expect(NextActionAnswer.fromJson(null).state, AnswerState.noSuggestion);
      final free = NextActionAnswer.fromJson({
        'state': 'free_content',
        'ageCardId': 'age_week_3',
        'gate': 'PREMIUM_REQUIRED',
      });
      expect(free.gateReason, GateReason.premiumRequired);
      final home = HomeComposition.fromJson(ps02Json());
      expect(home.recommendation?.changes, [RecChange.prefersHelpful]);
      expect(home.lastFeedback?.kind, FeedbackKind.helpful);
      final again = HomeComposition.fromJson(
        jsonDecode(jsonEncode(home.toJson())),
      );
      expect(again.lastFeedback?.id, home.lastFeedback?.id);
      expect(
        again.recommendation?.generatedAt,
        home.recommendation?.generatedAt,
      );
    });

    test('due date and preferences', () {
      final d = DueDate.fromJson({
        'date': '2026-09-21',
        'estimated': true,
        'gestation': {'weeks': 37, 'days': 4},
      })!;
      expect(d.estimated, isTrue);
      expect(DueDate.fromJson(d.toJson()), d);
      expect(DueDate.fromJson({'date': '21/09/2026'}), isNull);
      final profile = RhythmProfile.fromJson({
        'dateOfBirth': '2026-09-17',
        'gender': 'boy',
        'dueDate': d.toJson(),
      });
      expect(profile.dateOfBirth, DateTime(2026, 9, 17));
      expect(profile.dueDate?.date, '2026-09-21');

      expect(UserPreferences.fromJson(null).quietFrom, '22:00');
      final p = UserPreferences.fromJson({
        'interests': ['sleep', 'karaoke'],
        'digestTime': '20:30',
        'quietHours': null,
        'fewer': ['moments'],
      });
      expect(p.interests, [Interest.sleep]);
      expect(p.quietFrom, isNull);
      expect(p.toJson()['quietHours'], isNull);
      expect(UserPreferences.fromJson(p.toJson()).digestTime, '20:30');
    });
  });

  group('familyCan (D-072 #2)', () {
    test('check-in and feedback: Cùng nuôi and Người chăm sóc', () {
      for (final a in [
        FamilyAction.rhythmCheckin,
        FamilyAction.rhythmFeedback,
      ]) {
        expect(familyCan(mai, a), isTrue);
        expect(familyCan(lan, a), isTrue);
        expect(familyCan(hoa, a), isFalse);
      }
    });
    test(
      'reading needs "Chăm sóc hằng ngày" for a relative; setup is Cùng nuôi',
      () {
        expect(familyCan(hoa, FamilyAction.historyRead), isFalse);
        final reader = member(
          'u_ba',
          'Bà ngoại',
          MemberRole.relative,
          Relation.grandmother,
          extra: const ExtraRights(viewDailyCare: true),
        );
        expect(familyCan(reader, FamilyAction.historyRead), isTrue);
        expect(familyCan(lan, FamilyAction.rhythmSetup), isFalse);
        expect(familyCan(minh, FamilyAction.rhythmSetup), isTrue);
        expect(familyCan(hoa, FamilyAction.healthRead), isTrue);
        expect(familyCan(minh, FamilyAction.billingManage), isFalse);
        expect(familyCan(mai, FamilyAction.billingManage), isTrue);
      },
    );
  });
}
