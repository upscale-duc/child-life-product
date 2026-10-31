import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/baby/baby_repository.dart';
import 'package:child_life/features/care/care_hub_screen.dart';
import 'package:child_life/features/library/content_calc.dart';
import 'package:child_life/features/library/content_models.dart';
import 'package:child_life/features/library/content_repository.dart';
import 'package:child_life/features/library/library_screens.dart';
import 'package:child_life/features/library/library_today.dart';
import 'package:child_life/features/today/today_for_baby.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:child_life/features/library/stage_screens.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/first_aid_fixtures.dart';
import '../helpers/library_fixtures.dart';
import '../helpers/router_pump.dart';

/// Thư viện chăm bé (4a–4f) and Giai đoạn của bé (2a–2c; D-076 #5, #7) on test-only fixtures
/// in the published `content.ts` shape. Teddy: born 17/09/2026, "today" 08/10/2026 (3 weeks).
void main() {
  group('published documents', () {
    test('the safe block model: unknown blocks (video, html) are dropped', () {
      final a = LbArticle.fromDoc('art_newborn_sleep', newbornSleepDoc)!;
      final vi = a.blocksFor(const Locale('vi'));
      expect(vi.map((b) => b.runtimeType.toString()), [
        'LbParagraph',
        'LbHeading',
        'LbBullets',
        'LbFigure',
        'LbHeading',
        'LbParagraph',
        'LbCallout',
      ]);
      expect((vi.last as LbCallout).tone, LbCalloutTone.doctor);
      expect(a.blocksFor(const Locale('en')).first, isA<LbParagraph>());
      expect(a.illustrative, isFalse);
      expect(a.revision, 2);
    });

    test('drafts, bad ids and missing essentials are not shown', () {
      expect(
        LbArticle.fromDoc('art_x1', {...newbornSleepDoc, 'status': 'draft'}),
        isNull,
      );
      expect(LbArticle.fromDoc('Bad Id', newbornSleepDoc), isNull);
      expect(
        LbArticle.fromDoc('art_x1', {...newbornSleepDoc, 'topic': 'toys'}),
        isNull,
      );
      expect(
        LbArticle.fromDoc('art_x1', {
          ...newbornSleepDoc,
          'ageWeeks': {'from': 5, 'to': 2},
        }),
        isNull,
      );
    });

    test('"illustrative" holds until a review is recorded (P-141)', () {
      final draft = LbArticle.fromDoc('art_x1', {
        ...newbornSleepDoc,
        'review': null,
        'illustrative': false,
      })!;
      expect(draft.illustrative, isTrue);
      final s = fixtureStages().firstWhere((s) => s.id == 'stg_w0');
      expect(s.illustrative, isTrue);
      expect(
        fixtureStages().firstWhere((s) => s.id == 'stg_w3').review,
        isNotNull,
      );
    });
  });

  group('ages (content.ts ageInUnit / stageFor)', () {
    test('completed weeks and months; month ends clamp', () {
      final dob = DateTime(2026, 9, 17);
      expect(lbAgeIn(LbUnit.week, dob, DateTime(2026, 10, 8)), 3);
      expect(lbAgeIn(LbUnit.month, dob, DateTime(2026, 10, 16)), 0);
      expect(lbAgeIn(LbUnit.month, dob, DateTime(2026, 10, 17)), 1);
      expect(
        lbAgeIn(LbUnit.month, DateTime(2026, 1, 31), DateTime(2026, 2, 28)),
        1,
      );
      expect(lbAgeIn(LbUnit.week, dob, DateTime(2026, 9, 1)), 0);
    });

    test('the current stage: narrowest first where ranges overlap', () {
      final stages = fixtureStages();
      final dob = DateTime(2026, 9, 17);
      expect(lbStageFor(stages, dob, DateTime(2026, 10, 8))?.id, 'stg_w3');
      // Day 31: 4 weeks (3–4 tuần) and 1 month (1 tháng) both hold; the 2-week range is narrower.
      expect(lbStageFor(stages, dob, DateTime(2026, 10, 18))?.id, 'stg_w3');
      expect(lbStageFor(stages, dob, DateTime(2026, 10, 22))?.id, 'stg_m1');
      expect(lbStageFor(stages, dob, DateTime(2026, 9, 1)), isNull);
      expect(lbSortStages(stages).map((s) => s.id), [
        'stg_w0',
        'stg_w3',
        'stg_m1',
        'stg_m2',
        'stg_m3',
      ]);
    });
  });

  group('4b / 4c search and filters', () {
    final all = fixtureArticles()
        .where((a) => a.library == LbLibrary.care)
        .toList();

    test('typed without marks; title hits first', () {
      final hits = const LbFilter(query: 'ngu').apply(all);
      expect(hits.first.id, 'art_newborn_sleep');
      expect(hits.map((a) => a.id), contains('art_sleep_position'));
      expect(
        const LbFilter(query: 'ham ta').apply(all).first.id,
        'art_diaper_rash',
      );
      expect(const LbFilter(query: 'zzz').apply(all), isEmpty);
    });

    test('topic, age overlap and reading time; several values = any', () {
      final sleep0to3 = const LbFilter(
        topics: {LbTopic.sleep},
        ages: {LbAgeBand.m0to3},
      ).apply(all);
      // "Tư thế ngủ cho bé" is 0–12 months and still matches 0–3 (overlap).
      expect(sleep0to3.map((a) => a.id).toSet(), {
        'art_newborn_sleep',
        'art_day_night',
        'art_sleep_position',
      });
      expect(
        const LbFilter(ages: {LbAgeBand.y1to2}).apply(all).map((a) => a.id),
        ['art_fever'],
      );
      expect(
        const LbFilter(times: {LbReadTime.long}).apply(all).map((a) => a.id),
        ['art_fever'],
      );
      expect(
        const LbFilter(
          times: {LbReadTime.short, LbReadTime.long},
        ).apply(all).length,
        2,
      );
      final quick = const LbFilter(sort: LbSort.shortest).apply(all);
      expect(quick.first.readingMinutes, 2);
    });
  });

  group('4a–4f screens', () {
    testWidgets('4a: topics, "Hợp với Teddy · 3 tuần", recent, badges', (
      tester,
    ) async {
      final store = FakeContentStore();
      final (visits, _) = await pumpRouted(
        tester,
        const LibraryHomeScreen(),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(store: store),
        ],
      );
      expect(find.text('Thư viện chăm bé'), findsOneWidget);
      expect(find.text('Sốt & ốm vặt'), findsOneWidget);
      expect(find.text('Hợp với Teddy · 3 tuần'), findsOneWidget);
      // Ăn dặm is a separate library.
      expect(find.text('Cháo rây đầu tiên'), findsNothing);
      // D-082: no review note on cards and rows; only a footnote at the end of an article.
      expect(find.byKey(const Key('lbIllustrative')), findsNothing);
      await tester.tap(find.byKey(const Key('lbTopic_sleep')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/library/search?topic=sleep');
    });

    testWidgets('4a: save from a row shows the toast to "Đã lưu"', (
      tester,
    ) async {
      final store = FakeContentStore();
      final (visits, _) = await pumpRouted(
        tester,
        const LibraryHomeScreen(),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(store: store),
        ],
      );
      await tester.ensureVisible(
        find.byKey(const Key('lbBookmark_art_diaper_rash')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lbBookmark_art_diaper_rash')));
      await tester.pump();
      expect(store.calls, ['save art_diaper_rash r1']);
      expect(find.text('Đã lưu · xem trong Thư viện › Đã lưu'), findsOneWidget);
      await tester.tap(find.text('Xem'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/library/saved');
    });

    testWidgets('nothing published: an honest empty state, no samples', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const LibraryHomeScreen(),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(articles: []),
        ],
      );
      expect(find.text('Thư viện đang được chuẩn bị'), findsOneWidget);
      expect(find.text('Mới cập nhật'), findsNothing);
    });

    testWidgets('offline: the saved-copy banner', (tester) async {
      await pumpRouted(
        tester,
        const LibraryHomeScreen(),
        overrides: [
          ...careOverrides(online: false),
          ...libraryOverrides(fromCache: true),
        ],
      );
      expect(
        find.text('Không có kết nối. Thư viện đang hiện bản đã lưu trên máy.'),
        findsOneWidget,
      );
      expect(find.text('Giấc ngủ của bé sơ sinh'), findsWidgets);
    });

    testWidgets('4b + 4c: filter sheet with a live count, chips removable', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const LibrarySearchScreen(),
        overrides: [...careOverrides(), ...libraryOverrides()],
      );
      expect(find.text('9 bài viết'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('lbQuery')), 'ngủ');
      await tester.pumpAndSettle();
      expect(find.text('2 bài viết'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lbFilters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lbChip_m0to3')));
      await tester.tap(find.byKey(const Key('lbChip_short')));
      await tester.pumpAndSettle();
      expect(find.text('Xem 1 bài'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lbApply')));
      await tester.pumpAndSettle();
      expect(find.text('Bộ lọc · 2'), findsOneWidget);
      expect(find.text('1 bài viết'), findsOneWidget);
      expect(find.text('Tư thế ngủ cho bé'), findsOneWidget);
      await tester.tap(find.text('Dưới 3 phút'));
      await tester.pumpAndSettle();
      expect(find.text('2 bài viết'), findsOneWidget);
    });

    testWidgets('4d: blocks as native text, doctor callout → Sơ cứu', (
      tester,
    ) async {
      final store = FakeContentStore();
      final (visits, _) = await pumpRouted(
        tester,
        const ArticleScreen(articleId: 'art_newborn_sleep'),
        overrides: [
          ...careOverrides(firstAid: seedFirstAidPack()),
          ...libraryOverrides(store: store),
        ],
      );
      expect(find.text('Giấc ngủ của bé sơ sinh'), findsOneWidget);
      expect(find.text('Nhận biết bé buồn ngủ'), findsOneWidget);
      expect(find.text('Ngáp, dụi mắt, kéo tai'), findsOneWidget);
      expect(find.textContaining('<script>'), findsNothing);
      expect(find.textContaining('BS. Thu Hà'), findsOneWidget);
      expect(find.byKey(const Key('lbIllustrative')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('lbOpenFirstAid')));
      await tester.pumpAndSettle();
      expect(find.text('Khi nào nên hỏi bác sĩ'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lbOpenFirstAid')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/utilities/first-aid');
    });

    testWidgets('4d / 4e: Lưu → "Đã lưu"; a newer revision is marked read', (
      tester,
    ) async {
      final store = FakeContentStore();
      await pumpRouted(
        tester,
        const ArticleScreen(articleId: 'art_bath'),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(store: store),
        ],
      );
      expect(find.byKey(const Key('lbIllustrative')), findsOneWidget);
      await tester.tap(find.byKey(const Key('lbSave')));
      await tester.pump();
      expect(store.calls, ['save art_bath r1']);
      expect(find.text('Đã lưu · xem trong Thư viện › Đã lưu'), findsOneWidget);

      final store2 = FakeContentStore();
      await pumpRouted(
        tester,
        const ArticleScreen(articleId: 'art_newborn_sleep'),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(
            store: store2,
            saved: [
              (
                id: 'art_newborn_sleep',
                savedAt: DateTime(2026, 10, 2),
                revision: 1,
              ),
            ],
          ),
        ],
      );
      expect(store2.calls, ['read art_newborn_sleep r2']);
      expect(
        find.descendant(
          of: find.byKey(const Key('lbSave')),
          matching: find.text('Đã lưu'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('lbSave')));
      await tester.pump();
      expect(store2.calls.last, 'unsave art_newborn_sleep');
      expect(find.text('Hoàn tác'), findsOneWidget);
    });

    testWidgets('4f: saved list, the updated banner, empty state', (
      tester,
    ) async {
      final (visits, _) = await pumpRouted(
        tester,
        const SavedArticlesScreen(),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(
            saved: [
              (
                id: 'art_newborn_sleep',
                savedAt: DateTime(2026, 10, 8, 9),
                revision: 1,
              ),
              (id: 'art_pumping', savedAt: DateTime(2026, 10, 2), revision: 1),
              (id: 'art_gone', savedAt: DateTime(2026, 9, 28), revision: 1),
            ],
          ),
        ],
      );
      expect(find.text('Giấc ngủ · lưu hôm nay'), findsOneWidget);
      expect(find.text('Bú & sữa · lưu 02/10'), findsOneWidget);
      expect(
        find.text(
          'Bài “Giấc ngủ của bé sơ sinh” vừa được cập nhật. Mở để xem bản mới.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('lbUpdated_art_newborn_sleep')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/library/a/art_newborn_sleep');

      await pumpRouted(
        tester,
        const SavedArticlesScreen(),
        overrides: [...careOverrides(), ...libraryOverrides()],
      );
      expect(find.text('Chưa lưu bài nào'), findsOneWidget);
    });
  });

  group('2a–2c Giai đoạn của bé', () {
    testWidgets('2a: ordered, current stage marked, opens 2b', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const StagesScreen(),
        overrides: [...careOverrides(), ...libraryOverrides()],
      );
      expect(find.text('Giai đoạn của bé'), findsOneWidget);
      expect(find.text('Bé đang ở đây'), findsOneWidget);
      expect(find.text('3–4 tuần'), findsOneWidget);
      expect(find.text('0–2 tuần'), findsOneWidget);
      expect(find.byKey(const Key('lbNoDob')), findsNothing);
      await tester.tap(find.text('Bé nhìn theo mặt người, nghe giọng quen'));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/stages/stg_w3');
    });

    testWidgets('audience: a caregiver does not see a parents-only stage', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const StagesScreen(),
        overrides: [
          ...careOverrides(me: lan),
          ...libraryOverrides(),
        ],
      );
      expect(find.text('Với tay, nắm đồ chơi'), findsNothing);
      expect(find.text('Giữ đầu vững hơn khi nằm sấp'), findsOneWidget);
    });

    testWidgets('2c: no date of birth: a parent adds it', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const StagesScreen(),
        overrides: [
          // The fixture's profile, replaced by one without a readable date of birth.
          ...careOverrides().where(
            (o) => !'$o'.contains('<BabyPrivateProfile?'),
          ),
          ...libraryOverrides(),
          babyPrivateProfileProvider.overrideWith(
            (ref, id) => Stream.value(
              BabyPrivateProfile.fromJson(const {'dateOfBirth': ''}),
            ),
          ),
        ],
      );
      expect(find.text('Thêm ngày sinh của bé'), findsOneWidget);
      expect(find.text('Bé đang ở đây'), findsNothing);
      await tester.tap(find.byKey(const Key('lbAddDob')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/baby-edit/${teddy.id}');
    });

    testWidgets('2c: a member who may not see it reads every stage', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const StagesScreen(),
        overrides: [
          ...careOverrides(me: lan),
          ...libraryOverrides(),
        ],
      );
      expect(find.text('Chưa biết bé đang ở giai đoạn nào'), findsOneWidget);
      expect(find.byKey(const Key('lbAddDob')), findsNothing);
      expect(find.text('Làm quen với thế giới mới'), findsOneWidget);
    });

    testWidgets('2b: cards, related articles, review footnote', (tester) async {
      final (visits, _) = await pumpRouted(
        tester,
        const StageDetailScreen(stageId: 'stg_w3'),
        overrides: [...careOverrides(), ...libraryOverrides()],
      );
      expect(find.text('Teddy · 3 tuần'), findsOneWidget);
      expect(find.text('Bé đang thế nào'), findsOneWidget);
      expect(find.text('Để bé nhìn mặt bạn thật gần'), findsOneWidget);
      // Milestones are hidden until Mốc phát triển registers its route.
      expect(find.text('Mốc thường gặp'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const Key('lbStageArticle_art_day_night')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('BS. Thu Hà'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lbStageArticle_art_day_night')));
      await tester.pumpAndSettle();
      expect(visits.last.location, '/library/a/art_day_night');
    });

    testWidgets('empty: nothing published yet', (tester) async {
      await pumpRouted(
        tester,
        const StagesScreen(),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(stages: []),
        ],
      );
      expect(
        find.text('Nội dung theo giai đoạn đang được chuẩn bị'),
        findsOneWidget,
      );
    });
  });

  group('Hôm nay "Dành cho bé hôm nay" cards', () {
    test(
      'the current stage, then two reads for the age that move on each week (D-154 P3)',
      () async {
        SharedPreferences.setMockInitialValues(const {});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            minuteClockProvider.overrideWith(
              (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
            ),
            ...careOverrides(),
            ...libraryOverrides(),
          ],
        );
        addTearDown(container.dispose);
        final q = (babyId: teddy.id, uid: mai.uid, languageCode: 'vi');
        container.listen(lbForBabyCardsProvider(q), (_, _) {});
        // Let the streams deliver.
        await container.read(babyPrivateProfileProvider(teddy.id).future);
        await container.read(lbStagesProvider.future);
        await container.read(lbArticlesProvider.future);
        await container.read(minuteClockProvider.future);
        await Future<void>.delayed(Duration.zero, () {
          final cards = container.read(articleForBabyCardsProvider(q));
          expect(cards.map((c) => c.id), [
            'stage:stg_w3',
            // 3 weeks old: the pair from the newest-first list starting at 3 × 2.
            'article:art_day_night',
            'article:art_sleep_position',
          ]);
          expect(cards.first.kicker, 'Giai đoạn của bé · 3–4 tuần');
        });
      },
    );
  });

  group('entry and rename (D-076 #5)', () {
    testWidgets(
      'Chăm sóc opens Giai đoạn của bé and the library once published',
      (tester) async {
        final (visits, _) = await pumpRouted(
          tester,
          const Scaffold(body: CareHubScreen()),
          overrides: [...careOverrides(), ...libraryOverrides()],
        );
        expect(find.text('Giai đoạn của bé'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('careStages')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('careStages')));
        await tester.pumpAndSettle();
        expect(visits.last.location, '/stages');
      },
    );

    testWidgets('nothing published: both stay "Sớm ra mắt"', (tester) async {
      await pumpRouted(
        tester,
        const Scaffold(body: CareHubScreen()),
        overrides: [
          ...careOverrides(),
          ...libraryOverrides(articles: [], stages: []),
        ],
      );
      expect(find.byKey(const Key('careStages')), findsNothing);
      expect(find.byKey(const Key('careLibrary')), findsNothing);
      expect(find.text('Giai đoạn của bé'), findsOneWidget);
    });

    test('no app string calls this content "thẻ theo tuổi / tuần"', () async {
      for (final locale in ['vi', 'en']) {
        final arb =
            jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, Object?>;
        for (final MapEntry(:key, :value) in arb.entries) {
          if (key.startsWith('@') || value is! String) continue;
          expect(
            value.toLowerCase(),
            isNot(matches(RegExp('thẻ theo (tuổi|tuần)|age cards?'))),
            reason: key,
          );
        }
      }
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(vi.careAgeCards, 'Giai đoạn của bé');
      expect(vi.lbStagesTitle, 'Giai đoạn của bé');
      expect(en.careAgeCards, 'Your baby’s stages');
    });
  });
}
