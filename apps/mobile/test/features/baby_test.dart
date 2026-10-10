import 'package:child_life/core/format/age.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/onboarding/setup_draft.dart';
import 'package:child_life/l10n/app_localizations_en.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('baby age (38:1498 "Teddy được 3 tuần tuổi")', () {
    final dob = DateTime(2026, 9, 17);
    test('steps from days to weeks, months and years', () {
      expect(babyAge(dob, DateTime(2026, 9, 17)).unit, AgeUnit.newborn);
      expect(babyAge(dob, DateTime(2026, 9, 22)), (
        unit: AgeUnit.days,
        count: 5,
      ));
      expect(babyAge(dob, DateTime(2026, 10, 8)), (
        unit: AgeUnit.weeks,
        count: 3,
      ));
      expect(babyAge(dob, DateTime(2027, 3, 16)), (
        unit: AgeUnit.months,
        count: 5,
      ));
      expect(babyAge(dob, DateTime(2029, 9, 17)), (
        unit: AgeUnit.years,
        count: 3,
      ));
    });

    test('formats in Vietnamese and English', () {
      expect(
        ageLong(AppLocalizationsVi(), dob, DateTime(2026, 10, 8)),
        '3 tuần tuổi',
      );
      expect(
        ageLong(AppLocalizationsEn(), dob, DateTime(2026, 10, 8)),
        '3 weeks old',
      );
      expect(
        ageShort(AppLocalizationsVi(), dob, DateTime(2026, 10, 8)),
        '3 tuần',
      );
      expect(
        ageShort(AppLocalizationsEn(), dob, DateTime(2026, 9, 18)),
        '1 day',
      );
    });
  });

  group('time zones (11b, P-014)', () {
    setUpAll(ensureTimeZones);

    test('offset labels follow Figma, including DST and half hours', () {
      expect(
        gmtOffsetLabel('Asia/Ho_Chi_Minh', DateTime.utc(2026, 10, 8)),
        'GMT+7',
      );
      expect(
        gmtOffsetLabel('America/New_York', DateTime.utc(2026, 1, 8)),
        'GMT−5',
      );
      expect(
        gmtOffsetLabel('America/New_York', DateTime.utc(2026, 7, 8)),
        'GMT−4',
      );
      expect(
        gmtOffsetLabel('Asia/Kolkata', DateTime.utc(2026, 7, 8)),
        'GMT+5:30',
      );
    });

    test(
      'the default list is the six Figma rows; search ignores Vietnamese marks',
      () {
        expect(searchZones('').map((z) => z.zone).take(2), [
          'Asia/Ho_Chi_Minh',
          'Asia/Singapore',
        ]);
        expect(searchZones(''), hasLength(6));
        expect(searchZones('ha noi').single.zone, 'Asia/Ho_Chi_Minh');
        expect(searchZones('Đài Bắc').single.zone, 'Asia/Singapore');
        expect(searchZones('los angeles').single.zone, 'America/Los_Angeles');
        expect(searchZones('xyz'), isEmpty);
      },
    );
  });

  group('createBabyProfile payload (contracts/baby.ts)', () {
    test('matches the server schema', () {
      final draft = SetupDraft(
        displayName: ' Mai ',
        relation: SelfRelation.other,
        relationCustom: 'Dì',
        nickname: ' Teddy ',
        dateOfBirth: DateTime(2026, 9, 7),
        gender: Gender.girl,
        timeZone: const TimeZoneSetting(zone: 'Asia/Ho_Chi_Minh', auto: true),
        avatarPreset: 3,
        trackers: {TrackerKind.growth, TrackerKind.bottle},
        requestId: '6f1c2b8e-1d2a-4c3b-9e8f-0a1b2c3d4e5f',
      );
      expect(draft.toInput().toJson(), {
        'requestId': '6f1c2b8e-1d2a-4c3b-9e8f-0a1b2c3d4e5f',
        'nickname': 'Teddy',
        'dateOfBirth': '2026-09-07',
        'gender': 'girl',
        'timeZone': {'mode': 'auto', 'zone': 'Asia/Ho_Chi_Minh'},
        'avatarPreset': 3,
        'trackers': ['bottle', 'growth'],
        'self': {
          'displayName': 'Mai',
          'relation': 'other',
          'relationCustom': 'Dì',
        },
      });
    });

    test(
      'defaults follow Figma: 4 trackers on, DOB today, a stable request id',
      () {
        final draft = SetupDraft();
        expect(draft.trackers, SetupDraft.defaultTrackers);
        final now = DateTime.now();
        expect(draft.dateOfBirth, DateTime(now.year, now.month, now.day));
        expect(draft.copyWith(nickname: 'Na').requestId, draft.requestId);
        expect(draft.whoComplete, isFalse);
        expect(draft.copyWith(displayName: 'Mai').whoComplete, isTrue);
        expect(
          draft
              .copyWith(displayName: 'Mai', relation: SelfRelation.other)
              .whoComplete,
          isFalse,
        );
      },
    );

    test('parses Firestore documents defensively', () {
      final baby = Baby.fromJson('b_1', {
        'nickname': 'Teddy',
        'avatar': {'kind': 'photo', 'version': 12},
        'trackers': ['sleep', 'unknown', 'bottle'],
        'timeZone': {'mode': 'manual', 'zone': 'Asia/Tokyo'},
      });
      expect(baby.avatar, const PhotoAvatar(12));
      expect(baby.trackers, [TrackerKind.sleep, TrackerKind.bottle]);
      expect(
        baby.timeZone,
        const TimeZoneSetting(zone: 'Asia/Tokyo', auto: false),
      );
      expect(Baby.fromJson('b_2', const {}).avatar, const PresetAvatar(1));
      expect(Membership.fromJson(const {'status': 'weird'}).isActive, isFalse);
    });
  });
}
